# ~/.config/powershell/functions.ps1
# User-facing PowerShell functions and aliases.

function Get-CurrentShell {
  "PowerShell $($PSVersionTable.PSVersion)"
}

function Get-ShellFunction {
  Get-Command -CommandType Function |
    Where-Object {
      $_.Source -eq '' -and $_.Name -notlike '_*' -and
      $_.Name -notin 'Invoke-FzfPathAction', 'Invoke-FzfKeyBinding'
    } |
    Sort-Object -Property Name |
    Select-Object -Property Name, Definition
}

function Start-Lazygit {
  if (Test-Command lazygit) {
    lazygit @args
  }
}

function Show-Highlight {
  if (Test-Command rg) {
    rg --passthru @args
  }
}

Set-Alias -Name lg -Value Start-Lazygit
Set-Alias -Name hl -Value Show-Highlight
Set-Alias -Name C -Value Set-Clipboard

# Print common proxy variables, redacting URL credentials.
function Get-Proxy {
  [CmdletBinding(PositionalBinding = $false)]
  param()

  foreach ($name in @(
      'http_proxy', 'https_proxy', 'HTTP_PROXY', 'HTTPS_PROXY',
      'all_proxy', 'ALL_PROXY', 'no_proxy', 'NO_PROXY'
    )) {
    $item = Get-Item -LiteralPath "Env:$name" -ErrorAction Ignore
    $value = if ($null -eq $item) { '<unset>' } else {
      $item.Value -creplace '(?s)\A(.*?://)[^@]*@', '$1<redacted>@'
    }
    "$name=$value"
  }
}

# Replace proxy endpoints, preserving bypass lists unless explicitly supplied.
function Enable-Proxy {
  [CmdletBinding(PositionalBinding = $false)]
  param(
    [ValidateNotNullOrEmpty()][string] $HttpProxy,
    [ValidateNotNullOrEmpty()][string] $HttpsProxy,
    [ValidateNotNullOrEmpty()][string] $SocksProxy,
    [AllowEmptyString()][string] $BypassList
  )

  if (-not ($PSBoundParameters.ContainsKey('HttpProxy') -or
      $PSBoundParameters.ContainsKey('HttpsProxy') -or
      $PSBoundParameters.ContainsKey('SocksProxy'))) {
    throw "$($MyInvocation.MyCommand.Name): supply at least one of " +
    '-HttpProxy, -HttpsProxy, or -SocksProxy.'
  }

  # IWebProxy can be called on .NET worker threads without a PowerShell runspace.
  if (-not ('DotfilesProcessProxy' -as [type])) {
    Add-Type -TypeDefinition @'
using System;
using System.Net;

public sealed class DotfilesProcessProxy : IWebProxy, ICredentials
{
    private readonly string http;
    private readonly string https;
    private readonly string socks;
    private readonly string[] bypass;

    public DotfilesProcessProxy(string http, string https, string socks, string noProxy)
    {
        this.http = http;
        this.https = https;
        this.socks = socks;
        bypass = (noProxy ?? "").Split(',');
        Credentials = this;
    }

    public ICredentials Credentials { get; set; }

    private string Endpoint(Uri destination)
    {
        string endpoint = destination.Scheme == "https" || destination.Scheme == "wss"
            ? https : http;
        return string.IsNullOrEmpty(endpoint) ? socks : endpoint;
    }

    public bool IsBypassed(Uri destination)
    {
        if (string.IsNullOrEmpty(Endpoint(destination))) return true;
        string host = destination.IdnHost.Trim('[', ']');
        foreach (string entry in bypass)
        {
            string name = entry.Trim();
            if (name.Length == 0) continue;
            if (name[0] == '.')
            {
                if (host.Equals(name.Substring(1), StringComparison.OrdinalIgnoreCase) ||
                    host.EndsWith(name, StringComparison.OrdinalIgnoreCase)) return true;
            }
            else if (host.Equals(name.Trim('[', ']'), StringComparison.OrdinalIgnoreCase))
            {
                return true;
            }
        }
        return false;
    }

    public Uri GetProxy(Uri destination)
    {
        if (IsBypassed(destination)) return destination;
        string endpoint = Endpoint(destination);
        // .NET calls remote-DNS SOCKS5 "socks5"; retain socks5h in the environment.
        if (endpoint.StartsWith("socks5h://", StringComparison.OrdinalIgnoreCase))
            endpoint = "socks5://" + endpoint.Substring(10);
        if (!endpoint.Contains("://")) endpoint = "http://" + endpoint;
        // Defer URI parsing until a request so enable accepts raw endpoint strings.
        return new Uri(endpoint);
    }

    public NetworkCredential GetCredential(Uri uri, string authType)
    {
        string userInfo = uri.UserInfo;
        if (userInfo.Length == 0) return null;
        int separator = userInfo.IndexOf(':');
        string user = separator < 0 ? userInfo : userInfo.Substring(0, separator);
        string password = separator < 0 ? "" : userInfo.Substring(separator + 1);
        return new NetworkCredential(
            Uri.UnescapeDataString(user), Uri.UnescapeDataString(password));
    }
}
'@
  }

  $previous = @(Get-Proxy)
  foreach ($name in @(
      'http_proxy', 'https_proxy', 'HTTP_PROXY', 'HTTPS_PROXY', 'all_proxy', 'ALL_PROXY'
    )) {
    Remove-Item -LiteralPath "Env:$name" -ErrorAction Ignore
  }
  if ($PSBoundParameters.ContainsKey('HttpProxy')) {
    $env:http_proxy = $env:HTTP_PROXY = $HttpProxy
  }
  if ($PSBoundParameters.ContainsKey('HttpsProxy')) {
    $env:https_proxy = $env:HTTPS_PROXY = $HttpsProxy
  }
  if ($PSBoundParameters.ContainsKey('SocksProxy')) {
    $env:all_proxy = $env:ALL_PROXY = $SocksProxy
  }
  if ($PSBoundParameters.ContainsKey('BypassList')) {
    $env:no_proxy = $env:NO_PROXY = $BypassList
  }

  [System.Net.Http.HttpClient]::DefaultProxy = [DotfilesProcessProxy]::new(
    $HttpProxy, $HttpsProxy, $SocksProxy, $env:no_proxy
  )

  'Proxy enabled.'
  'Previous proxy settings:'
  $previous
  'Current proxy settings:'
  Get-Proxy
}

# Enable the local mixed-protocol listener used by native Karing installations.
function Enable-KaringProxy {
  [CmdletBinding(PositionalBinding = $false)]
  param()

  $proxyParameters = @{
    HttpProxy  = 'http://127.0.0.1:3067'
    HttpsProxy = 'http://127.0.0.1:3067'
    SocksProxy = 'socks5h://127.0.0.1:3067'
  }
  Enable-Proxy @proxyParameters
}

# Disable endpoints while preserving bypass lists.
function Disable-Proxy {
  [CmdletBinding(PositionalBinding = $false)]
  param()

  $previous = @(Get-Proxy)
  foreach ($name in @(
      'http_proxy', 'https_proxy', 'HTTP_PROXY', 'HTTPS_PROXY', 'all_proxy', 'ALL_PROXY'
    )) {
    Remove-Item -LiteralPath "Env:$name" -ErrorAction Ignore
  }
  [System.Net.Http.HttpClient]::DefaultProxy = [System.Net.WebProxy]::new()

  'Proxy disabled.'
  'Previous proxy settings:'
  $previous
  'Current proxy settings:'
  Get-Proxy
}

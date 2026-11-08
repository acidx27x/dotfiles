# ~/.config/powershell/functions.ps1
# User-facing PowerShell functions and aliases.

function current-shell {
  "PowerShell $($PSVersionTable.PSVersion)"
}

function functions-help {
  Get-Command -CommandType Function |
    Where-Object { $_.Source -eq '' -and $_.Name -notlike '_*' } |
    Sort-Object -Property Name |
    Select-Object -Property Name, Definition
}

function lg {
  if (Test-Command lazygit) {
    lazygit @args
  }
}

function hl {
  if (Test-Command rg) {
    rg --passthru @args
  }
}

function C {
  Set-Clipboard @args
}

# Print common proxy variables, redacting URL credentials.
function proxy-status {
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
function proxy-enable {
  [CmdletBinding(PositionalBinding = $false)]
  param(
    [ValidateNotNullOrEmpty()][string] $Http,
    [ValidateNotNullOrEmpty()][string] $Https,
    [ValidateNotNullOrEmpty()][string] $Socks,
    [AllowEmptyString()][string] $NoProxy
  )

  if (-not ($PSBoundParameters.ContainsKey('Http') -or
      $PSBoundParameters.ContainsKey('Https') -or
      $PSBoundParameters.ContainsKey('Socks'))) {
    throw "$($MyInvocation.MyCommand.Name): supply at least one of -Http, -Https, or -Socks."
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

  $previous = @(proxy-status)
  foreach ($name in @(
      'http_proxy', 'https_proxy', 'HTTP_PROXY', 'HTTPS_PROXY', 'all_proxy', 'ALL_PROXY'
    )) {
    Remove-Item -LiteralPath "Env:$name" -ErrorAction Ignore
  }
  if ($PSBoundParameters.ContainsKey('Http')) {
    $env:http_proxy = $env:HTTP_PROXY = $Http
  }
  if ($PSBoundParameters.ContainsKey('Https')) {
    $env:https_proxy = $env:HTTPS_PROXY = $Https
  }
  if ($PSBoundParameters.ContainsKey('Socks')) {
    $env:all_proxy = $env:ALL_PROXY = $Socks
  }
  if ($PSBoundParameters.ContainsKey('NoProxy')) {
    $env:no_proxy = $env:NO_PROXY = $NoProxy
  }

  [System.Net.Http.HttpClient]::DefaultProxy = [DotfilesProcessProxy]::new(
    $Http, $Https, $Socks, $env:no_proxy
  )

  'Proxy enabled.'
  'Previous proxy settings:'
  $previous
  'Current proxy settings:'
  proxy-status
}

# Enable the local mixed-protocol listener used by native Karing installations.
function karing-proxy-enable {
  [CmdletBinding(PositionalBinding = $false)]
  param()

  proxy-enable -Http 'http://127.0.0.1:3067' -Https 'http://127.0.0.1:3067' `
    -Socks 'socks5h://127.0.0.1:3067'
}

# Disable endpoints while preserving bypass lists.
function proxy-disable {
  [CmdletBinding(PositionalBinding = $false)]
  param()

  $previous = @(proxy-status)
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
  proxy-status
}

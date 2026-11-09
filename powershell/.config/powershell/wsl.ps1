# ~/.config/powershell/wsl.ps1
# Windows-side helpers for WSL networking.

function Get-WslAddress {
  param([string] $Distro)

  $output = (& wsl.exe -d $Distro -- hostname -I) -join ' '
  if ($LASTEXITCODE -ne 0) {
    return
  }
  foreach ($value in ($output -split '\s+')) {
    $address = $null
    if ([Net.IPAddress]::TryParse($value, [ref]$address) -and
      $address.AddressFamily -eq [Net.Sockets.AddressFamily]::InterNetwork) {
      return $address
    }
  }
}

function Set-WslTcpForward {
  param([Net.IPAddress] $Address, [int] $ListenPort, [int] $TargetPort)

  $endpoint = @('v4tov4', 'listenaddress=0.0.0.0', "listenport=$ListenPort")
  & netsh.exe interface portproxy delete @endpoint | Out-Null
  $target = @("connectaddress=$Address", "connectport=$TargetPort")
  & netsh.exe interface portproxy add @endpoint @target | Out-Null
  if ($LASTEXITCODE -ne 0) {
    throw "$($MyInvocation.MyCommand.Name): could not forward TCP " +
    "$ListenPort to ${Address}:$TargetPort."
  }
}

function Set-WslInboundRule {
  param([string] $Name, [string] $Protocol, [string[]] $Port, [string[]] $RemoteAddress)

  $existing = Get-NetFirewallRule -Name $Name -ErrorAction SilentlyContinue
  $settings = @{
    Enabled       = 'True'
    Profile       = 'Any'
    Direction     = 'Inbound'
    Action        = 'Allow'
    RemoteAddress = $RemoteAddress
    Protocol      = $Protocol
    LocalPort     = $Port
  }
  if ($existing) {
    $existing | Set-NetFirewallRule @settings
  }
  else {
    New-NetFirewallRule @settings -Name $Name -DisplayName $Name | Out-Null
  }
}

function Start-WslSshForward {
  <#
  .SYNOPSIS
  Forward a Windows TCP port to SSH inside WSL2 in NAT mode.
  .DESCRIPTION
  Run in an elevated PowerShell terminal with sshd listening inside WSL. Configures
  IPv4 portproxy on all Windows interfaces and a source-scoped inbound firewall rule.
  Returns immediately. Settings persist; rerun after the WSL IP changes.
  Use Remove-WslForward to remove all helper-created SSH and Mosh forwarding rules.
  .EXAMPLE
  Start-WslSshForward -Distro Astra1.8 -AllowedRemoteAddress '10.10.0.14'
  # Connect with: ssh -p 2200 user@WINDOWS_IP
  #>
  [CmdletBinding(PositionalBinding = $false)]
  param(
    [Parameter(Mandatory)][ValidateNotNullOrEmpty()][ValidatePattern('\S')][string] $Distro,
    [ValidateRange(1, 65535)][int] $ListenPort = 2200,
    [ValidateRange(1, 65535)][int] $TargetPort = 22,
    [Parameter(Mandatory)][ValidateNotNullOrEmpty()][string[]] $AllowedRemoteAddress
  )

  $ErrorActionPreference = 'Stop'
  $PSNativeCommandUseErrorActionPreference = $false
  $functionName = $MyInvocation.MyCommand.Name
  foreach ($command in 'wsl.exe', 'netsh.exe', 'Get-NetFirewallRule') {
    if (-not (Test-Command $command)) {
      throw "${functionName}: required command '$command' is unavailable."
    }
  }

  $identity = [Security.Principal.WindowsIdentity]::GetCurrent()
  $principal = [Security.Principal.WindowsPrincipal]::new($identity)
  if (-not $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    throw "${functionName}: run in an elevated PowerShell terminal."
  }

  $address = Get-WslAddress -Distro $Distro
  if (-not $address) {
    throw "${functionName}: could not determine the IPv4 address of '$Distro'."
  }
  Set-WslTcpForward -Address $address -ListenPort $ListenPort -TargetPort $TargetPort
  $rule = @{
    Name          = "WSL-NAT-SSH-$ListenPort"
    Protocol      = 'TCP'
    Port          = @("$ListenPort")
    RemoteAddress = $AllowedRemoteAddress
  }
  Set-WslInboundRule @rule
  Write-Information "TCP $ListenPort -> ${address}:$TargetPort" -InformationAction Continue
}

function Start-WslMoshForward {
  <#
  .SYNOPSIS
  Forward SSH and Mosh from Windows to WSL2 in NAT mode.
  .DESCRIPTION
  Run in an elevated PowerShell 7 terminal with sshd and mosh-server installed in WSL.
  TCP uses netsh portproxy; UDP uses one IPv4 socket per port. The relay runs until
  Ctrl+C and refreshes the WSL address every 15 seconds. TCP and firewall rules persist
  after stopping; UDP sockets are closed. Run only one relay for the selected ports.

  Each UDP port tracks one client; another client on that port displaces it. Match the
  client's Mosh port range to UdpPort. AllowedRemoteAddress must match the source Windows
  sees (an IP, CIDR, or Any). Listeners bind all IPv4 interfaces; prefer a restricted source.
  WSL restarts terminate sessions; address refresh only repairs forwarding for new ones.
  Use -Verbose for packet logging. For UDP timeouts, check firewall, VPN and routing.
  .EXAMPLE
  Start-WslMoshForward -Distro Astra1.8 -AllowedRemoteAddress '10.10.0.14'

  From the client:
  mosh --ssh="ssh -p 2200" -p 60001:60005 user@WINDOWS_IP
  Add --server=/home/linuxbrew/.linuxbrew/bin/mosh-server when using Linuxbrew.
  Omit --server if mosh-server is already on the noninteractive SSH PATH.
  .EXAMPLE
  Start-WslMoshForward -Distro Astra1.8 -UdpPort 60001 -AllowedRemoteAddress '10.10.0.0/24' -Verbose
  .NOTES
  After stopping, use Remove-WslForward to remove persistent forwarding and firewall rules.
  #>
  [CmdletBinding(PositionalBinding = $false)]
  param(
    [Parameter(Mandatory)][ValidateNotNullOrEmpty()][ValidatePattern('\S')][string] $Distro,
    [ValidateRange(1, 65535)][int] $ListenPort = 2200,
    [ValidateRange(1, 65535)][int] $TargetPort = 22,
    [ValidateCount(1, 32)][ValidateRange(1, 65535)][int[]] $UdpPort = (60001..60005),
    [Parameter(Mandatory)][ValidateNotNullOrEmpty()][string[]] $AllowedRemoteAddress
  )

  $ErrorActionPreference = 'Stop'
  $PSNativeCommandUseErrorActionPreference = $false
  $functionName = $MyInvocation.MyCommand.Name
  foreach ($command in 'wsl.exe', 'netsh.exe', 'Get-NetFirewallRule') {
    if (-not (Test-Command $command)) {
      throw "${functionName}: required command '$command' is unavailable."
    }
  }

  $identity = [Security.Principal.WindowsIdentity]::GetCurrent()
  $principal = [Security.Principal.WindowsPrincipal]::new($identity)
  if (-not $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    throw "${functionName}: run in an elevated PowerShell terminal."
  }

  $wslAddress = Get-WslAddress -Distro $Distro
  if (-not $wslAddress) {
    throw "${functionName}: could not determine the IPv4 address of '$Distro'."
  }

  $ports = @($UdpPort | Sort-Object -Unique)
  $sockets = @{}
  $clients = @{}
  try {
    # Bind every port before changing forwarding or firewall rules.
    foreach ($port in $ports) {
      $sockets[$port] = [Net.Sockets.UdpClient]::new($port)
    }

    Set-WslTcpForward -Address $wslAddress -ListenPort $ListenPort -TargetPort $TargetPort
    foreach ($rule in @(
        @{ Name = "WSL-NAT-SSH-$ListenPort"; Protocol = 'TCP'; Port = @("$ListenPort") }
        @{ Name = 'WSL-NAT-Mosh-UDP'; Protocol = 'UDP'; Port = [string[]]$ports }
      )) {
      Set-WslInboundRule @rule -RemoteAddress $AllowedRemoteAddress
    }

    $message = "TCP $ListenPort -> ${wslAddress}:$TargetPort; " +
    "UDP $($ports -join ',') -> $wslAddress. Ctrl+C stops UDP."
    Write-Information $message -InformationAction Continue
    $nextRefresh = [DateTime]::UtcNow.AddSeconds(15)
    while ($true) {
      foreach ($port in $ports) {
        $socket = $sockets[$port]
        if (-not $socket.Client.Poll(1000, [Net.Sockets.SelectMode]::SelectRead)) {
          continue
        }

        $sender = [Net.IPEndPoint]::new([Net.IPAddress]::Any, 0)
        try {
          $data = $socket.Receive([ref]$sender)
        }
        catch [Net.Sockets.SocketException] {
          # Windows can report ICMP port-unreachable while mosh-server is not listening.
          if ($_.Exception.SocketErrorCode -eq [Net.Sockets.SocketError]::ConnectionReset) {
            continue
          }
          throw
        }

        if ($sender.Address.Equals($wslAddress) -and $sender.Port -eq $port) {
          if (-not $clients.ContainsKey($port)) {
            continue
          }
          $destination = $clients[$port]
          Write-Verbose "UDP $port WSL -> $destination ($($data.Length) bytes)"
        }
        else {
          $clients[$port] = $sender
          $destination = [Net.IPEndPoint]::new($wslAddress, $port)
          Write-Verbose "UDP $port $sender -> WSL ($($data.Length) bytes)"
        }
        [void]$socket.Send($data, $data.Length, $destination)
      }

      if ([DateTime]::UtcNow -ge $nextRefresh) {
        $latestAddress = Get-WslAddress -Distro $Distro
        if ($latestAddress -and -not $latestAddress.Equals($wslAddress)) {
          Set-WslTcpForward -Address $latestAddress -ListenPort $ListenPort -TargetPort $TargetPort
          $wslAddress = $latestAddress
          $clients.Clear()
          Write-Verbose "WSL address changed to $wslAddress; TCP and UDP forwarding updated."
        }
        $nextRefresh = [DateTime]::UtcNow.AddSeconds(15)
      }
      Start-Sleep -Milliseconds 10
    }
  }
  finally {
    foreach ($socket in $sockets.Values) {
      $socket.Dispose()
    }
  }
}

function Remove-WslForward {
  <#
  .SYNOPSIS
  Remove all WSL NAT SSH and Mosh forwarding configuration created by these helpers.
  .DESCRIPTION
  Run in an elevated PowerShell terminal after stopping the relay. Removes all
  WSL-NAT-SSH-* firewall rules, their 0.0.0.0 TCP portproxy entries, and the
  WSL-NAT-Mosh-UDP firewall rule. Does not stop running relays.
  .EXAMPLE
  Remove-WslForward -WhatIf
  .EXAMPLE
  Remove-WslForward
  #>
  [CmdletBinding(SupportsShouldProcess, PositionalBinding = $false)]
  param()

  $ErrorActionPreference = 'Stop'
  $PSNativeCommandUseErrorActionPreference = $false
  $functionName = $MyInvocation.MyCommand.Name
  foreach ($command in 'netsh.exe', 'Get-NetFirewallRule', 'Remove-NetFirewallRule') {
    if (-not (Test-Command $command)) {
      throw "${functionName}: required command '$command' is unavailable."
    }
  }

  $identity = [Security.Principal.WindowsIdentity]::GetCurrent()
  $principal = [Security.Principal.WindowsPrincipal]::new($identity)
  if (-not $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    throw "${functionName}: run in an elevated PowerShell terminal."
  }

  $names = @('WSL-NAT-SSH-*', 'WSL-NAT-Mosh-UDP')
  $rules = Get-NetFirewallRule -Name $names -ErrorAction SilentlyContinue
  foreach ($rule in $rules) {
    $action = 'Remove firewall rule and matching TCP forwarding'
    if (-not $PSCmdlet.ShouldProcess($rule.Name, $action)) {
      continue
    }

    if ($rule.Name -match '^WSL-NAT-SSH-(\d{1,5})$') {
      $port = [int]$Matches[1]
      if ($port -ge 1 -and $port -le 65535) {
        $endpoint = @('v4tov4', 'listenaddress=0.0.0.0', "listenport=$port")
        & netsh.exe interface portproxy delete @endpoint | Out-Null
        if ($LASTEXITCODE -ne 0) {
          Write-Warning "${functionName}: TCP $port forwarding could not be removed or was absent."
        }
      }
    }
    Remove-NetFirewallRule -Name $rule.Name
  }
}

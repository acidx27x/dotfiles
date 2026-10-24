#Requires -Version 5.1

[CmdletBinding(SupportsShouldProcess = $true)]
param(
  [ValidateNotNullOrEmpty()]
  [string] $Root
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$ScoopInstallUrl = 'https://get.scoop.sh'

function Write-Info {
  param([Parameter(Mandatory)][string] $Message)

  Write-Host "[INFO] $Message"
}

function Get-DefaultScoopPaths {
  [PSCustomObject]@{
    User   = Join-Path $env:USERPROFILE 'scoop'
    Global = Join-Path $env:ProgramData 'scoop'
    Cache  = Join-Path (Join-Path $env:USERPROFILE 'scoop') 'cache'
  }
}

function Find-ScoopCommand {
  param([AllowNull()][PSCustomObject] $ExpectedPaths)

  $command = Get-Command scoop -ErrorAction SilentlyContinue | Select-Object -First 1
  if ($null -ne $command) {
    if ($command.PSObject.Properties.Name -contains 'Path' -and $command.Path) {
      return $command.Path
    }
    return $command.Name
  }

  $candidates = @()
  if ($null -ne $ExpectedPaths) {
    $candidates += Join-Path $ExpectedPaths.User 'shims\scoop.ps1'
  }
  else {
    $configuredPaths = Get-EffectiveScoopPaths
    $candidates += Join-Path $configuredPaths.User 'shims\scoop.ps1'
  }
  if ($env:SCOOP) {
    $candidates += Join-Path $env:SCOOP 'shims\scoop.ps1'
  }
  $candidates += Join-Path $env:USERPROFILE 'scoop\shims\scoop.ps1'

  foreach ($candidate in $candidates | Select-Object -Unique) {
    if (Test-Path -LiteralPath $candidate -PathType Leaf) {
      return $candidate
    }
  }

  return $null
}

function Get-ScoopConfig {
  $configHome = if ($env:XDG_CONFIG_HOME) {
    $env:XDG_CONFIG_HOME
  }
  else {
    Join-Path $env:USERPROFILE '.config'
  }
  $configPath = Join-Path $configHome 'scoop\config.json'

  if (-not (Test-Path -LiteralPath $configPath -PathType Leaf)) {
    return [PSCustomObject]@{}
  }

  return Get-Content -LiteralPath $configPath -Raw | ConvertFrom-Json
}

function Get-EffectiveScoopPaths {
  $defaults = Get-DefaultScoopPaths
  $config = Get-ScoopConfig

  $userPath = if ($env:SCOOP) {
    $env:SCOOP
  }
  elseif ($config.PSObject.Properties.Name -contains 'root_path' -and $config.root_path) {
    $config.root_path
  }
  else {
    $defaults.User
  }

  $globalPath = if ($env:SCOOP_GLOBAL) {
    $env:SCOOP_GLOBAL
  }
  elseif ($config.PSObject.Properties.Name -contains 'global_path' -and $config.global_path) {
    $config.global_path
  }
  else {
    $defaults.Global
  }

  $cachePath = if ($env:SCOOP_CACHE) {
    $env:SCOOP_CACHE
  }
  elseif ($config.PSObject.Properties.Name -contains 'cache_path' -and $config.cache_path) {
    $config.cache_path
  }
  else {
    Join-Path $userPath 'cache'
  }

  [PSCustomObject]@{
    User   = [System.IO.Path]::GetFullPath($userPath)
    Global = [System.IO.Path]::GetFullPath($globalPath)
    Cache  = [System.IO.Path]::GetFullPath($cachePath)
  }
}

function Test-SamePath {
  param(
    [Parameter(Mandatory)][string] $Left,
    [Parameter(Mandatory)][string] $Right
  )

  $leftPath = [System.IO.Path]::GetFullPath($Left).TrimEnd('\', '/')
  $rightPath = [System.IO.Path]::GetFullPath($Right).TrimEnd('\', '/')
  return [StringComparer]::OrdinalIgnoreCase.Equals($leftPath, $rightPath)
}

function Assert-ScoopPathsMatch {
  param(
    [Parameter(Mandatory)][PSCustomObject] $Expected,
    [Parameter(Mandatory)][PSCustomObject] $Actual
  )

  foreach ($name in 'User', 'Global', 'Cache') {
    if (-not (Test-SamePath -Left $Expected.$name -Right $Actual.$name)) {
      throw "Existing Scoop $name path is '$($Actual.$name)', not '$($Expected.$name)'. " +
      'This script does not migrate existing Scoop installations.'
    }
  }
}

function Invoke-Scoop {
  param(
    [Parameter(Mandatory)][string] $Command,
    [Parameter(Mandatory)][string[]] $Arguments
  )

  $global:LASTEXITCODE = 0
  & $Command @Arguments
  if ($LASTEXITCODE -ne 0) {
    throw "Scoop command failed with exit code $LASTEXITCODE`: scoop $($Arguments -join ' ')"
  }
}

function Show-ScoopPaths {
  param([Parameter(Mandatory)][PSCustomObject] $Paths)

  Write-Info "User root:  $($Paths.User)"
  Write-Info "Global root: $($Paths.Global)"
  Write-Info "Cache root:  $($Paths.Cache)"
}

function Main {
  if ($env:OS -ne 'Windows_NT') {
    throw 'This setup script only supports Windows.'
  }
  if ($ExecutionContext.SessionState.LanguageMode -ne 'FullLanguage') {
    throw 'Scoop requires PowerShell FullLanguage mode.'
  }
  $identity = [Security.Principal.WindowsIdentity]::GetCurrent()
  $principal = New-Object Security.Principal.WindowsPrincipal($identity)
  if ($principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    throw 'Run this setup from a non-elevated PowerShell session.'
  }

  $dotfilesRoot = [System.IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..'))
  $scoopfile = Join-Path $dotfilesRoot 'windows\scoop\Scoopfile.json'
  if (-not (Test-Path -LiteralPath $scoopfile -PathType Leaf)) {
    throw "Scoopfile is missing: $scoopfile"
  }
  $manifest = Get-Content -LiteralPath $scoopfile -Raw | ConvertFrom-Json
  if (@($manifest.buckets).Count -eq 0 -or @($manifest.apps).Count -eq 0) {
    throw "Scoopfile must declare at least one bucket and one app: $scoopfile"
  }

  $requestedPaths = $null
  if ($Root) {
    $parent = [Environment]::ExpandEnvironmentVariables($Root.Trim())
    if ([System.Management.Automation.WildcardPattern]::ContainsWildcardCharacters($parent) -or
      $parent -notmatch '^(?:[A-Za-z]:[\\/]|\\\\[^\\/]+[\\/][^\\/]+(?:[\\/]|$))') {
      throw "Scoop root must be an absolute drive or UNC path: $Root"
    }
    $parent = [System.IO.Path]::GetFullPath($parent)
    if (Test-Path -LiteralPath $parent -PathType Leaf) {
      throw "Scoop root exists but is not a directory: $parent"
    }
    $requestedPaths = [PSCustomObject]@{
      User   = Join-Path $parent 'User'
      Global = Join-Path $parent 'Global'
      Cache  = Join-Path $parent 'Cache'
    }
  }

  $scoopCommand = Find-ScoopCommand -ExpectedPaths $requestedPaths
  $scoopExists = $null -ne $scoopCommand
  if ($scoopExists) {
    $paths = Get-EffectiveScoopPaths
    if ($null -ne $requestedPaths) {
      Assert-ScoopPathsMatch -Expected $requestedPaths -Actual $paths
    }
    Write-Info "Using existing Scoop command: $scoopCommand"
  }
  else {
    $paths = if ($null -ne $requestedPaths) {
      $requestedPaths
    }
    else {
      Get-DefaultScoopPaths
    }

    if ($null -eq $requestedPaths) {
      Write-Info 'No -Root was supplied. Scoop would use its default locations:'
      Show-ScoopPaths -Paths $paths
      if (-not $WhatIfPreference) {
        try {
          $answer = Read-Host 'Install using these default Scoop locations? [y/N]'
        }
        catch {
          throw 'Cannot prompt for Scoop defaults. Rerun non-interactively with -Root.'
        }
        if ([string]::IsNullOrWhiteSpace($answer) -or
          $answer.Trim() -notmatch '^(y|yes)$') {
          throw 'Scoop setup cancelled. Rerun with -Root to select another location.'
        }
      }
    }

    $environmentPaths = @{
      SCOOP        = $paths.User
      SCOOP_GLOBAL = $paths.Global
      SCOOP_CACHE  = $paths.Cache
    }
    foreach ($name in $environmentPaths.Keys) {
      $value = [Environment]::GetEnvironmentVariable($name)
      if ($value -and -not (Test-SamePath -Left $value -Right $environmentPaths[$name])) {
        throw "Environment variable $name points to '$value', not " +
        "'$($environmentPaths[$name])'."
      }
    }

    foreach ($name in 'User', 'Global') {
      $path = $paths.$name
      if (Test-Path -LiteralPath $path -PathType Leaf) {
        throw "Scoop $name path exists but is not a directory: $path"
      }
      if ((Test-Path -LiteralPath $path -PathType Container) -and
        (Get-ChildItem -LiteralPath $path -Force | Select-Object -First 1)) {
        throw "Scoop $name path exists and is not empty: $path"
      }
    }
    if (Test-Path -LiteralPath $paths.Cache -PathType Leaf) {
      throw "Scoop cache path exists but is not a directory: $($paths.Cache)"
    }
  }

  Show-ScoopPaths -Paths $paths
  Write-Info "Scoopfile:   $scoopfile ($(@($manifest.apps).Count) apps)"

  if (-not $PSCmdlet.ShouldProcess('Scoop and declared packages', 'Bootstrap Windows tools')) {
    return
  }

  $installerFile = $null
  try {
    if (-not $scoopExists) {
      $installerName = "scoop-install-$([Guid]::NewGuid().ToString('N')).ps1"
      $installerFile = Join-Path ([System.IO.Path]::GetTempPath()) $installerName
      Write-Info "Downloading the official Scoop installer from $ScoopInstallUrl"
      [Net.ServicePointManager]::SecurityProtocol = (
        [Net.ServicePointManager]::SecurityProtocol -bor [Net.SecurityProtocolType]::Tls12
      )
      Invoke-WebRequest -UseBasicParsing -Uri $ScoopInstallUrl -OutFile $installerFile
      Unblock-File -LiteralPath $installerFile

      Write-Info 'Installing Scoop.'
      & $installerFile `
        -ScoopDir $paths.User `
        -ScoopGlobalDir $paths.Global `
        -ScoopCacheDir $paths.Cache

      $scoopCommand = Find-ScoopCommand -ExpectedPaths $paths
      if ($null -eq $scoopCommand) {
        throw 'Scoop installation completed, but its shim was not found under ' +
        "'$($paths.User)'."
      }
      Assert-ScoopPathsMatch -Expected $paths -Actual (Get-EffectiveScoopPaths)
    }

    Write-Info 'Updating Scoop and bucket metadata.'
    Invoke-Scoop -Command $scoopCommand -Arguments @('update')

    Write-Info 'Installing packages from the repository Scoopfile.'
    Invoke-Scoop -Command $scoopCommand -Arguments @('import', $scoopfile)
  }
  finally {
    if ($installerFile -and (Test-Path -LiteralPath $installerFile)) {
      Remove-Item -LiteralPath $installerFile -Force
    }
  }

  Write-Info 'Scoop setup complete.'
  Write-Info 'Close this terminal and open a new one before using the installed tools.'
}

Main

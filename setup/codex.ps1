#Requires -Version 7.0

[CmdletBinding(SupportsShouldProcess = $true)]
param()

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$managedMarker = '# Managed by acidx27x/dotfiles setup/codex.sh'

function Write-Info {
  param([Parameter(Mandatory)][string] $Message)

  Write-Host "[INFO] $Message"
}

if (-not [System.Runtime.InteropServices.RuntimeInformation]::IsOSPlatform(
    [System.Runtime.InteropServices.OSPlatform]::Windows
  )) {
  throw 'This setup script only supports Windows.'
}
$programDataRoot = $env:ProgramData
if (-not $programDataRoot) {
  $programDataRoot = [Environment]::GetFolderPath(
    [Environment+SpecialFolder]::CommonApplicationData
  )
}
if (-not $programDataRoot) {
  $systemDriveRoot = [System.IO.Path]::GetPathRoot([Environment]::SystemDirectory)
  $programDataRoot = Join-Path $systemDriveRoot 'ProgramData'
}

$dotfilesRoot = [System.IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..'))
$baseConfig = Join-Path $dotfilesRoot 'codex-system\config.toml'
$systemConfigDirectory = Join-Path $programDataRoot 'OpenAI\Codex'
$systemConfig = Join-Path $systemConfigDirectory 'config.toml'

if (-not (Test-Path -LiteralPath $baseConfig -PathType Leaf)) {
  throw "Portable base config is missing: $baseConfig"
}
$baseContent = [System.IO.File]::ReadAllText($baseConfig)
if (($baseContent -split '\r?\n') -notcontains $managedMarker) {
  throw "Portable base config is missing its managed marker: $baseConfig"
}

if (Test-Path -LiteralPath $systemConfigDirectory) {
  $directory = Get-Item -LiteralPath $systemConfigDirectory -Force
  if (-not $directory.PSIsContainer -or $directory.LinkType) {
    throw "$systemConfigDirectory must be a real directory."
  }
}

$action = 'Install'
if (Test-Path -LiteralPath $systemConfig) {
  $file = Get-Item -LiteralPath $systemConfig -Force
  if ($file.PSIsContainer -or $file.LinkType) {
    throw "$systemConfig must be a real file."
  }

  $installedContent = [System.IO.File]::ReadAllText($systemConfig)
  if ($installedContent -eq $baseContent) {
    $action = 'None'
  }
  elseif (($installedContent -split '\r?\n') -contains $managedMarker) {
    $action = 'Update'
  }
  else {
    throw "$systemConfig is not managed by this repository; refusing to replace it."
  }
}

if ($action -eq 'None') {
  Write-Info "Portable base config is already current: $systemConfig"
  return
}

if (-not $PSCmdlet.ShouldProcess($systemConfig, "$action portable Codex base config")) {
  return
}

[System.IO.Directory]::CreateDirectory($systemConfigDirectory) | Out-Null
$temporaryConfig = Join-Path $systemConfigDirectory (
  "config.$([Guid]::NewGuid().ToString('N')).tmp"
)
try {
  [System.IO.File]::WriteAllText($temporaryConfig, $baseContent)
  Move-Item -LiteralPath $temporaryConfig -Destination $systemConfig -Force
}
finally {
  if ([System.IO.File]::Exists($temporaryConfig)) {
    [System.IO.File]::Delete($temporaryConfig)
  }
}

$completedAction = if ($action -eq 'Install') { 'Installed' } else { 'Updated' }
Write-Info "$completedAction portable base config: $systemConfig"
Write-Info 'The user config under %USERPROFILE%\.codex remains writable and was not changed.'

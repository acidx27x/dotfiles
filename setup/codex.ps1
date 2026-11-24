#Requires -Version 7.0

[CmdletBinding(SupportsShouldProcess = $true)]
param()

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$managedMarker = '# Managed by acidx27x/dotfiles setup/codex.sh'
$managedRoleMarker = '# Managed by acidx27x/dotfiles'

function Write-Info {
  param([Parameter(Mandatory)][string] $Message)

  Write-Host "[INFO] $Message"
}

function Get-InstallAction {
  param([string] $Path, [string] $Content, [string] $Marker)

  try {
    $file = Get-Item -LiteralPath $Path -Force
  }
  catch [System.Management.Automation.ItemNotFoundException] {
    return 'Install'
  }
  if ($file.PSIsContainer -or ($file.Attributes -band [System.IO.FileAttributes]::ReparsePoint)) {
    throw "$Path must be a real file."
  }
  $installedContent = [System.IO.File]::ReadAllText($Path)
  if ($installedContent -ceq $Content) {
    return 'None'
  }
  if (($installedContent -split '\r?\n') -ccontains $Marker) {
    return 'Update'
  }
  throw "$Path is not managed by this repository; refusing to replace it."
}

function Write-AtomicFile {
  param([string] $Path, [string] $Content, [bool] $Overwrite)

  $directory = [System.IO.Path]::GetDirectoryName($Path)
  [System.IO.Directory]::CreateDirectory($directory) | Out-Null
  $temporaryFile = Join-Path $directory "codex.$([Guid]::NewGuid().ToString('N')).tmp"
  try {
    [System.IO.File]::WriteAllText($temporaryFile, $Content)
    [System.IO.File]::Move($temporaryFile, $Path, $Overwrite)
  }
  finally {
    [System.IO.File]::Delete($temporaryFile)
  }
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
$baseConfig = Join-Path $dotfilesRoot 'codex\config.toml'
$systemConfigDirectory = Join-Path $programDataRoot 'OpenAI\Codex'
$systemConfig = Join-Path $systemConfigDirectory 'config.toml'
$rolesSource = Join-Path $dotfilesRoot 'codex\.codex\agents'
$userProfile = $env:USERPROFILE
if (-not $userProfile) {
  $userProfile = $HOME
}
$codexHome = Join-Path $userProfile '.codex'
$rolesTarget = Join-Path $codexHome 'agents'

if (-not (Test-Path -LiteralPath $baseConfig -PathType Leaf)) {
  throw "Portable base config is missing: $baseConfig"
}
$baseContent = [System.IO.File]::ReadAllText($baseConfig)
if (($baseContent -split '\r?\n') -notcontains $managedMarker) {
  throw "Portable base config is missing its managed marker: $baseConfig"
}

# Native Windows rejects Unix absolute filesystem paths, even for unused grants.
$baseContent = $baseContent -replace '(?m)^"/[^"]+" = "read"\r?\n', ''

# The elevated Windows sandbox requires broad reads; write and deny rules still apply.
$baseContent = $baseContent.Replace(
  '[permissions.locked_folders_only.filesystem]',
  "[permissions.locked_folders_only.filesystem]`n" + '":root" = "read"'
)

foreach ($directoryPath in @($systemConfigDirectory, $codexHome, $rolesTarget)) {
  try {
    $directory = Get-Item -LiteralPath $directoryPath -Force
  }
  catch [System.Management.Automation.ItemNotFoundException] {
    continue
  }
  if (-not $directory.PSIsContainer -or
    ($directory.Attributes -band [System.IO.FileAttributes]::ReparsePoint)) {
    throw "$directoryPath must be a real directory."
  }
}

$action = Get-InstallAction $systemConfig $baseContent $managedMarker
$roleSources = @(Get-ChildItem -LiteralPath $rolesSource -File -Filter '*.toml')
if ($roleSources.Count -eq 0) {
  throw "No Codex roles found in $rolesSource."
}
$roles = foreach ($source in $roleSources) {
  $content = [System.IO.File]::ReadAllText($source.FullName)
  if (($content -split '\r?\n') -cnotcontains $managedRoleMarker) {
    throw "Codex role lacks its managed marker: $($source.FullName)"
  }
  $target = Join-Path $rolesTarget $source.Name
  @{
    Target  = $target
    Content = $content
    Action  = Get-InstallAction $target $content $managedRoleMarker
  }
}

if ($action -eq 'None') {
  Write-Info "Portable base config is already current: $systemConfig"
}
elseif ($PSCmdlet.ShouldProcess($systemConfig, "$action portable Codex base config")) {
  Write-AtomicFile $systemConfig $baseContent ($action -eq 'Update')
  Write-Info "Installed portable base config: $systemConfig"
}

foreach ($role in $roles) {
  if ($role.Action -ne 'None' -and
    $PSCmdlet.ShouldProcess($role.Target, "$($role.Action) Codex role")) {
    Write-AtomicFile $role.Target $role.Content ($role.Action -eq 'Update')
    Write-Info "Installed Codex role: $($role.Target)"
  }
}

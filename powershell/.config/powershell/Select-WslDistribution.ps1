#Requires -Version 7.0
# ~/.config/powershell/Select-WslDistribution.ps1
# Pick an installed WSL distro for Windows Terminal without creating a profile.

$ErrorActionPreference = 'Stop'
$PSNativeCommandUseErrorActionPreference = $false

foreach ($command in 'wsl.exe', 'fzf.exe') {
  if (-not (Get-Command $command -ErrorAction SilentlyContinue)) {
    throw "$($MyInvocation.MyCommand.Name): required command '$command' is unavailable."
  }
}

$distros = @(& wsl.exe --list --quiet)
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
$distros = @($distros | ForEach-Object { ($_ -replace "`0", '').Trim() } |
    Where-Object { $_ })
if ($distros.Count -eq 0) {
  throw "$($MyInvocation.MyCommand.Name): no WSL distributions are installed."
}

$env:FZF_DEFAULT_OPTS_FILE = Join-Path $PSScriptRoot 'fzfrc'
$distro = $distros | fzf.exe --no-multi --no-preview --height=100% --prompt 'WSL> ' `
  --header 'Enter: launch | Esc: cancel'
if ($LASTEXITCODE -in 1, 130) { exit 0 }
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
if (-not $distro) { exit 0 }

& wsl.exe --distribution $distro --cd '~'
exit $LASTEXITCODE

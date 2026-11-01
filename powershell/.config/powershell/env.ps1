# ~/.config/powershell/env.ps1
# Shared environment defaults for PowerShell.

if (-not $env:EDITOR -and (Test-Command nvim)) {
  $env:EDITOR = 'nvim'
}

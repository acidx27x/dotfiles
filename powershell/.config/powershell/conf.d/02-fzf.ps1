# ~/.config/powershell/conf.d/02-fzf.ps1
# fzf defaults and optional PSFzf key bindings.

$env:FZF_DEFAULT_OPTS_FILE = Join-Path $PSScriptRoot '..\fzfrc'

if (-not (Test-Command fzf) -or -not (Get-Module -ListAvailable -Name PSFzf)) {
  return
}

Import-Module PSReadLine -ErrorAction SilentlyContinue
Import-Module PSFzf
Set-PsFzfOption -PSReadlineChordProvider 'Ctrl+t' -PSReadlineChordSetLocation 'Alt+c'

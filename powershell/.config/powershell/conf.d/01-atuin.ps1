# ~/.config/powershell/conf.d/01-atuin.ps1
# Atuin history integration.

if ((Get-Module -ListAvailable -Name PSReadLine) -and (Test-Command atuin)) {
  $env:ATUIN_SEARCH_MODE = 'fuzzy'
  Import-Module PSReadLine
  atuin init powershell --disable-ai --disable-up-arrow |
    Out-String |
    Invoke-Expression
}

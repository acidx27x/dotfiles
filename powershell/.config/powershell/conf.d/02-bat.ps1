# ~/.config/powershell/conf.d/02-bat.ps1
# bat help rendering alias.

if (Test-Command bat) {
  function Show-BatHelp {
    bat --plain --language=help @args
  }
  Set-Alias -Name bathelp -Value Show-BatHelp
}

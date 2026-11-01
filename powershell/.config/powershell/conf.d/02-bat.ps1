# ~/.config/powershell/conf.d/02-bat.ps1
# bat help rendering alias.

if (Test-Command bat) {
  function bathelp {
    bat --plain --language=help @args
  }
}

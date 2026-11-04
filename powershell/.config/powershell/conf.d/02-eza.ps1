# ~/.config/powershell/conf.d/02-eza.ps1
# eza listing commands.

if (-not (Test-Command eza)) {
  return
}

$ezaOptions = @(
  '--color=auto',
  '--group-directories-first',
  '--icons=auto',
  '--ignore-glob=.DS_Store',
  '-s',
  'Name'
)

Remove-Item Alias:ls -ErrorAction SilentlyContinue
function ls { eza -1 @ezaOptions @args }
function l { eza -lh @ezaOptions @args }
function la { eza -A @ezaOptions @args }
function ll { eza -lhag @ezaOptions @args }
function ldr { eza -lhD @ezaOptions @args }
function lt { eza -T @ezaOptions @args }
function llt { eza -lagT @ezaOptions @args }
Set-Alias tree lt

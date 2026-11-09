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
function Get-EzaItem { eza -1 @ezaOptions @args }
function Get-EzaLongItem { eza -lh @ezaOptions @args }
function Get-EzaHiddenItem { eza -A @ezaOptions @args }
function Get-EzaDetailedItem { eza -lhag @ezaOptions @args }
function Get-EzaDirectory { eza -lhD @ezaOptions @args }
function Get-EzaTree { eza -T @ezaOptions @args }
function Get-EzaDetailedTree { eza -lagT @ezaOptions @args }
Set-Alias -Name ls -Value Get-EzaItem
Set-Alias -Name l -Value Get-EzaLongItem
Set-Alias -Name la -Value Get-EzaHiddenItem
Set-Alias -Name ll -Value Get-EzaDetailedItem
Set-Alias -Name ldr -Value Get-EzaDirectory
Set-Alias -Name lt -Value Get-EzaTree
Set-Alias -Name llt -Value Get-EzaDetailedTree
Set-Alias -Name tree -Value Get-EzaTree

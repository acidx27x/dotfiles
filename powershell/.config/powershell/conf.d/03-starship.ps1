# ~/.config/powershell/conf.d/03-starship.ps1
# Starship prompt.

if (Test-Command starship) {
  Invoke-Expression (&starship init powershell)
}

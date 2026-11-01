# ~/.config/powershell/conf.d/03-zoxide.ps1
# zoxide directory navigation.

if (Test-Command zoxide) {
  zoxide init powershell --cmd z |
    Out-String |
    Invoke-Expression
}

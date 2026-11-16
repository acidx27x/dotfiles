# ~/.config/powershell/conf.d/04-worktrunk.ps1
# Worktrunk directory switching and completion.

# Use git-wt to avoid invoking Windows Terminal's wt executable.
if (Test-Command git-wt) {
  $worktrunkInit = git-wt config shell init powershell --cmd wt | Out-String
  if ($LASTEXITCODE -eq 0 -and -not [string]::IsNullOrWhiteSpace($worktrunkInit)) {
    Invoke-Expression $worktrunkInit
  }
  else {
    Write-Warning "$($MyInvocation.MyCommand.Name): Worktrunk init failed"
  }
  Remove-Variable worktrunkInit
}

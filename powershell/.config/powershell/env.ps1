# ~/.config/powershell/env.ps1
# Shared environment defaults for PowerShell.

if (-not $env:EDITOR -and (Test-Command nvim)) {
  $env:EDITOR = 'nvim'
}

if ($IsWindows) {
  foreach ($shell in 'pwsh.exe', 'powershell.exe', 'cmd.exe') {
    $command = Get-Command $shell -CommandType Application -ErrorAction SilentlyContinue |
      Select-Object -First 1
    if ($command) {
      $env:SHELL = $command.Source
      break
    }
  }
  Remove-Variable shell, command -ErrorAction SilentlyContinue

  # Let Git's SSH use its default Unix shell without changing SHELL for other programs.
  if (-not $env:GIT_SSH_COMMAND -and -not $env:GIT_SSH) {
    $env:GIT_SSH_COMMAND = 'env -u SHELL ssh'
  }
}

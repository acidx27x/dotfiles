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
      $env:SHELL = $shell
      break
    }
  }
  Remove-Variable shell, command -ErrorAction SilentlyContinue
}

# ~/.config/powershell/profile.ps1
# Interactive PowerShell configuration entry point.

$configRoot = Join-Path $env:USERPROFILE '.config\powershell'

. (Join-Path $configRoot 'utils.ps1')
. (Join-Path $configRoot 'env.ps1')
. (Join-Path $configRoot 'functions.ps1')

if ([Environment]::UserInteractive -and -not [Console]::IsInputRedirected) {
  if (-not $env:NO_COLOR -and $env:TERM -ne 'dumb') {
    if (-not $env:COLORTERM) { $env:COLORTERM = 'truecolor' }
    if (-not $env:TERM) { $env:TERM = 'xterm-256color' }
  }

  foreach ($configDirectory in 'conf.d', 'conf.local.d') {
    foreach ($configScript in (Get-ConfigScripts (Join-Path $configRoot $configDirectory))) {
      . $configScript
    }
  }

  Remove-Variable configDirectory, configScript -ErrorAction SilentlyContinue
}

Remove-Variable configRoot

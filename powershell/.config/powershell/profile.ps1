# ~/.config/powershell/profile.ps1
# Interactive PowerShell configuration entry point.

$configRoot = Join-Path $env:USERPROFILE '.config\powershell'

. (Join-Path $configRoot 'utils.ps1')
. (Join-Path $configRoot 'env.ps1')
. (Join-Path $configRoot 'functions.ps1')
if ($IsWindows) {
  . (Join-Path $configRoot 'wsl.ps1')
}

if ([Environment]::UserInteractive -and -not [Console]::IsInputRedirected) {
  if ($IsWindows) {
    # Use UTF-8 for the console and PowerShell pipelines into native programs.
    $OutputEncoding = [System.Text.UTF8Encoding]::new($false)
    [Console]::InputEncoding = $OutputEncoding
    [Console]::OutputEncoding = $OutputEncoding
  }

  # Colors and terminal-specific themes.
  . (Join-Path $configRoot 'colors.ps1')

  # Personal aliases; tool-specific aliases live in conf.d.
  Set-Alias -Name lg -Value Start-Lazygit
  Set-Alias -Name hl -Value Show-Highlight
  Set-Alias -Name C -Value Set-Clipboard
  if (Get-Command rg -CommandType Application -ErrorAction SilentlyContinue) {
    Set-Alias -Name rg -Value Invoke-Ripgrep
  }

  # Tool setup, followed by machine-local overrides.
  foreach ($configDirectory in 'conf.d', 'conf.local.d') {
    foreach ($configScript in (Get-ConfigScript -Path (Join-Path $configRoot $configDirectory))) {
      . $configScript
    }
  }

  Remove-Variable configDirectory, configScript -ErrorAction SilentlyContinue
}

Remove-Variable configRoot

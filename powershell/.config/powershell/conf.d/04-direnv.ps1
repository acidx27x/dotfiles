# ~/.config/powershell/conf.d/04-direnv.ps1
# direnv project environment hook.

if (Test-Command direnv) {
  if (-not $env:APPDATA -or -not $env:LOCALAPPDATA) {
    return
  }

  $direnvConfigRoot = Join-Path $env:APPDATA 'direnv'
  $direnvLocalRoot = Join-Path $env:LOCALAPPDATA 'direnv'

  if (-not $env:DIRENV_CONFIG) {
    $env:DIRENV_CONFIG = Join-Path $direnvConfigRoot 'config'
  }
  if (-not $env:XDG_CACHE_HOME) {
    $env:XDG_CACHE_HOME = Join-Path $direnvLocalRoot 'cache'
  }
  if (-not $env:XDG_DATA_HOME) {
    $env:XDG_DATA_HOME = Join-Path $direnvLocalRoot 'data'
  }

  $direnvHook = direnv hook pwsh | Out-String
  if (-not [string]::IsNullOrWhiteSpace($direnvHook)) {
    Invoke-Expression $direnvHook
  }
}

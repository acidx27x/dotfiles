# ~/.config/powershell/conf.d/00-paths.ps1
# Keep Scoop-managed shims on PATH and allow machine-local additions.

$localPaths = Join-Path $PSScriptRoot 'local_paths.ps1'
if (Test-Path -LiteralPath $localPaths -PathType Leaf) {
  . $localPaths
}

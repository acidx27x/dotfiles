#Requires -Version 7.0

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

Import-Module PSScriptAnalyzer -MinimumVersion 1.25.0 -ErrorAction Stop

$settingsPath = Join-Path $PSScriptRoot '.PSScriptAnalyzerSettings.psd1'
if (-not (Test-Path -LiteralPath $settingsPath -PathType Leaf)) {
  throw "PowerShell formatter settings not found: $settingsPath"
}

$source = [Console]::In.ReadToEnd()
$formatted = Invoke-Formatter -ScriptDefinition $source -Settings $settingsPath
[Console]::Out.Write($formatted)

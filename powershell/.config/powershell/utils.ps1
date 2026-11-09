# ~/.config/powershell/utils.ps1
# Reusable helpers for PowerShell configuration.

function Test-Command {
  param([Parameter(Mandatory)][string] $Name)

  return $null -ne (Get-Command $Name -ErrorAction SilentlyContinue)
}

function Get-ConfigScript {
  param([Parameter(Mandatory)][string] $Path)

  if (-not (Test-Path -LiteralPath $Path -PathType Container)) {
    return
  }

  Get-ChildItem -LiteralPath $Path -Filter '*.ps1' -File |
    Sort-Object -Property Name |
    Select-Object -ExpandProperty FullName
}

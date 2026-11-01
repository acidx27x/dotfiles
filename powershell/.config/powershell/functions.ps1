# ~/.config/powershell/functions.ps1
# User-facing PowerShell functions and aliases.

function current-shell {
  "PowerShell $($PSVersionTable.PSVersion)"
}

function functions-help {
  Get-Command -CommandType Function |
    Where-Object { $_.Source -eq '' -and $_.Name -notlike '_*' } |
    Sort-Object -Property Name |
    Select-Object -Property Name, Definition
}

function lg {
  if (Test-Command lazygit) {
    lazygit @args
  }
}

function hl {
  if (Test-Command rg) {
    rg --passthru @args
  }
}

function C {
  Set-Clipboard @args
}

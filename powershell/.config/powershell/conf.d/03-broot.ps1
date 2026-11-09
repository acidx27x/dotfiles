# ~/.config/powershell/conf.d/03-broot.ps1
# Broot directory switching.

if (Test-Command broot) {
  function Invoke-Broot {
    $cmdFile = New-TemporaryFile

    try {
      & broot --outcmd $cmdFile.FullName @args
      if ($LASTEXITCODE -ne 0) { return }

      $command = Get-Content -LiteralPath $cmdFile.FullName -Raw
      if ($command) { Invoke-Expression $command }
    }
    finally {
      Remove-Item -LiteralPath $cmdFile.FullName -Force
    }
  }
  Set-Alias -Name br -Value Invoke-Broot
}

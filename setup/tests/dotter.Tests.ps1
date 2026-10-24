#Requires -Version 7.0

[CmdletBinding()]
param()

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$wrapper = [System.IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..\dotter.ps1'))
$testRoot = Join-Path (
  [System.IO.Path]::GetTempPath()
) "dotter wrapper tests $([Guid]::NewGuid().ToString('N'))"
$resolvedTemp = [System.IO.Path]::GetFullPath([System.IO.Path]::GetTempPath())
$resolvedTest = [System.IO.Path]::GetFullPath($testRoot)
if (-not $resolvedTest.StartsWith($resolvedTemp, [StringComparison]::OrdinalIgnoreCase)) {
  throw "Unsafe test path '$resolvedTest'."
}

function Assert-True {
  param(
    [Parameter(Mandatory)][bool] $Condition,
    [Parameter(Mandatory)][string] $Message
  )

  if (-not $Condition) {
    throw $Message
  }
}

function Assert-State {
  param(
    [Parameter(Mandatory)][string] $StatePath,
    [Parameter(Mandatory)][AllowEmptyCollection()][string[]] $Expected
  )

  $state = Get-Content -LiteralPath $StatePath -Raw | ConvertFrom-Json
  $actual = @($state.packages)
  Assert-True ($state.version -eq 2) 'Active state does not use version 2.'
  Assert-True `
    -Condition ($state.cacheFingerprint -match '^[0-9a-f]{64}$') `
    -Message 'Active state does not contain a SHA-256 cache fingerprint.'
  Assert-True `
    -Condition (($actual -join "`n") -eq ($Expected -join "`n")) `
    -Message "Expected packages '$($Expected -join ', ')', got '$($actual -join ', ')'."
}

function Assert-WrapperFails {
  param(
    [Parameter(Mandatory)][scriptblock] $Operation,
    [Parameter(Mandatory)][string] $Pattern
  )

  try {
    & $Operation *> $null
  }
  catch {
    if ($_.Exception.Message -notmatch $Pattern) {
      throw "Expected error '$Pattern', got '$($_.Exception.Message)'."
    }
    return
  }

  throw "Expected wrapper failure matching '$Pattern'."
}

function Get-Sha256Hex {
  param([Parameter(Mandatory)][byte[]] $Bytes)

  $sha256 = [Security.Cryptography.SHA256]::Create()
  try {
    return [BitConverter]::ToString(
      $sha256.ComputeHash($Bytes)
    ).Replace('-', '').ToLowerInvariant()
  }
  finally {
    $sha256.Dispose()
  }
}

$oldOs = $env:OS
$oldLocalAppData = $env:LOCALAPPDATA
$oldAppData = $env:APPDATA
$oldPath = $env:PATH

Push-Location ([System.IO.Path]::GetTempPath())
try {
  $env:OS = 'Windows_NT'
  $env:LOCALAPPDATA = Join-Path $testRoot 'Local'
  $env:APPDATA = Join-Path $testRoot 'Roaming'

  $helpOutput = @(& pwsh -NoProfile -File $wrapper --help 2>&1)
  Assert-True ($LASTEXITCODE -eq 0) '--help returned a failure exit code.'
  Assert-True `
    -Condition (($helpOutput -join "`n") -match '(?m)^Usage:') `
    -Message '--help did not print usage information.'
  Assert-True `
    -Condition (($helpOutput -join "`n") -match '-Package <name\[,name\.\.\.\]>') `
    -Message '--help did not document package selection.'
  Assert-True `
    -Condition (-not (Test-Path -LiteralPath $testRoot)) `
    -Message '--help created persistent files or state.'

  foreach ($invalidPackage in @('', ' ', ',', ',lazygit', 'lazygit,', 'git,,nvim')) {
    Assert-WrapperFails `
      -Operation {
      & $wrapper -Action Deploy -Package $invalidPackage -Replace -WhatIf
    } `
      -Pattern 'empty package name|at least one package'
  }
  Assert-WrapperFails `
    -Operation { & $wrapper -Action Deploy -Profile '' -WhatIf } `
    -Pattern 'Profile name cannot be empty'
  Assert-WrapperFails `
    -Operation { & $wrapper -Action Deploy -Profile windows -WhatIf } `
    -Pattern "Unknown Dotter profile 'windows'"
  Assert-WrapperFails `
    -Operation { & $wrapper -Action Undeploy -All -Package lazygit -WhatIf } `
    -Pattern 'cannot be combined'
  Assert-True `
    -Condition (-not (Test-Path -LiteralPath $testRoot)) `
    -Message 'Invalid input created persistent files or state.'

  & $wrapper -Action Deploy -Package lazygit -WhatIf *> $null
  Assert-True `
    -Condition (-not (Test-Path -LiteralPath $testRoot)) `
    -Message 'WhatIf created persistent files or state.'

  & $wrapper -Action Deploy -Package lazygit *> $null
  $stateRoot = Join-Path $env:LOCALAPPDATA 'dotfiles\dotter'
  $statePath = Join-Path $stateRoot 'active-packages.json'
  $cachePath = Join-Path $stateRoot 'cache.toml'
  $lazygitTarget = Join-Path $env:LOCALAPPDATA 'lazygit\config.yml'
  Assert-True (Test-Path -LiteralPath $lazygitTarget) 'lazygit was not deployed.'
  Assert-State -StatePath $statePath -Expected @('lazygit')
  Assert-True `
    -Condition (-not (Test-Path -LiteralPath (Join-Path $stateRoot 'local.toml'))) `
    -Message 'The wrapper persisted a generated local.toml.'
  & $wrapper -Action Deploy -Package lazygit *> $null
  Assert-State -StatePath $statePath -Expected @('lazygit')

  & $wrapper -Action Deploy -Package nvim, lazygit, nvim *> $null
  Assert-State -StatePath $statePath -Expected @('nvim', 'lazygit')
  & $wrapper -Action Deploy -Profile minimal -WhatIf *> $null

  & $wrapper -Action Undeploy -Package nvim *> $null
  Assert-True (Test-Path -LiteralPath $lazygitTarget) 'Selective removal removed lazygit.'
  Assert-True `
    -Condition (-not (Test-Path -LiteralPath (Join-Path $env:LOCALAPPDATA 'nvim\init.lua'))) `
    -Message 'Selective removal left nvim deployed.'
  Assert-State -StatePath $statePath -Expected @('lazygit')

  & $wrapper -Action Restow -Package lazygit *> $null
  Assert-State -StatePath $statePath -Expected @('lazygit')

  & $wrapper -Action Deploy -Package nvim -Replace *> $null
  Assert-True `
    -Condition (-not (Test-Path -LiteralPath $lazygitTarget)) `
    -Message 'Replace left lazygit deployed.'
  Assert-State -StatePath $statePath -Expected @('nvim')

  $conflictDirectory = Split-Path $lazygitTarget -Parent
  [System.IO.Directory]::CreateDirectory($conflictDirectory) | Out-Null
  [System.IO.File]::WriteAllText($lazygitTarget, 'unmanaged')
  $stateBeforeFailure = Get-Content -LiteralPath $statePath -Raw
  Assert-WrapperFails `
    -Operation { & $wrapper -Action Deploy -Package lazygit } `
    -Pattern 'conflict|failed'
  Assert-True `
    -Condition ((Get-Content -LiteralPath $statePath -Raw) -eq $stateBeforeFailure) `
    -Message 'Failed deployment changed active state.'
  Assert-True `
    -Condition ((Get-Content -LiteralPath $lazygitTarget -Raw) -eq 'unmanaged') `
    -Message 'Failed deployment changed an unmanaged file.'
  [System.IO.File]::Delete($lazygitTarget)
  [System.IO.Directory]::Delete($conflictDirectory)

  $cacheBeforeTamper = Get-Content -LiteralPath $cachePath -Raw
  [System.IO.File]::AppendAllText($cachePath, "`n# fingerprint tamper`n")
  Assert-WrapperFails `
    -Operation { & $wrapper -Action Deploy -Package lazygit -WhatIf } `
    -Pattern 'cache data changed outside the wrapper'
  Assert-True `
    -Condition ((Get-Content -LiteralPath $statePath -Raw) -eq $stateBeforeFailure) `
    -Message 'Cache fingerprint failure changed active state.'
  [System.IO.File]::WriteAllText($cachePath, $cacheBeforeTamper)

  $validState = Get-Content -LiteralPath $statePath -Raw
  [System.IO.File]::WriteAllText(
    $statePath,
    '{"version":1,"packages":["nvim"],"batConfigPathManaged":false}'
  )
  Assert-WrapperFails `
    -Operation { & $wrapper -Action Deploy -Package lazygit -WhatIf } `
    -Pattern 'unsupported version'
  [System.IO.File]::WriteAllText($statePath, $validState)

  $invalidState = $validState | ConvertFrom-Json -AsHashtable
  $invalidState.packages = 'nvim'
  [System.IO.File]::WriteAllText($statePath, ($invalidState | ConvertTo-Json))
  Assert-WrapperFails `
    -Operation { & $wrapper -Action Deploy -Package lazygit -WhatIf } `
    -Pattern 'invalid packages value'
  [System.IO.File]::WriteAllText($statePath, $validState)

  $canonicalRoot = [System.IO.Path]::GetFullPath($stateRoot).ToLowerInvariant()
  $rootHash = (Get-Sha256Hex `
      -Bytes ([Text.Encoding]::UTF8.GetBytes($canonicalRoot))).Substring(0, 32)
  $mutex = [Threading.Mutex]::new($false, "Local\dotfiles-dotter-$rootHash")
  try {
    Assert-True ($mutex.WaitOne(0)) 'Test could not acquire the Dotter mutex.'
    $mutexOutput = @(& pwsh `
        -NoProfile `
        -File $wrapper `
        -Action Deploy `
        -Package lazygit `
        -WhatIf 2>&1)
    $mutexExitCode = $LASTEXITCODE
    Assert-True ($mutexExitCode -ne 0) 'A second Dotter process acquired the mutex.'
    Assert-True `
      -Condition (($mutexOutput -join "`n") -match 'already using this machine state') `
      -Message 'The mutex failure did not explain the concurrent invocation.'
  }
  finally {
    $mutex.ReleaseMutex()
    $mutex.Dispose()
  }

  $env:PATH = ''
  Assert-WrapperFails `
    -Operation { & $wrapper -Action Deploy -Package lazygit -WhatIf } `
    -Pattern 'Dotter is not installed'
  $env:PATH = $oldPath

  $stateBeforeFailure = Get-Content -LiteralPath $statePath -Raw
  Assert-WrapperFails `
    -Operation { & $wrapper -Action Deploy -Package unknown } `
    -Pattern 'Unknown Dotter package'
  Assert-True `
    -Condition ((Get-Content -LiteralPath $statePath -Raw) -eq $stateBeforeFailure) `
    -Message 'Unknown package changed active state.'

  & $wrapper -Action Undeploy -All *> $null
  Assert-State -StatePath $statePath -Expected @()

  [System.IO.File]::Delete($statePath)
  Assert-WrapperFails `
    -Operation { & $wrapper -Action Deploy -Package lazygit -WhatIf } `
    -Pattern 'cache data exists without active state'

  Write-Host '[PASS] Dotter wrapper regression tests completed.'
}
finally {
  Pop-Location
  $env:OS = $oldOs
  $env:LOCALAPPDATA = $oldLocalAppData
  $env:APPDATA = $oldAppData
  $env:PATH = $oldPath
  if ([System.IO.Directory]::Exists($resolvedTest)) {
    [System.IO.Directory]::Delete($resolvedTest, $true)
  }
}

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
$oldTestBat = $env:DOTFILES_TEST_BAT
$oldTestBatWrites = $env:DOTFILES_TEST_BAT_WRITES

# Check the real mappings too: fixture-only tests cannot catch stale repository source paths.
$repositoryRoot = [System.IO.Path]::GetFullPath((Join-Path $PSScriptRoot '../..'))
$mappingPath = Join-Path $repositoryRoot 'windows/dotter/global.toml'
$mappingCount = 0
foreach ($line in Get-Content -LiteralPath $mappingPath) {
  if ($line -match '^\s*(?:"(?<source>[^"]+)"|''(?<source>[^'']+)'')\s*=') {
    $source = $Matches.source
    $mappingCount++
    Assert-True `
      -Condition (Test-Path -LiteralPath (Join-Path $repositoryRoot $source)) `
      -Message "Windows Dotter mapping references a missing repository source: $source"
  }
}
Assert-True ($mappingCount -gt 0) 'The repository mapping check did not inspect any sources.'

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
  Assert-WrapperFails `
    -Operation { & $wrapper -Package lazygit -Profile minimal -WhatIf } `
    -Pattern 'Use either -Package or -Profile'
  Assert-WrapperFails `
    -Operation { & $wrapper -Action Undeploy -WhatIf } `
    -Pattern 'requires -Package or -Profile'
  Assert-WrapperFails `
    -Operation { & $wrapper -Action Restow -All -WhatIf } `
    -Pattern 'valid only with -Action Undeploy'
  Assert-WrapperFails `
    -Operation { & $wrapper -Action Undeploy -Package lazygit -Replace -WhatIf } `
    -Pattern 'valid only with -Action Deploy'
  Assert-True `
    -Condition (-not (Test-Path -LiteralPath $testRoot)) `
    -Message 'Invalid input created persistent files or state.'

  # Use a disposable repository to change mappings and delete sources without touching this clone.
  $fixtureRoot = Join-Path $testRoot 'repository with spaces'
  $fixtureSetup = Join-Path $fixtureRoot 'setup'
  $fixtureConfig = Join-Path $fixtureRoot 'windows/dotter'
  [System.IO.Directory]::CreateDirectory($fixtureSetup) | Out-Null
  [System.IO.Directory]::CreateDirectory((Join-Path $fixtureConfig 'profiles')) | Out-Null
  $fixtureWrapper = Join-Path $fixtureSetup 'dotter.ps1'
  $wrapperText = Get-Content -LiteralPath $wrapper -Raw
  # Fake only the User environment store; all Dotter/link/cache work uses the real executable.
  $fakeBatStore = @'
function Get-UserBatConfig { return $env:DOTFILES_TEST_BAT }
function Set-UserBatConfig {
  param([AllowNull()][AllowEmptyString()][string] $Value)
  $env:DOTFILES_TEST_BAT = $Value
  $env:DOTFILES_TEST_BAT_WRITES = [string]([int]$env:DOTFILES_TEST_BAT_WRITES + 1)
}
Main
'@
  $wrapperText = $wrapperText -replace '(?m)^Main\s*$', $fakeBatStore
  $env:DOTFILES_TEST_BAT = $null
  $env:DOTFILES_TEST_BAT_WRITES = '0'
  [System.IO.File]::WriteAllText($fixtureWrapper, $wrapperText)
  $fixtureGlobal = Join-Path $fixtureConfig 'global.toml'
  $fixtureMappings = @'
[settings]
default_target_type = "symbolic"
[nvim.files]
"nvim/config" = "${LOCALAPPDATA}/targets/nvim"
[lazygit.files]
"lazygit/config" = "${LOCALAPPDATA}/targets/lazygit"
[codex.files]
"codex/config" = "${LOCALAPPDATA}/targets/codex"
[bat.files]
"bat/config.txt" = "${APPDATA}/bat/config"
'@
  [System.IO.File]::WriteAllText($fixtureGlobal, $fixtureMappings)
  foreach ($name in @('nvim', 'lazygit', 'codex')) {
    [System.IO.Directory]::CreateDirectory((Join-Path $fixtureRoot "$name/config")) | Out-Null
    [System.IO.File]::WriteAllText((Join-Path $fixtureRoot "$name/config/old.txt"), $name)
  }
  [System.IO.Directory]::CreateDirectory((Join-Path $fixtureRoot 'bat')) | Out-Null
  [System.IO.File]::WriteAllText((Join-Path $fixtureRoot 'bat/config.txt'), 'bat')
  $skippingSource = Join-Path $fixtureRoot 'nvim/config/skipping.txt'
  [System.IO.File]::WriteAllText($skippingSource, 'valid filename')
  $fixtureLocal = Join-Path $testRoot 'fixture Local'
  $env:LOCALAPPDATA = $fixtureLocal
  $fixtureState = Join-Path $fixtureLocal 'dotfiles/dotter/active-packages.json'
  $fixtureCache = Join-Path $fixtureLocal 'dotfiles/dotter/cache.toml'
  $fixtureProfile = Join-Path $fixtureConfig 'profiles/test.toml'
  foreach ($badProfile in @(
      'packages = ["codex"] extra = true',
      "extra = true`npackages = [`"codex`"]",
      "packages = [`"codex`"]`npackages = [`"nvim`"]",
      'packages = ["codex" "nvim"]',
      'packages = [,"codex"]',
      'packages = ["codex",,"nvim"]'
    )) {
    [System.IO.File]::WriteAllText($fixtureProfile, $badProfile)
    Assert-WrapperFails `
      -Operation { & $fixtureWrapper -Profile test -WhatIf } `
      -Pattern 'only a packages array|invalid package array'
  }
  [System.IO.File]::WriteAllText($fixtureProfile, "packages = ['codex', # comment`n 'nvim',]`n")
  $probePath = Join-Path $fixtureRoot 'DOTTER_SYMLINK_TEST'
  [System.IO.File]::WriteAllText($probePath, 'keep this file')
  Assert-WrapperFails `
    -Operation { & $fixtureWrapper -Package codex -WhatIf } `
    -Pattern 'symlink probe path already exists'
  Assert-True ((Get-Content $probePath -Raw) -eq 'keep this file') 'Preview deleted the probe path.'
  [System.IO.File]::Delete($probePath)
  & $fixtureWrapper -Profile test -WhatIf *> $null
  Assert-True (-not (Test-Path $fixtureLocal)) 'Fixture WhatIf created persistent state.'
  [System.IO.Directory]::CreateDirectory((Join-Path $fixtureRoot '.dotter')) | Out-Null
  [System.IO.File]::WriteAllText((Join-Path $fixtureRoot '.dotter/pre_deploy.sh'), 'exit 99')
  [System.IO.File]::WriteAllText(
    $fixtureWrapper,
    ($wrapperText -replace '(?m)^Main\s*$',
    "function Save-ActiveState { throw 'Injected initial-save failure.' }`nMain")
  )
  Assert-WrapperFails `
    -Operation { & $fixtureWrapper -Package nvim } `
    -Pattern 'Injected initial-save failure'
  Assert-True (-not (Test-Path $fixtureState)) 'Initial save failure left active state.'
  Assert-True (-not (Test-Path $fixtureCache)) 'Initial save failure left an orphaned cache.'
  [System.IO.File]::WriteAllText($fixtureWrapper, $wrapperText)
  & $fixtureWrapper -Package nvim, lazygit, codex *> $null

  # Cached entries do not prevent restoring manually deleted links or target directories.
  $codexTargetDirectory = Join-Path $fixtureLocal 'targets/codex'
  $codexTarget = Join-Path $codexTargetDirectory 'old.txt'
  $codexSource = Join-Path $fixtureRoot 'codex/config/old.txt'
  foreach ($restoreAction in @('Deploy', 'Restow')) {
    [System.IO.File]::Delete($codexTarget)
    $stateBeforeRestore = Get-Content $fixtureState -Raw
    $cacheBeforeRestore = Get-Content $fixtureCache -Raw
    & $fixtureWrapper -Action $restoreAction -Package codex -WhatIf *> $null
    Assert-True (-not (Test-Path $codexTarget)) 'WhatIf restored a deleted link.'
    Assert-True `
      -Condition ((Get-Content $fixtureState -Raw) -eq $stateBeforeRestore) `
      -Message 'Missing-link preview changed state.'
    Assert-True `
      -Condition ((Get-Content $fixtureCache -Raw) -eq $cacheBeforeRestore) `
      -Message 'Missing-link preview changed the shared cache.'
    & $fixtureWrapper -Action $restoreAction -Package codex *> $null
    Assert-True `
      -Condition ((Get-Item -LiteralPath $codexTarget).LinkType -eq 'SymbolicLink') `
      -Message "$restoreAction did not recreate the deleted link."

    $resolvedTarget = [System.IO.Path]::GetFullPath($codexTargetDirectory)
    $targetBoundary = [System.IO.Path]::GetFullPath($fixtureLocal) +
    [System.IO.Path]::DirectorySeparatorChar
    $withinFixture = $resolvedTarget.StartsWith(
      $targetBoundary, [StringComparison]::OrdinalIgnoreCase
    )
    Assert-True `
      -Condition $withinFixture `
      -Message "Unsafe target directory '$resolvedTarget'."
    [System.IO.Directory]::Delete($resolvedTarget, $true)
    & $fixtureWrapper -Action $restoreAction -Package codex *> $null
    Assert-True `
      -Condition ((Get-Item -LiteralPath $codexTarget).LinkType -eq 'SymbolicLink') `
      -Message "$restoreAction did not recreate the deleted target directory and link."
    Assert-True `
      -Condition ((Get-Content $codexSource -Raw) -eq 'codex') `
      -Message 'Restoring deleted links changed the source file.'
  }
  [System.IO.File]::Delete($codexTarget)
  & $fixtureWrapper -Action Undeploy -Package codex *> $null
  Assert-State $fixtureState @('nvim', 'lazygit')
  & $fixtureWrapper -Package codex *> $null

  $unrelatedTarget = Join-Path $fixtureLocal 'targets/lazygit/old.txt'
  [System.IO.File]::Delete($unrelatedTarget)
  [System.IO.File]::WriteAllText($unrelatedTarget, 'user edit')
  & $fixtureWrapper -Action Restow -Package codex *> $null
  Assert-True `
    -Condition ((Get-Content $unrelatedTarget -Raw) -eq 'user edit') `
    -Message 'An unrelated conflict was overwritten.'
  [System.IO.File]::Delete($unrelatedTarget)
  & $fixtureWrapper -Action Restow -Package lazygit *> $null

  # Leave unrelated packages with deleted sources, new files, and a changed destination.
  [System.IO.File]::Delete((Join-Path $fixtureRoot 'nvim/config/old.txt'))
  [System.IO.File]::WriteAllText((Join-Path $fixtureRoot 'nvim/config/new.txt'), 'new')
  [System.IO.File]::WriteAllText(
    $fixtureGlobal,
    $fixtureMappings.Replace('/targets/lazygit"', '/targets/lazygit-new"')
  )
  # Even deleting an entire selected source directory must not prevent cached undeployment.
  [System.IO.Directory]::Delete((Join-Path $fixtureRoot 'codex'), $true)
  $stateBeforePreview = Get-Content -LiteralPath $fixtureState -Raw
  $cacheBeforePreview = Get-Content -LiteralPath $fixtureCache -Raw
  $previewOutput = @(& $fixtureWrapper -Action Undeploy -Package codex -WhatIf 6>&1)
  $previewText = ($previewOutput | ForEach-Object { $_.ToString() }) -join "`n"
  Assert-True `
    -Condition ($previewText -match 'undeploy for: codex\.') `
    -Message 'Preview did not name the requested scope.'
  Assert-True ($previewText -notmatch 'nvim|lazygit') 'Preview included unrelated packages.'
  Assert-True `
    -Condition ((Get-Content $fixtureState -Raw) -eq $stateBeforePreview) `
    -Message 'WhatIf changed fixture state.'
  Assert-True `
    -Condition ((Get-Content $fixtureCache -Raw) -eq $cacheBeforePreview) `
    -Message 'WhatIf changed the shared cache.'
  & $fixtureWrapper -Action Undeploy -Package codex *> $null
  Assert-State $fixtureState @('nvim', 'lazygit')
  $nvimOld = Join-Path $fixtureLocal 'targets/nvim/old.txt'
  Assert-True `
    -Condition ($null -ne (Get-Item -LiteralPath $nvimOld -Force -ErrorAction SilentlyContinue)) `
    -Message 'Undeploy removed an unrelated dangling link.'
  Assert-True `
    -Condition (-not (Test-Path (Join-Path $fixtureLocal 'targets/nvim/new.txt'))) `
    -Message 'Undeploy deployed an unrelated new source.'
  Assert-True `
    -Condition (Test-Path (Join-Path $fixtureLocal 'targets/lazygit/old.txt')) `
    -Message 'Undeploy applied an unrelated destination change.'
  $unrelatedEntries = @($cacheBeforePreview -split '\r?\n' | Where-Object {
      $_ -match '^["''](?:nvim|lazygit)/'
    })
  foreach ($line in $unrelatedEntries) {
    Assert-True `
      -Condition ((Get-Content $fixtureCache) -contains $line) `
      -Message 'An unrelated cache entry changed.'
  }
  & $fixtureWrapper -Action Undeploy -Package codex *> $null
  & $fixtureWrapper -Action Undeploy -Package lazygit *> $null
  Assert-True `
    -Condition (-not (Test-Path (Join-Path $fixtureLocal 'targets/lazygit/old.txt'))) `
    -Message 'Undeploy did not use the cached destination.'

  # Simulate a native failure after it changed its cache, then retry using the saved state.
  [System.IO.Directory]::CreateDirectory((Join-Path $fixtureRoot 'codex/config')) | Out-Null
  [System.IO.File]::WriteAllText((Join-Path $fixtureRoot 'codex/config/new.txt'), 'codex')
  $stateBeforeFault = Get-Content $fixtureState -Raw
  $cacheBeforeFault = Get-Content $fixtureCache -Raw
  $failurePoint = 'Assert-NoSkippedTargets -Result $deployment -Phase $Action.ToLowerInvariant()'
  [System.IO.File]::WriteAllText(
    $fixtureWrapper,
    $wrapperText.Replace($failurePoint, "$failurePoint`n      throw 'Injected deployment failure.'")
  )
  Assert-WrapperFails `
    -Operation { & $fixtureWrapper -Package codex } `
    -Pattern 'Injected deployment failure'
  Assert-True `
    -Condition ((Get-Content $fixtureCache -Raw) -eq $cacheBeforeFault) `
    -Message 'Failed deployment changed the shared cache.'
  Assert-True `
    -Condition ((Get-Content $fixtureState -Raw) -eq $stateBeforeFault) `
    -Message 'Failed deployment changed saved state.'
  [System.IO.File]::WriteAllText($fixtureWrapper, $wrapperText)
  & $fixtureWrapper -Package codex *> $null
  & $fixtureWrapper -Action Restow -Package codex *> $null
  Assert-True `
    -Condition ($null -ne (Get-Item -LiteralPath $nvimOld -Force -ErrorAction SilentlyContinue)) `
    -Message 'Deploy or Restow changed an unrelated dangling link.'
  Assert-True `
    -Condition (-not (Test-Path (Join-Path $fixtureLocal 'targets/nvim/new.txt'))) `
    -Message 'Deploy or Restow applied unrelated pending changes.'

  # A source added between apply and verification must prevent committing unconverged state.
  $stateBeforeFault = Get-Content $fixtureState -Raw
  $cacheBeforeFault = Get-Content $fixtureCache -Raw
  $raceInjection = @'
      [System.IO.File]::WriteAllText((Join-Path $dotfilesRoot 'codex/config/race.txt'), 'race')
'@
  [System.IO.File]::WriteAllText(
    $fixtureWrapper,
    $wrapperText.Replace($failurePoint, "$failurePoint`n$raceInjection")
  )
  Assert-WrapperFails `
    -Operation { & $fixtureWrapper -Package codex } `
    -Pattern 'did not converge'
  Assert-True `
    -Condition ((Get-Content $fixtureCache -Raw) -eq $cacheBeforeFault) `
    -Message 'Convergence failure changed the shared cache.'
  Assert-True `
    -Condition ((Get-Content $fixtureState -Raw) -eq $stateBeforeFault) `
    -Message 'Convergence failure changed saved state.'
  [System.IO.File]::WriteAllText($fixtureWrapper, $wrapperText)
  & $fixtureWrapper -Package codex *> $null

  # State-save failure must roll back the shared cache, allowing a normal retry.
  $stateBeforeFault = Get-Content $fixtureState -Raw
  $cacheBeforeFault = Get-Content $fixtureCache -Raw
  [System.IO.File]::WriteAllText(
    $fixtureWrapper,
    ($wrapperText -replace '(?m)^Main\s*$',
    "function Save-ActiveState { throw 'Injected state-save failure.' }`nMain")
  )
  Assert-WrapperFails `
    -Operation { & $fixtureWrapper -Package lazygit } `
    -Pattern 'Injected state-save failure'
  Assert-True `
    -Condition ((Get-Content $fixtureCache -Raw) -eq $cacheBeforeFault) `
    -Message 'State-save failure did not restore the shared cache.'
  Assert-True `
    -Condition ((Get-Content $fixtureState -Raw) -eq $stateBeforeFault) `
    -Message 'State-save failure changed saved state.'
  [System.IO.File]::WriteAllText($fixtureWrapper, $wrapperText)
  & $fixtureWrapper -Package lazygit *> $null
  & $fixtureWrapper -Action Restow -Package nvim *> $null
  Assert-True `
    -Condition (Test-Path (Join-Path $fixtureLocal 'targets/nvim/new.txt')) `
    -Message 'Selected Restow did not apply pending changes.'
  Assert-True `
    -Condition ($null -eq (Get-Item -LiteralPath $nvimOld -Force -ErrorAction SilentlyContinue)) `
    -Message 'Selected Restow did not remove a stale link.'

  $stateBeforeFault = Get-Content $fixtureState -Raw
  $cacheBeforeFault = Get-Content $fixtureCache -Raw
  [System.IO.File]::WriteAllText(
    $fixtureWrapper,
    ($wrapperText -replace '(?m)^Main\s*$',
    "function Save-ActiveState { throw 'Injected Bat-save failure.' }`nMain")
  )
  Assert-WrapperFails `
    -Operation { & $fixtureWrapper -Package bat } `
    -Pattern 'Injected Bat-save failure'
  Assert-True (-not $env:DOTFILES_TEST_BAT) 'State-save failure did not restore Bat environment.'
  Assert-True `
    -Condition ((Get-Content $fixtureCache -Raw) -eq $cacheBeforeFault) `
    -Message 'Bat state-save failure did not restore the shared cache.'
  Assert-True `
    -Condition ((Get-Content $fixtureState -Raw) -eq $stateBeforeFault) `
    -Message 'Bat state-save failure changed saved state.'
  [System.IO.File]::WriteAllText($fixtureWrapper, $wrapperText)
  $env:DOTFILES_TEST_BAT_WRITES = '0'
  & $fixtureWrapper -Package bat *> $null
  $batState = Get-Content $fixtureState -Raw | ConvertFrom-Json
  Assert-True $batState.batConfigPathManaged 'Bat deployment did not record environment ownership.'
  Assert-True ($env:DOTFILES_TEST_BAT_WRITES -eq '1') 'Bat deployment did not set its environment.'
  $env:DOTFILES_TEST_BAT = 'D:/custom-bat-config'
  & $fixtureWrapper -Package codex *> $null
  Assert-True `
    -Condition ($env:DOTFILES_TEST_BAT_WRITES -eq '1') `
    -Message 'Unrelated deployment changed Bat environment.'
  Assert-WrapperFails `
    -Operation { & $fixtureWrapper -Action Restow -Package bat -WhatIf } `
    -Pattern 'User BAT_CONFIG_PATH already points'
  & $fixtureWrapper -Action Undeploy -Package bat *> $null
  Assert-True `
    -Condition ($env:DOTFILES_TEST_BAT -eq 'D:/custom-bat-config') `
    -Message 'Undeploy removed a user-customized Bat environment value.'
  $env:DOTFILES_TEST_BAT = Join-Path $env:APPDATA 'bat/config'
  & $fixtureWrapper -Package bat *> $null
  $batState = Get-Content $fixtureState -Raw | ConvertFrom-Json
  Assert-True `
    -Condition (-not $batState.batConfigPathManaged) `
    -Message 'Wrapper claimed a user-owned environment value.'
  & $fixtureWrapper -Action Undeploy -Package bat *> $null
  Assert-True `
    -Condition ($env:DOTFILES_TEST_BAT_WRITES -eq '1') `
    -Message 'Wrapper removed a user-owned environment value.'
  $env:DOTFILES_TEST_BAT = $null
  & $fixtureWrapper -Package bat *> $null
  & $fixtureWrapper -Action Undeploy -Package bat *> $null
  Assert-True (-not $env:DOTFILES_TEST_BAT) 'Undeploy did not clear its owned environment value.'
  Assert-True ($env:DOTFILES_TEST_BAT_WRITES -eq '3') 'Bat environment writes were unexpected.'
  & $fixtureWrapper -Action Undeploy -All *> $null
  Assert-State $fixtureState @()
  $env:LOCALAPPDATA = Join-Path $testRoot 'Local'

  & $wrapper -Action Deploy -Package lazygit -WhatIf *> $null
  Assert-True `
    -Condition (-not (Test-Path -LiteralPath $env:LOCALAPPDATA)) `
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

  foreach ($case in @(
      @{ Key = 'packages'; Value = @('nvim', 'nvim'); Error = 'duplicate packages' },
      @{ Key = 'packages'; Value = @('unknown'); Error = 'Unknown Dotter package' },
      @{ Key = 'packages'; Value = @(42); Error = 'invalid package name' },
      @{ Key = 'batConfigPathManaged'; Value = 'false'; Error = 'invalid BAT_CONFIG_PATH' },
      @{ Key = 'cacheFingerprint'; Value = 'wrong'; Error = 'invalid cache fingerprint' },
      @{ Key = 'version'; Value = '2'; Error = 'unsupported version' }
    )) {
    $invalidState = $validState | ConvertFrom-Json -AsHashtable
    $invalidState[$case.Key] = $case.Value
    [System.IO.File]::WriteAllText($statePath, ($invalidState | ConvertTo-Json))
    Assert-WrapperFails `
      -Operation { & $wrapper -Package lazygit -WhatIf } `
      -Pattern $case.Error
  }
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
  $env:DOTFILES_TEST_BAT = $oldTestBat
  $env:DOTFILES_TEST_BAT_WRITES = $oldTestBatWrites
  if ([System.IO.Directory]::Exists($resolvedTest)) {
    [System.IO.Directory]::Delete($resolvedTest, $true)
  }
}

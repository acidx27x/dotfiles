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

function Assert-Packages {
    param(
        [Parameter(Mandatory)][string] $StatePath,
        [Parameter(Mandatory)][AllowEmptyCollection()][string[]] $Expected
    )

    $state = Get-Content -LiteralPath $StatePath -Raw | ConvertFrom-Json
    $actual = @($state.packages)
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
    } catch {
        if ($_.Exception.Message -notmatch $Pattern) {
            throw "Expected error '$Pattern', got '$($_.Exception.Message)'."
        }
        return
    }

    throw "Expected wrapper failure matching '$Pattern'."
}

$oldOs = $env:OS
$oldLocalAppData = $env:LOCALAPPDATA
$oldAppData = $env:APPDATA

Push-Location ([System.IO.Path]::GetTempPath())
try {
    $env:OS = 'Windows_NT'
    $env:LOCALAPPDATA = Join-Path $testRoot 'Local'
    $env:APPDATA = Join-Path $testRoot 'Roaming'

    & $wrapper -Action Deploy -Package lazygit -WhatIf *> $null
    Assert-True `
        -Condition (-not (Test-Path -LiteralPath $testRoot)) `
        -Message 'WhatIf created persistent files or state.'

    & $wrapper -Action Deploy -Package lazygit *> $null
    $stateRoot = Join-Path $env:LOCALAPPDATA 'dotfiles\dotter'
    $statePath = Join-Path $stateRoot 'active-packages.json'
    $generatedConfig = Join-Path $stateRoot 'local.toml'
    $lazygitTarget = Join-Path $env:LOCALAPPDATA 'lazygit\config.yml'
    Assert-True (Test-Path -LiteralPath $lazygitTarget) 'lazygit was not deployed.'
    Assert-Packages -StatePath $statePath -Expected @('lazygit')

    & $wrapper -Action Deploy -Package lazygit *> $null
    Assert-Packages -StatePath $statePath -Expected @('lazygit')

    & $wrapper -Action Deploy -Package nvim,lazygit,nvim *> $null
    Assert-Packages -StatePath $statePath -Expected @('nvim', 'lazygit')
    & $wrapper -Action Deploy -Profile minimal -WhatIf *> $null

    & $wrapper -Action Undeploy -Package nvim *> $null
    Assert-True (Test-Path -LiteralPath $lazygitTarget) 'Selective removal removed lazygit.'
    Assert-True `
        -Condition (-not (Test-Path -LiteralPath (Join-Path $env:LOCALAPPDATA 'nvim\init.lua'))) `
        -Message 'Selective removal left nvim deployed.'
    Assert-Packages -StatePath $statePath -Expected @('lazygit')

    & $wrapper -Action Restow -Package lazygit *> $null
    Assert-Packages -StatePath $statePath -Expected @('lazygit')

    & $wrapper -Action Deploy -Package nvim -Replace *> $null
    Assert-True `
        -Condition (-not (Test-Path -LiteralPath $lazygitTarget)) `
        -Message 'Replace left lazygit deployed.'
    Assert-Packages -StatePath $statePath -Expected @('nvim')

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

    [System.IO.File]::Delete($statePath)
    [System.IO.File]::Delete($generatedConfig)
    & $wrapper -Action Deploy -Package lazygit -WhatIf *> $null
    Assert-True `
        -Condition (-not (Test-Path -LiteralPath $statePath)) `
        -Message 'Migration WhatIf created active state.'
    Assert-True `
        -Condition (-not (Test-Path -LiteralPath (Join-Path $stateRoot 'backups'))) `
        -Message 'Migration WhatIf created a backup.'

    & $wrapper -Action Deploy -Package lazygit *> $null
    Assert-Packages -StatePath $statePath -Expected @('nvim', 'lazygit')
    Assert-True `
        -Condition ([bool](Get-ChildItem `
            -LiteralPath (Join-Path $stateRoot 'backups') `
            -Directory `
            -Filter 'migration-*')) `
        -Message 'Migration did not back up the previous cache.'

    $stateBeforeFailure = Get-Content -LiteralPath $statePath -Raw
    Assert-WrapperFails `
        -Operation { & $wrapper -Action Deploy -Package unknown } `
        -Pattern 'Unknown Dotter package'
    Assert-True `
        -Condition ((Get-Content -LiteralPath $statePath -Raw) -eq $stateBeforeFailure) `
        -Message 'Unknown package changed active state.'

    & $wrapper -Action Undeploy -All *> $null
    Assert-Packages -StatePath $statePath -Expected @()

    Write-Host '[PASS] Dotter wrapper regression tests completed.'
} finally {
    Pop-Location
    $env:OS = $oldOs
    $env:LOCALAPPDATA = $oldLocalAppData
    $env:APPDATA = $oldAppData
    if ([System.IO.Directory]::Exists($resolvedTest)) {
        [System.IO.Directory]::Delete($resolvedTest, $true)
    }
}

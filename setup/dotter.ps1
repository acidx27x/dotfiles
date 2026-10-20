#Requires -Version 7.0

[CmdletBinding(SupportsShouldProcess = $true)]
param(
    [ValidateSet('Deploy', 'Undeploy')]
    [string] $Action = 'Deploy'
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Write-Info {
    param([Parameter(Mandatory)][string] $Message)

    Write-Host "[INFO] $Message"
}

function Test-SamePath {
    param(
        [Parameter(Mandatory)][string] $Left,
        [Parameter(Mandatory)][string] $Right
    )

    $leftPath = [System.IO.Path]::GetFullPath(
        [Environment]::ExpandEnvironmentVariables($Left)
    ).TrimEnd('\', '/')
    $rightPath = [System.IO.Path]::GetFullPath(
        [Environment]::ExpandEnvironmentVariables($Right)
    ).TrimEnd('\', '/')

    return [StringComparer]::OrdinalIgnoreCase.Equals($leftPath, $rightPath)
}

function Assert-SymbolicLinksAvailable {
    $testDirectory = Join-Path (
        [System.IO.Path]::GetTempPath()
    ) "dotter-symlink-$([Guid]::NewGuid().ToString('N'))"
    $source = Join-Path $testDirectory 'source.txt'
    $target = Join-Path $testDirectory 'target.txt'

    try {
        New-Item -ItemType Directory -Path $testDirectory | Out-Null
        New-Item -ItemType File -Path $source | Out-Null
        New-Item -ItemType SymbolicLink -Path $target -Target $source | Out-Null
    } catch {
        throw 'Windows could not create a file symlink. Enable Developer Mode or grant ' +
            'the current user symlink permission before deploying; copying is not allowed.'
    } finally {
        if (Test-Path -LiteralPath $testDirectory) {
            Remove-Item -LiteralPath $testDirectory -Recurse -Force
        }
    }
}

function Invoke-Dotter {
    param(
        [Parameter(Mandatory)][string] $Command,
        [Parameter(Mandatory)][string[]] $CommonArguments,
        [Parameter(Mandatory)][string] $Operation,
        [switch] $DryRun
    )

    $arguments = @($CommonArguments)
    if ($DryRun) {
        $arguments += '--dry-run'
    }
    $arguments += $Operation.ToLowerInvariant()

    $global:LASTEXITCODE = 0
    & $Command @arguments
    if ($LASTEXITCODE -ne 0) {
        $mode = if ($DryRun) { 'dry-run' } else { $Operation.ToLowerInvariant() }
        throw "Dotter $mode failed with exit code $LASTEXITCODE."
    }
}

function Main {
    if ($env:OS -ne 'Windows_NT') {
        throw 'This setup script only supports Windows.'
    }
    if (-not $env:LOCALAPPDATA -or -not $env:APPDATA) {
        throw 'LOCALAPPDATA and APPDATA must be set.'
    }

    $dotter = Get-Command dotter -ErrorAction SilentlyContinue | Select-Object -First 1
    if ($null -eq $dotter) {
        throw 'Dotter is not installed. Run setup\scoop.ps1, reopen the terminal, and retry.'
    }
    $dotterCommand = if ($dotter.PSObject.Properties.Name -contains 'Path' -and
        $dotter.Path) {
        $dotter.Path
    } else {
        $dotter.Name
    }

    $dotfilesRoot = [System.IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..'))
    $globalConfig = Join-Path $dotfilesRoot 'windows\dotter\global.toml'
    $localConfig = Join-Path $dotfilesRoot 'windows\dotter\windows.toml'
    foreach ($path in $globalConfig, $localConfig) {
        if (-not (Test-Path -LiteralPath $path -PathType Leaf)) {
            throw "Dotter configuration is missing: $path"
        }
    }

    $stateRoot = Join-Path $env:LOCALAPPDATA 'dotfiles\dotter'
    $cacheFile = Join-Path $stateRoot 'cache.toml'
    $cacheDirectory = Join-Path $stateRoot 'cache'
    $batConfigPath = Join-Path $env:APPDATA 'bat\config'
    $userBatConfig = [Environment]::GetEnvironmentVariable(
        'BAT_CONFIG_PATH',
        'User'
    )

    if ($Action -eq 'Deploy' -and $userBatConfig -and
        -not (Test-SamePath -Left $userBatConfig -Right $batConfigPath)) {
        throw "User BAT_CONFIG_PATH already points to '$userBatConfig', not '$batConfigPath'."
    }

    $commonArguments = @(
        '--global-config', $globalConfig,
        '--local-config', $localConfig,
        '--cache-file', $cacheFile,
        '--cache-directory', $cacheDirectory
    )

    Push-Location $dotfilesRoot
    try {
        if ($Action -eq 'Deploy') {
            Assert-SymbolicLinksAvailable
        }

        Write-Info "Previewing Dotter $($Action.ToLowerInvariant())."
        Invoke-Dotter `
            -Command $dotterCommand `
            -CommonArguments $commonArguments `
            -Operation $Action `
            -DryRun

        if ($WhatIfPreference) {
            if ($Action -eq 'Deploy' -and -not $userBatConfig) {
                Write-Info "Would set user BAT_CONFIG_PATH to '$batConfigPath'."
            } elseif ($Action -eq 'Undeploy' -and $userBatConfig -and
                (Test-SamePath -Left $userBatConfig -Right $batConfigPath)) {
                Write-Info "Would remove user BAT_CONFIG_PATH '$userBatConfig'."
            }
            return
        }

        if (-not $PSCmdlet.ShouldProcess('Windows dotfiles', $Action)) {
            return
        }

        New-Item -ItemType Directory -Path $stateRoot -Force | Out-Null
        Write-Info "Running Dotter $($Action.ToLowerInvariant())."
        Invoke-Dotter `
            -Command $dotterCommand `
            -CommonArguments $commonArguments `
            -Operation $Action

        if ($Action -eq 'Deploy' -and -not $userBatConfig) {
            [Environment]::SetEnvironmentVariable(
                'BAT_CONFIG_PATH',
                $batConfigPath,
                'User'
            )
            Write-Info "Set user BAT_CONFIG_PATH to '$batConfigPath'."
        } elseif ($Action -eq 'Undeploy' -and $userBatConfig -and
            (Test-SamePath -Left $userBatConfig -Right $batConfigPath)) {
            [Environment]::SetEnvironmentVariable('BAT_CONFIG_PATH', $null, 'User')
            Write-Info 'Removed the managed user BAT_CONFIG_PATH.'
        }
    } finally {
        Pop-Location
    }

    Write-Info 'Close this terminal and open a new one to refresh the environment.'
}

Main

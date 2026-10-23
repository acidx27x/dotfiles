#Requires -Version 7.0

[CmdletBinding(SupportsShouldProcess = $true)]
param(
    [ValidateSet('Deploy', 'Undeploy', 'Restow')]
    [string] $Action = 'Deploy',

    [string[]] $Package,

    [string] $Profile,

    [switch] $Replace,

    [switch] $All
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

function ConvertFrom-QuotedTomlString {
    param([Parameter(Mandatory)][string] $Value)

    if ($Value.StartsWith("'")) {
        return $Value.Substring(1, $Value.Length - 2).Replace("''", "'")
    }

    return $Value | ConvertFrom-Json
}

function Get-GlobalPackageDefinitions {
    param([Parameter(Mandatory)][string] $Path)

    $definitions = [ordered]@{}
    $currentPackage = $null

    foreach ($line in Get-Content -LiteralPath $Path) {
        if ($line -match '^\s*\[(?<section>[^]]+)\]\s*(?:#.*)?$') {
            $section = $Matches.section
            if ($section -match '^(?<package>[A-Za-z0-9_.-]+)\.files$') {
                $currentPackage = $Matches.package
                if (-not $definitions.Contains($currentPackage)) {
                    $definitions[$currentPackage] = [System.Collections.Generic.List[object]]::new()
                }
            } else {
                $currentPackage = $null
            }
            continue
        }

        if (-not $currentPackage) {
            continue
        }

        if ($line -match '^\s*(?<source>"(?:\\.|[^"])*"|''[^'']*'')\s*=\s*(?<target>.+)$') {
            $definitions[$currentPackage].Add([pscustomobject]@{
                Source = ConvertFrom-QuotedTomlString $Matches.source
                Recurse = $Matches.target -notmatch '\brecurse\s*=\s*false\b'
            })
        }
    }

    if ($definitions.Count -eq 0) {
        throw "No Dotter packages were found in '$Path'."
    }

    return $definitions
}

function Get-OrderedPackages {
    param(
        [Parameter(Mandatory)][System.Collections.IDictionary] $Definitions,
        [Parameter(Mandatory)][AllowEmptyCollection()][string[]] $Names
    )

    $selected = [System.Collections.Generic.HashSet[string]]::new(
        [StringComparer]::OrdinalIgnoreCase
    )
    foreach ($name in $Names) {
        [void] $selected.Add($name)
    }

    return @($Definitions.Keys | Where-Object { $selected.Contains($_) })
}

function Resolve-PackageNames {
    param(
        [Parameter(Mandatory)][System.Collections.IDictionary] $Definitions,
        [Parameter(Mandatory)][AllowEmptyCollection()][string[]] $Names
    )

    $resolved = [System.Collections.Generic.List[string]]::new()
    foreach ($nameGroup in $Names) {
        foreach ($name in $nameGroup -split ',') {
            $candidate = $name.Trim()
            if (-not $candidate) {
                continue
            }

            $match = @($Definitions.Keys | Where-Object {
                [StringComparer]::OrdinalIgnoreCase.Equals($_, $candidate)
            })
            if ($match.Count -ne 1) {
                $known = $Definitions.Keys -join ', '
                throw "Unknown Dotter package '$candidate'. Available packages: $known."
            }
            $resolved.Add($match[0])
        }
    }

    return Get-OrderedPackages -Definitions $Definitions -Names $resolved.ToArray()
}

function Read-ProfilePackages {
    param(
        [Parameter(Mandatory)][string] $Path,
        [Parameter(Mandatory)][System.Collections.IDictionary] $Definitions
    )

    $content = (Get-Content -LiteralPath $Path -Raw) -replace '(?m)#.*$', ''
    $packageList = [regex]::Match($content, '(?ms)^\s*packages\s*=\s*\[(?<body>.*?)\]\s*$')
    if (-not $packageList.Success) {
        throw "Profile '$Path' must contain only a packages array."
    }

    $body = $packageList.Groups['body'].Value
    $matches = [regex]::Matches(
        $body,
        '(?<value>"[A-Za-z0-9_.-]+"|''[A-Za-z0-9_.-]+'')'
    )
    $unparsed = $body
    foreach ($match in $matches) {
        $unparsed = $unparsed.Replace($match.Value, '')
    }
    if (($unparsed -replace '[\s,]', '').Length -ne 0) {
        throw "Profile '$Path' contains unsupported content. Use package names only."
    }

    $names = @($matches | ForEach-Object {
        $_.Value.Substring(1, $_.Value.Length - 2)
    })
    if ($names.Count -eq 0) {
        throw "Profile '$Path' does not select any packages."
    }

    return Resolve-PackageNames -Definitions $Definitions -Names $names
}

function Resolve-ProfilePackages {
    param(
        [Parameter(Mandatory)][string] $Name,
        [Parameter(Mandatory)][string] $DotterConfigRoot,
        [Parameter(Mandatory)][System.Collections.IDictionary] $Definitions
    )

    $profiles = [ordered]@{
        windows = Join-Path $DotterConfigRoot 'windows.toml'
    }
    $profileRoot = Join-Path $DotterConfigRoot 'profiles'
    if (Test-Path -LiteralPath $profileRoot -PathType Container) {
        foreach ($file in Get-ChildItem -LiteralPath $profileRoot -Filter '*.toml' -File) {
            if ($profiles.Contains($file.BaseName)) {
                throw "Duplicate Dotter profile name '$($file.BaseName)'."
            }
            $profiles[$file.BaseName] = $file.FullName
        }
    }

    $profileName = @($profiles.Keys | Where-Object {
        [StringComparer]::OrdinalIgnoreCase.Equals($_, $Name)
    })
    if ($profileName.Count -ne 1) {
        throw "Unknown Dotter profile '$Name'. Available profiles: $($profiles.Keys -join ', ')."
    }

    return Read-ProfilePackages `
        -Path $profiles[$profileName[0]] `
        -Definitions $Definitions
}

function Get-CacheEntries {
    param([Parameter(Mandatory)][string] $Path)

    $result = [pscustomobject]@{
        Symlinks = [System.Collections.Generic.List[object]]::new()
        TemplateCount = 0
    }
    if (-not (Test-Path -LiteralPath $Path -PathType Leaf)) {
        return $result
    }

    $section = $null
    foreach ($line in Get-Content -LiteralPath $Path) {
        if ($line -match '^\s*\[(?<section>symlinks|templates)\]\s*$') {
            $section = $Matches.section
            continue
        }
        if (-not $section -or $line -match '^\s*(?:#.*)?$') {
            continue
        }
        if ($line -notmatch '^\s*(?<source>"(?:\\.|[^"])*"|''[^'']*'')\s*=\s*(?<target>"(?:\\.|[^"])*"|''[^'']*'')\s*$') {
            throw "Cannot safely parse Dotter cache entry: $line"
        }

        if ($section -eq 'templates') {
            $result.TemplateCount++
        } else {
            $result.Symlinks.Add([pscustomobject]@{
                Source = ConvertFrom-QuotedTomlString $Matches.source
                Target = ConvertFrom-QuotedTomlString $Matches.target
            })
        }
    }

    return $result
}

function Get-CachePackages {
    param(
        [Parameter(Mandatory)] $Cache,
        [Parameter(Mandatory)][System.Collections.IDictionary] $Definitions,
        [Parameter(Mandatory)][string] $DotfilesRoot,
        [switch] $VerifyLinks,
        [AllowEmptyCollection()][string[]] $AllowMissingLinksForPackages = @()
    )

    if ($Cache.TemplateCount -ne 0) {
        throw 'The existing Dotter cache contains templates and cannot be migrated safely.'
    }

    $allowMissingLinks = [System.Collections.Generic.HashSet[string]]::new(
        [StringComparer]::OrdinalIgnoreCase
    )
    foreach ($packageName in $AllowMissingLinksForPackages) {
        [void] $allowMissingLinks.Add($packageName)
    }
    $packages = [System.Collections.Generic.List[string]]::new()
    foreach ($entry in $Cache.Symlinks) {
        $cacheSource = $entry.Source.Replace('\', '/').TrimStart('.', '/')
        $matches = [System.Collections.Generic.HashSet[string]]::new(
            [StringComparer]::OrdinalIgnoreCase
        )
        foreach ($packageName in $Definitions.Keys) {
            foreach ($source in $Definitions[$packageName]) {
                $configuredSource = $source.Source.Replace('\', '/').TrimStart('.', '/').TrimEnd('/')
                if ($cacheSource -eq $configuredSource -or
                    $cacheSource.StartsWith("$configuredSource/", [StringComparison]::OrdinalIgnoreCase)) {
                    [void] $matches.Add($packageName)
                }
            }
        }

        if ($matches.Count -eq 0) {
            $cacheSourceRoot = $cacheSource.Split('/', 2)[0]
            foreach ($packageName in $Definitions.Keys) {
                foreach ($source in $Definitions[$packageName]) {
                    $configuredSource = $source.Source.Replace('\', '/')
                    $configuredSource = $configuredSource.TrimStart('.', '/')
                    $configuredSourceRoot = $configuredSource.Split('/', 2)[0]
                    if ([StringComparer]::OrdinalIgnoreCase.Equals(
                        $cacheSourceRoot,
                        $configuredSourceRoot
                    )) {
                        [void] $matches.Add($packageName)
                        break
                    }
                }
            }
        }

        if ($matches.Count -ne 1) {
            throw "Cannot associate cached source '$($entry.Source)' with exactly one package."
        }
        $packageName = @($matches)[0]
        $packages.Add($packageName)

        if ($VerifyLinks) {
            $target = Get-Item -LiteralPath $entry.Target -Force -ErrorAction SilentlyContinue
            if ($null -eq $target -and $allowMissingLinks.Contains($packageName)) {
                continue
            }
            if ($null -eq $target -or $target.LinkType -ne 'SymbolicLink') {
                throw "Cached target '$($entry.Target)' is missing or is not a symbolic link."
            }

            $linkTarget = @($target.Target)[0]
            if (-not [System.IO.Path]::IsPathFullyQualified($linkTarget)) {
                $linkTarget = Join-Path $target.DirectoryName $linkTarget
            }
            $expectedSource = Join-Path $DotfilesRoot $entry.Source
            if (-not (Test-SamePath -Left $linkTarget -Right $expectedSource)) {
                throw "Cached target '$($entry.Target)' points to '$linkTarget', not '$expectedSource'."
            }
        }
    }

    return Get-OrderedPackages -Definitions $Definitions -Names $packages.ToArray()
}

function Read-ActiveState {
    param(
        [Parameter(Mandatory)][string] $Path,
        [Parameter(Mandatory)][System.Collections.IDictionary] $Definitions
    )

    $state = Get-Content -LiteralPath $Path -Raw | ConvertFrom-Json
    if ($state.version -ne 1 -or $null -eq $state.packages -or
        $null -eq $state.batConfigPathManaged) {
        throw "Active Dotter state '$Path' has an unsupported format."
    }

    return [pscustomobject]@{
        Packages = Resolve-PackageNames `
            -Definitions $Definitions `
            -Names @($state.packages)
        BatConfigPathManaged = [bool] $state.batConfigPathManaged
    }
}

function New-LocalConfigContent {
    param([Parameter(Mandatory)][AllowEmptyCollection()][string[]] $Packages)

    $lines = [System.Collections.Generic.List[string]]::new()
    $lines.Add('packages = [')
    foreach ($name in $Packages) {
        $lines.Add("  `"$name`",")
    }
    $lines.Add(']')
    return ($lines -join [Environment]::NewLine) + [Environment]::NewLine
}

function Save-MachineState {
    param(
        [Parameter(Mandatory)][string] $StatePath,
        [Parameter(Mandatory)][string] $LocalConfigPath,
        [Parameter(Mandatory)][AllowEmptyCollection()][string[]] $Packages,
        [Parameter(Mandatory)][bool] $BatConfigPathManaged
    )

    $state = [ordered]@{
        version = 1
        packages = @($Packages)
        batConfigPathManaged = $BatConfigPathManaged
    }
    $stateContent = ($state | ConvertTo-Json) + [Environment]::NewLine
    $localContent = New-LocalConfigContent -Packages $Packages

    foreach ($item in @(
        [pscustomobject]@{ Path = $LocalConfigPath; Content = $localContent },
        [pscustomobject]@{ Path = $StatePath; Content = $stateContent }
    )) {
        $temporaryPath = "$($item.Path).$([Guid]::NewGuid().ToString('N')).tmp"
        try {
            [System.IO.File]::WriteAllText($temporaryPath, $item.Content)
            Move-Item -LiteralPath $temporaryPath -Destination $item.Path -Force
        } finally {
            if ([System.IO.File]::Exists($temporaryPath)) {
                [System.IO.File]::Delete($temporaryPath)
            }
        }
    }
}

function Backup-MigrationState {
    param(
        [Parameter(Mandatory)][string] $StateRoot,
        [Parameter(Mandatory)][string[]] $Paths
    )

    $backupRoot = Join-Path $StateRoot (
        'backups\migration-' + (Get-Date -Format 'yyyyMMdd-HHmmss')
    )
    New-Item -ItemType Directory -Path $backupRoot -Force | Out-Null
    foreach ($path in $Paths) {
        if (Test-Path -LiteralPath $path) {
            Copy-Item -LiteralPath $path -Destination $backupRoot -Recurse
        }
    }
    Write-Info "Backed up previous Dotter data to '$backupRoot'."
}

function Get-RequiredSymlinkTypes {
    param(
        [Parameter(Mandatory)][System.Collections.IDictionary] $Definitions,
        [Parameter(Mandatory)][AllowEmptyCollection()][string[]] $Packages,
        [Parameter(Mandatory)][string] $DotfilesRoot
    )

    $requireFile = $false
    $requireDirectory = $false
    foreach ($packageName in $Packages) {
        foreach ($source in $Definitions[$packageName]) {
            $sourcePath = Join-Path $DotfilesRoot $source.Source
            $item = Get-Item -LiteralPath $sourcePath -Force
            if (-not $item.PSIsContainer) {
                $requireFile = $true
            } elseif (-not $source.Recurse) {
                $requireDirectory = $true
            } elseif (Get-ChildItem -LiteralPath $sourcePath -File -Force -Recurse |
                Select-Object -First 1) {
                $requireFile = $true
            }
        }
    }

    return [pscustomobject]@{
        File = $requireFile
        Directory = $requireDirectory
    }
}

function Assert-SymbolicLinksAvailable {
    param(
        [Parameter(Mandatory)][bool] $RequireFile,
        [Parameter(Mandatory)][bool] $RequireDirectory
    )

    if (-not $RequireFile -and -not $RequireDirectory) {
        return
    }

    $testDirectory = Join-Path (
        [System.IO.Path]::GetTempPath()
    ) "dotter-symlink-$([Guid]::NewGuid().ToString('N'))"
    $linkKind = 'symbolic'

    try {
        New-Item -ItemType Directory -Path $testDirectory | Out-Null
        if ($RequireFile) {
            $linkKind = 'file'
            $sourceFile = Join-Path $testDirectory 'source.txt'
            New-Item -ItemType File -Path $sourceFile | Out-Null
            New-Item `
                -ItemType SymbolicLink `
                -Path (Join-Path $testDirectory 'file-link.txt') `
                -Target $sourceFile | Out-Null
        }
        if ($RequireDirectory) {
            $linkKind = 'directory'
            $sourceDirectory = Join-Path $testDirectory 'source-directory'
            New-Item -ItemType Directory -Path $sourceDirectory | Out-Null
            New-Item `
                -ItemType SymbolicLink `
                -Path (Join-Path $testDirectory 'directory-link') `
                -Target $sourceDirectory | Out-Null
        }
    } catch {
        $message = "Windows could not create a $linkKind symlink. Enable Developer Mode " +
            'or grant the current user symlink permission before deploying; copying is not ' +
            "allowed. Original error: $($_.Exception.Message)"
        throw [InvalidOperationException]::new($message, $_.Exception)
    } finally {
        if ([System.IO.Directory]::Exists($testDirectory)) {
            [System.IO.Directory]::Delete($testDirectory, $true)
        }
    }
}

function Invoke-Dotter {
    param(
        [Parameter(Mandatory)][string] $Command,
        [Parameter(Mandatory)][string[]] $CommonArguments,
        [Parameter(Mandatory)][string] $DisplayOperation,
        [switch] $DryRun
    )

    $arguments = @($CommonArguments)
    if ($DryRun) {
        $arguments += '--dry-run'
    } else {
        $arguments += '--noconfirm'
    }
    $arguments += 'deploy'

    $global:LASTEXITCODE = 0
    $output = @(& $Command @arguments 2>&1)
    $exitCode = $LASTEXITCODE
    foreach ($line in $output) {
        Write-Host $line.ToString()
    }

    if ($exitCode -ne 0) {
        $mode = if ($DryRun) { 'dry-run' } else { $DisplayOperation.ToLowerInvariant() }
        throw "Dotter $mode failed with exit code $exitCode."
    }
    if ($DryRun -and ($output -join [Environment]::NewLine) -match
        'target (?:file|directory) already exists[^\r\n]*Skipping') {
        throw 'Dotter found a conflicting target and refused to replace it.'
    }

    return $output
}

function Main {
    if ($env:OS -ne 'Windows_NT') {
        throw 'This setup script only supports Windows.'
    }
    if (-not $env:LOCALAPPDATA -or -not $env:APPDATA) {
        throw 'LOCALAPPDATA and APPDATA must be set.'
    }
    if ($Package -and $Profile) {
        throw 'Use either -Package or -Profile, not both.'
    }
    if ($All -and ($Package -or $Profile -or $Replace)) {
        throw '-All cannot be combined with -Package, -Profile, or -Replace.'
    }
    if ($All -and $Action -ne 'Undeploy') {
        throw '-All is valid only with -Action Undeploy.'
    }
    if ($Replace -and $Action -ne 'Deploy') {
        throw '-Replace is valid only with -Action Deploy.'
    }
    if ($Action -ne 'Deploy' -and -not $All -and -not $Package -and -not $Profile) {
        throw "$Action requires -Package or -Profile. Use -All for complete undeployment."
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
    $dotterConfigRoot = Join-Path $dotfilesRoot 'windows\dotter'
    $globalConfig = Join-Path $dotterConfigRoot 'global.toml'
    if (-not (Test-Path -LiteralPath $globalConfig -PathType Leaf)) {
        throw "Dotter configuration is missing: $globalConfig"
    }
    $definitions = Get-GlobalPackageDefinitions -Path $globalConfig

    $selectedPackages = @()
    if (-not $All) {
        if ($Package) {
            $selectedPackages = @(Resolve-PackageNames `
                -Definitions $definitions `
                -Names $Package)
        } else {
            $profileName = if ($Profile) { $Profile } else { 'windows' }
            $selectedPackages = @(Resolve-ProfilePackages `
                -Name $profileName `
                -DotterConfigRoot $dotterConfigRoot `
                -Definitions $definitions)
        }
    }

    $stateRoot = Join-Path $env:LOCALAPPDATA 'dotfiles\dotter'
    $stateFile = Join-Path $stateRoot 'active-packages.json'
    $generatedConfig = Join-Path $stateRoot 'local.toml'
    $cacheFile = Join-Path $stateRoot 'cache.toml'
    $cacheDirectory = Join-Path $stateRoot 'cache'
    $cache = Get-CacheEntries -Path $cacheFile
    $cachedPackages = @(Get-CachePackages `
        -Cache $cache `
        -Definitions $definitions `
        -DotfilesRoot $dotfilesRoot)

    $isMigration = -not (Test-Path -LiteralPath $stateFile -PathType Leaf) -and
        ((Test-Path -LiteralPath $cacheFile) -or
        (Test-Path -LiteralPath $cacheDirectory) -or
        (Test-Path -LiteralPath $generatedConfig))

    if (Test-Path -LiteralPath $stateFile -PathType Leaf) {
        $activeState = Read-ActiveState -Path $stateFile -Definitions $definitions
        $currentPackages = @($activeState.Packages)
        $batConfigPathManaged = $activeState.BatConfigPathManaged

        $orderedCache = $cachedPackages -join "`n"
        $orderedState = $currentPackages -join "`n"
        if ($orderedCache -ne $orderedState) {
            throw 'Active package state does not match the Dotter cache. Restore the state ' +
                'backup or remove active-packages.json to run verified migration.'
        }
    } else {
        if ((Test-Path -LiteralPath $cacheDirectory -PathType Container) -and
            -not (Test-Path -LiteralPath $cacheFile -PathType Leaf) -and
            (Get-ChildItem -LiteralPath $cacheDirectory -Force | Select-Object -First 1)) {
            throw 'Dotter cache data exists without cache.toml; active packages cannot be reconstructed.'
        }

        if ($isMigration) {
            $allowMissingLinksForPackages = if ($Action -eq 'Undeploy') {
                if ($All) { $cachedPackages } else { $selectedPackages }
            } else {
                @()
            }
            $currentPackages = @(Get-CachePackages `
                -Cache $cache `
                -Definitions $definitions `
                -DotfilesRoot $dotfilesRoot `
                -VerifyLinks `
                -AllowMissingLinksForPackages $allowMissingLinksForPackages)
            Write-Info "Verified existing Dotter packages: $($currentPackages -join ', ')."
        } else {
            $currentPackages = @()
        }

        $batConfigPathManaged = $false
    }

    if ($All) {
        $desiredPackages = @()
    } elseif ($Replace) {
        $desiredPackages = @($selectedPackages)
    } elseif ($Action -in 'Deploy', 'Restow') {
        $desiredPackages = @(Get-OrderedPackages `
            -Definitions $definitions `
            -Names @($currentPackages + $selectedPackages))
    } else {
        $removed = [System.Collections.Generic.HashSet[string]]::new(
            [StringComparer]::OrdinalIgnoreCase
        )
        foreach ($packageName in $selectedPackages) {
            [void] $removed.Add($packageName)
        }
        $desiredPackages = @($currentPackages | Where-Object { -not $removed.Contains($_) })
    }

    $batConfigPath = Join-Path $env:APPDATA 'bat\config'
    $userBatConfig = [Environment]::GetEnvironmentVariable('BAT_CONFIG_PATH', 'User')
    if ($isMigration -and $currentPackages -contains 'bat' -and $userBatConfig -and
        (Test-SamePath -Left $userBatConfig -Right $batConfigPath)) {
        $batConfigPathManaged = $true
    }
    $batSelected = $desiredPackages -contains 'bat'
    if ($batSelected -and $userBatConfig -and
        -not (Test-SamePath -Left $userBatConfig -Right $batConfigPath)) {
        throw "User BAT_CONFIG_PATH already points to '$userBatConfig', not '$batConfigPath'."
    }

    $temporaryConfig = Join-Path (
        [System.IO.Path]::GetTempPath()
    ) "dotter-local-$([Guid]::NewGuid().ToString('N')).toml"
    [System.IO.File]::WriteAllText(
        $temporaryConfig,
        (New-LocalConfigContent -Packages $desiredPackages)
    )

    $commonArguments = @(
        '--global-config', $globalConfig,
        '--local-config', $temporaryConfig,
        '--cache-file', $cacheFile,
        '--cache-directory', $cacheDirectory
    )

    Push-Location $dotfilesRoot
    try {
        $displayPackages = if ($desiredPackages.Count) {
            $desiredPackages -join ', '
        } else {
            '(none)'
        }
        Write-Info "Previewing Dotter $($Action.ToLowerInvariant()) for: $displayPackages."
        $previewOutput = @(Invoke-Dotter `
            -Command $dotterCommand `
            -CommonArguments $commonArguments `
            -DisplayOperation $Action `
            -DryRun)

        if ($WhatIfPreference) {
            if ($batSelected -and -not $userBatConfig) {
                Write-Info "Would set user BAT_CONFIG_PATH to '$batConfigPath'."
            } elseif (-not $batSelected -and $batConfigPathManaged -and
                $userBatConfig -and
                (Test-SamePath -Left $userBatConfig -Right $batConfigPath)) {
                Write-Info "Would remove managed user BAT_CONFIG_PATH '$userBatConfig'."
            }
            Write-Info 'WhatIf completed without changing managed files or saved state.'
            return
        }

        if (-not $PSCmdlet.ShouldProcess("Windows dotfiles: $displayPackages", $Action)) {
            return
        }

        if (($previewOutput -join [Environment]::NewLine) -match '\[\+\]\s+symlink') {
            $requiredLinks = Get-RequiredSymlinkTypes `
                -Definitions $definitions `
                -Packages $desiredPackages `
                -DotfilesRoot $dotfilesRoot
            Assert-SymbolicLinksAvailable `
                -RequireFile $requiredLinks.File `
                -RequireDirectory $requiredLinks.Directory
        }

        New-Item -ItemType Directory -Path $stateRoot -Force | Out-Null
        if ($isMigration) {
            Backup-MigrationState `
                -StateRoot $stateRoot `
                -Paths @($cacheFile, $cacheDirectory, $generatedConfig)
        }

        Write-Info "Running Dotter $($Action.ToLowerInvariant())."
        $null = Invoke-Dotter `
            -Command $dotterCommand `
            -CommonArguments $commonArguments `
            -DisplayOperation $Action

        if ($batSelected -and -not $userBatConfig) {
            [Environment]::SetEnvironmentVariable(
                'BAT_CONFIG_PATH',
                $batConfigPath,
                'User'
            )
            $batConfigPathManaged = $true
            Write-Info "Set user BAT_CONFIG_PATH to '$batConfigPath'."
        } elseif (-not $batSelected) {
            if ($batConfigPathManaged -and $userBatConfig -and
                (Test-SamePath -Left $userBatConfig -Right $batConfigPath)) {
                [Environment]::SetEnvironmentVariable('BAT_CONFIG_PATH', $null, 'User')
                Write-Info 'Removed the managed user BAT_CONFIG_PATH.'
            }
            $batConfigPathManaged = $false
        }

        Save-MachineState `
            -StatePath $stateFile `
            -LocalConfigPath $generatedConfig `
            -Packages $desiredPackages `
            -BatConfigPathManaged $batConfigPathManaged
    } finally {
        Pop-Location
        if ([System.IO.File]::Exists($temporaryConfig)) {
            [System.IO.File]::Delete($temporaryConfig)
        }
    }

    Write-Info 'Deployment state saved. Reopen the terminal after BAT_CONFIG_PATH changes.'
}

Main

#Requires -Version 7.0

[CmdletBinding(SupportsShouldProcess = $true)]
param(
  [ValidateSet('Deploy', 'Undeploy', 'Restow')]
  [string] $Action = 'Deploy',

  [string[]] $Package,

  [Alias('Profile')]
  [string] $SelectedProfile,

  [switch] $Replace,

  [switch] $All,

  [Alias('h')]
  [switch] $Help
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$script:PackageSpecified = $PSBoundParameters.ContainsKey('Package')
$script:ProfileSpecified = $PSBoundParameters.ContainsKey('SelectedProfile')

function Write-Info {
  param([Parameter(Mandatory)][string] $Message)

  Write-Host "[INFO] $Message"
}

function Show-DotterHelp {
  @'
Deploy Windows dotfiles through Dotter while preserving explicit package state.

Usage:
  pwsh -NoProfile -File <repo>\setup\dotter.ps1 [options]

Options:
  --help, -Help, -h           Show this help and exit without reading machine state.
  -Action <action>            Deploy (default), Undeploy, or Restow.
  -Package <name[,name...]>   Change only these packages.
  -Profile <name>             Select a tracked Dotter profile.
  -Replace                    Replace the complete selection during Deploy.
  -All                        Remove the complete selection during Undeploy.
  -WhatIf                     Preview without changing links, state, or environment.
  -Confirm                    Prompt before applying the previewed operation.

Rules:
  -Package and -Profile are mutually exclusive.
  Undeploy and Restow require -Package or -Profile.
  Only "-Action Undeploy -All" requests an empty package selection.

Examples:
  dotter.ps1 -WhatIf
  dotter.ps1 -Package git,nvim
  dotter.ps1 -Action Undeploy -Package nvim
  dotter.ps1 -Action Restow -Profile minimal
  dotter.ps1 -Profile minimal -Replace
  dotter.ps1 -Action Undeploy -All

See windows.md for prerequisites, state integrity, and recovery guidance.
'@
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

function Get-GlobalPackageNames {
  param([Parameter(Mandatory)][string] $Path)

  $names = [System.Collections.Generic.List[string]]::new()
  $seen = [System.Collections.Generic.HashSet[string]]::new(
    [StringComparer]::OrdinalIgnoreCase
  )
  $section = ''
  $symbolicDefault = $false

  foreach ($line in Get-Content -LiteralPath $Path) {
    if ($line -match '^\s*(?:#.*)?$') {
      continue
    }
    if ($line -notmatch '^\s*\[(?<section>[^]]+)\]\s*(?:#.*)?$') {
      if ($section -eq 'settings' -and
        $line -match '^\s*default_target_type\s*=\s*"symbolic"\s*(?:#.*)?$') {
        $symbolicDefault = $true
        continue
      }
      # Scope cache entries by the first source directory. Keep this invariant explicit.
      if ($section -match '^(?<package>[A-Za-z0-9_.-]+)\.files$') {
        $owner = $Matches.package
        $tomlString = '(?:"(?:[^"\\]|\\.)*"|''[^'']*'')'
        if ($line -match "^\s*(?<source>$tomlString)\s*=\s*$tomlString\s*(?:#.*)?$") {
          $source = $Matches.source.Substring(1, $Matches.source.Length - 2)
          if ($source.StartsWith("$owner/", [StringComparison]::OrdinalIgnoreCase) -and
            $source -notmatch '(?:/|\\)\.\.(?:/|\\|$)') {
            continue
          }
        }
      }
      throw "Unsupported scoped Dotter mapping in '$Path': $line"
    }

    $section = $Matches.section
    if ($section -eq 'settings') {
      continue
    }
    if ($section -notmatch '^(?<package>[A-Za-z0-9_.-]+)\.files$') {
      throw "Unsupported Dotter package section '[$section]' in '$Path'."
    }

    $name = $Matches.package
    if (-not $seen.Add($name)) {
      throw "Duplicate Dotter package '$name' in '$Path'."
    }
    $names.Add($name)
  }

  if ($names.Count -eq 0) {
    throw "No Dotter packages were found in '$Path'."
  }
  if (-not $symbolicDefault) {
    throw 'Scoped Dotter deployment requires default_target_type = "symbolic".'
  }

  return $names.ToArray()
}

function Resolve-PackageNames {
  param(
    [Parameter(Mandatory)][string[]] $KnownNames,
    [Parameter(Mandatory)][AllowEmptyCollection()][string[]] $Names,
    [string] $Source = 'Package selection'
  )

  if ($Names.Count -eq 0) {
    throw "$Source must select at least one package."
  }

  $selected = [System.Collections.Generic.HashSet[string]]::new(
    [StringComparer]::OrdinalIgnoreCase
  )
  foreach ($nameGroup in $Names) {
    if ([string]::IsNullOrWhiteSpace($nameGroup)) {
      throw "$Source contains an empty package name."
    }

    foreach ($name in $nameGroup.Split(',', [StringSplitOptions]::None)) {
      $candidate = $name.Trim()
      if (-not $candidate) {
        throw "$Source contains an empty package name."
      }

      $match = @($KnownNames | Where-Object {
          [StringComparer]::OrdinalIgnoreCase.Equals($_, $candidate)
        })
      if ($match.Count -ne 1) {
        throw "Unknown Dotter package '$candidate'. Available packages: " +
        "$($KnownNames -join ', ')."
      }
      [void] $selected.Add($match[0])
    }
  }

  return @($KnownNames | Where-Object { $selected.Contains($_) })
}

function Read-ProfilePackages {
  param(
    [Parameter(Mandatory)][string] $Path,
    [Parameter(Mandatory)][string[]] $KnownNames
  )

  $content = (Get-Content -LiteralPath $Path -Raw) -replace '(?m)#.*$', ''
  $packageList = [regex]::Match($content, '(?s)\A\s*packages\s*=\s*\[(?<body>.*?)\]\s*\z')
  if (-not $packageList.Success) {
    throw "Profile '$Path' must contain only a packages array."
  }

  $body = $packageList.Groups['body'].Value
  $namePattern = '(?:"[A-Za-z0-9_.-]+"|''[A-Za-z0-9_.-]+'')'
  if ($body -notmatch "\A\s*(?:$namePattern(?:\s*,\s*$namePattern)*\s*,?)?\s*\z") {
    throw "Profile '$Path' contains an invalid package array."
  }
  $packageMatches = [regex]::Matches($body, $namePattern)

  $names = @($packageMatches | ForEach-Object {
      $_.Value.Substring(1, $_.Value.Length - 2)
    })
  return Resolve-PackageNames `
    -KnownNames $KnownNames `
    -Names $names `
    -Source "Profile '$Path'"
}

function Resolve-ProfilePackages {
  param(
    [Parameter(Mandatory)][string] $Name,
    [Parameter(Mandatory)][string] $DotterConfigRoot,
    [Parameter(Mandatory)][string[]] $KnownNames
  )

  if ([string]::IsNullOrWhiteSpace($Name)) {
    throw 'Profile name cannot be empty.'
  }

  $profiles = [ordered]@{}
  $profileNames = [System.Collections.Generic.HashSet[string]]::new(
    [StringComparer]::OrdinalIgnoreCase
  )

  $profileRoot = Join-Path $DotterConfigRoot 'profiles'
  if (Test-Path -LiteralPath $profileRoot -PathType Container) {
    foreach ($file in Get-ChildItem -LiteralPath $profileRoot -Filter '*.toml' -File) {
      if (-not $profileNames.Add($file.BaseName)) {
        throw "Duplicate Dotter profile name '$($file.BaseName)'."
      }
      $profiles[$file.BaseName] = $file.FullName
    }
  }

  $profileName = @($profiles.Keys | Where-Object {
      [StringComparer]::OrdinalIgnoreCase.Equals($_, $Name.Trim())
    })
  if ($profileName.Count -ne 1) {
    throw "Unknown Dotter profile '$Name'. Available profiles: $($profiles.Keys -join ', ')."
  }

  return Read-ProfilePackages `
    -Path $profiles[$profileName[0]] `
    -KnownNames $KnownNames
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

function Read-SymbolicCache {
  param(
    [Parameter(Mandatory)][string] $Path,
    [Parameter(Mandatory)][AllowEmptyCollection()][string[]] $ActivePackages
  )

  $entries = [System.Collections.Generic.List[object]]::new()
  $section = ''
  foreach ($line in Get-Content -LiteralPath $Path) {
    if ($line -match '^\s*(?:#.*)?$') {
      continue
    }
    if ($line -match '^\[(symlinks|templates)\]$') {
      $section = $Matches[1]
      continue
    }
    if ($section -ne 'symlinks' -or
      $line -notmatch '^["''](?<package>[A-Za-z0-9_.-]+)[/\\]') {
      throw "Unsupported Dotter cache entry in '$Path'. Only package-owned symlinks are supported."
    }
    $owner = $Matches.package
    if ($ActivePackages -notcontains $owner) {
      throw "Dotter cache contains an entry for inactive package '$owner'."
    }
    # Preserve Dotter's TOML quoting, including Windows separators, without reserializing paths.
    $entries.Add([pscustomobject]@{ Package = $owner; Line = $line })
  }
  return $entries.ToArray()
}

function New-SymbolicCacheContent {
  param([Parameter(Mandatory)][AllowEmptyCollection()][object[]] $Entries)

  $lines = @('[symlinks]') + @($Entries | ForEach-Object { $_.Line }) + @('', '[templates]', '')
  return $lines -join "`n"
}

function Get-CacheFingerprint {
  param(
    [Parameter(Mandatory)][string] $CacheFile,
    [Parameter(Mandatory)][string] $CacheDirectory
  )

  if (-not (Test-Path -LiteralPath $CacheFile -PathType Leaf)) {
    throw "Dotter cache file is missing: $CacheFile"
  }

  $entries = [System.Collections.Generic.List[string]]::new()
  $cacheHash = (Get-FileHash -LiteralPath $CacheFile -Algorithm SHA256).Hash.ToLowerInvariant()
  $cacheLength = (Get-Item -LiteralPath $CacheFile -Force).Length
  $entries.Add("file:cache.toml:${cacheLength}:$cacheHash")

  $directoryExists = Test-Path -LiteralPath $CacheDirectory -PathType Container
  $entries.Add("directory:cache:$([int] $directoryExists)")
  if ($directoryExists) {
    $relativePaths = [System.Collections.Generic.HashSet[string]]::new(
      [StringComparer]::OrdinalIgnoreCase
    )
    $files = @(Get-ChildItem -LiteralPath $CacheDirectory -File -Force -Recurse |
        Sort-Object FullName)
    foreach ($file in $files) {
      $relativePath = [System.IO.Path]::GetRelativePath(
        $CacheDirectory,
        $file.FullName
      ).Replace('\', '/')
      if (-not $relativePaths.Add($relativePath)) {
        throw "Dotter cache contains duplicate path '$relativePath'."
      }

      $fileHash = (Get-FileHash -LiteralPath $file.FullName -Algorithm SHA256).Hash
      $entries.Add(
        "file:cache/${relativePath}:$($file.Length):$($fileHash.ToLowerInvariant())"
      )
    }
  }

  $payload = [Text.Encoding]::UTF8.GetBytes($entries -join "`n")
  return Get-Sha256Hex -Bytes $payload
}

function Get-UserBatConfig {
  return [Environment]::GetEnvironmentVariable('BAT_CONFIG_PATH', 'User')
}

function Set-UserBatConfig {
  param([AllowNull()][AllowEmptyString()][string] $Value)

  [Environment]::SetEnvironmentVariable('BAT_CONFIG_PATH', $Value, 'User')
}

function Read-ActiveState {
  param(
    [Parameter(Mandatory)][string] $Path,
    [Parameter(Mandatory)][string[]] $KnownNames
  )

  try {
    $state = Get-Content -LiteralPath $Path -Raw | ConvertFrom-Json -AsHashtable
  }
  catch {
    throw "Active Dotter state '$Path' is not valid JSON: $($_.Exception.Message)"
  }
  if ($state -isnot [System.Collections.IDictionary]) {
    throw "Active Dotter state '$Path' must be a JSON object."
  }

  $integralTypes = @([int], [long])
  $versionIsInteger = $false
  foreach ($type in $integralTypes) {
    if ($state.version -is $type) {
      $versionIsInteger = $true
      break
    }
  }
  if (-not $versionIsInteger -or $state.version -ne 2) {
    throw "Active Dotter state '$Path' has an unsupported version."
  }
  if ($state.packages -isnot [System.Collections.IList] -or
    $state.packages -is [string]) {
    throw "Active Dotter state '$Path' has an invalid packages value."
  }
  foreach ($name in $state.packages) {
    if ($name -isnot [string] -or [string]::IsNullOrWhiteSpace($name)) {
      throw "Active Dotter state '$Path' has an invalid package name."
    }
  }
  if ($state.batConfigPathManaged -isnot [bool]) {
    throw "Active Dotter state '$Path' has an invalid BAT_CONFIG_PATH ownership value."
  }
  if ($state.cacheFingerprint -isnot [string] -or
    $state.cacheFingerprint -notmatch '^[0-9a-f]{64}$') {
    throw "Active Dotter state '$Path' has an invalid cache fingerprint."
  }

  $packages = @()
  if ($state.packages.Count) {
    $packages = @(Resolve-PackageNames `
        -KnownNames $KnownNames `
        -Names @($state.packages) `
        -Source 'Active Dotter state')
  }
  if ($packages.Count -ne $state.packages.Count) {
    throw "Active Dotter state '$Path' contains duplicate packages."
  }

  return [pscustomobject]@{
    Packages             = $packages
    BatConfigPathManaged = $state.batConfigPathManaged
    CacheFingerprint     = $state.cacheFingerprint
  }
}

function Save-ActiveState {
  param(
    [Parameter(Mandatory)][string] $Path,
    [Parameter(Mandatory)][AllowEmptyCollection()][string[]] $Packages,
    [Parameter(Mandatory)][bool] $BatConfigPathManaged,
    [Parameter(Mandatory)][string] $CacheFingerprint
  )

  $state = [ordered]@{
    version              = 2
    packages             = @($Packages)
    batConfigPathManaged = $BatConfigPathManaged
    cacheFingerprint     = $CacheFingerprint
  }
  $content = ($state | ConvertTo-Json) + [Environment]::NewLine
  $temporaryPath = "$Path.$([Guid]::NewGuid().ToString('N')).tmp"
  try {
    [System.IO.File]::WriteAllText(
      $temporaryPath,
      $content,
      [Text.UTF8Encoding]::new($false)
    )
    Move-Item -LiteralPath $temporaryPath -Destination $Path -Force -Confirm:$false
  }
  finally {
    if ([System.IO.File]::Exists($temporaryPath)) {
      [System.IO.File]::Delete($temporaryPath)
    }
  }
}

function Enter-DotterMutex {
  param([Parameter(Mandatory)][string] $StateRoot)

  $canonicalRoot = [System.IO.Path]::GetFullPath($StateRoot).ToLowerInvariant()
  $rootBytes = [Text.Encoding]::UTF8.GetBytes($canonicalRoot)
  $rootHash = (Get-Sha256Hex -Bytes $rootBytes).Substring(0, 32)
  $mutex = [Threading.Mutex]::new($false, "Local\dotfiles-dotter-$rootHash")

  try {
    $acquired = $mutex.WaitOne(0)
  }
  catch [Threading.AbandonedMutexException] {
    $acquired = $true
  }
  if (-not $acquired) {
    $mutex.Dispose()
    throw 'Another Dotter wrapper process is already using this machine state.'
  }

  return $mutex
}

function Get-DotterCommand {
  $dotter = Get-Command dotter -CommandType Application -ErrorAction SilentlyContinue |
    Select-Object -First 1
  if ($null -eq $dotter) {
    throw 'Dotter is not installed. Run setup\scoop.ps1, reopen the terminal, and retry.'
  }

  $command = $dotter.Path
  $global:LASTEXITCODE = 0
  $output = @(& $command --version 2>&1)
  $exitCode = $LASTEXITCODE
  $versionText = ($output | ForEach-Object { $_.ToString() }) -join "`n"
  if ($exitCode -ne 0 -or
    $versionText -notmatch '(?m)^dotter\s+(?<major>\d+)\.(?<minor>\d+)\.(?<patch>\d+)') {
    throw "Could not determine the Dotter version from '$command'."
  }

  $version = [version]::new(
    [int] $Matches.major,
    [int] $Matches.minor,
    [int] $Matches.patch
  )
  if ($version -lt [version] '0.13.5') {
    throw "Dotter 0.13.5 or newer is required; found $version."
  }

  return $command
}

function Invoke-Dotter {
  param(
    [Parameter(Mandatory)][string] $Command,
    [Parameter(Mandatory)][string[]] $CommonArguments,
    [Parameter(Mandatory)][string] $DisplayOperation,
    [ValidateSet('deploy', 'undeploy')][string] $NativeAction = 'deploy',
    [switch] $DryRun,
    [switch] $QuietOutput
  )

  $arguments = @($CommonArguments)
  if ($DryRun) {
    $arguments += '--dry-run'
  }
  else {
    $arguments += '--noconfirm'
  }
  $arguments += $NativeAction

  # Dotter 0.13.5 unconditionally removes this path before probing Windows symlink support.
  if ($NativeAction -eq 'deploy' -and
    $null -ne (Get-Item -LiteralPath 'DOTTER_SYMLINK_TEST' -Force -ErrorAction SilentlyContinue)) {
    throw 'Dotter symlink probe path already exists: DOTTER_SYMLINK_TEST. Move it before retrying.'
  }
  $global:LASTEXITCODE = 0
  $nativeOutput = @(& $Command @arguments 2>&1)
  $exitCode = $LASTEXITCODE
  $output = @($nativeOutput | ForEach-Object { $_.ToString() })
  if (-not $QuietOutput) {
    foreach ($line in $output) {
      Write-Host $line
    }
  }

  if ($exitCode -ne 0) {
    $mode = if ($DryRun) { 'dry-run' } else { $DisplayOperation.ToLowerInvariant() }
    throw "Dotter $mode failed with exit code $exitCode."
  }

  return [pscustomobject]@{
    Output = $output
    Text   = $output -join [Environment]::NewLine
  }
}

function Assert-NoSkippedTargets {
  param(
    [Parameter(Mandatory)] $Result,
    [Parameter(Mandatory)][string] $Phase
  )

  $warningLine = '(?im)^\[\s*(?:WARN|ERROR)\s*\].*'
  $skipPattern = "$warningLine\bSkipping\.?\s*$|" +
  "$warningLine\btarget (?:file|directory) already exists"
  if ($Result.Text -match $skipPattern) {
    throw "Dotter $Phase found a conflicting target and refused to replace it."
  }
  if ($Result.Text -match '(?im)copying instead of symlinking|^\[.*\]\s+\[[+~-]\]\s+template\b') {
    throw "Dotter $Phase would copy files. Symbolic links are required; enable Developer Mode."
  }
}

function Assert-SymbolicLinksAvailable {
  $testDirectory = Join-Path (
    [System.IO.Path]::GetTempPath()
  ) "dotter-symlink-$([Guid]::NewGuid().ToString('N'))"
  $linkKind = 'file'

  try {
    New-Item -ItemType Directory -Path $testDirectory -Confirm:$false | Out-Null
    $sourceFile = Join-Path $testDirectory 'source.txt'
    New-Item -ItemType File -Path $sourceFile -Confirm:$false | Out-Null
    New-Item `
      -ItemType SymbolicLink `
      -Path (Join-Path $testDirectory 'file-link.txt') `
      -Confirm:$false `
      -Target $sourceFile | Out-Null

    $linkKind = 'directory'
    $sourceDirectory = Join-Path $testDirectory 'source-directory'
    New-Item -ItemType Directory -Path $sourceDirectory -Confirm:$false | Out-Null
    New-Item `
      -ItemType SymbolicLink `
      -Path (Join-Path $testDirectory 'directory-link') `
      -Confirm:$false `
      -Target $sourceDirectory | Out-Null
  }
  catch {
    $message = "Windows could not create a $linkKind symlink. Enable Developer Mode " +
    'or grant the current user symlink permission before deploying; copying is not ' +
    "allowed. Original error: $($_.Exception.Message)"
    throw [InvalidOperationException]::new($message, $_.Exception)
  }
  finally {
    if ([System.IO.Directory]::Exists($testDirectory)) {
      [System.IO.Directory]::Delete($testDirectory, $true)
    }
  }
}

function Assert-InvocationArguments {
  param(
    [Parameter(Mandatory)][string] $RequestedAction,
    [Parameter(Mandatory)][bool] $PackageSpecified,
    [AllowNull()][AllowEmptyCollection()][AllowEmptyString()][string[]] $PackageNames,
    [Parameter(Mandatory)][bool] $ProfileSpecified,
    [AllowNull()][AllowEmptyString()][string] $ProfileName,
    [Parameter(Mandatory)][bool] $ReplaceSelection,
    [Parameter(Mandatory)][bool] $RemoveAll
  )

  if ($PackageSpecified -and $ProfileSpecified) {
    throw 'Use either -Package or -Profile, not both.'
  }
  if ($PackageSpecified) {
    if ($null -eq $PackageNames -or @($PackageNames).Count -eq 0) {
      throw 'Package selection must select at least one package.'
    }
    foreach ($nameGroup in @($PackageNames)) {
      if ([string]::IsNullOrWhiteSpace($nameGroup)) {
        throw 'Package selection contains an empty package name.'
      }
    }
  }
  if ($ProfileSpecified -and [string]::IsNullOrWhiteSpace($ProfileName)) {
    throw 'Profile name cannot be empty.'
  }
  if ($RemoveAll -and ($PackageSpecified -or $ProfileSpecified -or $ReplaceSelection)) {
    throw '-All cannot be combined with -Package, -Profile, or -Replace.'
  }
  if ($RemoveAll -and $RequestedAction -ne 'Undeploy') {
    throw '-All is valid only with -Action Undeploy.'
  }
  if ($ReplaceSelection -and $RequestedAction -ne 'Deploy') {
    throw '-Replace is valid only with -Action Deploy.'
  }
  if ($RequestedAction -ne 'Deploy' -and -not $RemoveAll -and
    -not $PackageSpecified -and -not $ProfileSpecified) {
    throw "$RequestedAction requires -Package or -Profile. " +
    'Use -All for complete undeployment.'
  }
}

function Get-DesiredPackages {
  param(
    [Parameter(Mandatory)][string[]] $KnownPackages,
    [Parameter(Mandatory)][AllowEmptyCollection()][string[]] $CurrentPackages,
    [Parameter(Mandatory)][AllowEmptyCollection()][string[]] $SelectedPackages,
    [Parameter(Mandatory)][string] $RequestedAction,
    [Parameter(Mandatory)][bool] $ReplaceSelection,
    [Parameter(Mandatory)][bool] $RemoveAll
  )

  if ($RemoveAll) {
    return @()
  }
  if ($ReplaceSelection) {
    return @($SelectedPackages)
  }
  if ($RequestedAction -in 'Deploy', 'Restow') {
    $desired = [System.Collections.Generic.HashSet[string]]::new(
      [StringComparer]::OrdinalIgnoreCase
    )
    foreach ($name in @($CurrentPackages + $SelectedPackages)) {
      [void] $desired.Add($name)
    }
    return @($KnownPackages | Where-Object { $desired.Contains($_) })
  }

  $removed = [System.Collections.Generic.HashSet[string]]::new(
    [StringComparer]::OrdinalIgnoreCase
  )
  foreach ($name in $SelectedPackages) {
    [void] $removed.Add($name)
  }
  return @($CurrentPackages | Where-Object { -not $removed.Contains($_) })
}

function Main {
  if ($Help) {
    Show-DotterHelp
    return
  }

  if ($env:OS -ne 'Windows_NT') {
    throw 'This setup script only supports Windows.'
  }
  if (-not $env:LOCALAPPDATA -or -not $env:APPDATA) {
    throw 'LOCALAPPDATA and APPDATA must be set.'
  }

  $packageSpecified = $script:PackageSpecified
  $profileSpecified = $script:ProfileSpecified
  Assert-InvocationArguments `
    -RequestedAction $Action `
    -PackageSpecified $packageSpecified `
    -PackageNames $Package `
    -ProfileSpecified $profileSpecified `
    -ProfileName $SelectedProfile `
    -ReplaceSelection $Replace `
    -RemoveAll $All

  $dotfilesRoot = [System.IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..'))
  $dotterConfigRoot = Join-Path $dotfilesRoot 'windows\dotter'
  $globalConfig = Join-Path $dotterConfigRoot 'global.toml'
  if (-not (Test-Path -LiteralPath $globalConfig -PathType Leaf)) {
    throw "Dotter configuration is missing: $globalConfig"
  }
  $knownPackages = @(Get-GlobalPackageNames -Path $globalConfig)

  $selectedPackages = @()
  if (-not $All) {
    if ($packageSpecified) {
      $selectedPackages = @(Resolve-PackageNames `
          -KnownNames $knownPackages `
          -Names @($Package))
    }
    else {
      $profileName = if ($profileSpecified) { $SelectedProfile } else { 'all' }
      $selectedPackages = @(Resolve-ProfilePackages `
          -Name $profileName `
          -DotterConfigRoot $dotterConfigRoot `
          -KnownNames $knownPackages)
    }
  }

  $stateRoot = Join-Path $env:LOCALAPPDATA 'dotfiles\dotter'
  $stateFile = Join-Path $stateRoot 'active-packages.json'
  $cacheFile = Join-Path $stateRoot 'cache.toml'
  $cacheDirectory = Join-Path $stateRoot 'cache'
  $mutex = Enter-DotterMutex -StateRoot $stateRoot
  $temporaryRoot = $null

  try {
    $dotterCommand = Get-DotterCommand
    if (Test-Path -LiteralPath $stateFile -PathType Leaf) {
      $activeState = Read-ActiveState `
        -Path $stateFile `
        -KnownNames $knownPackages
      $currentFingerprint = Get-CacheFingerprint `
        -CacheFile $cacheFile `
        -CacheDirectory $cacheDirectory
      if ($currentFingerprint -ne $activeState.CacheFingerprint) {
        throw 'Dotter cache data changed outside the wrapper. Restore the cache and ' +
        'state together before retrying.'
      }
      $currentPackages = @($activeState.Packages)
      $batConfigPathManaged = $activeState.BatConfigPathManaged
    }
    else {
      $orphanedCache = (Test-Path -LiteralPath $cacheFile) -or
      (Test-Path -LiteralPath $cacheDirectory)
      if ($orphanedCache) {
        throw 'Dotter cache data exists without active state. Restore or remove the ' +
        'orphaned cache before using this wrapper.'
      }
      $currentPackages = @()
      $batConfigPathManaged = $false
    }
    $cacheEntries = @()
    if (Test-Path -LiteralPath $cacheFile -PathType Leaf) {
      $cacheEntries = @(Read-SymbolicCache -Path $cacheFile -ActivePackages $currentPackages)
    }

    $desiredPackages = @(Get-DesiredPackages `
        -KnownPackages $knownPackages `
        -CurrentPackages $currentPackages `
        -SelectedPackages $selectedPackages `
        -RequestedAction $Action `
        -ReplaceSelection $Replace `
        -RemoveAll $All)

    $scopePackages = @($selectedPackages)
    if ($Replace -or $All) {
      $scopePackages = @($knownPackages | Where-Object {
          $_ -in $currentPackages -or $_ -in $selectedPackages
        })
    }
    $scopedEntries = @($cacheEntries | Where-Object { $_.Package -in $scopePackages })
    $preservedEntries = @($cacheEntries | Where-Object { $_.Package -notin $scopePackages })
    $operationPackages = @($selectedPackages)
    if ($Action -eq 'Undeploy') {
      $operationPackages = @()
    }
    $nativeAction = if ($Action -eq 'Undeploy') { 'undeploy' } else { 'deploy' }

    $batConfigPath = Join-Path $env:APPDATA 'bat\config'
    $batAffected = $scopePackages -contains 'bat'
    $userBatConfig = if ($batAffected) {
      Get-UserBatConfig
    }
    else { $null }
    $batSelected = $desiredPackages -contains 'bat'
    if ($batAffected -and $batSelected -and $userBatConfig -and
      -not (Test-SamePath -Left $userBatConfig -Right $batConfigPath)) {
      throw "User BAT_CONFIG_PATH already points to '$userBatConfig', not '$batConfigPath'."
    }

    $temporaryRoot = Join-Path (
      [System.IO.Path]::GetTempPath()
    ) "dotter-operation-$([Guid]::NewGuid().ToString('N'))"
    [System.IO.Directory]::CreateDirectory($temporaryRoot) | Out-Null
    $temporaryConfig = Join-Path $temporaryRoot 'local.toml'
    $temporaryCache = Join-Path $temporaryRoot 'cache.toml'
    [System.IO.File]::WriteAllText(
      $temporaryConfig,
      (New-LocalConfigContent -Packages @($operationPackages)),
      [Text.UTF8Encoding]::new($false)
    )
    [System.IO.File]::WriteAllText(
      $temporaryCache,
      (New-SymbolicCacheContent -Entries $scopedEntries),
      [Text.UTF8Encoding]::new($false)
    )

    $commonArguments = @(
      '--global-config', $globalConfig,
      '--local-config', $temporaryConfig,
      '--cache-file', $temporaryCache,
      '--cache-directory', (Join-Path $temporaryRoot 'cache'),
      '--pre-deploy', (Join-Path $temporaryRoot 'no-hook'),
      '--post-deploy', (Join-Path $temporaryRoot 'no-hook'),
      '--pre-undeploy', (Join-Path $temporaryRoot 'no-hook'),
      '--post-undeploy', (Join-Path $temporaryRoot 'no-hook')
    )

    Push-Location $dotfilesRoot
    try {
      $displayPackages = if ($scopePackages.Count) {
        $scopePackages -join ', '
      }
      else {
        '(none)'
      }
      Write-Info "Previewing Dotter $($Action.ToLowerInvariant()) for: $displayPackages."
      $preview = Invoke-Dotter `
        -Command $dotterCommand `
        -CommonArguments $commonArguments `
        -DisplayOperation $Action `
        -NativeAction $nativeAction `
        -DryRun
      Assert-NoSkippedTargets -Result $preview -Phase 'preview'

      if ($WhatIfPreference) {
        if ($batAffected -and $batSelected -and -not $userBatConfig) {
          Write-Info "Would set user BAT_CONFIG_PATH to '$batConfigPath'."
        }
        elseif ($batAffected -and -not $batSelected -and $batConfigPathManaged -and
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

      if ($nativeAction -eq 'deploy' -and $operationPackages.Count) {
        Assert-SymbolicLinksAvailable
      }

      New-Item -ItemType Directory -Path $stateRoot -Force -Confirm:$false | Out-Null
      Write-Info "Running Dotter $($Action.ToLowerInvariant())."
      $deployment = Invoke-Dotter `
        -Command $dotterCommand `
        -CommonArguments $commonArguments `
        -DisplayOperation $Action `
        -NativeAction $nativeAction
      Assert-NoSkippedTargets -Result $deployment -Phase $Action.ToLowerInvariant()

      $verification = Invoke-Dotter `
        -Command $dotterCommand `
        -CommonArguments $commonArguments `
        -DisplayOperation 'verification' `
        -NativeAction $nativeAction `
        -DryRun `
        -QuietOutput
      if ($verification.Output.Count -ne 0) {
        foreach ($line in $verification.Output) {
          Write-Host $line
        }
        throw 'Dotter did not converge; active state was not saved.'
      }

      $resultEntries = @(Read-SymbolicCache `
          -Path $temporaryCache `
          -ActivePackages @($operationPackages))
      $originalUserBatConfig = $userBatConfig
      $environmentChanged = $false
      $cacheCommitted = $false
      $stagedCacheFile = "$cacheFile.$([Guid]::NewGuid().ToString('N')).tmp"
      $previousCache = if (Test-Path -LiteralPath $cacheFile -PathType Leaf) {
        [System.IO.File]::ReadAllBytes($cacheFile)
      }
      else { $null }
      try {
        if ($batAffected -and $batSelected -and -not $userBatConfig) {
          Set-UserBatConfig -Value $batConfigPath
          $batConfigPathManaged = $true
          $environmentChanged = $true
          Write-Info "Set user BAT_CONFIG_PATH to '$batConfigPath'."
        }
        elseif ($batAffected -and -not $batSelected) {
          if ($batConfigPathManaged -and $userBatConfig -and
            (Test-SamePath -Left $userBatConfig -Right $batConfigPath)) {
            Set-UserBatConfig -Value $null
            $environmentChanged = $true
            Write-Info 'Removed the managed user BAT_CONFIG_PATH.'
          }
          $batConfigPathManaged = $false
        }

        [System.IO.File]::WriteAllText(
          $temporaryCache,
          (New-SymbolicCacheContent -Entries @($preservedEntries + $resultEntries)),
          [Text.UTF8Encoding]::new($false)
        )
        Copy-Item -LiteralPath $temporaryCache -Destination $stagedCacheFile -Confirm:$false
        Move-Item -LiteralPath $stagedCacheFile -Destination $cacheFile -Force -Confirm:$false
        $cacheCommitted = $true
        $newFingerprint = Get-CacheFingerprint `
          -CacheFile $cacheFile `
          -CacheDirectory $cacheDirectory
        Save-ActiveState `
          -Path $stateFile `
          -Packages $desiredPackages `
          -BatConfigPathManaged $batConfigPathManaged `
          -CacheFingerprint $newFingerprint
      }
      catch {
        if ($cacheCommitted) {
          try {
            if ($null -ne $previousCache) {
              [System.IO.File]::WriteAllBytes($cacheFile, $previousCache)
            }
            else {
              [System.IO.File]::Delete($cacheFile)
            }
          }
          catch {
            Write-Warning 'Could not restore the Dotter cache after state-save failure.'
          }
        }
        if ($environmentChanged) {
          try {
            Set-UserBatConfig -Value $originalUserBatConfig
          }
          catch {
            Write-Warning 'Could not restore BAT_CONFIG_PATH after state-save failure.'
          }
        }
        throw
      }
      finally {
        if ([System.IO.File]::Exists($stagedCacheFile)) {
          [System.IO.File]::Delete($stagedCacheFile)
        }
      }
    }
    finally {
      Pop-Location
    }
  }
  finally {
    try {
      if ($temporaryRoot -and [System.IO.Directory]::Exists($temporaryRoot)) {
        [System.IO.Directory]::Delete($temporaryRoot, $true)
      }
    }
    finally {
      $mutex.ReleaseMutex()
      $mutex.Dispose()
    }
  }

  Write-Info 'Deployment state saved.'
  if ($environmentChanged) {
    Write-Info 'Reopen the terminal to pick up the BAT_CONFIG_PATH change.'
  }
}

Main

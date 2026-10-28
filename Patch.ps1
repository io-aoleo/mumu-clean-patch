[CmdletBinding()]
param(
    [ValidateSet('Apply','Restore','Check')][string]$Mode = 'Check',
    [string]$InstallPath,
    [string]$DataPath = (Join-Path $env:APPDATA 'Netease\MuMuPlayer\data'),
    [switch]$SkipAndroid
)
$ErrorActionPreference = 'Stop'
$ExpectedVersion = '6.8.8.0'
if (-not $InstallPath) {
    $keys = @('HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*',
        'HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*',
        'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*')
    $locations = @(Get-ItemProperty $keys -ErrorAction SilentlyContinue |
        Where-Object { $_.DisplayName -match 'MuMu' -and $_.InstallLocation } |
        Select-Object -ExpandProperty InstallLocation -Unique)
    if ($locations.Count -ne 1) { throw 'Specify one MuMu installation using -InstallPath.' }
    $InstallPath = $locations[0]
}
$InstallPath = (Resolve-Path -LiteralPath $InstallPath).Path.TrimEnd('\')
if (-not (Test-Path -LiteralPath $DataPath -PathType Container)) { throw 'MuMu data directory was not found.' }
$DataPath = (Resolve-Path -LiteralPath $DataPath).Path.TrimEnd('\')
foreach ($root in @($InstallPath, $DataPath)) {
    if ((Get-Item -LiteralPath $root).Attributes -band [IO.FileAttributes]::ReparsePoint) {
        throw 'Linked directories are not supported.'
    }
}
$configPath = Join-Path $InstallPath 'configs\main\install_config.json'
$version = (Get-Content -LiteralPath $configPath -Raw -Encoding UTF8 | ConvertFrom-Json).product.version
Write-Host "MuMu version: $version / Patch version: 1.0.1 / Mode: $Mode"
if ($Mode -eq 'Apply' -and $version -ne $ExpectedVersion) {
    throw "Unsupported version. This patch supports $ExpectedVersion only."
}
$updater = Join-Path $InstallPath 'nx_main\MuMuNxUpdater.exe'
$targets = @(
    @{ Path = (Join-Path $DataPath 'startupImage'); Type = 'Directory'; Legacy = '.disabled-20261028' },
    @{ Path = (Join-Path $DataPath 'ProgramAds'); Type = 'Directory'; Legacy = '.disabled-20261028' },
    @{ Path = $updater; Type = 'File'; Legacy = '.disabled-20261028' }
)
function Assert-PlainPath([string]$Path) {
    if (Test-Path -LiteralPath $Path) {
        if ((Get-Item -LiteralPath $Path -Force).Attributes -band [IO.FileAttributes]::ReparsePoint) {
            throw "Linked path refused: $Path"
        }
    }
}
function Get-BackupPath($Target) {
    $standard = $Target.Path + '.mumu-clean-backup'
    $legacy = $Target.Path + $Target.Legacy
    if ((Test-Path -LiteralPath $standard) -and (Test-Path -LiteralPath $legacy)) {
        throw "Multiple backups found: $($Target.Path)"
    }
    if (Test-Path -LiteralPath $legacy) { return $legacy }
    return $standard
}
function Assert-Placeholder([string]$Path) {
    Assert-PlainPath $Path
    $item = Get-Item -LiteralPath $Path -Force
    if ($item.PSIsContainer -or $item.Length -ne 0) { throw "Unexpected contents; left untouched: $Path" }
}
# Validate all targets before making changes. Never overwrite an existing backup.
foreach ($target in $targets) {
    Assert-PlainPath (Split-Path -Parent $target.Path)
    Assert-PlainPath $target.Path
    $backup = Get-BackupPath $target
    Assert-PlainPath $backup
    if (Test-Path -LiteralPath $backup) {
        $saved = Get-Item -LiteralPath $backup -Force
        if (($target.Type -eq 'Directory') -ne $saved.PSIsContainer) { throw "Wrong backup type: $backup" }
        if ($Mode -in @('Apply','Restore') -and (Test-Path -LiteralPath $target.Path)) { Assert-Placeholder $target.Path }
    } elseif ($Mode -eq 'Apply' -and (Test-Path -LiteralPath $target.Path)) {
        $original = Get-Item -LiteralPath $target.Path -Force
        if (($target.Type -eq 'Directory') -ne $original.PSIsContainer) { throw "Wrong target type: $($target.Path)" }
    } elseif ($Mode -eq 'Apply' -and $target.Type -eq 'File') {
        throw "Updater missing and no backup found: $($target.Path)"
    }
}
if ($Mode -ne 'Check' -and (Get-Process -Name MuMuNxUpdater -ErrorAction SilentlyContinue)) {
    throw 'Close the MuMu updater before applying or restoring this patch.'
}
foreach ($target in $targets) {
    $path = $target.Path
    $backup = Get-BackupPath $target
    if ($Mode -eq 'Apply') {
        if (-not (Test-Path -LiteralPath $backup) -and (Test-Path -LiteralPath $path)) {
            Rename-Item -LiteralPath $path -NewName (Split-Path -Leaf $backup)
        }
        # A file at the former directory path prevents advertisement downloads there.
        # A zero-byte updater placeholder cannot execute. The original executable is retained.
        if (-not (Test-Path -LiteralPath $path)) { [IO.File]::WriteAllText($path, '') }
        (Get-Item -LiteralPath $path -Force).IsReadOnly = $true
    } elseif ($Mode -eq 'Restore') {
        if (Test-Path -LiteralPath $backup) {
            if (Test-Path -LiteralPath $path) {
                Assert-Placeholder $path
                (Get-Item -LiteralPath $path -Force).IsReadOnly = $false
                Remove-Item -LiteralPath $path
            }
            Rename-Item -LiteralPath $backup -NewName (Split-Path -Leaf $path)
        } elseif (Test-Path -LiteralPath $path -PathType Leaf) {
            # Advertisement paths that originally did not exist have no backup.
            if ($target.Type -eq 'Directory') {
                Assert-Placeholder $path
                (Get-Item -LiteralPath $path -Force).IsReadOnly = $false
                Remove-Item -LiteralPath $path
            }
        }
    }
    $item = Get-Item -LiteralPath $path -Force -ErrorAction SilentlyContinue
    $blocked = $item -and (-not $item.PSIsContainer) -and $item.Length -eq 0 -and $item.IsReadOnly
    Write-Host "$(Split-Path -Leaf $path): blocked=$([bool]$blocked); backup=$(Test-Path -LiteralPath $backup)"
    if ($Mode -eq 'Apply' -and -not $blocked) { throw "Verification failed: $path" }
}
# Keep the application center enabled: its download/install functions are shared.
$adb = Join-Path $InstallPath 'nx_main\adb.exe'
$cli = Join-Path $InstallPath 'nx_main\mumu-cli.exe'
if (-not $SkipAndroid -and (Test-Path -LiteralPath $adb) -and (Test-Path -LiteralPath $cli)) {
    try {
        [Console]::OutputEncoding = New-Object System.Text.UTF8Encoding($false)
        $devices = @((& $cli info --vmindex all | Out-String | ConvertFrom-Json))
        if ($devices.Count -eq 1 -and -not $devices[0].adb_port) {
            $devices = @($devices[0].PSObject.Properties | ForEach-Object { $_.Value })
        }
        $running = @($devices | Where-Object { $_.is_android_started -and $_.adb_port })
        if (-not $running.Count) { Write-Warning 'Start Android, then run Apply again to restore its download center.' }
        foreach ($device in $running) {
            $serial = '127.0.0.1:' + [int]$device.adb_port
            & $adb connect $serial | Out-Null
            if ($LASTEXITCODE -ne 0) { throw "ADB connection failed: $serial" }
            $androidHome = (& $adb -s $serial shell cmd package resolve-activity --brief -a android.intent.action.MAIN -c android.intent.category.HOME | Out-String).Trim()
            if ($Mode -in @('Apply','Restore')) {
                & $adb -s $serial shell pm default-state --user 0 com.mumu.store
            }
            if ($LASTEXITCODE -ne 0) { throw "Android operation failed: $serial" }
            Write-Host "Android $serial default HOME: $androidHome"
            Write-Host 'Enabled application center (required for downloads):'
            & $adb -s $serial shell pm list packages -e com.mumu.store
        }
    } catch {
        Write-Warning "PC patch completed; Android step needs attention: $_"
    }
}
Write-Host 'Done. Restart MuMu to clear advertisements already loaded in memory.'

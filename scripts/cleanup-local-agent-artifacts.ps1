[CmdletBinding()]
param(
    [string]$TargetRepo,
    [string]$OutputPath,
    [switch]$Apply,
    [switch]$AsJson,
    [switch]$IncludeRuntimeOutput,
    [switch]$IncludeGeneratedSamples,
    [switch]$IncludeBackups,
    [switch]$IncludeFailedReports
)

$ErrorActionPreference = "Stop"

$repoRoot = Split-Path -Parent $PSScriptRoot
if (-not $TargetRepo) {
    $TargetRepo = $repoRoot
}

if (-not ($IncludeRuntimeOutput -or $IncludeGeneratedSamples -or $IncludeBackups -or $IncludeFailedReports)) {
    $IncludeRuntimeOutput = $true
    $IncludeGeneratedSamples = $true
    $IncludeBackups = $true
    $IncludeFailedReports = $true
}

function Resolve-RequiredPath {
    param([string]$Path)

    $resolved = Resolve-Path -LiteralPath $Path -ErrorAction SilentlyContinue
    if (-not $resolved) {
        throw "Target repository path does not exist: $Path"
    }

    return $resolved.Path
}

function Test-IsUnderRoot {
    param(
        [string]$Root,
        [string]$Path
    )

    $rootFull = [System.IO.Path]::GetFullPath($Root).TrimEnd([System.IO.Path]::DirectorySeparatorChar, [System.IO.Path]::AltDirectorySeparatorChar)
    $pathFull = [System.IO.Path]::GetFullPath($Path).TrimEnd([System.IO.Path]::DirectorySeparatorChar, [System.IO.Path]::AltDirectorySeparatorChar)
    return ($pathFull -eq $rootFull) -or $pathFull.StartsWith("$rootFull$([System.IO.Path]::DirectorySeparatorChar)", [System.StringComparison]::OrdinalIgnoreCase) -or $pathFull.StartsWith("$rootFull$([System.IO.Path]::AltDirectorySeparatorChar)", [System.StringComparison]::OrdinalIgnoreCase)
}

function New-CleanupItem {
    param(
        [string]$Category,
        [string]$Path,
        [string]$Reason
    )

    if (-not (Test-Path -LiteralPath $Path)) {
        return $null
    }

    $item = Get-Item -LiteralPath $Path -Force
    $fileCount = if ($item.PSIsContainer) {
        @(Get-ChildItem -LiteralPath $item.FullName -Recurse -File -Force -ErrorAction SilentlyContinue).Count
    } else {
        1
    }

    return [pscustomobject]@{
        Category = $Category
        Path = Resolve-Path -LiteralPath $item.FullName -Relative
        FullPath = $item.FullName
        Type = if ($item.PSIsContainer) { "directory" } else { "file" }
        FileCount = $fileCount
        Reason = $Reason
        Removed = $false
    }
}

function Add-CleanupItem {
    param(
        [System.Collections.Generic.List[object]]$Items,
        [string]$Category,
        [string]$Path,
        [string]$Reason
    )

    $item = New-CleanupItem -Category $Category -Path $Path -Reason $Reason
    if ($item) {
        [void]$Items.Add($item)
    }
}

$targetRoot = Resolve-RequiredPath -Path $TargetRepo
$items = [System.Collections.Generic.List[object]]::new()

if ($IncludeRuntimeOutput) {
    Add-CleanupItem -Items $items -Category "runtime-output" -Path (Join-Path $targetRoot "runtime-validation-output") -Reason "Ignored runtime validation output can be regenerated."
}

if ($IncludeGeneratedSamples -and -not $IncludeRuntimeOutput) {
    Add-CleanupItem -Items $items -Category "generated-samples" -Path (Join-Path $targetRoot "runtime-validation-output/sample-repositories") -Reason "Generated sample repositories are disposable validation fixtures."
}

if ($IncludeBackups) {
    $backupDirs = @(Get-ChildItem -LiteralPath $targetRoot -Force -Directory -Filter ".continue.backup-*" -ErrorAction SilentlyContinue)
    foreach ($backupDir in $backupDirs) {
        Add-CleanupItem -Items $items -Category "backup" -Path $backupDir.FullName -Reason "Installer backup folder can be removed after review."
    }

    $backupFiles = @(Get-ChildItem -LiteralPath $targetRoot -Force -File -Filter "*.backup-*" -ErrorAction SilentlyContinue)
    foreach ($backupFile in $backupFiles) {
        Add-CleanupItem -Items $items -Category "backup" -Path $backupFile.FullName -Reason "Generated config backup file can be removed after review."
    }
}

if ($IncludeFailedReports -and -not $IncludeRuntimeOutput) {
    $runtimeRoot = Join-Path $targetRoot "runtime-validation-output"
    if (Test-Path -LiteralPath $runtimeRoot) {
        $failedReports = @(Get-ChildItem -LiteralPath $runtimeRoot -Recurse -File -Force -Include "*failed*", "*.filename-fidelity-fallback.md" -ErrorAction SilentlyContinue)
        foreach ($failedReport in $failedReports) {
            Add-CleanupItem -Items $items -Category "failed-report" -Path $failedReport.FullName -Reason "Failed validation artifact is local diagnostic output."
        }
    }
}

$deduped = @($items | Group-Object FullPath | ForEach-Object { $_.Group | Select-Object -First 1 })

if ($Apply) {
    foreach ($item in $deduped) {
        if (-not (Test-IsUnderRoot -Root $targetRoot -Path $item.FullPath)) {
            throw "Refusing to remove path outside target repository: $($item.FullPath)"
        }

        if ($item.FullPath -eq $targetRoot) {
            throw "Refusing to remove target repository root."
        }

        Remove-Item -LiteralPath $item.FullPath -Recurse -Force
        $item.Removed = $true
    }
}

$report = [pscustomobject]@{
    SchemaVersion = 1
    GeneratedAtUtc = (Get-Date).ToUniversalTime().ToString("o")
    TargetRepoChecked = $true
    Applied = [bool]$Apply
    ItemCount = $deduped.Count
    Items = $deduped | Select-Object Category, Path, Type, FileCount, Reason, Removed
}

if ($OutputPath) {
    $parent = Split-Path -Parent $OutputPath
    if ($parent) {
        New-Item -ItemType Directory -Force -Path $parent | Out-Null
    }
    $report | ConvertTo-Json -Depth 10 | Set-Content -LiteralPath $OutputPath -Encoding utf8
}

if ($AsJson -or $OutputPath) {
    $report | ConvertTo-Json -Depth 10
} else {
    if ($Apply) {
        Write-Host "Cleanup applied. Removed $($deduped.Count) item(s)."
    } else {
        Write-Host "Dry run only. Would remove $($deduped.Count) item(s). Use -Apply to remove planned items."
    }

    foreach ($item in $deduped) {
        Write-Host "$($item.Category): $($item.Path) ($($item.Type), $($item.FileCount) file(s))"
    }
}

exit 0

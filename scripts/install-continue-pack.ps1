param(
    [string]$TargetRepo,
    [Alias("target-repo")]
    [string]$TargetRepoAlias,
    [switch]$DryRun,
    [Alias("dry-run")]
    [switch]$DryRunAlias
)

$ErrorActionPreference = "Stop"

$repoRoot = Split-Path -Parent $PSScriptRoot
$sourceContinue = Join-Path $repoRoot ".continue"

if (-not $TargetRepo -and $TargetRepoAlias) {
    $TargetRepo = $TargetRepoAlias
}

if ($DryRunAlias) {
    $DryRun = $true
}

if (-not $TargetRepo) {
    throw "TargetRepo is required. Use -TargetRepo <path> or --target-repo <path>."
}

if (-not (Test-Path -LiteralPath $sourceContinue)) {
    throw "Source .continue folder does not exist: $sourceContinue"
}

if (-not (Test-Path -LiteralPath $TargetRepo)) {
    throw "Target repository path does not exist: $TargetRepo"
}

$repoRootResolved = (Resolve-Path -LiteralPath $repoRoot).Path
$targetResolved = (Resolve-Path -LiteralPath $TargetRepo).Path

if ($repoRootResolved.TrimEnd('\', '/') -eq $targetResolved.TrimEnd('\', '/')) {
    throw "Target repository must be different from this pack repository."
}

$targetContinue = Join-Path $targetResolved ".continue"
$timestamp = Get-Date -Format "yyyyMMdd-HHmmss"
$backupContinue = Join-Path $targetResolved ".continue.backup-$timestamp"

function Write-Plan {
    param([string]$Message)
    Write-Host $Message -ForegroundColor Cyan
}

function Get-PackFiles {
    Get-ChildItem -LiteralPath $sourceContinue -Recurse -File -Force |
        Where-Object {
            $relative = [System.IO.Path]::GetRelativePath($sourceContinue, $_.FullName).Replace('\', '/')
            $relative -notmatch "^config\.local.*\.ya?ml$"
        }
}

function Copy-PackFiles {
    foreach ($file in Get-PackFiles) {
        $relative = [System.IO.Path]::GetRelativePath($sourceContinue, $file.FullName)
        $destination = Join-Path $targetContinue $relative
        $destinationDirectory = Split-Path -Parent $destination

        if (-not (Test-Path -LiteralPath $destinationDirectory)) {
            New-Item -ItemType Directory -Force -Path $destinationDirectory | Out-Null
        }

        Copy-Item -LiteralPath $file.FullName -Destination $destination -Force
    }
}

function Test-InstalledPack {
    $configPath = Join-Path $targetContinue "config.yaml"

    if (-not (Test-Path -LiteralPath $configPath)) {
        throw "Installed config is missing: $configPath"
    }

    $config = Get-Content -LiteralPath $configPath -Raw
    $fileRefs = [regex]::Matches($config, "file://\.\/([^`r`n]+)") | ForEach-Object {
        $_.Groups[1].Value.Trim()
    }

    foreach ($ref in $fileRefs) {
        if ([System.IO.Path]::IsPathFullyQualified($ref) -or $ref -match "(^|/)\.\.(/|$)") {
            throw "Installed config has unsafe file reference: $ref"
        }

        $refPath = Join-Path $targetContinue $ref
        if (-not (Test-Path -LiteralPath $refPath)) {
            throw "Installed config references a missing file: .continue/$ref"
        }
    }

    $localConfigFiles = Get-ChildItem -LiteralPath $targetContinue -Force -File -Filter "config.local*.yaml" -ErrorAction SilentlyContinue
    if ($localConfigFiles.Count -gt 0) {
        throw "Installed pack should not include local config overrides."
    }
}

Write-Plan "Install Continue Enterprise Engineering Pack"
Write-Plan "Source: $sourceContinue"
Write-Plan "Target: $targetContinue"

if (Test-Path -LiteralPath $targetContinue) {
    Write-Plan "Existing target .continue will be backed up to: $backupContinue"
} else {
    Write-Plan "Target .continue does not exist and will be created."
}

Write-Plan "Local config overrides matching config.local*.yaml will be excluded."

if ($DryRun) {
    Write-Plan "Dry run only. No files will be changed."
    Write-Plan "Files that would be copied:"
    Get-PackFiles | ForEach-Object {
        $relative = [System.IO.Path]::GetRelativePath($sourceContinue, $_.FullName).Replace('\', '/')
        Write-Host "- .continue/$relative"
    }
    exit 0
}

if (Test-Path -LiteralPath $targetContinue) {
    Move-Item -LiteralPath $targetContinue -Destination $backupContinue
}

New-Item -ItemType Directory -Force -Path $targetContinue | Out-Null
Copy-PackFiles
Test-InstalledPack

Write-Host "Install complete." -ForegroundColor Green
Write-Host "Installed .continue to $targetContinue" -ForegroundColor Green

if (Test-Path -LiteralPath $backupContinue) {
    Write-Host "Backup created at $backupContinue" -ForegroundColor Yellow
}

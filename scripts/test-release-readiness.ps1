[CmdletBinding()]
param(
    [string]$ExpectedVersion = "0.2.0",
    [string]$ReleaseVersion,
    [string]$OutputPath,
    [switch]$AsJson,
    [switch]$AllowDirty,
    [switch]$SkipValidation,
    [switch]$SkipTests,
    [switch]$SkipPackageDryRun
)

$ErrorActionPreference = "Stop"

$repoRoot = Split-Path -Parent $PSScriptRoot

function Invoke-GateCommand {
    param(
        [string]$Id,
        [string]$Name,
        [string]$FilePath,
        [string[]]$Arguments = @(),
        [switch]$Skip
    )

    if ($Skip) {
        return [pscustomobject]@{
            Id = $Id
            Name = $Name
            Status = "skip"
            ExitCode = $null
            Message = "Skipped by request."
        }
    }

    $output = & pwsh -NoProfile -ExecutionPolicy Bypass -File $FilePath @Arguments 2>&1
    $exitCode = $LASTEXITCODE

    return [pscustomobject]@{
        Id = $Id
        Name = $Name
        Status = if ($exitCode -eq 0) { "pass" } else { "fail" }
        ExitCode = $exitCode
        Message = if ($exitCode -eq 0) { "Command completed successfully." } else { "Command failed. $($output -join ' ')" }
    }
}

function New-CheckResult {
    param(
        [string]$Id,
        [string]$Name,
        [ValidateSet("pass", "warn", "fail", "skip")]
        [string]$Status,
        [string]$Message
    )

    return [pscustomobject]@{
        Id = $Id
        Name = $Name
        Status = $Status
        Message = $Message
    }
}

function Test-GitState {
    $status = git -C $repoRoot status --short --branch 2>&1
    if ($LASTEXITCODE -ne 0) {
        return New-CheckResult -Id "git.status" -Name "Git Status" -Status "fail" -Message "Git status failed."
    }

    $lines = @($status)
    $branchLine = if ($lines.Count -gt 0) { $lines[0] } else { "" }
    $changes = @($lines | Select-Object -Skip 1)

    if ($changes.Count -gt 0 -and -not $AllowDirty) {
        return New-CheckResult -Id "git.status" -Name "Git Status" -Status "fail" -Message "Working tree has uncommitted changes."
    }

    if ($branchLine -match "\[(ahead|behind|diverged)") {
        return New-CheckResult -Id "git.status" -Name "Git Status" -Status "warn" -Message "Branch is not fully synced with upstream."
    }

    if ($changes.Count -gt 0) {
        return New-CheckResult -Id "git.status" -Name "Git Status" -Status "warn" -Message "Working tree has local changes; allowed for this run."
    }

    return New-CheckResult -Id "git.status" -Name "Git Status" -Status "pass" -Message "Working tree is clean and branch appears synced."
}

function Test-JsonFile {
    param(
        [string]$Id,
        [string]$Name,
        [string]$Path
    )

    try {
        Get-Content -LiteralPath $Path -Raw | ConvertFrom-Json | Out-Null
        return New-CheckResult -Id $Id -Name $Name -Status "pass" -Message "JSON parsed successfully."
    }
    catch {
        return New-CheckResult -Id $Id -Name $Name -Status "fail" -Message "JSON parsing failed."
    }
}

$checks = @()
$checks += Test-GitState
$checks += Test-JsonFile -Id "workflow.registry" -Name "Workflow Registry" -Path (Join-Path $repoRoot "config/workflows.json")
$checks += Test-JsonFile -Id "surface.parity" -Name "Agent Surface Parity Matrix" -Path (Join-Path $repoRoot "config/agent-surface-capabilities.json")

$checks += Invoke-GateCommand `
    -Id "validate-pack" `
    -Name "Pack Validation" `
    -FilePath (Join-Path $repoRoot "scripts/validate-pack.ps1") `
    -Arguments @("-ExpectedVersion", $ExpectedVersion) `
    -Skip:$SkipValidation

$checks += Invoke-GateCommand `
    -Id "test-pack" `
    -Name "Pack Tests" `
    -FilePath (Join-Path $repoRoot "scripts/test-pack.ps1") `
    -Arguments @() `
    -Skip:$SkipTests

$packageArgs = @("-DryRun", "-AllowDirty")
if ($ReleaseVersion) {
    $packageArgs += @("-Version", $ReleaseVersion)
}
$checks += Invoke-GateCommand `
    -Id "release-package-dry-run" `
    -Name "Release Package Dry Run" `
    -FilePath (Join-Path $repoRoot "scripts/build-release-package.ps1") `
    -Arguments $packageArgs `
    -Skip:$SkipPackageDryRun

$rank = @{
    "fail" = 3
    "warn" = 2
    "skip" = 1
    "pass" = 0
}
$overall = ($checks | Sort-Object { $rank[$_.Status] } -Descending | Select-Object -First 1).Status

$report = [pscustomobject]@{
    SchemaVersion = 1
    GeneratedAtUtc = (Get-Date).ToUniversalTime().ToString("o")
    OverallStatus = $overall
    ExpectedVersion = $ExpectedVersion
    ReleaseVersion = if ($ReleaseVersion) { $ReleaseVersion } else { $ExpectedVersion }
    Checks = $checks
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
    Write-Host "Overall: $overall"
    foreach ($check in $checks) {
        Write-Host "$($check.Status.ToUpperInvariant()) $($check.Name): $($check.Message)"
    }
}

if ($overall -eq "fail") {
    exit 1
}

exit 0

param(
    [string]$PolicyPath
)

$ErrorActionPreference = "Stop"
$repoRoot = Split-Path -Parent $PSScriptRoot
if (-not $PolicyPath) {
    $local = Join-Path $repoRoot "config/model-runtime-policy.local.json"
    $PolicyPath = if (Test-Path -LiteralPath $local) { $local } else { Join-Path $repoRoot "config/model-runtime-policy.sample.json" }
}
if (-not (Test-Path -LiteralPath $PolicyPath)) { throw "Model runtime policy does not exist: $PolicyPath" }
$policy = Get-Content -LiteralPath $PolicyPath -Raw | ConvertFrom-Json
if ($policy.schemaVersion -ne 1) { throw "Unsupported model runtime policy schema." }
if ($policy.residencyMode -notin @("unload-after-run", "keep-loaded")) { throw "residencyMode must be unload-after-run or keep-loaded." }
if ([int]$policy.maxResidentModels -lt 1) { throw "maxResidentModels must be positive." }
$policy | ConvertTo-Json -Depth 5

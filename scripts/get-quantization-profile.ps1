param(
    [int]$ContextTokens = 16384,
    [int]$Concurrency = 1,
    [ValidateSet("general-chat", "summarization", "tool-use", "engineering-read", "engineering-write")]
    [string]$WorkloadLane = "tool-use",
    [string]$StorageRoot = $HOME
)

$ErrorActionPreference = "Stop"
$python = Get-Command python -ErrorAction SilentlyContinue
if (-not $python) {
    throw "Python 3 is required to generate the quantization hardware profile."
}

& $python.Source (Join-Path $PSScriptRoot "quantization-planner.py") profile `
    --context-tokens $ContextTokens `
    --concurrency $Concurrency `
    --workload-lane $WorkloadLane `
    --storage-root $StorageRoot
exit $LASTEXITCODE

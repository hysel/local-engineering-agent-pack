[CmdletBinding()]
param(
    [string]$ScenarioPath,
    [switch]$SelfTest,
    [switch]$AsJson
)
$ErrorActionPreference = "Stop"
$python = Get-Command python -ErrorAction SilentlyContinue
if (-not $python) { $python = Get-Command python3 -ErrorAction SilentlyContinue }
if (-not $python) { throw "Python 3 is required for core update lifecycle simulation." }
if (-not $SelfTest -and -not $ScenarioPath) {
    throw "ScenarioPath is required unless SelfTest is used."
}
$arguments = @((Join-Path $PSScriptRoot "core-update-lifecycle.py"))
if ($SelfTest) {
    $arguments += "--self-test"
}
else {
    $arguments += @("--scenario-path", $ScenarioPath)
    if ($AsJson) { $arguments += "--json" }
}
& $python.Source @arguments
exit $LASTEXITCODE

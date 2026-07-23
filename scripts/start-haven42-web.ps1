[CmdletBinding()]
param(
    [ValidateRange(0, 65535)][int]$Port = 4242,
    [switch]$NoOpen
)

$ErrorActionPreference = "Stop"
$serverPath = Join-Path (Split-Path -Parent $PSScriptRoot) "web/server.py"
$python = Get-Command python3 -ErrorAction SilentlyContinue
if (-not $python) { $python = Get-Command python -ErrorAction SilentlyContinue }
$arguments = @($serverPath, "--port", [string]$Port)
if ($NoOpen) { $arguments += "--no-open" }

if ($python) {
    & $python.Source @arguments
    exit $LASTEXITCODE
}
if (Get-Command py -ErrorAction SilentlyContinue) {
    & py -3 @arguments
    exit $LASTEXITCODE
}
throw "Python 3 is required to run the Haven 42 local web application."

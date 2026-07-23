[CmdletBinding()]
param(
    [ValidateRange(0, 65535)][int]$Port = 4242,
    [switch]$NoOpen
)

$ErrorActionPreference = "Stop"
$serverPath = Join-Path (Split-Path -Parent $PSScriptRoot) "web/server.py"
$arguments = @($serverPath, "--port", [string]$Port)
if ($NoOpen) { $arguments += "--no-open" }

function Resolve-Python3Command {
    foreach ($candidate in @(
        @{ Name = "python3"; Prefix = @() },
        @{ Name = "python"; Prefix = @() },
        @{ Name = "py"; Prefix = @("-3") }
    )) {
        $command = Get-Command $candidate.Name -ErrorAction SilentlyContinue | Select-Object -First 1
        if (-not $command -or -not $command.Source) { continue }
        & $command.Source @($candidate.Prefix) -c "import sys; raise SystemExit(0 if sys.version_info.major == 3 else 1)" 2>$null
        if ($LASTEXITCODE -eq 0) {
            return [pscustomobject]@{ Path = $command.Source; Prefix = @($candidate.Prefix) }
        }
    }
    return $null
}

$python = Resolve-Python3Command
if (-not $python) { throw "A working Python 3 interpreter is required to run the Haven 42 local web application." }
& $python.Path @($python.Prefix) @arguments
exit $LASTEXITCODE

param(
    [string[]]$Models = @(),
    [string]$TargetRepo,
    [string]$OutputPath,
    [string]$OllamaBaseUrl = "http://127.0.0.1:11434",
    [string]$AgentCommand = "kilo-code",
    [string]$AgentArgumentsTemplate = '--task "{Prompt}"',
    [string]$ModelArgumentTemplate = '--model "{Model}"',
    [int]$TimeoutSeconds = 600,
    [switch]$IncludeWriteSmoke,
    [switch]$AllowNonGeneratedTarget,
    [switch]$UnloadAfterEach,
    [switch]$DryRun
)

$scriptPath = Join-Path $PSScriptRoot "test-agent-cli-surface-models.ps1"
$arguments = @{
    SurfaceName = "Kilo Code"
    SurfaceKey = "kilo-code-cli"
    Models = $Models
    TargetRepo = $TargetRepo
    OutputPath = $OutputPath
    OllamaBaseUrl = $OllamaBaseUrl
    AgentCommand = $AgentCommand
    AgentArgumentsTemplate = $AgentArgumentsTemplate
    ModelArgumentTemplate = $ModelArgumentTemplate
    InstallHint = "Install or configure Kilo Code CLI if available, or pass the command/template override. Editor extension validation is separate."
    TimeoutSeconds = $TimeoutSeconds
    IncludeWriteSmoke = $IncludeWriteSmoke
    AllowNonGeneratedTarget = $AllowNonGeneratedTarget
    UnloadAfterEach = $UnloadAfterEach
    DryRun = $DryRun
}

& $scriptPath @arguments
exit $LASTEXITCODE

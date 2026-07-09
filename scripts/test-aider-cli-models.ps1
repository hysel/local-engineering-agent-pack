param(
    [string[]]$Models = @(),
    [string]$TargetRepo,
    [string]$OutputPath,
    [string]$OllamaBaseUrl = "http://127.0.0.1:11434",
    [string]$AgentCommand = "aider",
    [string]$AgentArgumentsTemplate = '--message "{Prompt}" --yes-always --no-auto-commits',
    [string]$ModelArgumentTemplate = '--model "ollama_chat/{Model}"',
    [int]$TimeoutSeconds = 600,
    [switch]$IncludeWriteSmoke,
    [switch]$AllowNonGeneratedTarget,
    [switch]$UnloadAfterEach,
    [switch]$DryRun
)

$scriptPath = Join-Path $PSScriptRoot "test-agent-cli-surface-models.ps1"
$arguments = @{
    SurfaceName = "Aider CLI"
    SurfaceKey = "aider-cli"
    Models = $Models
    TargetRepo = $TargetRepo
    OutputPath = $OutputPath
    OllamaBaseUrl = $OllamaBaseUrl
    AgentCommand = $AgentCommand
    AgentArgumentsTemplate = $AgentArgumentsTemplate
    ModelArgumentTemplate = $ModelArgumentTemplate
    InstallHint = "Install with pipx install aider-chat or pass the command override."
    TimeoutSeconds = $TimeoutSeconds
    IncludeWriteSmoke = $IncludeWriteSmoke
    AllowNonGeneratedTarget = $AllowNonGeneratedTarget
    UnloadAfterEach = $UnloadAfterEach
    DryRun = $DryRun
}

& $scriptPath @arguments
exit $LASTEXITCODE

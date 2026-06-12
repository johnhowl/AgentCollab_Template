param(
    [Parameter(Mandatory = $true)]
    [string]$Objective,

    [string]$OutFile = ""
)

# Claude decides the git lifecycle (commit / branch / merge / tag / version) and
# emits a structured directive; Codex executes it. Push always requires human
# confirmation.

$ErrorActionPreference = "Stop"
$ProjectRoot = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
$Schema = Join-Path $ProjectRoot ".ai-collab\schemas\git-directive.schema.json"
$PromptFile = Join-Path $ProjectRoot ".ai-collab\prompts\git.md"

if ($OutFile -eq "") {
    $stamp = Get-Date -Format "yyyyMMdd-HHmmss"
    $OutFile = Join-Path $ProjectRoot ".ai-collab\tasks\$stamp-git-directive.json"
}

if (-not (Get-Command claude -ErrorAction SilentlyContinue)) {
    throw "claude was not found in PATH."
}

Push-Location $ProjectRoot
try {
    if (-not (Test-Path ".git")) {
        throw "Not a Git repository. Run scripts\Initialize-CollabGit.ps1 first."
    }

    $branch = git rev-parse --abbrev-ref HEAD
    $status = git status --short
    $log = git log --oneline -n 15
    $tags = git tag --sort=-v:refname

    $prompt = @"
$(Get-Content -Raw -Path $PromptFile)

用户意图：
$Objective

当前分支：$branch

工作区状态：
$status

最近提交：
$log

现有标签：
$tags
"@

    $result = $prompt | claude -p --json-schema $Schema --output-format json --permission-mode plan --add-dir $ProjectRoot
    $result | Set-Content -Path $OutFile -Encoding UTF8
    Write-Host "Git directive written to $OutFile"
    Write-Host "Codex executes it; push (if any) stops for human confirmation."
} finally {
    Pop-Location
}


param(
    [string]$OutFile = ""
)

$ErrorActionPreference = "Stop"
$ProjectRoot = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
$Schema = Join-Path $ProjectRoot ".ai-collab\schemas\review.schema.json"
$PromptFile = Join-Path $ProjectRoot ".ai-collab\prompts\review.md"

if ($OutFile -eq "") {
    $stamp = Get-Date -Format "yyyyMMdd-HHmmss"
    $OutFile = Join-Path $ProjectRoot ".ai-collab\reviews\$stamp-review.json"
}

if (-not (Get-Command git -ErrorAction SilentlyContinue)) {
    throw "git was not found in PATH."
}
if (-not (Get-Command claude -ErrorAction SilentlyContinue)) {
    throw "claude was not found in PATH."
}

Push-Location $ProjectRoot
try {
    if (-not (Test-Path ".git")) {
        throw "This directory is not a Git repository. Run scripts\Initialize-CollabGit.ps1 first."
    }

    $diff = git diff -- . ":(exclude).ai-collab/reviews" ":(exclude).ai-collab/tasks"
    if ([string]::IsNullOrWhiteSpace($diff)) {
        throw "No Git diff found to review."
    }

    $prompt = @"
$(Get-Content -Raw -Path $PromptFile)

Git diff:
$diff
"@

    $result = $prompt | claude -p --json-schema $Schema --output-format json --permission-mode plan --add-dir $ProjectRoot
    $result | Set-Content -Path $OutFile -Encoding UTF8
    Write-Host "Review written to $OutFile"
} finally {
    Pop-Location
}



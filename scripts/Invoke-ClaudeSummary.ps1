param(
    [Parameter(Mandatory = $true)]
    [string]$Objective,

    [string]$TestLog = "",
    [string]$OutFile = ""
)

$ErrorActionPreference = "Stop"
$ProjectRoot = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
$Schema = Join-Path $ProjectRoot ".ai-collab\schemas\summary.schema.json"
$PromptFile = Join-Path $ProjectRoot ".ai-collab\prompts\summary.md"

if ($OutFile -eq "") {
    $stamp = Get-Date -Format "yyyyMMdd-HHmmss"
    $OutFile = Join-Path $ProjectRoot ".ai-collab\reviews\$stamp-summary.json"
}

if (-not (Get-Command claude -ErrorAction SilentlyContinue)) {
    throw "claude was not found in PATH."
}

Push-Location $ProjectRoot
try {
    $log = ""
    $changed = ""
    if (Test-Path ".git") {
        $log = git log --oneline -n 20
        $changed = git status --short
    }

    $testEvidence = ""
    if ($TestLog -ne "" -and (Test-Path $TestLog)) {
        $testEvidence = Get-Content -Raw -Path $TestLog
    }

    $prompt = @"
$(Get-Content -Raw -Path $PromptFile)

本轮任务目标：
$Objective

最近 Git 提交：
$log

当前工作区状态：
$changed

测试/实验日志：
$testEvidence
"@

    $result = $prompt | claude -p --json-schema $Schema --output-format json --permission-mode plan --add-dir $ProjectRoot
    $result | Set-Content -Path $OutFile -Encoding UTF8
    Write-Host "Summary written to $OutFile"
} finally {
    Pop-Location
}


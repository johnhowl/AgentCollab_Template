param(
    [Parameter(Mandatory = $true)]
    [string]$Objective,

    [string]$OutFile = ""
)

$ErrorActionPreference = "Stop"
$ProjectRoot = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
$Schema = Join-Path $ProjectRoot ".ai-collab\schemas\test-spec.schema.json"
$PromptFile = Join-Path $ProjectRoot ".ai-collab\prompts\test.md"

if ($OutFile -eq "") {
    $stamp = Get-Date -Format "yyyyMMdd-HHmmss"
    $OutFile = Join-Path $ProjectRoot ".ai-collab\tasks\$stamp-test-spec.json"
}

if (-not (Get-Command claude -ErrorAction SilentlyContinue)) {
    throw "claude was not found in PATH. Run this from the Codex side terminal where Claude Code is available."
}

Push-Location $ProjectRoot
try {
    $diff = ""
    if (Test-Path ".git") {
        $diff = git diff -- . ":(exclude).ai-collab/reviews" ":(exclude).ai-collab/tasks"
    }

    $prompt = @"
$(Get-Content -Raw -Path $PromptFile)

用户目标：
$Objective

当前 Git diff（可能为空）：
$diff

项目上下文：
- 主开发目录：$ProjectRoot
- 项目领域：__PROJECT_DOMAIN__
- 构建/测试契约：__BUILD_TEST_CONTRACT__
- 可选只读参考：__LEGACY_REF__
"@

    $result = $prompt | claude -p --json-schema $Schema --output-format json --permission-mode plan --add-dir $ProjectRoot
    $result | Set-Content -Path $OutFile -Encoding UTF8
    Write-Host "Test spec written to $OutFile"
} finally {
    Pop-Location
}


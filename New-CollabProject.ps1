param(
    [Parameter(Mandatory = $true)]
    [string]$TargetDir,

    [Parameter(Mandatory = $true)]
    [string]$ProjectName,

    [switch]$NoGit
)

$ErrorActionPreference = "Stop"

$TemplateRoot = $PSScriptRoot
$TargetPath = $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($TargetDir)

if (Test-Path $TargetPath) {
    $existing = Get-ChildItem -Force -LiteralPath $TargetPath
    if ($existing.Count -gt 0) {
        throw "TargetDir exists and is not empty: $TargetPath"
    }
} else {
    New-Item -ItemType Directory -Force -Path $TargetPath | Out-Null
}

# Never copy the template's own VCS history or transient dirs into a new project;
# the new project gets a fresh git via Initialize-CollabGit.
$exclude = @("New-CollabProject.ps1", "TEMPLATE-README.md",
             ".git", ".planning", "build", "__pycache__")
Get-ChildItem -Force -LiteralPath $TemplateRoot | Where-Object {
    $exclude -notcontains $_.Name
} | ForEach-Object {
    Copy-Item -LiteralPath $_.FullName -Destination $TargetPath -Recurse -Force
}

$utf8NoBom = New-Object System.Text.UTF8Encoding $false
Get-ChildItem -Force -Recurse -File -LiteralPath $TargetPath | Where-Object {
    $_.FullName -notmatch '\\(\.git|\.planning|__pycache__|build)\\'
} | ForEach-Object {
    $text = Get-Content -Raw -Encoding UTF8 -LiteralPath $_.FullName
    $text = $text.Replace("__PROJECT_NAME__", $ProjectName)
    $isHook = ($_.FullName -like "*\scripts\git-hooks\commit-msg") -or
              ($_.FullName -like "*\scripts\git-hooks\post-commit")
    if ($isHook) {
        # Shell hooks: LF line endings, no BOM (avoid "bad interpreter" on sh).
        $text = $text -replace "`r`n", "`n"
        [System.IO.File]::WriteAllText($_.FullName, $text, (New-Object System.Text.UTF8Encoding $false))
    } else {
        # Text/JSON: UTF-8 without BOM so strict parsers (python, etc.) accept it.
        [System.IO.File]::WriteAllText($_.FullName, $text, $utf8NoBom)
    }
}

if (-not $NoGit) {
    $init = Join-Path $TargetPath "scripts\Initialize-CollabGit.ps1"
    if (-not (Test-Path $init)) {
        throw "Initialize-CollabGit.ps1 was not copied to $init"
    }
    & $init
}

Write-Host ""
Write-Host "Project created: $TargetPath"
Write-Host "Remaining placeholders to customize:"
$placeholders = "__PROJECT_DOMAIN__|__BUILD_TEST_CONTRACT__|__LEGACY_REF__"
Get-ChildItem -Force -Recurse -File -LiteralPath $TargetPath |
    Select-String -Pattern $placeholders |
    Select-Object -ExpandProperty Path -Unique |
    ForEach-Object { Write-Host "  $_" }

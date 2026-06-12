param(
    [string]$RemoteUrl = "",
    [string]$InitialBranch = "main"
)

$ErrorActionPreference = "Stop"
$ProjectRoot = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
Set-Location $ProjectRoot

if (-not (Get-Command git -ErrorAction SilentlyContinue)) {
    throw "git was not found in PATH."
}

if (-not (Test-Path ".git")) {
    git init -b $InitialBranch
}

if ($RemoteUrl -ne "") {
    $existing = git remote
    if ($existing -notcontains "origin") {
        git remote add origin $RemoteUrl
    }
}

# Install version-controlled hooks (protected-path guardrail for Tier-B changes).
$hooksDir = "scripts/git-hooks"
if (Test-Path $hooksDir) {
    git config core.hooksPath $hooksDir
    Write-Host "Installed git hooks via core.hooksPath = $hooksDir"
}

git status --short

Write-Host ""
Write-Host "Git is ready in $ProjectRoot"
Write-Host "Next: review files, then run: git add .; git commit -m `"Initialize __PROJECT_NAME__ collaboration baseline`""



$ErrorActionPreference = "Stop"
$ProjectRoot = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
Set-Location $ProjectRoot

Write-Host "Project: $ProjectRoot"
Write-Host ""

if (Test-Path ".git") {
    Write-Host "Git status:"
    git status --short
} else {
    Write-Host "Git status: not initialized. Run scripts\Initialize-CollabGit.ps1"
}

Write-Host ""
Write-Host "Recent task plans:"
Get-ChildItem ".ai-collab\tasks" -File -ErrorAction SilentlyContinue |
    Sort-Object LastWriteTime -Descending |
    Select-Object -First 5 FullName, LastWriteTime

Write-Host ""
Write-Host "Recent research briefs:"
Get-ChildItem ".ai-collab\research" -File -ErrorAction SilentlyContinue |
    Sort-Object LastWriteTime -Descending |
    Select-Object -First 5 FullName, LastWriteTime

Write-Host ""
Write-Host "Recent reviews:"
Get-ChildItem ".ai-collab\reviews" -File -ErrorAction SilentlyContinue |
    Sort-Object LastWriteTime -Descending |
    Select-Object -First 5 FullName, LastWriteTime



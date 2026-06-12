param(
    [Parameter(Mandatory = $true)]
    [string]$Artifact,

    [int]$Round = 1,
    [string]$OutFile = ""
)

# Scaffolds a query JSON skeleton for Codex to fill when it has questions or a
# technical objection about a plan / review / test-spec. Codex (or a human) fills
# in the queries, then submits it via Invoke-ClaudeResolve.ps1.

$ErrorActionPreference = "Stop"
$ProjectRoot = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
if ($OutFile -eq "") {
    $stamp = Get-Date -Format "yyyyMMdd-HHmmss"
    $dir = Join-Path $ProjectRoot ".ai-collab\dialogue\$stamp"
    New-Item -ItemType Directory -Force -Path $dir | Out-Null
    $OutFile = Join-Path $dir "query-r$Round.json"
} else {
    $parent = Split-Path -Parent $OutFile
    if ($parent -and -not (Test-Path $parent)) {
        New-Item -ItemType Directory -Force -Path $parent | Out-Null
    }
}

$skeleton = [ordered]@{
    project        = "__PROJECT_NAME__"
    round          = $Round
    overall_stance = "proceed_with_questions"
    queries        = @(
        [ordered]@{
            id                  = "q1"
            refers_to           = [ordered]@{ artifact = $Artifact; item_id = "whole" }
            type                = "clarification"
            question            = ""
            codex_position      = ""
            evidence            = ""
            proposed_resolution = ""
        }
    )
}

$skeleton | ConvertTo-Json -Depth 6 | Set-Content -Path $OutFile -Encoding UTF8
Write-Host "Query skeleton created: $OutFile"
Write-Host "Fill in queries[].question / codex_position / evidence, then run Invoke-ClaudeResolve.ps1 -QueryFile $OutFile"


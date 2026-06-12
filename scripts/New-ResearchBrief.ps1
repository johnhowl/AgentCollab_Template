param(
    [Parameter(Mandatory = $true)]
    [string]$Topic
)

$ErrorActionPreference = "Stop"
$ProjectRoot = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
$safe = ($Topic -replace '[^\p{L}\p{Nd}\-_]+', '-').Trim('-')
if ($safe.Length -gt 60) { $safe = $safe.Substring(0, 60) }
$stamp = Get-Date -Format "yyyyMMdd-HHmmss"
$OutFile = Join-Path $ProjectRoot ".ai-collab\research\$stamp-$safe.md"

$template = @"
# Research Brief: $Topic

## Questions

- 

## Sources

| Source | Link / ID | What it supports | Confidence |
| --- | --- | --- | --- |
|  |  |  |  |

## Findings

- 

## Candidate Approaches

- 

## Risks / Unknowns

- 

## Next Experiments

- 

## Handoff Notes For Claude

- 

## Handoff Notes For Codex

- 
"@

$template | Set-Content -Path $OutFile -Encoding UTF8
Write-Host "Research brief created: $OutFile"



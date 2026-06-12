param(
    [Parameter(Mandatory = $true)]
    [string]$Topic
)

$ErrorActionPreference = "Stop"
$ProjectRoot = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
$safe = ($Topic -replace '[^\p{L}\p{Nd}\-_]+', '-').Trim('-')
if ($safe.Length -gt 60) { $safe = $safe.Substring(0, 60) }
$stamp = Get-Date -Format "yyyyMMdd-HHmmss"
$OutFile = Join-Path $ProjectRoot ".ai-collab\experiments\$stamp-$safe.md"

$template = @"
# Experiment: $Topic

## Hypothesis (falsifiable)

-

## Setup

- Dataset:
- Conditions / parameters:
- Scenario:
- Labels:

## Procedure (runnable locally)

1. Prepare inputs / fixtures:
2. Build:
3. Run:

## Metrics

| Metric | Definition | Target |
| --- | --- | --- |
| <metric_1> |  |  |
| <metric_2> |  |  |
| <metric_3> |  |  |

## Results (separate fact vs inference; mark confidence)

| Metric | Value | Confidence | Evidence |
| --- | --- | --- | --- |
|  |  |  |  |

## Conclusion

-

## Next Experiments

-
"@

$template | Set-Content -Path $OutFile -Encoding UTF8
Write-Host "Experiment record created: $OutFile"


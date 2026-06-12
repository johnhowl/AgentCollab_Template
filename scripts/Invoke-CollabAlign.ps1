<#
.SYNOPSIS
    Drive a Codex<->Claude alignment thread to convergence or human escalation.

.DESCRIPTION
    One round = Claude resolves the current Codex query. If not aligned, Codex
    gets a turn (accept the ruling, or write the next-round query). Capped at
    MaxRounds; if still unresolved, both positions are printed for the human.

.PARAMETER QueryFile
    The initial Codex query JSON (e.g. from New-CodexQuery.ps1, filled in).

.PARAMETER MaxRounds
    Max resolve<->respond rounds before escalating to a human (default 2).

.PARAMETER CodexCmd
    Optional Codex command template for the respond step. Tokens:
      {artifact} -> the resolution JSON, {phase} -> align-respond,
      {next}     -> path where Codex should write the next-round query if it
                    still disputes. If omitted, the step is a manual checkpoint.
#>
param(
    [Parameter(Mandatory = $true)]
    [string]$QueryFile,

    [int]$MaxRounds = 2,
    [string]$CodexCmd = ""
)

$ErrorActionPreference = "Stop"
$ProjectRoot = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
$ScriptDir = $PSScriptRoot
if (-not (Test-Path $QueryFile)) { throw "Query file not found: $QueryFile" }
$DialogueDir = Split-Path -Parent (Resolve-Path $QueryFile).Path

function Read-ClaudeJson($path) {
    $raw = Get-Content -Raw -Path $path
    try { $obj = $raw | ConvertFrom-Json } catch { return $null }
    if ($null -ne $obj.result) {
        if ($obj.result -is [string]) {
            try { return $obj.result | ConvertFrom-Json } catch { return $obj }
        }
        return $obj.result
    }
    return $obj
}

$currentQuery = (Resolve-Path $QueryFile).Path
$aligned = $false
$lastResolutionFile = ""

for ($round = 1; $round -le $MaxRounds; $round++) {
    Write-Host ""
    Write-Host "---------- ALIGN round $round ----------" -ForegroundColor Cyan

    $resolutionFile = Join-Path $DialogueDir ("resolution-r{0}.json" -f $round)
    & (Join-Path $ScriptDir "Invoke-ClaudeResolve.ps1") -QueryFile $currentQuery -OutFile $resolutionFile
    $lastResolutionFile = $resolutionFile
    $res = Read-ClaudeJson $resolutionFile

    if ($null -ne $res -and $res.aligned -eq $true) {
        $aligned = $true
        Write-Host "Aligned." -ForegroundColor Green
        break
    }
    Write-Host "Not aligned yet (round $round)." -ForegroundColor Yellow

    $nextQuery = Join-Path $DialogueDir ("query-r{0}.json" -f ($round + 1))
    if ($CodexCmd -ne "") {
        $cmd = $CodexCmd.Replace("{artifact}", $resolutionFile).Replace("{phase}", "align-respond").Replace("{next}", $nextQuery)
        Write-Host "Codex respond: $cmd" -ForegroundColor Yellow
        Invoke-Expression $cmd
    } else {
        Write-Host ""
        Write-Host "CHECKPOINT [align-respond] - Codex action:" -ForegroundColor Yellow
        Write-Host "  Read the resolution: $resolutionFile"
        Write-Host "  Apply any updated_instruction. If you accept, do nothing."
        Write-Host "  If you still dispute with new evidence, write a query at:"
        Write-Host "    $nextQuery"
        Read-Host "Press Enter when done"
    }

    if (Test-Path $nextQuery) {
        $currentQuery = $nextQuery
        continue
    } else {
        Write-Host "No further query from Codex; treating ruling as accepted." -ForegroundColor Green
        $aligned = $true
        break
    }
}

Write-Host ""
if ($aligned) {
    Write-Host "ALIGNMENT RESOLVED. Latest: $lastResolutionFile" -ForegroundColor Green
    exit 0
} else {
    Write-Host "ALIGNMENT NOT RESOLVED after $MaxRounds round(s) - escalating to human." -ForegroundColor Red
    Write-Host "Claude latest ruling:  $lastResolutionFile"
    Write-Host "Codex latest position: $currentQuery"
    Write-Host "Review both and decide the call manually."
    exit 3
}


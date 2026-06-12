<#
.SYNOPSIS
    __PROJECT_NAME__ Commander-Worker orchestrator.
    Drives: plan -> implement -> review -> fix(retry) -> test -> summary.

    Claude (Commander) produces structured JSON for plan / review / test-spec / summary.
    Codex (Worker) implements and fixes code, then runs tests.

.DESCRIPTION
    By default the Codex implementation/fix/test steps are CHECKPOINTS: the
    orchestrator writes the instruction artifact, prints what Codex must do, and
    waits for the operator. Supply -CodexCmd to automate those steps with a real
    Codex CLI. Nothing is pushed to a remote; commits stay local.

.PARAMETER Objective
    The development objective handed to the Commander.

.PARAMETER CodexCmd
    Optional command template invoked for Codex steps. Tokens substituted:
      {artifact} -> path to the JSON instruction file for this step
      {phase}    -> plan-implement | review-fix | test-run
      {next}     -> optional output path for alignment-query phases
    Example: -CodexCmd 'codex exec --file {artifact}'
    If omitted, each Codex step pauses for manual execution.

.PARAMETER MaxReviewRounds
    Maximum review->fix iterations before giving up (default 3).

.PARAMETER SkipTests
    Skip the test phase (not recommended).

.PARAMETER AlignGate
    Enable the Codex<->Claude alignment gate after plan and after each review:
    Codex may raise structured queries about the artifact; they are resolved (and
    escalated to a human if unresolved) before work continues. Default off.
#>
param(
    [Parameter(Mandatory = $true)]
    [string]$Objective,

    [string]$CodexCmd = "",
    [int]$MaxReviewRounds = 3,
    [switch]$SkipTests,
    [switch]$AlignGate
)

$ErrorActionPreference = "Stop"
$ProjectRoot = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
$ScriptDir = $PSScriptRoot
$Stamp = Get-Date -Format "yyyyMMdd-HHmmss"
$RunDir = Join-Path $ProjectRoot ".ai-collab\runs\$Stamp"
New-Item -ItemType Directory -Force -Path $RunDir | Out-Null

function Write-Phase($name) {
    Write-Host ""
    Write-Host "==================== $name ====================" -ForegroundColor Cyan
}

# Claude -p --output-format json returns an envelope; with --json-schema the
# schema-conforming object is in the .result field (as object or JSON string).
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

function Invoke-CodexStep($phase, $artifact, $humanInstruction, $next = "") {
    if ($CodexCmd -ne "") {
        $cmd = $CodexCmd.Replace("{artifact}", $artifact).Replace("{phase}", $phase).Replace("{next}", $next)
        Write-Host "Codex step [$phase]: $cmd" -ForegroundColor Yellow
        Invoke-Expression $cmd
        if ($LASTEXITCODE -ne 0) { throw "Codex step [$phase] failed with exit code $LASTEXITCODE." }
    } else {
        Write-Host ""
        Write-Host "CHECKPOINT [$phase] - Codex action required:" -ForegroundColor Yellow
        Write-Host $humanInstruction
        Write-Host "Artifact: $artifact"
        Read-Host "Press Enter after Codex has finished this step"
    }
}

# Optional alignment gate: let Codex question `artifact` before acting on it.
# Codex writes a query at $queryPath; if present, the alignment loop resolves it.
function Invoke-AlignGate($label, $artifact) {
    if (-not $AlignGate) { return }
    $gateDir = Join-Path $RunDir "align-$label"
    New-Item -ItemType Directory -Force -Path $gateDir | Out-Null
    $queryPath = Join-Path $gateDir "query-r1.json"

    Write-Phase "ALIGN GATE ($label)"
    Invoke-CodexStep "raise-query" $artifact "If you have questions or a technical objection about this artifact, write a query JSON at: $queryPath (see .ai-collab\schemas\query.schema.json). If you have none, leave it absent." $queryPath

    if (Test-Path $queryPath) {
        & (Join-Path $ScriptDir "Invoke-CollabAlign.ps1") -QueryFile $queryPath -CodexCmd $CodexCmd
        if ($LASTEXITCODE -eq 3) {
            throw "Alignment gate ($label) escalated to human; resolve it before continuing."
        }
    } else {
        Write-Host "No query raised; continuing." -ForegroundColor Green
    }
}

if (-not (Get-Command claude -ErrorAction SilentlyContinue)) {
    throw "claude was not found in PATH. Run from the terminal where Claude Code is available."
}

Push-Location $ProjectRoot
try {
    if (-not (Test-Path ".git")) {
        throw "Not a Git repository. Run scripts\Initialize-CollabGit.ps1 first."
    }

    # ---- Phase 1: PLAN (Commander) ----
    Write-Phase "1/5 PLAN (Claude)"
    $planFile = Join-Path $RunDir "task-plan.json"
    & (Join-Path $ScriptDir "Invoke-ClaudePlan.ps1") -Objective $Objective -OutFile $planFile
    $plan = Read-ClaudeJson $planFile
    if ($null -ne $plan -and $plan.tasks) {
        Write-Host ("Planned {0} task(s)." -f $plan.tasks.Count)
    }

    # ---- Alignment gate on the plan (optional) ----
    Invoke-AlignGate "plan" $planFile

    # ---- Phase 2: IMPLEMENT (Worker) ----
    Write-Phase "2/5 IMPLEMENT (Codex)"
    Invoke-CodexStep "plan-implement" $planFile "Implement every task in the task plan inside __PROJECT_NAME__. Treat __LEGACY_REF__ as read-only unless explicitly authorized. Stage changes with git add."

    # ---- Phase 3: REVIEW -> FIX loop (Commander reviews, Worker fixes) ----
    $reviewPassed = $false
    for ($round = 1; $round -le $MaxReviewRounds; $round++) {
        Write-Phase "3/5 REVIEW round $round (Claude)"
        $reviewFile = Join-Path $RunDir ("review-r{0}.json" -f $round)
        & (Join-Path $ScriptDir "Invoke-ClaudeReview.ps1") -OutFile $reviewFile
        $review = Read-ClaudeJson $reviewFile
        $verdict = if ($null -ne $review) { $review.verdict } else { "unknown" }
        Write-Host "Verdict: $verdict"

        if ($verdict -eq "pass" -or $verdict -eq "pass_with_notes") {
            $reviewPassed = $true
            break
        }

        # ---- Alignment gate on the review (optional): dispute before fixing ----
        Invoke-AlignGate "review-r$round" $reviewFile

        Write-Phase "FIX round $round (Codex)"
        Invoke-CodexStep "review-fix" $reviewFile "Apply every item in required_fixes from the review JSON (as adjudicated by any alignment ruling). Re-stage changes with git add."
    }

    if (-not $reviewPassed) {
        Write-Host "Review did not pass within $MaxReviewRounds rounds. Stopping before tests." -ForegroundColor Red
        Write-Host "Artifacts in: $RunDir"
        return
    }

    # ---- Phase 4: TEST (Commander writes spec, Worker runs) ----
    if (-not $SkipTests) {
        Write-Phase "4/5 TEST (Claude spec + Codex run)"
        $testSpecFile = Join-Path $RunDir "test-spec.json"
        & (Join-Path $ScriptDir "Invoke-ClaudeTestSpec.ps1") -Objective $Objective -OutFile $testSpecFile

        $testLog = Join-Path $RunDir "test-run.log"
        Invoke-CodexStep "test-run" $testSpecFile "Realize the test cases from the test spec, then run the project validation command from __BUILD_TEST_CONTRACT__ and capture output with Tee-Object '$testLog'. Ensure the run log lands at that path."

        if (-not (Test-Path $testLog)) {
            Write-Host "No test log found at $testLog; recording test phase as skipped." -ForegroundColor Yellow
            "TEST PHASE: no log captured (toolchain or runner unavailable)." | Set-Content -Path $testLog -Encoding UTF8
        }
    } else {
        Write-Host "SkipTests set; skipping test phase." -ForegroundColor Yellow
        $testLog = ""
    }

    # ---- Phase 5: SUMMARY (Commander) ----
    Write-Phase "5/5 SUMMARY (Claude)"
    $summaryFile = Join-Path $RunDir "summary.json"
    & (Join-Path $ScriptDir "Invoke-ClaudeSummary.ps1") -Objective $Objective -TestLog $testLog -OutFile $summaryFile

    Write-Host ""
    Write-Host "Loop complete. Run artifacts:" -ForegroundColor Green
    Get-ChildItem $RunDir -File | Select-Object Name, Length | Format-Table -AutoSize
    Write-Host "Review the summary, then commit: git commit -m `"<task>`""
} finally {
    Pop-Location
}


param(
    [Parameter(Mandatory = $true)]
    [string]$Summary,

    [string]$Files = "",
    [string]$Why = "",
    [ValidateSet("A")]
    [string]$Tier = "A"
)

# Records a Tier-A autonomous fix in FIXLOG.md. This is the mandatory disclosure
# step: an A-tier fix is allowed without discussion, but never silent.
# B-tier changes must NOT be logged here -- they go through the alignment channel.

$ErrorActionPreference = "Stop"
$ProjectRoot = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
$FixLog = Join-Path $ProjectRoot "FIXLOG.md"
if (-not (Test-Path $FixLog)) { throw "FIXLOG.md not found at $FixLog" }

if ($Files -eq "") {
    Push-Location $ProjectRoot
    try {
        if (Test-Path ".git") {
            $Files = (git diff --name-only) -join ", "
            if ($Files -eq "") { $Files = (git diff --cached --name-only) -join ", " }
        }
    } finally { Pop-Location }
}

$stamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
$entry = @"

## $stamp  [Tier $Tier autofix]

- Summary: $Summary
- Files: $Files
- Why deterministic / contract-neutral: $Why
"@

Add-Content -Path $FixLog -Value $entry -Encoding UTF8
Write-Host "Logged Tier-$Tier fix to FIXLOG.md"
Write-Host "Now commit it on its own:"
Write-Host "  git add <files> FIXLOG.md"
Write-Host "  git commit -m `"[autofix] $Summary`""


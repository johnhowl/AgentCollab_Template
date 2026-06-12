param(
    [Parameter(Mandatory = $true)]
    [string]$QueryFile,

    [string]$OutFile = ""
)

# Feeds a Codex query (plus the questioned artifact and current Git diff) to
# Claude, which returns a structured resolution adjudicating each query.

$ErrorActionPreference = "Stop"
$ProjectRoot = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
$Schema = Join-Path $ProjectRoot ".ai-collab\schemas\resolution.schema.json"
$PromptFile = Join-Path $ProjectRoot ".ai-collab\prompts\resolve.md"

if (-not (Test-Path $QueryFile)) { throw "Query file not found: $QueryFile" }
if ($OutFile -eq "") {
    $OutFile = [System.IO.Path]::ChangeExtension($QueryFile, $null) + "resolution.json"
}

if (-not (Get-Command claude -ErrorAction SilentlyContinue)) {
    throw "claude was not found in PATH."
}

$queryRaw = Get-Content -Raw -Path $QueryFile

# Best-effort: embed the content of each referenced artifact.
$artifactText = ""
try {
    $q = $queryRaw | ConvertFrom-Json
    $seen = @{}
    foreach ($item in $q.queries) {
        $a = $item.refers_to.artifact
        if ($a -and -not $seen.ContainsKey($a)) {
            $seen[$a] = $true
            $full = if ([System.IO.Path]::IsPathRooted($a)) { $a } else { Join-Path $ProjectRoot $a }
            if (Test-Path $full) {
                $artifactText += "`n--- $a ---`n" + (Get-Content -Raw -Path $full)
            }
        }
    }
} catch { }

Push-Location $ProjectRoot
try {
    $diff = ""
    if (Test-Path ".git") { $diff = git diff -- . ":(exclude).ai-collab" }

    $prompt = @"
$(Get-Content -Raw -Path $PromptFile)

Codex 质询（query）：
$queryRaw

被质询的产物内容：
$artifactText

当前 Git diff（可能为空）：
$diff
"@

    $result = $prompt | claude -p --json-schema $Schema --output-format json --permission-mode plan --add-dir $ProjectRoot
    $result | Set-Content -Path $OutFile -Encoding UTF8
    Write-Host "Resolution written to $OutFile"
} finally {
    Pop-Location
}


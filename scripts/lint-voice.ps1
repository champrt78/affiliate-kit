# Lints target files against the voice doctrine's forbidden phrases.
# Run AFTER the AI expands the scaffold, BEFORE commit. This is the back-stop
# layer when the AI drifts past the prompt-construction constraint (see U3/U4).
#
# Reads docs/voice-doctrine.md, extracts every literal in backticks from the
# `## Forbidden phrases` section, and greps the target(s) for each one.
# Case-insensitive, literal match (no regex interpretation of the literals).
#
# -Path accepts:
#   - A single file (.md, .astro, .mdx, .html, anything textual)
#   - A directory (recurses, scans .md + .astro + .mdx within)
#   - A glob pattern resolved via Get-ChildItem
#
# Exit codes:
#   0 — clean (no forbidden phrases found)
#   1 — one or more forbidden phrases found
#   2 — setup error (missing file, unparseable doctrine, etc.)

[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$Path,

    [string]$DoctrinePath = ""
)

$ErrorActionPreference = "Stop"

$repoRoot = Split-Path -Parent $PSScriptRoot

if (-not $DoctrinePath -or $DoctrinePath.Trim().Length -eq 0) {
    $DoctrinePath = Join-Path $repoRoot "docs/voice-doctrine.md"
}

# --- validate inputs ---------------------------------------------------------

if (-not (Test-Path $Path)) {
    [Console]::Error.WriteLine("[err] Target path not found: $Path")
    Write-Host ""
    Write-Host "Next:"
    Write-Host "  - Fix the lint setup, then re-run."
    exit 2
}

# Resolve $Path to a concrete list of files. Directory → recurse for content
# extensions; single file → list-of-one; glob → expand via Get-ChildItem.
$targetFiles = @()
$item = Get-Item -LiteralPath $Path -ErrorAction SilentlyContinue
if ($item -and $item.PSIsContainer) {
    $targetFiles = Get-ChildItem -Path $Path -Recurse -File -Include *.md, *.astro, *.mdx |
        ForEach-Object { $_.FullName }
}
elseif ($item) {
    $targetFiles = @($item.FullName)
}
else {
    # Glob — let Get-ChildItem expand it
    $targetFiles = Get-ChildItem -Path $Path -File | ForEach-Object { $_.FullName }
}

if ($targetFiles.Count -eq 0) {
    [Console]::Error.WriteLine("[err] No files to scan at: $Path")
    Write-Host ""
    Write-Host "Next:"
    Write-Host "  - Pass a file, directory, or glob with at least one .md / .astro / .mdx target."
    exit 2
}

if (-not (Test-Path $DoctrinePath)) {
    [Console]::Error.WriteLine("[err] Voice doctrine not found: $DoctrinePath")
    [Console]::Error.WriteLine("       Expected from U1 of the comparison-and-fit framework MVP plan.")
    [Console]::Error.WriteLine("       Re-run from the repo root, or pass -DoctrinePath <override>.")
    Write-Host ""
    Write-Host "Next:"
    Write-Host "  - Fix the lint setup, then re-run."
    exit 2
}

# --- parse forbidden phrases -------------------------------------------------

$doctrineText = Get-Content -Path $DoctrinePath -Raw

# Carve out the `## Forbidden phrases` section: everything between that heading
# and the next `## ` heading (or EOF). Multiline + case-sensitive match on the
# header line itself — the doctrine is canonical, so we expect exact casing.
$sectionPattern = '(?ms)^## Forbidden phrases\s*\r?\n(.*?)(?=^## |\z)'
$sectionMatch = [regex]::Match($doctrineText, $sectionPattern)

if (-not $sectionMatch.Success) {
    [Console]::Error.WriteLine("[err] Could not find the `## Forbidden phrases` section in $DoctrinePath.")
    [Console]::Error.WriteLine("       Expected an H2 heading exactly: ## Forbidden phrases")
    [Console]::Error.WriteLine("       Followed by bullet lines of the form: - `<literal>` — <reason>")
    Write-Host ""
    Write-Host "Next:"
    Write-Host "  - Fix the lint setup, then re-run."
    exit 2
}

$sectionBody = $sectionMatch.Groups[1].Value

# Each forbidden literal sits inside backticks at the start of a bullet line:
#   - `I tested` — claims direct testing
# We capture the first backticked token per bullet.
$literalPattern = '(?m)^- `([^`]+)`'
$literalMatches = [regex]::Matches($sectionBody, $literalPattern)

if ($literalMatches.Count -eq 0) {
    [Console]::Error.WriteLine("[err] The `## Forbidden phrases` section parsed but contained no backticked literals.")
    [Console]::Error.WriteLine("       Expected bullet lines like: - `I tested` — claims direct testing")
    Write-Host ""
    Write-Host "Next:"
    Write-Host "  - Fix the lint setup, then re-run."
    exit 2
}

$literals = @()
foreach ($m in $literalMatches) {
    $lit = $m.Groups[1].Value
    if ($lit -and $lit.Trim().Length -gt 0) {
        $literals += $lit
    }
}

# Dedupe while preserving order (a literal listed twice in the doctrine
# shouldn't cause double-counted findings).
$seen = @{}
$uniqueLiterals = @()
foreach ($lit in $literals) {
    $key = $lit.ToLowerInvariant()
    if (-not $seen.ContainsKey($key)) {
        $seen[$key] = $true
        $uniqueLiterals += $lit
    }
}

Write-Verbose "Loaded $($uniqueLiterals.Count) forbidden literals from $DoctrinePath"

# --- grep the targets --------------------------------------------------------

$findings = @()

foreach ($literal in $uniqueLiterals) {
    # -SimpleMatch makes this a literal substring search (regex metacharacters
    # in the literal are treated as plain text). Default -CaseSensitive:$false
    # is implicit; Select-String is case-insensitive by default.
    $hits = Select-String -Path $targetFiles -Pattern $literal -SimpleMatch
    if ($hits) {
        foreach ($hit in $hits) {
            $findings += [pscustomobject]@{
                Literal    = $literal
                FilePath   = $hit.Path
                LineNumber = $hit.LineNumber
                LineText   = $hit.Line
            }
        }
    }
}

# --- report ------------------------------------------------------------------

Write-Verbose "Scanned $($targetFiles.Count) file(s)."

if ($findings.Count -eq 0) {
    Write-Host "Voice doctrine: clean ($($targetFiles.Count) file(s) scanned)" -ForegroundColor Green
    Write-Host ""
    Write-Host "Next:"
    Write-Host "  - Voice doctrine clean. Proceed to ``astro build`` + preview, then commit."
    exit 0
}

foreach ($f in $findings) {
    Write-Host "$($f.FilePath):$($f.LineNumber): matched forbidden phrase: `"$($f.Literal)`"" -ForegroundColor Red
    if ($VerbosePreference -eq 'Continue') {
        Write-Host "    > $($f.LineText.Trim())" -ForegroundColor DarkGray
    }
}

Write-Host ""
Write-Host "Summary: $($findings.Count) finding(s) across $($targetFiles.Count) file(s) and $($uniqueLiterals.Count) forbidden literals." -ForegroundColor Red
Write-Host ""
Write-Host "Next:"
Write-Host "  - $($findings.Count) findings — edit the file(s) to remove forbidden phrases, then re-run."
exit 1

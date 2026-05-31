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
#   - OMITTED — defaults to a full-repo sweep: every content markdown under
#     sites/*/src/content/ AND every page template under sites/*/src/pages/
#     (*.astro). The page-template sweep was added 2026-05-29 after a voice
#     violation ("Hands-on product reviews ... buy with our own money") shipped
#     live in DetailerPicks reviews/index.astro: the copy is hardcoded in the
#     .astro page, not the content markdown the pre-commit hook scans, so the
#     existing lint never saw it. The default sweep closes that blind spot.
#
# Exit codes:
#   0 — clean (no forbidden phrases found)
#   1 — one or more forbidden phrases found
#   2 — setup error (missing file, unparseable doctrine, etc.)

[CmdletBinding()]
param(
    [Parameter(Mandatory = $false)]
    [string]$Path = "",

    [string]$DoctrinePath = ""
)

$ErrorActionPreference = "Stop"

$repoRoot = Split-Path -Parent $PSScriptRoot

if (-not $DoctrinePath -or $DoctrinePath.Trim().Length -eq 0) {
    $DoctrinePath = Join-Path $repoRoot "docs/voice-doctrine.md"
}

# --- resolve targets ---------------------------------------------------------

$targetFiles = @()

if (-not $Path -or $Path.Trim().Length -eq 0) {
    # No -Path → full-repo sweep. Two roots:
    #   1. Content markdown (the original scope) — sites/*/src/content/**.md
    #   2. Page templates — sites/*/src/pages/**/*.astro. These carry hardcoded
    #      copy (page ledes, descriptions, intros) that the content-markdown
    #      scan never sees. This is the blind spot that let the DTP reviews
    #      index ship a hands-on + "buy with our own money" violation.
    $sitesRoot = Join-Path $repoRoot "sites"
    if (-not (Test-Path $sitesRoot)) {
        [Console]::Error.WriteLine("[err] No -Path given and sites/ root not found at: $sitesRoot")
        Write-Host ""
        Write-Host "Next:"
        Write-Host "  - Run from the repo root, or pass an explicit -Path."
        exit 2
    }
    $contentFiles = Get-ChildItem -Path $sitesRoot -Recurse -File -Include *.md, *.mdx |
        Where-Object { $_.FullName -match '[\\/]src[\\/]content[\\/]' } |
        ForEach-Object { $_.FullName }
    $pageFiles = Get-ChildItem -Path $sitesRoot -Recurse -File -Include *.astro |
        Where-Object { $_.FullName -match '[\\/]src[\\/]pages[\\/]' } |
        ForEach-Object { $_.FullName }
    $targetFiles = @($contentFiles) + @($pageFiles)
}
else {
    # --- validate explicit path ---
    if (-not (Test-Path $Path)) {
        [Console]::Error.WriteLine("[err] Target path not found: $Path")
        Write-Host ""
        Write-Host "Next:"
        Write-Host "  - Fix the lint setup, then re-run."
        exit 2
    }

    # Resolve $Path to a concrete list of files. Directory → recurse for content
    # extensions; single file → list-of-one; glob → expand via Get-ChildItem.
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
#
# Two literal sets, partitioned by file type:
#   - Markdown (.md / .mdx) is wholly content body, so the FULL literal list
#     applies — including the punctuation-only em-dash ban.
#   - Page templates (.astro) interleave copy with CSS and JS where hyphens,
#     em dashes in code comments, and other punctuation are legitimate source,
#     not prose. Applying a punctuation-only literal (the em dash) to raw
#     .astro source flags `flex-direction`, `/* … — … */` comments, etc. —
#     code, not copy. So for .astro we skip any literal that is ENTIRELY
#     non-letter characters (the em-dash style-tell), and keep every literal
#     that carries at least one letter (the real hands-on / ownership / quote
#     phrases that hardcoded page copy can still smuggle in). The em-dash ban
#     still has full force in markdown content bodies.

$findings = @()

# Split targets by extension once.
$mdTargets = @($targetFiles | Where-Object { $_ -match '\.(md|mdx)$' })
$astroTargets = @($targetFiles | Where-Object { $_ -match '\.astro$' })
$otherTargets = @($targetFiles | Where-Object { $_ -notmatch '\.(md|mdx|astro)$' })

# Letter-bearing literals only — used for .astro source.
$letterLiterals = @($uniqueLiterals | Where-Object { $_ -match '\p{L}' })

function Find-Literals {
    param(
        [string[]]$Files,
        [string[]]$Literals
    )
    $out = @()
    if ($Files.Count -eq 0) { return $out }
    foreach ($literal in $Literals) {
        # -SimpleMatch makes this a literal substring search (regex metacharacters
        # in the literal are treated as plain text). Select-String is
        # case-insensitive by default.
        $hits = Select-String -Path $Files -Pattern $literal -SimpleMatch
        if ($hits) {
            foreach ($hit in $hits) {
                $out += [pscustomobject]@{
                    Literal    = $literal
                    FilePath   = $hit.Path
                    LineNumber = $hit.LineNumber
                    LineText   = $hit.Line
                }
            }
        }
    }
    return $out
}

# Markdown + any other textual target: full literal set (em dash included).
$findings += Find-Literals -Files ($mdTargets + $otherTargets) -Literals $uniqueLiterals
# .astro page templates: letter-bearing literals only (skip the em-dash style-tell).
$findings += Find-Literals -Files $astroTargets -Literals $letterLiterals

# --- semicolon ban (Vonnegut rule, 2026-05-31) -------------------------------
# Semicolons are banned in content prose, same tier as em dashes. A plain
# substring match would flag every HTML entity (&amp; &rarr; &middot; all END in
# a semicolon), so this is a dedicated check: strip HTML entities first, then
# flag any remaining `;`. Markdown content bodies only (NOT .astro — that source
# carries CSS/JS where `;` is legitimate). Frontmatter prose (verdict, supporting,
# facts) is in-scope because that is content too.
function Strip-Entities([string]$line) {
    $s = $line -replace '&#\d+;', '' -replace '&#x[0-9a-fA-F]+;', '' -replace '&[a-zA-Z][a-zA-Z0-9]*;', ''
    return $s
}
foreach ($mdFile in ($mdTargets + $otherTargets)) {
    $lineNo = 0
    foreach ($raw in (Get-Content -LiteralPath $mdFile)) {
        $lineNo++
        if ((Strip-Entities $raw).Contains(';')) {
            $findings += [pscustomobject]@{
                Literal    = "; (semicolon — Vonnegut rule)"
                FilePath   = $mdFile
                LineNumber = $lineNo
                LineText   = $raw
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

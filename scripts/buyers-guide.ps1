# Scaffolds a new buyer's guide: copies templates/buyers-guide.md.tmpl,
# fills frontmatter, writes the cloaked-link KV entry via scripts/add-link.ps1,
# prints next steps.
#
# Buyer's guides cover products Ray does NOT own. Frontmatter shape is
# `products[]` (per the buyersGuides Zod schema) — for v1 we seed a single
# product. No `rating` field — buyer's guides don't carry a personal score.

[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$Site,

    [Parameter(Mandatory = $true)]
    [string]$Slug,

    [Parameter(Mandatory = $true)]
    [string]$ProductName,

    [Parameter(Mandatory = $true)]
    [string]$Brand,

    [Parameter(Mandatory = $true)]
    [string]$AmazonUrl,

    [string]$Description = "",

    [string]$Tag = "",

    [switch]$NoKV,

    [switch]$Force
)

$ErrorActionPreference = "Stop"

$repoRoot = Split-Path -Parent $PSScriptRoot
$templatePath = Join-Path $repoRoot "templates/buyers-guide.md.tmpl"
$targetDir = Join-Path $repoRoot "sites/$Site/src/content/buyers-guides"
$targetPath = Join-Path $targetDir "$Slug.md"

if (-not (Test-Path $templatePath)) {
    Write-Host "[err] Template not found: $templatePath" -ForegroundColor Red
    exit 1
}

if (-not (Test-Path (Join-Path $repoRoot "sites/$Site"))) {
    Write-Host "[err] Site directory not found: sites/$Site" -ForegroundColor Red
    Write-Host "       Known sites live under sites/. Did you mean to bootstrap first?" -ForegroundColor Red
    exit 1
}

if ((Test-Path $targetPath) -and -not $Force) {
    Write-Host "[err] Buyer's guide already exists: $targetPath" -ForegroundColor Red
    Write-Host "       Re-run with -Force to overwrite." -ForegroundColor Red
    exit 1
}

if (-not (Test-Path $targetDir)) {
    New-Item -ItemType Directory -Path $targetDir -Force | Out-Null
}

$pubDate = (Get-Date -Format "yyyy-MM-dd")

$content = Get-Content $templatePath -Raw

$substitutions = [ordered]@{
    "__PRODUCT_NAME__"             = $ProductName
    "__PRODUCT_BRAND__"            = $Brand
    "__SLUG__"                     = $Slug
    "__PUB_DATE__"                 = $pubDate
    "__AMAZON_URL__"               = $AmazonUrl
    "__SHORT_DESCRIPTION__"        = $Description
    "__TAGLINE_HOOK_ONE_LINER__"   = ""
    "__FAQ_QUESTION_1__"           = ""
    "__FAQ_QUESTION_2__"           = ""
    "__FAQ_QUESTION_3__"           = ""
}

foreach ($key in $substitutions.Keys) {
    $content = $content.Replace($key, $substitutions[$key])
}

# Preserve the template's trailing-newline state.
Set-Content -Path $targetPath -Value $content -NoNewline

Write-Host "[ok] Wrote $targetPath"

# -----------------------------------------------------------------------------
# Sibling AI-drafting prompt file: <slug>.prompt.md
#
# Composes a markdown prompt the publisher pastes into Claude to expand the
# scaffold. Pulls voice doctrine (forbidden phrases + preferred framings) and
# per-site reader-segment metadata. If either source file is missing, emits a
# stub with a <!-- WARNING --> line — never blocks the scaffold itself.
# -----------------------------------------------------------------------------

$voiceDoctrinePath = Join-Path $repoRoot "docs/voice-doctrine.md"
$siteConfigPath = Join-Path $repoRoot "sites/$Site/src/data/site-config.json"

# Prompt file lives OUTSIDE src/content/ so Astro doesn't pick it up as a Zod-validated
# collection entry (that error blocks the build and is non-obvious). Lives at
# sites/<slug>/prompts/<slug>.prompt.md — adjacent to its site, outside Astro's build view.
$promptDir = Join-Path $repoRoot "sites/$Site/prompts"
if (-not (Test-Path $promptDir)) {
	New-Item -ItemType Directory -Path $promptDir -Force | Out-Null
}
$promptPath = Join-Path $promptDir "$Slug.prompt.md"

$voiceWarning = $null
$siteWarning = $null

$voiceDoctrine = $null
if (Test-Path $voiceDoctrinePath) {
    $voiceDoctrine = Get-Content $voiceDoctrinePath -Raw
} else {
    $voiceWarning = "<!-- WARNING: voice doctrine ($voiceDoctrinePath) missing — prompt is incomplete. Run U1 to create it. -->"
}

$siteConfig = $null
if (Test-Path $siteConfigPath) {
    try {
        $siteConfig = Get-Content $siteConfigPath -Raw | ConvertFrom-Json
    } catch {
        $siteWarning = "<!-- WARNING: site-config.json ($siteConfigPath) failed to parse: $($_.Exception.Message) -->"
    }
} else {
    $siteWarning = "<!-- WARNING: site-config.json ($siteConfigPath) missing — reader-segment context unavailable. -->"
}

# Extract a single H2 section verbatim from voice doctrine markdown. Returns
# the heading + body up to (but not including) the next H2 or horizontal rule.
function Get-DoctrineSection {
    param(
        [string]$Doctrine,
        [string]$Heading
    )
    if (-not $Doctrine) { return $null }
    $pattern = "(?ms)^##\s+$([regex]::Escape($Heading))\s*$.*?(?=^##\s+|^---\s*$)"
    $match = [regex]::Match($Doctrine, $pattern)
    if ($match.Success) {
        return $match.Value.TrimEnd()
    }
    return $null
}

$forbiddenSection = Get-DoctrineSection -Doctrine $voiceDoctrine -Heading "Forbidden phrases"
$preferredSection = Get-DoctrineSection -Doctrine $voiceDoctrine -Heading "Preferred framings"

# Reader-segment context lines. Build defensively in case site-config is null.
if ($siteConfig) {
    $siteName = $siteConfig.siteName
    $niche = $siteConfig.niche
    $brandTone = $siteConfig.brandTone
    $primary = if ($siteConfig.primarySegments) { ($siteConfig.primarySegments -join ", ") } else { "(none specified)" }
    $secondary = if ($siteConfig.secondarySegments) { ($siteConfig.secondarySegments -join ", ") } else { "(none specified)" }
    $excluded = if ($siteConfig.excludedSegments) { ($siteConfig.excludedSegments -join ", ") } else { "(none specified)" }
} else {
    $siteName = $Site
    $niche = "(unknown — site-config.json missing)"
    $brandTone = "(unknown — site-config.json missing)"
    $primary = "(unknown)"
    $secondary = "(unknown)"
    $excluded = "(unknown)"
}

$promptLines = New-Object System.Collections.Generic.List[string]
$promptLines.Add("# AI Drafting Prompt — $siteName — $ProductName")
$promptLines.Add("")
if ($voiceWarning) { $promptLines.Add($voiceWarning); $promptLines.Add("") }
if ($siteWarning)  { $promptLines.Add($siteWarning);  $promptLines.Add("") }
$promptLines.Add("You are drafting a comparison-and-fit affiliate piece for $siteName ($niche).")
$promptLines.Add("Reader profile: primary = [$primary], secondary = [$secondary], EXPLICITLY EXCLUDED = [$excluded].")
$promptLines.Add("Brand tone: $brandTone.")
$promptLines.Add("")
$promptLines.Add("## Piece context")
$promptLines.Add("")
$promptLines.Add("- Product: $ProductName ($Brand)")
$promptLines.Add("- Piece type: buyers-guide")
$promptLines.Add("- Slug: $Slug")
$promptLines.Add("- Pub date: $pubDate")
$promptLines.Add("")
if ($forbiddenSection) {
    $promptLines.Add("## Voice doctrine (MANDATORY — never produce these phrases)")
    $promptLines.Add("")
    $promptLines.Add($forbiddenSection)
    $promptLines.Add("")
} else {
    $promptLines.Add("## Voice doctrine (MANDATORY — never produce these phrases)")
    $promptLines.Add("")
    $promptLines.Add("<!-- WARNING: 'Forbidden phrases' section not found in voice doctrine. -->")
    $promptLines.Add("")
}
if ($preferredSection) {
    $promptLines.Add($preferredSection)
    $promptLines.Add("")
} else {
    $promptLines.Add("## Preferred framings")
    $promptLines.Add("")
    $promptLines.Add("<!-- WARNING: 'Preferred framings' section not found in voice doctrine. -->")
    $promptLines.Add("")
}
$promptLines.Add("## Your task")
$promptLines.Add("")
$promptLines.Add("Draft the markdown body of ``$Slug.md`` per the scaffold below. The ``## Bottom Line`` section")
$promptLines.Add("STAYS as the placeholder (``> _The Bottom Line is being written._``) — the publisher writes")
$promptLines.Add("that themselves. Fill ``## Who This Is For`` and all other sections, drawing only from spec")
$promptLines.Add("sheets, manufacturer documentation, and aggregated owner reviews. Cite sources where you")
$promptLines.Add("make specific claims. This is a buyer's guide — frame as research synthesis, not a personal")
$promptLines.Add("review.")
$promptLines.Add("")
$promptLines.Add("## Scaffold to fill")
$promptLines.Add("")
$promptLines.Add('```markdown')
$promptLines.Add($content)
$promptLines.Add('```')
$promptLines.Add("")

$promptBody = ($promptLines -join "`n")
Set-Content -Path $promptPath -Value $promptBody -NoNewline

Write-Host "[ok] Wrote $promptPath"

# Delegate the KV write to add-link.ps1 unless suppressed.
if (-not $NoKV) {
    $addLink = Join-Path $PSScriptRoot "add-link.ps1"
    if (-not (Test-Path $addLink)) {
        Write-Host "[warn] add-link.ps1 not found at $addLink — skipping KV write." -ForegroundColor Yellow
    } else {
        Write-Host "[..] Invoking add-link.ps1 for KV entry"
        $addLinkArgs = @(
            "-Site",     $Site,
            "-Slug",     $Slug,
            "-Url",      $AmazonUrl,
            "-Merchant", "amazon"
        )
        if ($Tag -and $Tag.Trim().Length -gt 0) {
            $addLinkArgs += @("-Tag", $Tag)
        }

        & $addLink @addLinkArgs
        if ($LASTEXITCODE -ne 0) {
            Write-Host "[warn] add-link.ps1 exited $LASTEXITCODE — markdown was still written." -ForegroundColor Yellow
            Write-Host "       Fix the KV entry by re-running scripts/add-link.ps1 directly." -ForegroundColor Yellow
        }
    }
} else {
    Write-Host "[..] -NoKV set; skipped KV write."
}

Write-Host ""
Write-Host "Next:"
Write-Host "  - Open $promptPath"
Write-Host "  - Paste its contents into Claude to draft the body"
Write-Host "  - Review the AI output against docs/voice-doctrine.md"
Write-Host "  - Write your ``## Bottom Line`` section in sites/$Site/src/content/buyers-guides/$Slug.md"
Write-Host "  - Run: pwsh scripts/lint-voice.ps1 sites/$Site/src/content/buyers-guides/$Slug.md (before commit)"
Write-Host "  - Buyer's guides are NOT personal reviews — frame as research synthesis"
Write-Host "  - Verify the cloaked link: <apex>/go/$Slug should 302 to $AmazonUrl (post-publish)"
Write-Host "  - Commit + push when ready: git add . && git commit -m `"feat: add $Slug buyer's guide`""

<#
.SYNOPSIS
  Magic Go per-site readiness gate. Reports which sites are content-ready
  for an autonomous scaffold run; skips (with reasons) those that are not.

.DESCRIPTION
  Build step 1 of the Magic Go orchestrator (docs/brainstorms/2026-05-29-magic-go-v1-plan.md).
  Deterministic, no Claude / no API calls. Run standalone for a table, or with
  -Json for machine output consumed by the runner + /aff Step 2 survey.

  A site at sites/<slug>/ is CONTENT-READY iff ALL hold:
    R1  src/data/site-config.json exists + parses
    R2  niche + reader segments + feature axes all resolvable (via the
        two-shape adapter — works on MWC flat AND DTP nested)
    R3  src/content/config.ts exists + defines reviews + buyers-guides
        collections, both carrying bottomLine in the schema
    R4  src/pages/reviews/[...slug].astro AND
        src/pages/buyers-guides/[...slug].astro both exist
    R5  the DRAFT/noindex gate is live in the PAGE template (CE finding V14:
        the robots flip lives in the page template, NOT ReviewArticle.astro) —
        grep the page template for noindex + bottomLine co-occurrence

  Also reports (NOT a gate, CE finding V7): whether the site can monetize
  (non-empty affiliate.amazonTag). A ready-but-non-monetizing site is flagged
  so the orchestrator can warn before pouring a run into a $0 site.

.PARAMETER Site
  Optional. Restrict to one slug.

.PARAMETER Json
  Emit JSON to stdout (for the runner). Default: human-readable table.

.EXAMPLE
  pwsh scripts/magic-go-readiness.ps1
  pwsh scripts/magic-go-readiness.ps1 -Json
  pwsh scripts/magic-go-readiness.ps1 -Site detailerpicks
#>

param(
  [string]$Site = "",
  [switch]$Json
)

$ErrorActionPreference = "Stop"
$repoRoot = Split-Path -Parent $PSScriptRoot
$sitesDir = Join-Path $repoRoot "sites"
. (Join-Path $PSScriptRoot "lib/site-config.ps1")

# askbigchew is a separate Next.js repo — never a Magic Go target (CLAUDE.md).
$EXCLUDE = @("askbigchew")

$siteDirs = if ($Site) {
  @(Get-Item -LiteralPath (Join-Path $sitesDir $Site) -ErrorAction SilentlyContinue)
} else {
  Get-ChildItem -Directory $sitesDir | Where-Object { $EXCLUDE -notcontains $_.Name }
}

$results = @()

foreach ($sd in $siteDirs) {
  if (-not $sd) { continue }
  $slug = $sd.Name
  $src = Join-Path $sd.FullName "src"
  $failed = @()
  $notes = @()

  # R1 — config exists + parses
  $configPath = Join-Path $src "data/site-config.json"
  $config = Get-SiteConfigObject -ConfigPath $configPath
  if ($null -eq $config) {
    $failed += "R1"
    $notes += "no parseable src/data/site-config.json"
  }

  # R2 — niche + segments + axes resolvable (adapter handles both shapes)
  if ($config) {
    $missing = @()
    if (-not (Get-SiteConfigField -Config $config -Field 'niche'))       { $missing += "niche" }
    if (-not (Get-SiteConfigField -Config $config -Field 'segments'))    { $missing += "segments" }
    if (-not (Get-SiteConfigField -Config $config -Field 'featureAxes')) { $missing += "featureAxes" }
    if ($missing.Count -gt 0) {
      $failed += "R2"
      $notes += "config missing: $($missing -join ', ')"
    }
  }

  # R3 — content collections wired with bottomLine
  $configTs = Join-Path $src "content/config.ts"
  if (-not (Test-Path -LiteralPath $configTs)) {
    $failed += "R3"; $notes += "no src/content/config.ts"
  } else {
    $ts = Get-Content -Raw -LiteralPath $configTs
    $hasReviews = $ts -match 'reviews\s*[:=]' -or $ts -match '"reviews"'
    $hasGuides  = $ts -match 'buyersGuides|buyers-guides|"buyers-guides"'
    $hasBottom  = $ts -match 'bottomLine'
    if (-not ($hasReviews -and $hasGuides)) { $failed += "R3"; $notes += "config.ts missing reviews and/or buyers-guides collection" }
    elseif (-not $hasBottom) { $failed += "R3"; $notes += "config.ts has no bottomLine in schema (old scaffold)" }
  }

  # R4 — both page templates exist
  $reviewTpl = Join-Path $src "pages/reviews/[...slug].astro"
  $guideTpl  = Join-Path $src "pages/buyers-guides/[...slug].astro"
  if (-not (Test-Path -LiteralPath $reviewTpl)) { $failed += "R4"; $notes += "no reviews/[...slug].astro" }
  if (-not (Test-Path -LiteralPath $guideTpl))  { $failed += "R4"; $notes += "no buyers-guides/[...slug].astro" }

  # R5 — DRAFT/noindex gate live in the PAGE template (keyed off bottomLine)
  foreach ($tpl in @($reviewTpl, $guideTpl)) {
    if (Test-Path -LiteralPath $tpl) {
      $t = Get-Content -Raw -LiteralPath $tpl
      if (-not (($t -match 'noindex') -and ($t -match 'bottomLine'))) {
        $failed += "R5"
        $notes += "no noindex+bottomLine gate in $((Split-Path $tpl -Leaf))"
      }
    }
  }

  $failed = $failed | Select-Object -Unique
  $ready = ($failed.Count -eq 0)

  # V7 monetization flag (not a gate)
  $tag = if ($config) { Get-SiteConfigField -Config $config -Field 'amazonTag' } else { $null }
  $monetizable = [bool]($tag -and $tag.Trim() -ne "")
  if ($ready -and -not $monetizable) {
    $notes += "READY BUT NON-MONETIZING: affiliate.amazonTag is empty (links earn `$0 until set)"
  }

  $results += [PSCustomObject]@{
    slug          = $slug
    ready         = $ready
    failed_checks = @($failed)
    monetizable   = $monetizable
    amazonTag     = $tag
    notes         = ($notes -join "; ")
  }
}

if ($Json) {
  $results | ConvertTo-Json -Depth 5
  exit 0
}

# Human-readable table
Write-Host ""
Write-Host "Magic Go readiness — $(Get-Date -Format 'yyyy-MM-dd HH:mm')" -ForegroundColor Cyan
Write-Host ""
foreach ($r in $results) {
  if ($r.ready -and $r.monetizable) {
    Write-Host ("  [READY] {0}" -f $r.slug) -ForegroundColor Green
  } elseif ($r.ready) {
    Write-Host ("  [READY*] {0}  (non-monetizing)" -f $r.slug) -ForegroundColor Yellow
  } else {
    Write-Host ("  [SKIP]  {0}  failed: {1}" -f $r.slug, ($r.failed_checks -join ',')) -ForegroundColor DarkGray
  }
  if ($r.notes) { Write-Host ("          {0}" -f $r.notes) -ForegroundColor DarkGray }
}
Write-Host ""
$readyCount = ($results | Where-Object { $_.ready }).Count
Write-Host ("{0} of {1} site(s) content-ready." -f $readyCount, $results.Count) -ForegroundColor Cyan
exit 0

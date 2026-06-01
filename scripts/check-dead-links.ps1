<#
.SYNOPSIS
  Post-build dead-internal-link check across all built sites.

.DESCRIPTION
  Scans each sites/<slug>/dist for root-relative internal links (href="/...")
  and flags any that resolve to no built page (a 404). Catches the failure class
  that bit the rebuild 2026-06-01: body-fill authored bare-pillar inline links
  like [Controllers](/controllers) when the real page is /topics/controllers/.

  EXCLUDES /go/* — those are link-cloaker Worker routes served at the edge, not
  static files (they 404 in a local dist scan but work in production; every site
  domain is routed in workers/link-cloaker/wrangler.toml).

  Run AFTER `pnpm -r build` (or per-site build). Exits 1 if any dead link found,
  so it can gate the Magic Go pre-publish QA or a manual pre-merge check.

.EXAMPLE
  pwsh scripts/check-dead-links.ps1
  pwsh scripts/check-dead-links.ps1 -Site gameovergear
#>
param(
  [string]$Site = ""
)

$ErrorActionPreference = "Stop"
$repo = Split-Path -Parent $PSScriptRoot
$sitesDir = Join-Path $repo "sites"

$siteDirs = if ($Site) {
  @(Join-Path $sitesDir $Site)
} else {
  Get-ChildItem -Path $sitesDir -Directory | ForEach-Object { $_.FullName }
}

$assetExt = @('.xml', '.txt', '.ico', '.png', '.jpg', '.jpeg', '.svg', '.webp', '.gif', '.json', '.css', '.js', '.pdf', '.woff', '.woff2')
$totalDead = 0
$report = @()

foreach ($sd in $siteDirs) {
  $slug = Split-Path $sd -Leaf
  $dist = Join-Path $sd "dist"
  if (-not (Test-Path $dist)) {
    Write-Host "skip $slug (no dist - build first)" -ForegroundColor DarkGray
    continue
  }

  # Collect every distinct root-relative href across the site's HTML.
  $hrefs = New-Object System.Collections.Generic.HashSet[string]
  Get-ChildItem -Path $dist -Recurse -Filter *.html | ForEach-Object {
    $content = Get-Content $_.FullName -Raw
    foreach ($m in [regex]::Matches($content, 'href="(/[^"]*)"')) {
      [void]$hrefs.Add($m.Groups[1].Value)
    }
  }

  $dead = @()
  foreach ($h in $hrefs) {
    # strip query/hash
    $p = ($h -split '[?#]')[0]
    if ([string]::IsNullOrWhiteSpace($p) -or $p -eq "/") { continue }
    if ($p -like "/go/*") { continue }                       # cloaker Worker routes
    $ext = [System.IO.Path]::GetExtension($p).ToLower()
    if ($assetExt -contains $ext) { continue }

    $clean = $p.Trim("/")
    $cands = @(
      (Join-Path $dist $clean),
      (Join-Path $dist (Join-Path $clean "index.html")),
      (Join-Path $dist "$clean.html")
    )
    $found = $false
    foreach ($c in $cands) { if (Test-Path $c) { $found = $true; break } }
    if (-not $found) { $dead += $p }
  }

  if ($dead.Count -gt 0) {
    $totalDead += $dead.Count
    Write-Host "DEAD LINKS in $slug ($($dead.Count)):" -ForegroundColor Red
    $dead | Sort-Object | ForEach-Object {
      Write-Host "  404 -> $_" -ForegroundColor Red
      $report += "$slug : $_"
    }
  } else {
    Write-Host "OK $slug - no dead internal links" -ForegroundColor Green
  }
}

Write-Host ""
if ($totalDead -gt 0) {
  Write-Host "FAIL: $totalDead dead internal link(s) found. Fix the source links (point to a real built route, e.g. /topics/<slug>/)." -ForegroundColor Red
  exit 1
} else {
  Write-Host "PASS: no dead internal links across $((@($siteDirs)).Count) site(s)." -ForegroundColor Green
  exit 0
}

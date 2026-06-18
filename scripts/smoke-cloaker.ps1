<#
.SYNOPSIS
  Live smoke-test of every /go/<slug> affiliate cloaker route against production.

.DESCRIPTION
  check-dead-links.ps1 deliberately SKIPS /go/* (those are link-cloaker Worker
  routes, not static files). That left the highest-revenue links in the portfolio
  with ZERO automated coverage — and on 2026-06-18 we found 24 review-page cloaker
  routes across 4 sites returning 404 because their KV keys were never registered.
  This script closes that gap.

  For each built site it:
    1. derives the production origin from dist/sitemap-index.xml (<loc>),
    2. collects every distinct href="/go/<slug>" in the built HTML,
    3. requests https://<origin>/go/<slug> WITHOUT following the redirect and
       confirms a 301/302 (a live, registered cloaker route). Anything else
       (404 = missing KV key, 5xx, etc.) is reported as broken.

  Run AFTER `pnpm -r build` (needs dist/ to know which routes exist). No wrangler
  or Cloudflare auth required — it only reads public production responses.
  Exits 1 if any route is broken, so it can gate a post-deploy check.

.EXAMPLE
  pwsh scripts/smoke-cloaker.ps1
  pwsh scripts/smoke-cloaker.ps1 -Site fussybean
#>
param(
  [string]$Site = "",
  [int]$TimeoutSec = 20
)

$ErrorActionPreference = "Stop"
$repo = Split-Path -Parent $PSScriptRoot
$sitesDir = Join-Path $repo "sites"

$siteDirs = if ($Site) {
  @(Join-Path $sitesDir $Site)
} else {
  Get-ChildItem -Path $sitesDir -Directory | ForEach-Object { $_.FullName }
}

$curl = (Get-Command curl.exe -ErrorAction SilentlyContinue)
if (-not $curl) {
  Write-Host "[err] curl.exe not found on PATH." -ForegroundColor Red
  exit 1
}

$totalBroken = 0
$totalChecked = 0
$sitesScanned = 0

foreach ($sd in $siteDirs) {
  $slug = Split-Path $sd -Leaf
  $dist = Join-Path $sd "dist"
  if (-not (Test-Path $dist)) {
    Write-Host "skip $slug (no dist - build first)" -ForegroundColor DarkGray
    continue
  }

  # Derive production origin from the sitemap index (<loc>https://host/sitemap-0.xml</loc>).
  $sitemapIndex = Join-Path $dist "sitemap-index.xml"
  if (-not (Test-Path $sitemapIndex)) {
    Write-Host "skip $slug (no sitemap-index.xml)" -ForegroundColor DarkGray
    continue
  }
  $idxRaw = Get-Content $sitemapIndex -Raw
  $locMatch = [regex]::Match($idxRaw, '<loc>(https?://[^/<]+)')
  if (-not $locMatch.Success) {
    Write-Host "skip $slug (could not read origin from sitemap-index.xml)" -ForegroundColor DarkGray
    continue
  }
  $origin = $locMatch.Groups[1].Value

  # Collect every distinct /go/<slug> referenced in the built HTML.
  $routes = New-Object System.Collections.Generic.HashSet[string]
  Get-ChildItem -Path $dist -Recurse -Filter *.html | ForEach-Object {
    $content = Get-Content $_.FullName -Raw
    foreach ($m in [regex]::Matches($content, 'href="(/go/[^"]+)"')) {
      [void]$routes.Add(($m.Groups[1].Value -split '[?#]')[0])
    }
  }

  $sitesScanned++
  if ($routes.Count -eq 0) {
    Write-Host "OK $slug - no /go/ routes in build" -ForegroundColor DarkGray
    continue
  }

  $broken = @()
  foreach ($r in $routes) {
    $url = "$origin$r"
    $totalChecked++
    # -o NUL discards body; -w prints status; NO -L so we see the 302 itself.
    $code = & curl.exe -s -o NUL -w "%{http_code}" --max-time $TimeoutSec $url
    if ($code -ne "301" -and $code -ne "302") {
      $broken += "$code  $r"
    }
  }

  if ($broken.Count -gt 0) {
    $totalBroken += $broken.Count
    Write-Host "BROKEN cloaker routes in $slug ($($broken.Count) / $($routes.Count)):" -ForegroundColor Red
    $broken | Sort-Object | ForEach-Object { Write-Host "  $_  ($origin)" -ForegroundColor Red }
  } else {
    Write-Host "OK $slug - all $($routes.Count) cloaker routes resolve (302)" -ForegroundColor Green
  }
}

Write-Host ""
if ($totalBroken -gt 0) {
  Write-Host "FAIL: $totalBroken broken cloaker route(s) across $sitesScanned site(s). Register the missing KV keys with scripts/add-link.ps1 (destination is each piece's affiliate.amazon frontmatter)." -ForegroundColor Red
  exit 1
} else {
  Write-Host "PASS: all $totalChecked cloaker route(s) across $sitesScanned site(s) resolve." -ForegroundColor Green
  exit 0
}

<#
.SYNOPSIS
  Pre-commit gate: every affiliate URL on sites/<site>/ must use the
  expected `tag=` value declared in that site's config.

.DESCRIPTION
  Catches the failure mode that almost bit us 2026-05-24: every DTP
  affiliate link was using `tag=mywildlifecam-20` because the scaffolder
  defaulted to one global tag and the per-site override was never wired.

  Source of truth: each site declares its expected tag in
  `sites/<slug>/src/data/site-config.json` under `affiliate.amazonTag`.
  If `affiliate.amazonTag` is empty/missing, this script treats the site
  as "not yet configured" and SKIPS validation for it — that way the
  current state (DTP shares mywildlifecam-20 because no DTP tag has been
  set up yet on Amazon Associates) doesn't fail the lint, but the moment
  a site declares its own tag the lint enforces it.

  Greps every `tag=<value>` substring in:
    - sites/<slug>/src/content/**/*.md
    - sites/<slug>/src/**/*.astro
  Fails if any tag value doesn't match the site's declared `amazonTag`.

.PARAMETER Site
  Optional. Restrict scan to one site slug.

.EXAMPLE
  pwsh scripts/lint-affiliate-tags.ps1
  pwsh scripts/lint-affiliate-tags.ps1 -Site detailerpicks
#>

param([string]$Site = "")

$ErrorActionPreference = "Stop"
$repoRoot = Split-Path -Parent $PSScriptRoot
$sitesDir = Join-Path $repoRoot "sites"

$siteDirs = if ($Site) {
  @(Get-Item (Join-Path $sitesDir $Site) -ErrorAction SilentlyContinue)
} else {
  Get-ChildItem -Directory $sitesDir
}

$findings = @()
$checked = 0

foreach ($siteDir in $siteDirs) {
  if (-not $siteDir) { continue }
  $slug = $siteDir.Name

  $configPath = Join-Path $siteDir.FullName "src/data/site-config.json"
  if (-not (Test-Path $configPath)) {
    Write-Host "[$slug] no site-config.json — skipping" -ForegroundColor DarkGray
    continue
  }

  $config = Get-Content -Raw -LiteralPath $configPath | ConvertFrom-Json
  $expectedTag = $config.affiliate.amazonTag
  if (-not $expectedTag -or $expectedTag -eq "") {
    Write-Host "[$slug] affiliate.amazonTag not declared — skipping (set it in site-config.json to enforce)" -ForegroundColor DarkGray
    continue
  }

  # Find every `tag=<value>` in markdown + astro under this site
  $files = Get-ChildItem -Recurse -Path (Join-Path $siteDir.FullName "src") -Include "*.md","*.astro" -File
  foreach ($f in $files) {
    $content = Get-Content -Raw -LiteralPath $f.FullName
    $matches = [regex]::Matches($content, 'tag=(?<v>[a-zA-Z0-9_-]+)')
    foreach ($m in $matches) {
      $checked++
      $found = $m.Groups['v'].Value
      if ($found -ne $expectedTag) {
        $findings += [PSCustomObject]@{
          Site = $slug
          File = $f.FullName.Replace($repoRoot, '').TrimStart('\','/')
          Found = $found
          Expected = $expectedTag
        }
      }
    }
  }
}

Write-Host ""
Write-Host "Scanned $checked tag= occurrence(s)." -ForegroundColor Cyan

if ($findings.Count -eq 0) {
  Write-Host "All affiliate tags PASS (or sites haven't declared one yet)." -ForegroundColor Green
  exit 0
}

Write-Host ""
Write-Host "FAIL: $($findings.Count) tag mismatch(es):" -ForegroundColor Red
foreach ($f in $findings) {
  Write-Host "  [$($f.Site)] $($f.File)" -ForegroundColor Yellow
  Write-Host "    expected: tag=$($f.Expected)" -ForegroundColor Green
  Write-Host "    found:    tag=$($f.Found)" -ForegroundColor Red
}
exit 1

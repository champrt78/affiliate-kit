<#
.SYNOPSIS
  Content-frontmatter safeguard lint. Catches two failure classes that bit us
  during the 2026-05-30 live review BEFORE they ship:

    1. Missing/invalid `pillar:` on a site that has topic/[pillar] pages. A
       guide/review without a `pillar:` matching a nav-pillar slug never appears
       on its section hub -> the hub renders "coming soon" even though content
       exists. (Root cause of the gog consoles/handhelds coming-soon bug.)

    2. `description:` longer than 160 chars. The content schema caps it at
       z.string().max(160); over-length descriptions pass voice-lint but FAIL
       `astro build`. Catch it at commit, not at deploy.

  Sites WITHOUT a src/pages/topics/[pillar].astro (currently mywildlifecam,
  detailerpicks) are skipped for the pillar check — they don't have section hubs,
  so a missing pillar can't strand content. The description check applies to all.

.PARAMETER Path   Optional single file to check. Default: every content .md.
.EXAMPLE
  pwsh scripts/lint-content-frontmatter.ps1
#>
param([string]$Path)

$ErrorActionPreference = "Stop"
$repoRoot = Split-Path -Parent $PSScriptRoot

function Get-Frontmatter([string]$p) {
  $raw = Get-Content -Raw -LiteralPath $p
  $m = [regex]::Match($raw, '(?s)^---\r?\n(.*?)\r?\n---')
  if ($m.Success) { return $m.Groups[1].Value } else { return "" }
}

# Per-site: does it have section hubs, and what pillar slugs are valid?
$siteInfo = @{}
function Get-SiteInfo([string]$slug) {
  if ($siteInfo.ContainsKey($slug)) { return $siteInfo[$slug] }
  $hasHubs = Test-Path (Join-Path $repoRoot "sites/$slug/src/pages/topics/[pillar].astro")
  $valid = @()
  $cfg = Join-Path $repoRoot "sites/$slug/src/data/site-config.json"
  if (Test-Path $cfg) {
    $c = Get-Content -Raw -LiteralPath $cfg | ConvertFrom-Json
    $valid = @($c.navigation.pillars | ForEach-Object { $_.slug })
  }
  $info = [pscustomobject]@{ HasHubs=$hasHubs; ValidPillars=$valid }
  $siteInfo[$slug] = $info
  return $info
}

if ($Path) {
  $files = @(Get-Item -LiteralPath $Path)
} else {
  $files = Get-ChildItem -Recurse -LiteralPath (Join-Path $repoRoot "sites") -Filter *.md -ErrorAction SilentlyContinue |
           Where-Object { $_.FullName -match '[\\/]src[\\/]content[\\/](buyers-guides|reviews)[\\/]' }
}

$issues = @()
$scanned = 0
foreach ($f in $files) {
  $scanned++
  $fm = Get-Frontmatter $f.FullName
  if (-not $fm) { continue }
  $rel = $f.FullName.Replace($repoRoot, "").TrimStart('\','/') -replace '\\','/'
  $slug = if ($rel -match '^sites/([^/]+)/') { $Matches[1] } else { "" }

  # --- description length ---
  $dm = [regex]::Match($fm, '(?m)^description:\s*"(.*)"\s*$')
  if ($dm.Success -and $dm.Groups[1].Value.Length -gt 160) {
    $issues += "  $rel : description is $($dm.Groups[1].Value.Length) chars (max 160 - will FAIL astro build)"
  }

  # --- pillar (only for sites with section hubs) ---
  if ($slug) {
    $info = Get-SiteInfo $slug
    if ($info.HasHubs) {
      $pm = [regex]::Match($fm, '(?m)^pillar:\s*"?([a-z0-9-]+)"?')
      if (-not $pm.Success) {
        $issues += "  $rel : missing 'pillar:' (site has section hubs; content will be stranded -> 'coming soon')"
      } elseif ($info.ValidPillars -notcontains $pm.Groups[1].Value) {
        $issues += "  $rel : pillar '$($pm.Groups[1].Value)' is not a nav pillar slug for $slug [valid: $($info.ValidPillars -join ', ')]"
      }
    }
  }
}

Write-Host ""
Write-Host "Scanned $scanned content file(s) for frontmatter (pillar + description)."
if ($issues.Count -eq 0) {
  Write-Host "All content frontmatter PASS." -ForegroundColor Green
  exit 0
} else {
  Write-Host "FAIL: $($issues.Count) frontmatter issue(s):" -ForegroundColor Red
  $issues | ForEach-Object { Write-Host $_ -ForegroundColor Yellow }
  exit 1
}

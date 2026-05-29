<#
.SYNOPSIS
  Magic Go allocator — splits N pieces across content-ready sites by
  cadence-deficit, with a per-site cap (CE finding V7).

.DESCRIPTION
  Build step 2 of the Magic Go orchestrator. Deterministic, no Claude/API.
  Calls magic-go-readiness.ps1 to get ready sites, computes each site's
  days-since-last-ship vs its cadence target, allocates N proportional to
  the deficit, with:
    - a FLOOR so no ready site gets zero (>=1 each),
    - a CAP so no single site absorbs the bulk of a run (default 60% of N),
      addressing the "22 of 25 into DTP" failure the CE review flagged,
    - integer rounding that sums exactly to N.

  Cadence targets (days): mywildlifecam 7, detailerpicks 18, satellites 180
  (matches aff.md). A site at/under cadence still gets the floor.

.PARAMETER N            Total pieces to allocate (default 25).
.PARAMETER CapFraction  Max fraction of N for any one site (default 0.6).
.PARAMETER Json         Emit JSON { site: count } for the runner.

.EXAMPLE
  pwsh scripts/magic-go-allocate.ps1 -N 25
  pwsh scripts/magic-go-allocate.ps1 -N 2 -Json
#>

param(
  [int]$N = 25,
  [double]$CapFraction = 0.6,
  [switch]$Json
)

$ErrorActionPreference = "Stop"
$repoRoot = Split-Path -Parent $PSScriptRoot
$sitesDir = Join-Path $repoRoot "sites"

$cadenceTarget = @{ mywildlifecam = 7; detailerpicks = 18 }   # default 180 for satellites
$today = Get-Date

# --- get ready sites from the readiness gate ---
$readyJson = pwsh -NoProfile -File (Join-Path $PSScriptRoot "magic-go-readiness.ps1") -Json
$readiness = $readyJson | ConvertFrom-Json
$readySites = @($readiness | Where-Object { $_.ready } | ForEach-Object { $_.slug })

if ($readySites.Count -eq 0) {
  if ($Json) { "{}" } else { Write-Host "No content-ready sites — nothing to allocate." -ForegroundColor Yellow }
  exit 0
}

# --- days since last ship per ready site (latest pubDate among non-DRAFT) ---
function Get-DaysSinceLastShip {
  param([string]$Slug)
  $contentDir = Join-Path $sitesDir "$Slug/src/content"
  if (-not (Test-Path -LiteralPath $contentDir)) { return 9999 }
  $mds = Get-ChildItem -Recurse -LiteralPath $contentDir -Filter "*.md" -File -ErrorAction SilentlyContinue
  $latest = $null
  foreach ($md in $mds) {
    $c = Get-Content -Raw -LiteralPath $md.FullName
    # frontmatter only
    $fm = if ($c -match '(?s)^---(.*?)\r?\n---') { $matches[1] } else { $c }
    # DRAFT iff bottomLine.verdict empty/placeholder
    $verdict = $null
    if ($fm -match '(?ms)^bottomLine:\s*\r?\n(?:\s+.*\r?\n)*?\s+verdict:\s*(.+)$') { $verdict = $matches[1].Trim().Trim("'`"") }
    $isDraft = (-not $verdict) -or ($verdict -eq "") -or ($verdict -match 'being written')
    if ($isDraft) { continue }
    if ($fm -match '(?m)^pubDate:\s*(\S+)') {
      try { $d = [datetime]::Parse($matches[1]) } catch { continue }
      if ($null -eq $latest -or $d -gt $latest) { $latest = $d }
    }
  }
  if ($null -eq $latest) { return 9999 }   # nothing shipped → maximally behind
  return [int]($today - $latest).TotalDays
}

$rows = foreach ($s in $readySites) {
  $target = if ($cadenceTarget.ContainsKey($s)) { $cadenceTarget[$s] } else { 180 }
  $since = Get-DaysSinceLastShip -Slug $s
  $deficit = [Math]::Max(0, $since - $target)
  [PSCustomObject]@{ slug = $s; since = $since; target = $target; deficit = $deficit }
}

# --- allocate N proportional to deficit, floor 1, cap CapFraction*N, sum=N ---
$count = $rows.Count
$cap = [Math]::Max(1, [int][Math]::Ceiling($CapFraction * $N))
$totalDeficit = ($rows | Measure-Object -Property deficit -Sum).Sum

$alloc = @{}
if ($totalDeficit -le 0) {
  # all at/under cadence → even split
  $base = [int][Math]::Floor($N / $count)
  foreach ($r in $rows) { $alloc[$r.slug] = $base }
} else {
  foreach ($r in $rows) {
    $alloc[$r.slug] = [int][Math]::Floor($N * ($r.deficit / $totalDeficit))
  }
}
# floor: every ready site gets >=1
foreach ($r in $rows) { if ($alloc[$r.slug] -lt 1) { $alloc[$r.slug] = 1 } }
# cap
foreach ($r in $rows) { if ($alloc[$r.slug] -gt $cap) { $alloc[$r.slug] = $cap } }

# reconcile to sum=N (respecting cap; give remainder to highest-deficit under-cap sites)
$sum = ($alloc.Values | Measure-Object -Sum).Sum
$ordered = $rows | Sort-Object -Property deficit -Descending
while ($sum -lt $N) {
  $bumped = $false
  foreach ($r in $ordered) { if ($alloc[$r.slug] -lt $cap) { $alloc[$r.slug]++; $sum++; $bumped = $true; if ($sum -ge $N) { break } } }
  if (-not $bumped) { break }   # everyone capped; can't place the rest
}
while ($sum -gt $N) {
  $reduced = $false
  foreach ($r in ($ordered | Sort-Object -Property deficit)) { if ($alloc[$r.slug] -gt 1) { $alloc[$r.slug]--; $sum--; $reduced = $true; if ($sum -le $N) { break } } }
  if (-not $reduced) { break }
}

if ($Json) {
  ($alloc | ConvertTo-Json)
  exit 0
}

Write-Host ""
Write-Host "Magic Go allocation — N=$N across $count ready site(s), cap=$cap (${CapFraction}xN)" -ForegroundColor Cyan
Write-Host ""
foreach ($r in $ordered) {
  Write-Host ("  {0,-16} {1,2} pieces   (last ship {2}d ago vs {3}d target, deficit {4})" -f $r.slug, $alloc[$r.slug], $r.since, $r.target, $r.deficit)
}
Write-Host ""
$placed = ($alloc.Values | Measure-Object -Sum).Sum
if ($placed -lt $N) { Write-Host ("WARNING: only placed {0}/{1} (all sites hit the {2}-cap). Raise CapFraction or add ready sites." -f $placed, $N, $cap) -ForegroundColor Yellow }
else { Write-Host ("Allocated {0}/{1}." -f $placed, $N) -ForegroundColor Green }
exit 0

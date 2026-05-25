<#
.SYNOPSIS
  Audit + fix product image URLs across all sites by querying Canopy
  for every Amazon-linked product and picking the most-square (truest
  product-shot) variant.

.DESCRIPTION
  Catches the failure mode the URL-aspect lint can't: Amazon's
  `mainImageUrl` is sometimes a marketing composite (e.g. 1280x2560
  with the product in the bottom half + scene art above) that has a
  passable aspect but renders as a tall sliver in 1:1-hint card
  containers. The fix is to pick from Canopy's `imageUrls` array,
  which usually contains the canonical 1000x1000 or 1080x1080 product
  shot.

  For every `image:` line in markdown product frontmatter, finds the
  associated `affiliateUrl:` Amazon URL, extracts the ASIN, queries
  Canopy for all image variants, decodes each via System.Drawing to
  get true dimensions, and picks the one with aspect closest to 1.0.
  If the current image is significantly less square than the best
  alternative (delta >= AspectImproveThreshold), recommends or applies
  a swap.

.PARAMETER Site
  Optional. Restrict to one site slug.

.PARAMETER Apply
  Switch. When set, rewrites markdown files in place. Without it, dry-run
  only (prints recommendations).

.PARAMETER AspectImproveThreshold
  Minimum aspect-distance-from-1.0 improvement required to recommend a
  swap. Defaults to 0.2 (e.g. swap a 0.5-aspect composite for a 1.0
  square, but don't swap a 0.85 for a 0.95 — diminishing returns).

.EXAMPLE
  pwsh scripts/audit-product-images.ps1                  # dry-run, all sites
  pwsh scripts/audit-product-images.ps1 -Site detailerpicks -Apply
#>

param(
  [string]$Site = "",
  [switch]$Apply,
  [double]$AspectImproveThreshold = 0.2
)

$ErrorActionPreference = "Stop"
Add-Type -AssemblyName System.Drawing

$repoRoot = Split-Path -Parent $PSScriptRoot
$sitesDir = Join-Path $repoRoot "sites"

# Canopy API key — same source as research-product.md
$envPath = "$HOME/.config/last30days/.env"
if (-not (Test-Path $envPath)) {
  Write-Host "ERROR: $envPath not found; need CANOPY_API_KEY for image alternates" -ForegroundColor Red
  exit 2
}
$canopyKey = (Get-Content $envPath | Where-Object { $_ -match '^CANOPY_API_KEY=' }) -replace '^CANOPY_API_KEY=', ''
if (-not $canopyKey) {
  Write-Host "ERROR: CANOPY_API_KEY missing from $envPath" -ForegroundColor Red
  exit 2
}

$browserUA = "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/130.0.0.0 Safari/537.36"

function Get-ImageAspect {
  param([string]$Url)
  try {
    # HEAD first — fail fast on stale Canopy URLs that 400/404. Some Canopy
    # results list image IDs Amazon no longer serves; we caught one of these
    # (611iZ-xzHIL._AC_SL1000_.jpg for GMAX32) shipping a broken card.
    $head = Invoke-WebRequest -Uri $Url -Method Head -UseBasicParsing -UserAgent $browserUA -TimeoutSec 10 -ErrorAction Stop
    if ($head.StatusCode -ne 200) { return $null }
    $tmp = [System.IO.Path]::GetTempFileName() + ".jpg"
    Invoke-WebRequest -Uri $Url -OutFile $tmp -UseBasicParsing -UserAgent $browserUA -TimeoutSec 15 -ErrorAction Stop | Out-Null
    $img = [System.Drawing.Image]::FromFile($tmp)
    $aspect = [math]::Round($img.Width / $img.Height, 3)
    $w = $img.Width; $h = $img.Height
    $img.Dispose()
    Remove-Item $tmp -ErrorAction SilentlyContinue
    return @{ aspect = $aspect; w = $w; h = $h }
  } catch {
    return $null
  }
}

function Get-CanopyImages {
  param([string]$Asin)
  $body = @{ query = "{ amazonProduct(input:{asinLookup:{asin:`"$Asin`"}}){ mainImageUrl imageUrls } }" } | ConvertTo-Json -Compress
  try {
    $resp = Invoke-WebRequest -Uri "https://graphql.canopyapi.co/" -Method Post -Headers @{ "API-KEY" = $canopyKey; "Content-Type" = "application/json" } -Body $body -UseBasicParsing -TimeoutSec 30 -ErrorAction Stop
    $data = ($resp.Content | ConvertFrom-Json).data.amazonProduct
    if (-not $data) { return $null }
    $all = @()
    if ($data.mainImageUrl) { $all += $data.mainImageUrl }
    if ($data.imageUrls)    { $all += $data.imageUrls }
    return $all | Select-Object -Unique
  } catch {
    Write-Host "  Canopy lookup failed for $Asin : $($_.Exception.Message.Split([Environment]::NewLine)[0])" -ForegroundColor DarkYellow
    return $null
  }
}

# Walk site content markdown
$mdFiles = if ($Site) {
  Get-ChildItem -Recurse -Path (Join-Path $sitesDir "$Site/src/content") -Filter "*.md"
} else {
  Get-ChildItem -Recurse -Path $sitesDir -Filter "*.md" |
    Where-Object { $_.FullName -match "[/\\]src[/\\]content[/\\]" }
}

$swapCount = 0
$checkedCount = 0
$skipCount = 0

foreach ($file in $mdFiles) {
  $relPath = $file.FullName.Replace($repoRoot, '').TrimStart('\','/')
  $content = Get-Content -Raw -LiteralPath $file.FullName

  # Find pairs of (affiliateUrl OR amazon, then image) lines in order
  # Match each Amazon affiliate URL and the image: line that follows it
  $pattern = '(?ms)(?:affiliateUrl|amazon):\s*"https://www\.amazon\.com[^"]*?/dp/(?<asin>[A-Z0-9]{10})[^"]*"\s*(?:\r?\n[^\r\n]*)*?\r?\n\s+image:\s*"(?<imgurl>https?://[^"]+)"'
  $matches = [regex]::Matches($content, $pattern)

  if ($matches.Count -eq 0) { continue }

  Write-Host ""
  Write-Host "$relPath" -ForegroundColor Cyan

  foreach ($m in $matches) {
    $asin = $m.Groups['asin'].Value
    $currentUrl = $m.Groups['imgurl'].Value
    $checkedCount++

    Write-Host "  ASIN $asin"
    Write-Host "    current: $currentUrl" -ForegroundColor DarkGray

    $currentDim = Get-ImageAspect -Url $currentUrl
    if (-not $currentDim) {
      Write-Host "    current URL failed to decode — skipping" -ForegroundColor Yellow
      $skipCount++
      continue
    }
    $currentDistFromSquare = [math]::Abs([math]::Log($currentDim.aspect))  # log-distance to 1.0
    Write-Host "    current dim: $($currentDim.w)x$($currentDim.h) aspect=$($currentDim.aspect) distFromSquare=$([math]::Round($currentDistFromSquare, 2))" -ForegroundColor DarkGray

    $candidates = Get-CanopyImages -Asin $asin
    if (-not $candidates) {
      Write-Host "    no Canopy alternates available — skipping" -ForegroundColor DarkYellow
      $skipCount++
      continue
    }

    $best = $null
    $bestDist = [double]::MaxValue
    foreach ($cu in $candidates) {
      $cd = Get-ImageAspect -Url $cu
      if (-not $cd) { continue }
      $dist = [math]::Abs([math]::Log($cd.aspect))
      if ($dist -lt $bestDist) {
        $bestDist = $dist
        $best = @{ url = $cu; dim = $cd; dist = $dist }
      }
    }

    if (-not $best) {
      Write-Host "    no decodable candidates from Canopy — skipping" -ForegroundColor DarkYellow
      $skipCount++
      continue
    }

    $improvement = $currentDistFromSquare - $best.dist
    if ($improvement -ge $AspectImproveThreshold -and $best.url -ne $currentUrl) {
      $swapCount++
      Write-Host "    >> SWAP recommended:" -ForegroundColor Green
      Write-Host "       best: $($best.url)" -ForegroundColor Green
      Write-Host "       best dim: $($best.dim.w)x$($best.dim.h) aspect=$($best.dim.aspect) (improvement $([math]::Round($improvement,2)))" -ForegroundColor Green

      if ($Apply) {
        # Rewrite the file
        $oldLine = "image: `"$currentUrl`""
        $newLine = "image: `"$($best.url)`""
        if ($content.Contains($oldLine)) {
          $content = $content.Replace($oldLine, $newLine)
          Write-Host "       APPLIED" -ForegroundColor Green
        } else {
          Write-Host "       WARN: could not find exact line to replace" -ForegroundColor Yellow
        }
      }
    } else {
      Write-Host "    current image is best available (or improvement < $AspectImproveThreshold)" -ForegroundColor DarkGray
    }
  }

  if ($Apply -and $matches.Count -gt 0) {
    Set-Content -LiteralPath $file.FullName -Value $content -NoNewline
  }
}

Write-Host ""
Write-Host "Audit complete." -ForegroundColor Cyan
Write-Host "  Checked:  $checkedCount products" -ForegroundColor Cyan
Write-Host "  Swappable: $swapCount" -ForegroundColor Cyan
Write-Host "  Skipped:  $skipCount" -ForegroundColor Cyan

if ($Apply) {
  Write-Host ""
  Write-Host "Files were modified. Re-run 'pwsh scripts/lint-product-images.ps1' and 'pnpm -r build' before commit." -ForegroundColor Yellow
} else {
  Write-Host ""
  Write-Host "Dry-run only. Re-run with -Apply to rewrite markdown." -ForegroundColor Yellow
}

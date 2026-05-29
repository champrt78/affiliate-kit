<#
.SYNOPSIS
  Rewrite every product `image:` URL in a content .md to Amazon's AUTHORITATIVE
  main image, sourced from the live /dp page's `colorImages.initial[0].hiRes`.

.DESCRIPTION
  The Canopy-based audit (audit-product-images.ps1) is the "right" tool but its
  free-tier quota (100 req/month) is exhausted as of 2026-05-29. This is the
  fallback: it firecrawl-scrapes each product's Amazon /dp page as rawHtml and
  extracts colorImages.initial[0].hiRes — the exact image Amazon renders as
  #landingImage, i.e. the true main product shot.

  WHY NOT just grep any media-amazon URL: Amazon pages are saturated with
  cross-sell/"customers also bought" images. Picking by document order or file
  size grabs a DIFFERENT product's image (confirmed 2026-05-29: a Browning page
  served Moultrie + Tactacam images in its carousel). colorImages.initial is
  keyed to THIS ASIN, so it is contamination-proof as long as the ASIN is right.

  Pairs each `affiliateUrl:`/`amazon:` ...dp/<ASIN>... line with the `image:`
  line that follows it (same pairing as audit-product-images.ps1), then rewrites
  that image URL. ASIN identity itself is the research step's job (verify the
  /dp title) — this only fixes the IMAGE for an already-validated ASIN.

.PARAMETER Path     Content .md file to fix (required).
.PARAMETER DryRun   Print what would change; don't write.

.EXAMPLE
  pwsh scripts/fix-product-images.ps1 -Path sites/fussybean/src/content/buyers-guides/best-coffee-grinder-for-beginners.md
#>
param(
  [Parameter(Mandatory)][string]$Path,
  [switch]$DryRun
)
$ErrorActionPreference = "Stop"

if (-not (Test-Path -LiteralPath $Path)) { Write-Host "File not found: $Path" -ForegroundColor Red; exit 1 }
$content = Get-Content -Raw -LiteralPath $Path

# Pair each Amazon /dp ASIN with the image: line that follows it.
$pattern = '(?:affiliateUrl|amazon):\s*"https://www\.amazon\.com[^"]*?/dp/(?<asin>[A-Z0-9]{10})[^"]*"\s*(?:\r?\n[^\r\n]*)*?\r?\n\s+(?:image|hero):\s*"(?<imgurl>https?://[^"]+)"'
$matches = [regex]::Matches($content, $pattern)
if ($matches.Count -eq 0) { Write-Host "No Amazon affiliateUrl+image pairs found in $Path." -ForegroundColor Yellow; exit 0 }

function Get-AmazonMainImage {
  param([string]$Asin)
  $tmp = [System.IO.Path]::GetTempFileName() + ".json"
  try {
    & firecrawl scrape "https://www.amazon.com/dp/$Asin" -f rawHtml -o $tmp *> $null
    if (-not (Test-Path $tmp)) { return $null }
    $raw = Get-Content -Raw -LiteralPath $tmp
    # firecrawl wraps rawHtml in JSON with escaped quotes: \"hiRes\":\"<url>\"
    $m = [regex]::Match($raw, '\\"hiRes\\":\\"(https://m\.media-amazon\.com/images/I/[^\\]+\.jpg)\\"')
    if ($m.Success) { return $m.Groups[1].Value }
    # fallback: unescaped form
    $m2 = [regex]::Match($raw, '"hiRes":"(https://m\.media-amazon\.com/images/I/[^"]+\.jpg)"')
    if ($m2.Success) { return $m2.Groups[1].Value }
    return $null
  } finally {
    Remove-Item $tmp -ErrorAction SilentlyContinue
  }
}

$changed = 0; $report = @()
foreach ($mt in $matches) {
  $asin = $mt.Groups['asin'].Value
  $oldUrl = $mt.Groups['imgurl'].Value
  $newUrl = Get-AmazonMainImage -Asin $asin
  if (-not $newUrl) { $report += "  $asin  -> LOOKUP FAILED (kept $oldUrl)"; continue }
  if ($newUrl -eq $oldUrl) { $report += "  $asin  -> already authoritative"; continue }
  $content = $content.Replace("`"$oldUrl`"", "`"$newUrl`"")
  $report += "  $asin  -> $newUrl"
  $changed++
}

Write-Host ""
Write-Host "fix-product-images: $Path" -ForegroundColor Cyan
$report | ForEach-Object { Write-Host $_ }
Write-Host ""

if ($DryRun) { Write-Host "DRY RUN — $changed change(s) not written." -ForegroundColor Yellow; exit 0 }
if ($changed -gt 0) {
  Set-Content -LiteralPath $Path -Value $content -NoNewline -Encoding utf8
  Write-Host "Wrote $changed image fix(es)." -ForegroundColor Green
} else {
  Write-Host "No changes needed." -ForegroundColor Green
}

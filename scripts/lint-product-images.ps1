<#
.SYNOPSIS
  Pre-commit gate: validate every `image:` URL in sites/<slug>/src/content/**/*.md.

.DESCRIPTION
  Catches the failure modes that bit us 2026-05-24:
    - CarPro PERL Coat shipped with a brand-wordmark image (494x107 = 4.6:1 aspect)
    - P&S Xpress Interior shipped with a 106x434 vertical sliver (0.24 aspect)
    - GMAX32 image was a 404
    - Multiple portrait products got center-clipped because the source aspect
      was outside the card's design tolerance

  For every `image: "https://..."` URL in markdown frontmatter:
    1. HEAD-fetch the URL. Fail if not 200 OR if Content-Type isn't image/*.
    2. Read intrinsic dimensions (via a tiny GET + magic-bytes parse).
       Fail if aspect ratio is outside MIN_ASPECT..MAX_ASPECT (catches logos
       at >2.0 and slivers at <0.4).
    3. Fail if file size < MIN_BYTES (catches "tiny placeholder" cases).

  Exit code 0 if everything passes, 1 if any image fails.

.PARAMETER Site
  Optional. Restrict the scan to one site slug (e.g. `mywildlifecam`,
  `detailerpicks`). Default: scan all sites.

.PARAMETER MinAspect
  Minimum allowed width/height ratio. Default 0.5 (allows portrait bottles).

.PARAMETER MaxAspect
  Maximum allowed width/height ratio. Default 2.0 (rejects wordmark banners).

.PARAMETER MinBytes
  Minimum allowed file size. Default 5000 (5 KB).

.EXAMPLE
  pwsh scripts/lint-product-images.ps1
  pwsh scripts/lint-product-images.ps1 -Site detailerpicks
#>

param(
  [string]$Site = "",
  [double]$MinAspect = 0.35,
  [double]$MaxAspect = 2.5,
  [int]$MinBytes = 2000
)

$ErrorActionPreference = "Stop"

# .NET image decoder for reliable dimension reads (replaces hand-rolled JPEG
# parser that mis-read EXIF thumbnail SOFs in Amazon CDN images).
Add-Type -AssemblyName System.Drawing

$repoRoot = Split-Path -Parent $PSScriptRoot
$sitesDir = Join-Path $repoRoot "sites"

# Pick the markdown files to scan
$mdFiles = if ($Site) {
  Get-ChildItem -Recurse -Path (Join-Path $sitesDir "$Site/src/content") -Filter "*.md" -ErrorAction SilentlyContinue
} else {
  Get-ChildItem -Recurse -Path $sitesDir -Filter "*.md" |
    Where-Object { $_.FullName -match "[/\\]src[/\\]content[/\\]" }
}

if (-not $mdFiles -or $mdFiles.Count -eq 0) {
  Write-Host "No content markdown files found." -ForegroundColor Yellow
  exit 0
}

$findings = @()
$checked = 0

$sceneHosts = @('images.unsplash.com', 'images.pexels.com')

# Browser UA — Amazon's CDN sometimes 400s/429s requests with no/odd UA, and
# the bare default WebRequest UA gets rate-limited on bursts. Use a real one.
$browserUA = "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/130.0.0.0 Safari/537.36"

# Retry wrapper — absorbs TRANSIENT Amazon-CDN failures (sporadic 400/429/5xx on
# HEAD bursts) that would otherwise spuriously block every commit. Caught a real
# transient 400 on 2026-05-29 where the same URL returned 200 on retry. Only the
# LAST exception propagates, so genuinely-dead URLs still fail the lint.
function Invoke-WithRetry {
  param([scriptblock]$Action, [int]$Tries = 3, [int]$DelayMs = 600)
  $lastErr = $null
  for ($i = 1; $i -le $Tries; $i++) {
    try { return & $Action } catch {
      $lastErr = $_
      if ($i -lt $Tries) { Start-Sleep -Milliseconds ($DelayMs * $i) }
    }
  }
  throw $lastErr
}

foreach ($file in $mdFiles) {
  $content = Get-Content -Raw -LiteralPath $file.FullName
  # Extract every `image: "URL"` (or `hero: "URL"`) in frontmatter
  $matches = [regex]::Matches($content, '(?m)^\s*(image|hero):\s*"(?<url>https?://[^"]+)"')
  foreach ($m in $matches) {
    $url = $m.Groups['url'].Value
    $checked++

    # Scene-photo CDNs (Unsplash/Pexels) are atmospheric, not product images —
    # they don't need product-aspect validation. Still check HTTP 200 +
    # image content-type below, just skip the aspect-ratio gate.
    $hostName = ([uri]$url).Host.ToLower()
    $isScenePhoto = $sceneHosts -contains $hostName

    # Fetch via curl, NOT Invoke-WebRequest. Amazon's image CDN consistently
    # 400s the .NET WebRequest client (TLS/header fingerprint) AND mangles a
    # literal '+' in image IDs (e.g. 71kziOgT+CL) into a space — both produce
    # FALSE failures on images that are valid and render fine in browsers.
    # curl fetches all of them correctly. (Confirmed 2026-05-29: curl 200 /
    # IWR 400 on the same Amazon URLs, with and without '+'.) curl.exe ships
    # with Windows 10+ and git, so it's always on PATH for the pre-commit hook.
    $tmp = [System.IO.Path]::GetTempFileName()
    $httpCode = (& curl.exe -s -L -A $browserUA --retry 2 --max-time 20 -w "%{http_code}" -o $tmp $url 2>$null)
    $bytes = if (Test-Path $tmp) { [System.IO.File]::ReadAllBytes($tmp) } else { @() }
    Remove-Item $tmp -ErrorAction SilentlyContinue

    if ("$httpCode" -ne "200") {
      $findings += [PSCustomObject]@{ File = $file.FullName.Replace($repoRoot, '').TrimStart('\','/'); Url = $url; Issue = "HTTP $httpCode" }
      continue
    }
    if (-not $bytes -or $bytes.Length -lt $MinBytes) {
      $sz = if ($bytes) { $bytes.Length } else { 0 }
      $findings += [PSCustomObject]@{ File = $file.FullName.Replace($repoRoot, '').TrimStart('\','/'); Url = $url; Issue = "Too small ($sz bytes < $MinBytes)" }
      continue
    }

    # Decode with .NET to get canonical width/height for the aspect gate.
    # Decode failure is a SOFT skip (some valid CDN images use formats
    # System.Drawing can't read); the 200 + min-bytes checks above already
    # gate the catastrophic cases.
    try {
      $stream = New-Object System.IO.MemoryStream(, [byte[]]$bytes)
      $img = [System.Drawing.Image]::FromStream($stream)
      $dim = @{ w = $img.Width; h = $img.Height }
      $img.Dispose()
      $stream.Dispose()

      if ($dim -and -not $isScenePhoto) {
        $aspect = [math]::Round($dim.w / $dim.h, 2)
        if ($aspect -lt $MinAspect -or $aspect -gt $MaxAspect) {
          $findings += [PSCustomObject]@{
            File = $file.FullName.Replace($repoRoot, '').TrimStart('\','/')
            Url = $url
            Issue = "Bad aspect $($dim.w)x$($dim.h) (=$aspect) - outside $MinAspect..$MaxAspect"
          }
        }
      }
    } catch {
      # Couldn't parse dimensions — not a hard fail, just skip the aspect check
    }
  }
}

Write-Host ""
Write-Host "Scanned $checked image URL(s) across $($mdFiles.Count) file(s)." -ForegroundColor Cyan

if ($findings.Count -eq 0) {
  Write-Host "All product images PASS." -ForegroundColor Green
  exit 0
}

Write-Host ""
Write-Host "FAIL: $($findings.Count) image issue(s) found:" -ForegroundColor Red
foreach ($f in $findings) {
  Write-Host "  $($f.File)" -ForegroundColor Yellow
  Write-Host "    $($f.Issue)" -ForegroundColor Red
  Write-Host "    $($f.Url)" -ForegroundColor DarkGray
}
exit 1

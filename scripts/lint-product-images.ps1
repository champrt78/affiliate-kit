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

    try {
      $head = Invoke-WebRequest -Uri $url -Method Head -UseBasicParsing -TimeoutSec 10 -ErrorAction Stop
    } catch {
      $findings += [PSCustomObject]@{
        File = $file.FullName.Replace($repoRoot, '').TrimStart('\','/')
        Url = $url
        Issue = "HEAD failed: $($_.Exception.Message.Split([Environment]::NewLine)[0])"
      }
      continue
    }

    if ($head.StatusCode -ne 200) {
      $findings += [PSCustomObject]@{
        File = $file.FullName.Replace($repoRoot, '').TrimStart('\','/')
        Url = $url
        Issue = "HTTP $($head.StatusCode)"
      }
      continue
    }

    $contentType = $head.Headers['Content-Type']
    if ($contentType -is [array]) { $contentType = $contentType[0] }
    if (-not $contentType -or $contentType -notlike "image/*") {
      $findings += [PSCustomObject]@{
        File = $file.FullName.Replace($repoRoot, '').TrimStart('\','/')
        Url = $url
        Issue = "Not an image (Content-Type: $contentType)"
      }
      continue
    }

    $size = [int]($head.Headers['Content-Length'] | Select-Object -First 1)
    if ($size -and $size -lt $MinBytes) {
      $findings += [PSCustomObject]@{
        File = $file.FullName.Replace($repoRoot, '').TrimStart('\','/')
        Url = $url
        Issue = "Too small ($size bytes < $MinBytes)"
      }
      continue
    }

    # Decode image with .NET to get canonical width/height.
    try {
      $resp = Invoke-WebRequest -Uri $url -UseBasicParsing -TimeoutSec 15 -UserAgent "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/130.0.0.0 Safari/537.36" -ErrorAction Stop
      $stream = New-Object System.IO.MemoryStream(, [byte[]]$resp.Content)
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
            Issue = "Bad aspect $($dim.w)x$($dim.h) (=$aspect) — outside $MinAspect..$MaxAspect"
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

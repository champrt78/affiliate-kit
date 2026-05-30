# For each ASIN, scrape colorImages, decode every candidate's dims, pick the one
# with aspect closest to 1.0 that passes the 0.35..2.5 gate. Prints "ASIN <url>".
param([string[]]$Asins)
$ErrorActionPreference = "Stop"
Add-Type -AssemblyName System.Drawing

function Get-AllHiRes([string]$Asin) {
  $tmp = [System.IO.Path]::GetTempFileName() + ".json"
  try {
    & firecrawl scrape "https://www.amazon.com/dp/$Asin" -f rawHtml -o $tmp *> $null
    if (-not (Test-Path $tmp)) { return @() }
    $raw = Get-Content -Raw -LiteralPath $tmp
    $urls = [System.Collections.Generic.HashSet[string]]::new()
    foreach ($m in [regex]::Matches($raw, '\\"hiRes\\":\\"(https://m\.media-amazon\.com/images/I/[^\\]+\.jpg)\\"')) { [void]$urls.Add($m.Groups[1].Value) }
    foreach ($m in [regex]::Matches($raw, '\\"large\\":\\"(https://m\.media-amazon\.com/images/I/[^\\]+\.jpg)\\"')) { [void]$urls.Add($m.Groups[1].Value) }
    return @($urls)
  } finally { Remove-Item $tmp -ErrorAction SilentlyContinue }
}

function Get-Dims([string]$Url) {
  $tmp = [System.IO.Path]::GetTempFileName() + ".jpg"
  try {
    & curl.exe -s -L -A "Mozilla/5.0" -o $tmp $Url *> $null
    if (-not (Test-Path $tmp) -or (Get-Item $tmp).Length -lt 2000) { return $null }
    $img = [System.Drawing.Image]::FromFile($tmp)
    $w = $img.Width; $h = $img.Height; $img.Dispose()
    return @{ w=$w; h=$h }
  } catch { return $null } finally { Remove-Item $tmp -ErrorAction SilentlyContinue }
}

foreach ($asin in $Asins) {
  $cands = Get-AllHiRes -Asin $asin
  $best = $null; $bestScore = [double]::MaxValue
  foreach ($u in $cands) {
    $d = Get-Dims -Url $u
    if (-not $d) { continue }
    $aspect = [double]$d.w / [double]$d.h
    if ($aspect -lt 0.35 -or $aspect -gt 2.5) { continue }
    $score = [math]::Abs([math]::Log($aspect))   # distance from square (log scale)
    if ($score -lt $bestScore) { $bestScore = $score; $best = $u; $bestDims = "$($d.w)x$($d.h)" }
  }
  if ($best) { Write-Output "$asin $best $bestDims" } else { Write-Output "$asin NONE" }
}

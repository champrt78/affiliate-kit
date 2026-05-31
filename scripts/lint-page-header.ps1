<#
.SYNOPSIS
  Pre-commit gate: a `.page-header__inner` rule must never declare `display: grid`
  or `grid-template-columns`.

.DESCRIPTION
  Catches the exact regression that bit us repeatedly (2026-05-20 .. 2026-05-31):
  the listing/topic page-header is a single-column stack (kicker -> title -> lede,
  full width). When a card-grid find/replace sweep, or a copy-pasted old template,
  puts a grid on `.page-header__inner`, the H1 gets trapped in one ~300px column or
  split into a 2-column layout with a big empty gap. Ray flagged "the header is only
  half the page" more than once. The layout CSS is duplicated across ~13 per-site
  pages, so the failure can reappear in any one of them.

  This lint blocks the failure SIGNATURE at commit time rather than relying on a
  shared component (the title typography is per-skin divergent, so the layout stays
  duplicated for now — but it can no longer drift into a grid).

  Block-aware: it isolates each `.page-header__inner { ... }` rule body (including
  ones inside an @media block, and compound selectors like `.a, .page-header__inner`)
  and fails if the body contains `display: grid` or `grid-template-columns`.

  Scans every sites/<slug>/src/**/*.astro. (Cheap — pure text scan, no network.)

.EXAMPLE
  pwsh scripts/lint-page-header.ps1
#>

$ErrorActionPreference = "Stop"
$repoRoot = Split-Path -Parent $PSScriptRoot
$sitesDir = Join-Path $repoRoot "sites"

# A .page-header__inner rule block: any selector group that mentions the class,
# then `{ <body, no nested braces> }`.
$blockRe = [regex]'(?<sel>[^{}\n;]*\.page-header__inner[^{}]*?)\{(?<body>[^{}]*)\}'
# The forbidden declarations inside that body.
$badRe   = [regex]'(?im)(display\s*:\s*grid\b|grid-template-columns\s*:)'

$findings = @()
$checked = 0

$files = Get-ChildItem -Recurse -Path $sitesDir -Include "*.astro" -File
foreach ($f in $files) {
  $content = Get-Content -Raw -LiteralPath $f.FullName
  if ($content -notmatch '\.page-header__inner') { continue }
  foreach ($m in $blockRe.Matches($content)) {
    $checked++
    $body = $m.Groups['body'].Value
    $bad = $badRe.Match($body)
    if ($bad.Success) {
      $findings += [PSCustomObject]@{
        File = $f.FullName.Replace($repoRoot, '').TrimStart('\','/')
        Rule = ($m.Groups['sel'].Value.Trim() + ' { ... }')
        Bad  = $bad.Value.Trim()
      }
    }
  }
}

Write-Host ""
Write-Host "Scanned $checked .page-header__inner rule block(s)." -ForegroundColor Cyan

if ($findings.Count -eq 0) {
  Write-Host "page-header layout PASS — no grid on .page-header__inner." -ForegroundColor Green
  exit 0
}

Write-Host ""
Write-Host "FAIL: $($findings.Count) .page-header__inner rule(s) declare a grid — this is the header-split regression:" -ForegroundColor Red
foreach ($x in $findings) {
  Write-Host "  $($x.File)" -ForegroundColor Yellow
  Write-Host "    rule:  $($x.Rule)" -ForegroundColor DarkGray
  Write-Host "    found: $($x.Bad)" -ForegroundColor Red
}
Write-Host ""
Write-Host "Fix: the page-header is a single-column stack. Remove display:grid / grid-template-columns" -ForegroundColor Green
Write-Host "from .page-header__inner (it should be a plain block: max-width + margin:0 auto only)." -ForegroundColor Green
exit 1

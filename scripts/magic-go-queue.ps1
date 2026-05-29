<#
.SYNOPSIS
  Render a Magic Go run's Bottom Line queue to dist/magic-go/queue.html.

.DESCRIPTION
  Build step 4 of the orchestrator. A dumb template-filler: reads the run
  manifest (the source of truth) and renders a static HTML page Ray opens in
  the morning to whip through verdicts. It does NOT call Claude — the 3 Bottom
  Line options were drafted during the run and stored in the manifest
  (options-drafted phase, CE finding V15).

  dist/ is gitignored and disposable — this view is regenerable from the
  manifest any time (CE finding: manifest is durable, queue.html is not).

.PARAMETER RunId   Run to render. Default: most recent.
.PARAMETER Open    Start-Process the rendered HTML.

.EXAMPLE
  pwsh scripts/magic-go-queue.ps1 -Open
#>

param(
  [string]$RunId = "",
  [switch]$Open
)

$ErrorActionPreference = "Stop"
$repoRoot = Split-Path -Parent $PSScriptRoot
. (Join-Path $PSScriptRoot "lib/magic-go-manifest.ps1")

if (-not $RunId) { $RunId = Find-LatestMagicGoRunId }
if (-not $RunId) { Write-Host "No Magic Go runs found." -ForegroundColor Yellow; exit 0 }

$m = Read-MagicGoManifest -RunId $RunId
if ($null -eq $m) { Write-Host "Manifest not found for run $RunId." -ForegroundColor Red; exit 1 }

function HtmlEnc([string]$s) {
  if ($null -eq $s) { return "" }
  return $s.Replace('&','&amp;').Replace('<','&lt;').Replace('>','&gt;').Replace('"','&quot;')
}

$ready      = @($m.pieces | Where-Object { @("ready","committed","verdict-written") -contains $_.status })
$quarantined= @($m.pieces | Where-Object { $_.status -eq "quarantined" })

$readyCards = foreach ($p in $ready) {
  $opts = ""
  if ($p.bottom_line_options -and $p.bottom_line_options.Count -gt 0) {
    $i = 0
    $opts = ($p.bottom_line_options | ForEach-Object {
      $i++
      "<div class='opt'><span class='optn'>Option $i</span><p>$(HtmlEnc $_)</p></div>"
    }) -join "`n"
  } else {
    $opts = "<p class='muted'>No options drafted (write your own).</p>"
  }
  $verdictBadge = if ($p.verdict_written) { "<span class='badge done'>verdict written</span>" } else { "<span class='badge todo'>needs verdict</span>" }
  $fileAbs = (Join-Path $repoRoot $p.content_path) -replace '\\','/'
  @"
<article class="card">
  <header>
    <span class="site">$(HtmlEnc $p.site) · $(HtmlEnc $p.type)</span>
    <h2>$(HtmlEnc $p.title)</h2>
    <span class="product">$(HtmlEnc $p.product)</span>
    $verdictBadge
  </header>
  <div class="opts">
    <h3>Bottom Line — pick / edit / write your own</h3>
    $opts
    <p class="supporting"><strong>Supporting:</strong> $(HtmlEnc $p.supporting)</p>
  </div>
  <footer><a href="file:///$fileAbs">Open the draft &rarr;</a></footer>
</article>
"@
}

$failCards = foreach ($p in $quarantined) {
  @"
<article class="card fail">
  <header>
    <span class="site">$(HtmlEnc $p.site) · $(HtmlEnc $p.type)</span>
    <h2>$(HtmlEnc $p.title) <span class="badge fail">quarantined</span></h2>
  </header>
  <div class="err"><strong>Failed at:</strong> $(HtmlEnc $p.failed_at)<pre>$(HtmlEnc $p.error)</pre></div>
</article>
"@
}

$html = @"
<!DOCTYPE html><html lang="en"><head><meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<title>Magic Go queue — $($m.runid)</title>
<style>
  :root { --ink:#1a1410; --paper:#f5f0e6; --muted:#6b6256; --accent:#A07C3A; --line:#e2d9c8; }
  * { box-sizing:border-box; } body { margin:0; font:16px/1.55 'Inter',system-ui,sans-serif; background:var(--paper); color:var(--ink); }
  .wrap { max-width:900px; margin:0 auto; padding:40px 24px 80px; }
  h1 { font-size:28px; margin:0 0 4px; } .sub { color:var(--muted); margin:0 0 32px; }
  .sec { font-size:13px; text-transform:uppercase; letter-spacing:.08em; color:var(--accent); font-weight:700; margin:36px 0 14px; border-bottom:1px solid var(--line); padding-bottom:6px; }
  .card { background:#fff; border:1px solid var(--line); border-radius:10px; padding:20px 22px; margin:0 0 18px; }
  .card.fail { border-color:#d9b3b3; background:#fdf6f6; }
  .site { font-size:12px; text-transform:uppercase; letter-spacing:.06em; color:var(--muted); }
  .card h2 { font-size:20px; margin:4px 0 2px; } .product { color:var(--muted); font-size:14px; }
  .badge { display:inline-block; font-size:11px; font-weight:700; padding:2px 8px; border-radius:999px; margin-left:8px; vertical-align:middle; }
  .badge.todo { background:#f3e6c6; color:#7a5b16; } .badge.done { background:#d8ecd8; color:#2c5e2c; } .badge.fail { background:#e9c9c9; color:#7a2c2c; }
  .opts { margin-top:14px; } .opts h3 { font-size:13px; color:var(--muted); margin:0 0 8px; font-weight:600; }
  .opt { border-left:3px solid var(--accent); padding:2px 0 2px 12px; margin:0 0 10px; } .optn { font-size:11px; font-weight:700; color:var(--accent); }
  .opt p { margin:2px 0 0; } .supporting { font-size:14px; color:#3a342c; margin-top:10px; }
  .card footer { margin-top:14px; } .card footer a { color:var(--accent); text-decoration:none; font-weight:600; }
  .err pre { white-space:pre-wrap; background:#fff; border:1px solid #e9c9c9; padding:8px; border-radius:6px; font-size:13px; }
  .muted { color:var(--muted); }
</style></head>
<body><div class="wrap">
  <h1>Magic Go queue</h1>
  <p class="sub">Run <code>$($m.runid)</code> · $($ready.Count) ready · $($quarantined.Count) quarantined · status: $($m.status)</p>
  $(if ($readyCards) { "<div class='sec'>Ready — write the Bottom Lines</div>" + ($readyCards -join "`n") } else { "<p class='muted'>No ready pieces.</p>" })
  $(if ($failCards) { "<div class='sec'>Needs attention — quarantined</div>" + ($failCards -join "`n") })
</div></body></html>
"@

$outDir = Join-Path $repoRoot "dist/magic-go"
New-Item -ItemType Directory -Force -Path $outDir | Out-Null
$outPath = Join-Path $outDir "queue.html"
$html | Set-Content -LiteralPath $outPath -Encoding utf8

Write-Host "Rendered queue: $outPath" -ForegroundColor Green
Write-Host "  $($ready.Count) ready, $($quarantined.Count) quarantined (run $($m.runid))" -ForegroundColor Cyan
if ($Open) { Start-Process $outPath }
exit 0

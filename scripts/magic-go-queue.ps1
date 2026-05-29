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

# Sort verify-first pieces to the top so they get attention before Ray flies
# through the solid ones; within a tier, keep site grouping for a dashboard feel.
$confRank = { switch ($_.confidence) { "verify-first" {0} "thin" {1} default {2} } }
$ready = @($ready | Sort-Object @{Expression=$confRank}, site, type)

$readyCards = foreach ($p in $ready) {
  $slug = $p.slug
  $titleEnc = HtmlEnc $p.title
  $opts = ""
  if ($p.bottom_line_options -and $p.bottom_line_options.Count -gt 0) {
    $i = 0
    $opts = ($p.bottom_line_options | ForEach-Object {
      $i++
      "<label class='opt'><input type='radio' name='pick_$slug' value='Option $i' data-slug='$slug' data-title='$titleEnc'><span class='optn'>Option $i</span><p>$(HtmlEnc $_)</p></label>"
    }) -join "`n"
  } else {
    $opts = "<p class='muted'>No options drafted — use Write my own below.</p>"
  }
  $verdictBadge = if ($p.verdict_written) { "<span class='badge done'>verdict written</span>" } else { "<span class='badge todo'>needs verdict</span>" }
  $confClass = switch ($p.confidence) { "verify-first" {"vfirst"} "thin" {"thin"} default {"solid"} }
  $confLabel = switch ($p.confidence) { "verify-first" {"verify first"} "thin" {"thin evidence"} default {"solid"} }
  $confBadge = if ($p.confidence) { "<span class='badge conf-$confClass'>$confLabel</span>" } else { "" }
  $confNote  = if ($p.confidence_note) { "<p class='confnote'>$(HtmlEnc $p.confidence_note)</p>" } else { "" }
  $fileAbs = (Join-Path $repoRoot $p.content_path) -replace '\\','/'
  @"
<article class="card" data-slug="$slug">
  <header>
    <span class="site">$(HtmlEnc $p.site) · $(HtmlEnc $p.type)</span>
    <h2>$titleEnc</h2>
    <span class="product">$(HtmlEnc $p.product)</span>
    $confBadge $verdictBadge
    $confNote
  </header>
  <div class="opts">
    <h3>Bottom Line — check the one you want</h3>
    $opts
    <label class="opt own"><input type="radio" name="pick_$slug" value="__own__" data-slug="$slug" data-title="$titleEnc"><span class="optn">&#9998; Write my own</span><textarea class="ownbox" data-slug="$slug" placeholder="Type your own Bottom Line here (this auto-selects when you type)..."></textarea></label>
    <label class="opt skip"><input type="radio" name="pick_$slug" value="__skip__" data-slug="$slug" data-title="$titleEnc"><span class="optn">Skip for now</span></label>
    <p class="supporting"><strong>Supporting context:</strong> $(HtmlEnc $p.supporting)</p>
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
  .badge.conf-solid { background:#d8ecd8; color:#2c5e2c; } .badge.conf-vfirst { background:#f7e0c0; color:#8a4b16; } .badge.conf-thin { background:#f1e2c2; color:#7a5b16; }
  .confnote { font-size:13px; color:#7a4b16; margin:8px 0 0; font-style:italic; }
  .opts { margin-top:14px; } .opts h3 { font-size:13px; color:var(--muted); margin:0 0 10px; font-weight:600; }
  /* options are now clickable radio labels */
  .opt { display:block; border:1px solid var(--line); border-left:3px solid var(--line); border-radius:8px; padding:10px 12px 10px 36px; margin:0 0 9px; position:relative; cursor:pointer; transition:.1s; }
  .opt:hover { border-color:var(--accent); border-left-color:var(--accent); background:#fbf7ee; }
  .opt input[type=radio]{ position:absolute; left:12px; top:13px; width:16px; height:16px; accent-color:var(--accent); cursor:pointer; }
  .opt:has(input:checked){ border-color:var(--accent); border-left-color:var(--accent); background:#fbf4e3; box-shadow:0 0 0 1px var(--accent) inset; }
  .optn { font-size:11px; font-weight:700; color:var(--accent); text-transform:uppercase; letter-spacing:.04em; }
  .opt p { margin:3px 0 0; } .opt.skip .optn { color:var(--muted); } .opt.own .optn { color:#2c5e2c; }
  .ownbox { display:block; width:100%; margin-top:8px; min-height:60px; border:1px solid var(--line); border-radius:6px; padding:8px; font:14px/1.5 'Inter',sans-serif; resize:vertical; }
  .supporting { font-size:13.5px; color:#5d564b; margin-top:12px; background:#faf7f0; border-radius:6px; padding:8px 10px; }
  .card footer { margin-top:14px; } .card footer a { color:var(--accent); text-decoration:none; font-weight:600; }
  .err pre { white-space:pre-wrap; background:#fff; border:1px solid #e9c9c9; padding:8px; border-radius:6px; font-size:13px; }
  .muted { color:var(--muted); }
  /* sticky copy-picks bar */
  .pickbar { position:fixed; left:0; right:0; bottom:0; z-index:200; background:#1a1410; color:#f5f0e6; box-shadow:0 -4px 18px rgba(0,0,0,.25); padding:12px 0; }
  .pickbar .wrap { padding:0 24px; max-width:900px; margin:0 auto; display:flex; align-items:center; gap:14px; flex-wrap:wrap; }
  #copybtn { background:var(--accent); color:#1a1410; border:none; font-weight:700; font-size:15px; padding:11px 18px; border-radius:8px; cursor:pointer; }
  #copybtn:hover { filter:brightness(1.08); }
  #copymsg { color:#bfe6bf; font-weight:600; font-size:14px; }
  .pickbar .count { color:#cfc6b4; font-size:14px; }
  .pickbar details { width:100%; }
  .pickbar summary { cursor:pointer; color:#cfc6b4; font-size:13px; }
  #picksout { width:100%; min-height:150px; margin-top:8px; background:#0f0c09; color:#e8f6e8; border:1px solid #3a342c; border-radius:6px; padding:10px; font:13px/1.5 ui-monospace,monospace; }
</style></head>
<body><div class="wrap">
  <h1>Magic Go queue</h1>
  <p class="sub">Run <code>$($m.runid)</code> · $($ready.Count) ready · $($quarantined.Count) quarantined · status: $($m.status)<br>Check the Bottom Line you want on each, then hit <strong>Copy my picks</strong> at the bottom and paste it back to Claude.</p>
  $(if ($readyCards) { "<div class='sec'>Ready — check the Bottom Line you want</div>" + ($readyCards -join "`n") } else { "<p class='muted'>No ready pieces.</p>" })
  $(if ($failCards) { "<div class='sec'>Needs attention — quarantined</div>" + ($failCards -join "`n") })
</div>
<div class="pickbar"><div class="wrap">
  <button id="copybtn">&#128203; Copy my picks</button>
  <span class="count"><span id="pickcount">0</span> / $($ready.Count) chosen</span>
  <span id="copymsg"></span>
  <details><summary>Preview / edit the text</summary><textarea id="picksout" readonly></textarea></details>
</div></div>
<script>
  var RUN = "$($m.runid)";
  function rebuild(){
    var cards = document.querySelectorAll('article.card[data-slug]');
    var lines = [], n = 0;
    cards.forEach(function(c){
      var sel = c.querySelector('input[type=radio]:checked');
      if(!sel) return;
      n++;
      var slug = c.dataset.slug, title = sel.getAttribute('data-title'), v = sel.value;
      if(v === '__own__'){ var t = c.querySelector('textarea.ownbox'); var txt = (t && t.value.trim()) || '(write your own — left blank)'; lines.push('- ' + slug + ' (' + title + '): MY OWN -> ' + txt); }
      else if(v === '__skip__'){ lines.push('- ' + slug + ' (' + title + '): SKIP'); }
      else { lines.push('- ' + slug + ' (' + title + '): ' + v); }
    });
    document.getElementById('pickcount').textContent = n;
    document.getElementById('picksout').value = 'MAGIC GO PICKS - run ' + RUN + '\n' + (lines.join('\n') || '(nothing selected yet)');
  }
  document.addEventListener('change', function(e){
    if(e.target.matches('input[type=radio], textarea.ownbox')) rebuild();
  });
  document.addEventListener('input', function(e){
    if(e.target.matches('textarea.ownbox')){ var own = e.target.closest('.card').querySelector('input[value="__own__"]'); if(own) own.checked = true; rebuild(); }
  });
  document.getElementById('copybtn').addEventListener('click', function(){
    var t = document.getElementById('picksout');
    navigator.clipboard.writeText(t.value).then(function(){
      var m = document.getElementById('copymsg'); m.textContent = 'Copied! Paste it back to Claude.'; setTimeout(function(){ m.textContent=''; }, 4000);
    }, function(){ var d=document.querySelector('.pickbar details'); d.open=true; t.select(); });
  });
  rebuild();
</script>
</body></html>
"@

$outDir = Join-Path $repoRoot "dist/magic-go"
New-Item -ItemType Directory -Force -Path $outDir | Out-Null
$outPath = Join-Path $outDir "queue.html"
$html | Set-Content -LiteralPath $outPath -Encoding utf8

Write-Host "Rendered queue: $outPath" -ForegroundColor Green
Write-Host "  $($ready.Count) ready, $($quarantined.Count) quarantined (run $($m.runid))" -ForegroundColor Cyan
if ($Open) { Start-Process $outPath }
exit 0

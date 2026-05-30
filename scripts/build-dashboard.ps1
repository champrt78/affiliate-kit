<#
.SYNOPSIS
  Build Ray's REUSABLE affiliate decision dashboard — a single stable HTML page
  that aggregates everything across ALL Magic Go runs that needs his eyes or a
  decision, with click-to-pick + copy-back UI.

.DESCRIPTION
  Unlike magic-go-queue.ps1 (per-run, dist/, disposable), this is the durable
  cockpit Ray keeps on his desktop and opens whenever he wants to make calls.
  Every run it regenerates from current state, so it's always live.

  It collects TWO kinds of pending decisions:

    1. Bottom Line picks  — every piece across docs/magic-go/runs/*/manifest.json
       that has drafted options but no written verdict yet. Sorted verify-first
       to the top, then by site/type. Each shows 3 options + write-my-own + skip.

    2. Decisions & reviews — free-form items from docs/magic-go/decisions.json
       (CTA/order calls, image judgment, QA flags, anything that needs Ray).
       Each can carry preset options or just take a free-text answer.

  Output goes to a STABLE path OUTSIDE the repo ($env:USERPROFILE\
  AffiliateDashboard\dashboard.html) so git doesn't churn and the desktop
  shortcut always finds it. A desktop .lnk is created/refreshed on every run
  (idempotent) pointing back at this script with -Open, so double-clicking it
  regenerates from the latest state and opens.

.PARAMETER Open            Start-Process the rendered HTML after building.
.PARAMETER NoShortcut      Skip the desktop-shortcut self-heal.

.EXAMPLE
  pwsh scripts/build-dashboard.ps1 -Open
#>

param(
  [switch]$Open,
  [switch]$NoShortcut
)

$ErrorActionPreference = "Stop"
$repoRoot = Split-Path -Parent $PSScriptRoot
. (Join-Path $PSScriptRoot "lib/magic-go-manifest.ps1")

function HtmlEnc([string]$s) {
  if ($null -eq $s) { return "" }
  return $s.Replace('&','&amp;').Replace('<','&lt;').Replace('>','&gt;').Replace('"','&quot;')
}

# ---- gather: Bottom Line picks across ALL runs -----------------------------
$runsDir = Get-MagicGoRunsDir
$pieces = @()
if (Test-Path -LiteralPath $runsDir) {
  foreach ($d in (Get-ChildItem -Directory -LiteralPath $runsDir -ErrorAction SilentlyContinue | Sort-Object Name)) {
    $m = Read-MagicGoManifest -RunId $d.Name
    if ($null -eq $m) { continue }
    foreach ($p in $m.pieces) {
      # needs a pick = has drafted options AND verdict not yet written AND not discarded
      $hasOpts = $p.bottom_line_options -and @($p.bottom_line_options).Count -gt 0
      $written = $p.verdict_written -eq $true
      $discarded = $p.status -eq "discarded"
      if ($hasOpts -and -not $written -and -not $discarded) {
        $p | Add-Member -NotePropertyName _runid -NotePropertyValue $m.runid -Force
        $pieces += $p
      }
    }
  }
}

$confRank = { switch ($_.confidence) { "verify-first" {0} "thin" {1} default {2} } }
$pieces = @($pieces | Sort-Object @{Expression=$confRank}, site, type, slug)

$pickCards = foreach ($p in $pieces) {
  $slug = $p.slug
  $titleEnc = HtmlEnc $p.title
  $i = 0
  $opts = ($p.bottom_line_options | ForEach-Object {
    $i++
    "<label class='opt'><input type='radio' name='pick_$slug' value='Option $i' data-slug='$slug' data-title='$titleEnc'><span class='optn'>Option $i</span><p>$(HtmlEnc $_)</p></label>"
  }) -join "`n"
  $confClass = switch ($p.confidence) { "verify-first" {"vfirst"} "thin" {"thin"} default {"solid"} }
  $confLabel = switch ($p.confidence) { "verify-first" {"verify first"} "thin" {"thin evidence"} default {"solid"} }
  $confBadge = if ($p.confidence) { "<span class='badge conf-$confClass'>$confLabel</span>" } else { "" }
  $confNote  = if ($p.confidence_note) { "<p class='confnote'>$(HtmlEnc $p.confidence_note)</p>" } else { "" }
  $fileRel = $p.content_path
  $fileAbs = if ($fileRel) { ((Join-Path $repoRoot $fileRel) -replace '\\','/') } else { "" }
  $openLink = if ($fileAbs) { "<footer><a href=`"file:///$fileAbs`">Open the draft &rarr;</a></footer>" } else { "" }
  @"
<article class="card" data-slug="$slug" data-run="$($p._runid)">
  <header>
    <span class="site">$(HtmlEnc $p.site) &middot; $(HtmlEnc $p.type) &middot; run $($p._runid)</span>
    <h2>$titleEnc</h2>
    <span class="product">$(HtmlEnc $p.product)</span>
    $confBadge <span class="badge todo">needs verdict</span>
    $confNote
  </header>
  <div class="opts">
    <h3>Bottom Line &mdash; check the one you want</h3>
    $opts
    <label class="opt own"><input type="radio" name="pick_$slug" value="__own__" data-slug="$slug" data-title="$titleEnc"><span class="optn">&#9998; Write my own</span><textarea class="ownbox" data-slug="$slug" placeholder="Type your own Bottom Line here (this auto-selects when you type)..."></textarea></label>
    <label class="opt skip"><input type="radio" name="pick_$slug" value="__skip__" data-slug="$slug" data-title="$titleEnc"><span class="optn">Skip for now</span></label>
    <p class="supporting"><strong>Supporting context:</strong> $(HtmlEnc $p.supporting)</p>
  </div>
  $openLink
</article>
"@
}

# ---- gather: free-form decisions -------------------------------------------
$decisionsPath = Join-Path $repoRoot "docs/magic-go/decisions.json"
$decisions = @()
if (Test-Path -LiteralPath $decisionsPath) {
  $raw = Get-Content -Raw -LiteralPath $decisionsPath
  if ($raw.Trim()) { $decisions = @($raw | ConvertFrom-Json) }
}

$decisionCards = foreach ($d in $decisions) {
  $id = $d.id
  $titleEnc = HtmlEnc $d.title
  $optsHtml = ""
  if ($d.options -and @($d.options).Count -gt 0) {
    $i = 0
    $optsHtml = ($d.options | ForEach-Object {
      $i++
      "<label class='opt'><input type='radio' name='dec_$id' value='Option $i' data-id='$id' data-title='$titleEnc'><span class='optn'>Option $i</span><p>$(HtmlEnc $_)</p></label>"
    }) -join "`n"
  }
  $siteTag = if ($d.site) { "$(HtmlEnc $d.site) &middot; " } else { "" }
  @"
<article class="dcard" data-id="$id">
  <header>
    <span class="site">${siteTag}decision</span>
    <h2>$titleEnc</h2>
  </header>
  <p class="dbody">$(HtmlEnc $d.body)</p>
  <div class="opts">
    $optsHtml
    <label class="opt own"><input type="radio" name="dec_$id" value="__own__" data-id="$id" data-title="$titleEnc"><span class="optn">&#9998; My own answer</span><textarea class="ownbox" data-id="$id" placeholder="Type your decision / instruction here..."></textarea></label>
    <label class="opt skip"><input type="radio" name="dec_$id" value="__skip__" data-id="$id" data-title="$titleEnc"><span class="optn">Decide later</span></label>
  </div>
</article>
"@
}

$pickCount = @($pieces).Count
$decCount  = @($decisions).Count
$genStamp  = (Get-Date).ToString("yyyy-MM-dd HH:mm")

$html = @"
<!DOCTYPE html><html lang="en"><head><meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<title>Affiliate Dashboard</title>
<style>
  :root { --ink:#1a1410; --paper:#f5f0e6; --muted:#6b6256; --accent:#A07C3A; --line:#e2d9c8; }
  * { box-sizing:border-box; } body { margin:0; font:16px/1.55 'Inter',system-ui,sans-serif; background:var(--paper); color:var(--ink); }
  .wrap { max-width:920px; margin:0 auto; padding:40px 24px 96px; }
  h1 { font-size:30px; margin:0 0 4px; } .sub { color:var(--muted); margin:0 0 8px; }
  .sec { font-size:13px; text-transform:uppercase; letter-spacing:.08em; color:var(--accent); font-weight:700; margin:40px 0 14px; border-bottom:1px solid var(--line); padding-bottom:6px; }
  .card, .dcard { background:#fff; border:1px solid var(--line); border-radius:10px; padding:20px 22px; margin:0 0 18px; }
  .dcard { border-left:3px solid var(--accent); }
  .site { font-size:12px; text-transform:uppercase; letter-spacing:.06em; color:var(--muted); }
  .card h2, .dcard h2 { font-size:20px; margin:4px 0 2px; } .product { color:var(--muted); font-size:14px; }
  .dbody { color:#4d473d; font-size:14.5px; margin:8px 0 4px; }
  .badge { display:inline-block; font-size:11px; font-weight:700; padding:2px 8px; border-radius:999px; margin-left:8px; vertical-align:middle; }
  .badge.todo { background:#f3e6c6; color:#7a5b16; }
  .badge.conf-solid { background:#d8ecd8; color:#2c5e2c; } .badge.conf-vfirst { background:#f7e0c0; color:#8a4b16; } .badge.conf-thin { background:#f1e2c2; color:#7a5b16; }
  .confnote { font-size:13px; color:#7a4b16; margin:8px 0 0; font-style:italic; }
  .opts { margin-top:14px; } .opts h3 { font-size:13px; color:var(--muted); margin:0 0 10px; font-weight:600; }
  .opt { display:block; border:1px solid var(--line); border-left:3px solid var(--line); border-radius:8px; padding:10px 12px 10px 36px; margin:0 0 9px; position:relative; cursor:pointer; transition:.1s; }
  .opt:hover { border-color:var(--accent); border-left-color:var(--accent); background:#fbf7ee; }
  .opt input[type=radio]{ position:absolute; left:12px; top:13px; width:16px; height:16px; accent-color:var(--accent); cursor:pointer; }
  .opt:has(input:checked){ border-color:var(--accent); border-left-color:var(--accent); background:#fbf4e3; box-shadow:0 0 0 1px var(--accent) inset; }
  .optn { font-size:11px; font-weight:700; color:var(--accent); text-transform:uppercase; letter-spacing:.04em; }
  .opt p { margin:3px 0 0; } .opt.skip .optn { color:var(--muted); } .opt.own .optn { color:#2c5e2c; }
  .ownbox { display:block; width:100%; margin-top:8px; min-height:60px; border:1px solid var(--line); border-radius:6px; padding:8px; font:14px/1.5 'Inter',sans-serif; resize:vertical; }
  .supporting { font-size:13.5px; color:#5d564b; margin-top:12px; background:#faf7f0; border-radius:6px; padding:8px 10px; }
  .card footer { margin-top:14px; } .card footer a { color:var(--accent); text-decoration:none; font-weight:600; }
  .muted { color:var(--muted); }
  .pickbar { position:fixed; left:0; right:0; bottom:0; z-index:200; background:#1a1410; color:#f5f0e6; box-shadow:0 -4px 18px rgba(0,0,0,.25); padding:12px 0; }
  .pickbar .wrap { padding:0 24px; max-width:920px; margin:0 auto; display:flex; align-items:center; gap:14px; flex-wrap:wrap; }
  #copybtn { background:var(--accent); color:#1a1410; border:none; font-weight:700; font-size:15px; padding:11px 18px; border-radius:8px; cursor:pointer; }
  #copybtn:hover { filter:brightness(1.08); }
  #copymsg { color:#bfe6bf; font-weight:600; font-size:14px; }
  .pickbar .count { color:#cfc6b4; font-size:14px; }
  .pickbar details { width:100%; }
  .pickbar summary { cursor:pointer; color:#cfc6b4; font-size:13px; }
  #picksout { width:100%; min-height:170px; margin-top:8px; background:#0f0c09; color:#e8f6e8; border:1px solid #3a342c; border-radius:6px; padding:10px; font:13px/1.5 ui-monospace,monospace; }
  .empty { color:var(--muted); background:#fff; border:1px dashed var(--line); border-radius:10px; padding:24px; text-align:center; }
</style></head>
<body><div class="wrap">
  <h1>Affiliate Dashboard</h1>
  <p class="sub">Generated $genStamp &middot; $pickCount Bottom Line pick(s) &middot; $decCount decision(s) waiting.</p>
  <p class="sub">Make your calls below, hit <strong>Copy my picks</strong>, and paste the block back to Claude.</p>
  $(if ($pickCards) { "<div class='sec'>Bottom Lines &mdash; check the verdict you want</div>" + ($pickCards -join "`n") })
  $(if ($decisionCards) { "<div class='sec'>Decisions &amp; reviews</div>" + ($decisionCards -join "`n") })
  $(if (-not $pickCards -and -not $decisionCards) { "<div class='empty'>Nothing waiting on you right now. New Bottom Lines and decisions will show up here after the next run.</div>" })
</div>
<div class="pickbar"><div class="wrap">
  <button id="copybtn">&#128203; Copy my picks</button>
  <span class="count"><span id="pickcount">0</span> chosen</span>
  <span id="copymsg"></span>
  <details><summary>Preview / edit the text</summary><textarea id="picksout" readonly></textarea></details>
</div></div>
<script>
  function rebuild(){
    var lines = [], n = 0;
    var bl = [];
    document.querySelectorAll('article.card[data-slug]').forEach(function(c){
      var sel = c.querySelector('input[type=radio]:checked'); if(!sel) return; n++;
      var slug = c.dataset.slug, run = c.dataset.run, title = sel.getAttribute('data-title'), v = sel.value;
      if(v === '__own__'){ var t = c.querySelector('textarea.ownbox'); var txt = (t && t.value.trim()) || '(write your own - left blank)'; bl.push('- ' + slug + ' [' + run + '] (' + title + '): MY OWN -> ' + txt); }
      else if(v === '__skip__'){ bl.push('- ' + slug + ' [' + run + '] (' + title + '): SKIP'); }
      else { bl.push('- ' + slug + ' [' + run + '] (' + title + '): ' + v); }
    });
    var dec = [];
    document.querySelectorAll('article.dcard[data-id]').forEach(function(c){
      var sel = c.querySelector('input[type=radio]:checked'); if(!sel) return; n++;
      var id = c.dataset.id, title = sel.getAttribute('data-title'), v = sel.value;
      if(v === '__own__'){ var t = c.querySelector('textarea.ownbox'); var txt = (t && t.value.trim()) || '(left blank)'; dec.push('- ' + id + ' (' + title + '): MY OWN -> ' + txt); }
      else if(v === '__skip__'){ dec.push('- ' + id + ' (' + title + '): DECIDE LATER'); }
      else { dec.push('- ' + id + ' (' + title + '): ' + v); }
    });
    document.getElementById('pickcount').textContent = n;
    var out = 'AFFILIATE DASHBOARD PICKS - ' + new Date().toISOString().slice(0,10) + '\n';
    if(bl.length){ out += '\n[BOTTOM LINES]\n' + bl.join('\n') + '\n'; }
    if(dec.length){ out += '\n[DECISIONS]\n' + dec.join('\n') + '\n'; }
    if(!bl.length && !dec.length){ out += '(nothing selected yet)'; }
    document.getElementById('picksout').value = out;
  }
  document.addEventListener('change', function(e){ if(e.target.matches('input[type=radio], textarea.ownbox')) rebuild(); });
  document.addEventListener('input', function(e){
    if(e.target.matches('textarea.ownbox')){ var own = e.target.closest('article').querySelector('input[value="__own__"]'); if(own) own.checked = true; rebuild(); }
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

# ---- write to stable path --------------------------------------------------
$dashDir = Join-Path $env:USERPROFILE "AffiliateDashboard"
New-Item -ItemType Directory -Force -Path $dashDir | Out-Null
$outPath = Join-Path $dashDir "dashboard.html"
$html | Set-Content -LiteralPath $outPath -Encoding utf8

Write-Host "Dashboard: $outPath" -ForegroundColor Green
Write-Host "  $pickCount Bottom Line pick(s), $decCount decision(s)" -ForegroundColor Cyan

# ---- desktop shortcut self-heal --------------------------------------------
if (-not $NoShortcut) {
  try {
    $desktop = [Environment]::GetFolderPath('Desktop')
    $lnkPath = Join-Path $desktop "Affiliate Dashboard.lnk"
    $pwshExe = (Get-Process -Id $PID).Path  # the pwsh that's running this
    if (-not $pwshExe) { $pwshExe = "pwsh.exe" }
    $scriptPath = Join-Path $PSScriptRoot "build-dashboard.ps1"
    $ws = New-Object -ComObject WScript.Shell
    $sc = $ws.CreateShortcut($lnkPath)
    $sc.TargetPath = $pwshExe
    $sc.Arguments = "-NoProfile -WindowStyle Hidden -File `"$scriptPath`" -Open"
    $sc.WorkingDirectory = $repoRoot
    $sc.Description = "Rebuild + open the affiliate decision dashboard"
    $sc.IconLocation = "shell32.dll,21"
    $sc.Save()
    Write-Host "  Desktop shortcut: $lnkPath" -ForegroundColor Cyan
  } catch {
    Write-Host "  (shortcut skipped: $($_.Exception.Message))" -ForegroundColor Yellow
  }
}

if ($Open) { Start-Process $outPath }
exit 0

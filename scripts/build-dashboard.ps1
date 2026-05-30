<#
.SYNOPSIS
  Build Ray's REUSABLE affiliate COCKPIT — a single stable HTML page that is the
  one place to see portfolio state + make decisions. Picks are one section among
  several panels.

.DESCRIPTION
  Durable cockpit Ray keeps on his desktop. Regenerates from current state every
  run, so it's always live. Panels:

    1. Portfolio status   — per site: live vs DRAFT counts, last shipped, cadence.
    2. Section coverage    — per site nav pillars with zero content (the
       "coming soon" early-warning; ties to the no-empty-section goal).
    3. Recently deployed   — git commits from the last 3 days.
    4. Open TODOs          — the docs/TODO.md "Now" / "READY" items.
    5. Bottom Line picks   — pieces with drafted options + no verdict (click-to-pick).
    6. Decisions & reviews — free-form items from docs/magic-go/decisions.json.

  Output to a STABLE path OUTSIDE the repo ($env:USERPROFILE\AffiliateDashboard\
  dashboard.html). A desktop .lnk self-heals on every run, pointing back here with
  -Open, so double-clicking regenerates + opens.

.PARAMETER Open         Start-Process the rendered HTML after building.
.PARAMETER NoShortcut   Skip the desktop-shortcut self-heal.

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
function Get-Frontmatter([string]$path) {
  $raw = Get-Content -Raw -LiteralPath $path
  $m = [regex]::Match($raw, '(?s)^---\r?\n(.*?)\r?\n---')
  if ($m.Success) { return $m.Groups[1].Value } else { return "" }
}

$sites = @(
  @{ slug="mywildlifecam";   name="MyWildlifeCam"; cadence=7 }
  @{ slug="detailerpicks";   name="DetailerPicks"; cadence=18 }
  @{ slug="fussybean";       name="FussyBean";     cadence=180 }
  @{ slug="gameovergear";    name="GameOverGear";  cadence=180 }
  @{ slug="starteraquarium"; name="StarterAquarium"; cadence=180 }
)

# ---- gather: per-site portfolio + section coverage -------------------------
$siteStats = @()
foreach ($s in $sites) {
  $dir = Join-Path $repoRoot "sites/$($s.slug)/src/content"
  $files = @()
  foreach ($sub in @("buyers-guides","reviews")) {
    $p = Join-Path $dir $sub
    if (Test-Path $p) { $files += Get-ChildItem -LiteralPath $p -Filter *.md -ErrorAction SilentlyContinue }
  }
  $live = 0; $draft = 0; $latest = $null
  $pillarCounts = @{}
  foreach ($f in $files) {
    $fm = Get-Frontmatter $f.FullName
    if (-not $fm) { continue }
    $vm = [regex]::Match($fm, 'verdict:\s*"([^"]*)"')
    if ($vm.Success -and $vm.Groups[1].Value.Trim().Length -gt 0) { $live++ } else { $draft++ }
    $pd = [regex]::Match($fm, 'pubDate:\s*"?(\d{4}-\d{2}-\d{2})')
    if ($pd.Success) { $d = [datetime]$pd.Groups[1].Value; if ($null -eq $latest -or $d -gt $latest) { $latest = $d } }
    $pl = [regex]::Match($fm, '(?m)^pillar:\s*"?([a-z0-9-]+)"?')
    if ($pl.Success) { $k = $pl.Groups[1].Value; $pillarCounts[$k] = 1 + ($pillarCounts[$k] | ForEach-Object { $_ }) }
  }
  $daysSince = if ($latest) { [int]((Get-Date).Date - $latest.Date).TotalDays } else { $null }
  # section coverage from site-config nav pillars
  $empty = @()
  $cfgPath = Join-Path $repoRoot "sites/$($s.slug)/src/data/site-config.json"
  if (Test-Path $cfgPath) {
    $cfg = Get-Content -Raw -LiteralPath $cfgPath | ConvertFrom-Json
    foreach ($pl in $cfg.navigation.pillars) {
      $cnt = $pillarCounts[$pl.slug]; if (-not $cnt) { $cnt = 0 }
      if ($cnt -eq 0) { $empty += $pl.label }
    }
  }
  $siteStats += [pscustomobject]@{
    Name=$s.name; Slug=$s.slug; Live=$live; Draft=$draft; Total=$files.Count
    DaysSince=$daysSince; Cadence=$s.cadence
    Behind=($daysSince -ne $null -and $daysSince -gt $s.cadence)
    Empty=$empty
  }
}

# ---- gather: recent commits ------------------------------------------------
Push-Location $repoRoot
$commits = @()
try { $commits = & git log --since="3 days ago" --format="%h|%ar|%s" 2>$null | Select-Object -First 12 } catch {}
Pop-Location

# ---- gather: TODO Now / READY ----------------------------------------------
$todoItems = @()
$todoPath = Join-Path $repoRoot "docs/TODO.md"
if (Test-Path $todoPath) {
  $lines = Get-Content -LiteralPath $todoPath
  $inNow = $false; $taken = 0
  foreach ($ln in $lines) {
    if ($ln -match '^##\s') { $inNow = ($ln -match '(?i)\bNow\b|READY FOR RAY'); continue }
    if ($inNow -and $ln -match '^\s*-\s*\[ \]\s*(.+)') {
      $t = $Matches[1] -replace '\*\*',''
      if ($t.Length -gt 130) { $t = $t.Substring(0,127) + "..." }
      $todoItems += $t; $taken++
      if ($taken -ge 8) { break }
    }
  }
}

# ---- gather: Bottom Line picks across ALL runs -----------------------------
$runsDir = Get-MagicGoRunsDir
$pieces = @()
if (Test-Path -LiteralPath $runsDir) {
  foreach ($d in (Get-ChildItem -Directory -LiteralPath $runsDir -ErrorAction SilentlyContinue | Sort-Object Name)) {
    $m = Read-MagicGoManifest -RunId $d.Name
    if ($null -eq $m) { continue }
    foreach ($p in $m.pieces) {
      $hasOpts = $p.bottom_line_options -and @($p.bottom_line_options).Count -gt 0
      if ($hasOpts -and -not ($p.verdict_written -eq $true) -and $p.status -ne "discarded") {
        $p | Add-Member -NotePropertyName _runid -NotePropertyValue $m.runid -Force
        $pieces += $p
      }
    }
  }
}
$confRank = { switch ($_.confidence) { "verify-first" {0} "thin" {1} default {2} } }
$pieces = @($pieces | Sort-Object @{Expression=$confRank}, site, type, slug)

$pickCards = foreach ($p in $pieces) {
  $slug = $p.slug; $titleEnc = HtmlEnc $p.title; $i = 0
  $opts = ($p.bottom_line_options | ForEach-Object {
    $i++
    "<label class='opt'><input type='radio' name='pick_$slug' value='Option $i' data-slug='$slug' data-title='$titleEnc'><span class='optn'>Option $i</span><p>$(HtmlEnc $_)</p></label>"
  }) -join "`n"
  $confClass = switch ($p.confidence) { "verify-first" {"vfirst"} "thin" {"thin"} default {"solid"} }
  $confLabel = switch ($p.confidence) { "verify-first" {"verify first"} "thin" {"thin evidence"} default {"solid"} }
  $confBadge = if ($p.confidence) { "<span class='badge conf-$confClass'>$confLabel</span>" } else { "" }
  $confNote  = if ($p.confidence_note) { "<p class='confnote'>$(HtmlEnc $p.confidence_note)</p>" } else { "" }
  $fileAbs = if ($p.content_path) { ((Join-Path $repoRoot $p.content_path) -replace '\\','/') } else { "" }
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
    <label class="opt own"><input type="radio" name="pick_$slug" value="__own__" data-slug="$slug" data-title="$titleEnc"><span class="optn">&#9998; Write my own</span><textarea class="ownbox" data-slug="$slug" placeholder="Type your own Bottom Line here..."></textarea></label>
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
  $id = $d.id; $titleEnc = HtmlEnc $d.title; $optsHtml = ""
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
  <header><span class="site">${siteTag}decision</span><h2>$titleEnc</h2></header>
  <p class="dbody">$(HtmlEnc $d.body)</p>
  <div class="opts">
    $optsHtml
    <label class="opt own"><input type="radio" name="dec_$id" value="__own__" data-id="$id" data-title="$titleEnc"><span class="optn">&#9998; My own answer</span><textarea class="ownbox" data-id="$id" placeholder="Type your decision..."></textarea></label>
    <label class="opt skip"><input type="radio" name="dec_$id" value="__skip__" data-id="$id" data-title="$titleEnc"><span class="optn">Decide later</span></label>
  </div>
</article>
"@
}

# ---- render overview panels ------------------------------------------------
$genStamp = (Get-Date).ToString("yyyy-MM-dd HH:mm")
$totalLive = ($siteStats | Measure-Object -Property Live -Sum).Sum
$totalDraft = ($siteStats | Measure-Object -Property Draft -Sum).Sum
$totalEmpty = ($siteStats | ForEach-Object { $_.Empty.Count } | Measure-Object -Sum).Sum

$portfolioRows = foreach ($st in $siteStats) {
  $cad = if ($st.DaysSince -eq $null) { "<span class='dim'>none yet</span>" }
         elseif ($st.Behind) { "<span class='warn'>$($st.DaysSince)d ago (target $($st.Cadence)d)</span>" }
         else { "$($st.DaysSince)d ago" }
  "<tr><td class='sname'>$(HtmlEnc $st.Name)</td><td><b>$($st.Live)</b> live</td><td>$($st.Draft) draft</td><td>$cad</td></tr>"
}
$coverageItems = foreach ($st in $siteStats) {
  if ($st.Empty.Count -gt 0) {
    "<li><b>$(HtmlEnc $st.Name):</b> <span class='warn'>$(($st.Empty | ForEach-Object { HtmlEnc $_ }) -join ', ')</span></li>"
  }
}
$coveragePanel = if ($coverageItems) {
  "<ul class='cov'>" + ($coverageItems -join "") + "</ul>"
} else {
  "<p class='ok'>&#10003; Every nav section on every site has at least one article. No coming-soon pages.</p>"
}
$commitRows = foreach ($c in $commits) {
  $parts = $c -split '\|', 3
  if ($parts.Count -eq 3) { "<li><code>$(HtmlEnc $parts[0])</code> <span class='dim'>$(HtmlEnc $parts[1])</span> $(HtmlEnc $parts[2])</li>" }
}
$todoRows = foreach ($t in $todoItems) { "<li>$(HtmlEnc $t)</li>" }

$html = @"
<!DOCTYPE html><html lang="en"><head><meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<title>Affiliate Cockpit</title>
<style>
  :root { --ink:#1a1410; --paper:#f5f0e6; --muted:#6b6256; --accent:#A07C3A; --line:#e2d9c8; --warn:#9a4b16; --ok:#2c5e2c; }
  * { box-sizing:border-box; } body { margin:0; font:16px/1.55 'Inter',system-ui,sans-serif; background:var(--paper); color:var(--ink); }
  .wrap { max-width:980px; margin:0 auto; padding:36px 24px 96px; }
  h1 { font-size:30px; margin:0 0 4px; } .sub { color:var(--muted); margin:0 0 8px; }
  .panels { display:grid; grid-template-columns:1fr 1fr; gap:16px; margin:22px 0 8px; }
  .panel { background:#fff; border:1px solid var(--line); border-radius:10px; padding:16px 18px; }
  .panel h2 { font-size:13px; text-transform:uppercase; letter-spacing:.08em; color:var(--accent); font-weight:700; margin:0 0 12px; }
  .panel.span2 { grid-column:1 / -1; }
  table { width:100%; border-collapse:collapse; font-size:14px; }
  table td { padding:5px 6px; border-bottom:1px solid var(--line); }
  .sname { font-weight:600; }
  .dim { color:var(--muted); } .warn { color:var(--warn); font-weight:600; } .ok { color:var(--ok); font-weight:600; margin:0; }
  ul.cov, .panel ul { margin:0; padding-left:18px; font-size:14px; } .panel li { margin:3px 0; }
  .panel code { background:#f3ecdd; padding:1px 5px; border-radius:4px; font-size:12.5px; }
  .statline { display:flex; gap:18px; margin:4px 0 0; font-size:14px; color:var(--muted); flex-wrap:wrap; }
  .statline b { color:var(--ink); }
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
  .pickbar .wrap { padding:0 24px; max-width:980px; margin:0 auto; display:flex; align-items:center; gap:14px; flex-wrap:wrap; }
  #copybtn { background:var(--accent); color:#1a1410; border:none; font-weight:700; font-size:15px; padding:11px 18px; border-radius:8px; cursor:pointer; }
  #copybtn:hover { filter:brightness(1.08); }
  #copymsg { color:#bfe6bf; font-weight:600; font-size:14px; } .pickbar .count { color:#cfc6b4; font-size:14px; }
  .pickbar details { width:100%; } .pickbar summary { cursor:pointer; color:#cfc6b4; font-size:13px; }
  #picksout { width:100%; min-height:170px; margin-top:8px; background:#0f0c09; color:#e8f6e8; border:1px solid #3a342c; border-radius:6px; padding:10px; font:13px/1.5 ui-monospace,monospace; }
  .empty { color:var(--muted); background:#fff; border:1px dashed var(--line); border-radius:10px; padding:24px; text-align:center; }
  @media (max-width:720px){ .panels { grid-template-columns:1fr; } }
</style></head>
<body><div class="wrap">
  <h1>Affiliate Cockpit</h1>
  <p class="sub">Generated $genStamp</p>
  <div class="statline"><span><b>$totalLive</b> live pieces</span><span><b>$totalDraft</b> DRAFT</span><span><b>$(@($pieces).Count)</b> awaiting a Bottom Line</span><span><b>$totalEmpty</b> empty sections</span></div>

  <div class="panels">
    <div class="panel"><h2>Portfolio</h2><table>$(($portfolioRows) -join "")</table></div>
    <div class="panel"><h2>Section coverage</h2>$coveragePanel</div>
    <div class="panel"><h2>Recently deployed</h2><ul>$(($commitRows) -join "")</ul></div>
    <div class="panel"><h2>Open TODOs (Now)</h2><ul>$(if($todoRows){($todoRows) -join ""}else{"<li class='dim'>none parsed</li>"})</ul></div>
  </div>

  $(if ($pickCards) { "<div class='sec'>Bottom Lines &mdash; check the verdict you want</div>" + ($pickCards -join "`n") })
  $(if ($decisionCards) { "<div class='sec'>Decisions &amp; reviews</div>" + ($decisionCards -join "`n") })
  $(if (-not $pickCards -and -not $decisionCards) { "<div class='empty'>No Bottom Lines or decisions waiting. Portfolio panels above are still live.</div>" })
</div>
<div class="pickbar"><div class="wrap">
  <button id="copybtn">&#128203; Copy my picks</button>
  <span class="count"><span id="pickcount">0</span> chosen</span>
  <span id="copymsg"></span>
  <details><summary>Preview / edit the text</summary><textarea id="picksout" readonly></textarea></details>
</div></div>
<script>
  function rebuild(){
    var n=0, bl=[], dec=[];
    document.querySelectorAll('article.card[data-slug]').forEach(function(c){
      var sel=c.querySelector('input[type=radio]:checked'); if(!sel) return; n++;
      var slug=c.dataset.slug, run=c.dataset.run, title=sel.getAttribute('data-title'), v=sel.value;
      if(v==='__own__'){ var t=c.querySelector('textarea.ownbox'); var txt=(t&&t.value.trim())||'(write your own - left blank)'; bl.push('- '+slug+' ['+run+'] ('+title+'): MY OWN -> '+txt); }
      else if(v==='__skip__'){ bl.push('- '+slug+' ['+run+'] ('+title+'): SKIP'); }
      else { bl.push('- '+slug+' ['+run+'] ('+title+'): '+v); }
    });
    document.querySelectorAll('article.dcard[data-id]').forEach(function(c){
      var sel=c.querySelector('input[type=radio]:checked'); if(!sel) return; n++;
      var id=c.dataset.id, title=sel.getAttribute('data-title'), v=sel.value;
      if(v==='__own__'){ var t=c.querySelector('textarea.ownbox'); var txt=(t&&t.value.trim())||'(left blank)'; dec.push('- '+id+' ('+title+'): MY OWN -> '+txt); }
      else if(v==='__skip__'){ dec.push('- '+id+' ('+title+'): DECIDE LATER'); }
      else { dec.push('- '+id+' ('+title+'): '+v); }
    });
    document.getElementById('pickcount').textContent=n;
    var out='AFFILIATE DASHBOARD PICKS - '+new Date().toISOString().slice(0,10)+'\n';
    if(bl.length){ out+='\n[BOTTOM LINES]\n'+bl.join('\n')+'\n'; }
    if(dec.length){ out+='\n[DECISIONS]\n'+dec.join('\n')+'\n'; }
    if(!bl.length&&!dec.length){ out+='(nothing selected yet)'; }
    document.getElementById('picksout').value=out;
  }
  document.addEventListener('change',function(e){ if(e.target.matches('input[type=radio], textarea.ownbox')) rebuild(); });
  document.addEventListener('input',function(e){ if(e.target.matches('textarea.ownbox')){ var own=e.target.closest('article').querySelector('input[value="__own__"]'); if(own) own.checked=true; rebuild(); } });
  document.getElementById('copybtn').addEventListener('click',function(){
    var t=document.getElementById('picksout');
    navigator.clipboard.writeText(t.value).then(function(){ var m=document.getElementById('copymsg'); m.textContent='Copied! Paste it back to Claude.'; setTimeout(function(){ m.textContent=''; },4000); },
    function(){ var d=document.querySelector('.pickbar details'); d.open=true; t.select(); });
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

Write-Host "Cockpit: $outPath" -ForegroundColor Green
Write-Host "  $totalLive live, $totalDraft draft, $(@($pieces).Count) picks, $totalEmpty empty section(s)" -ForegroundColor Cyan

# ---- desktop shortcut self-heal --------------------------------------------
if (-not $NoShortcut) {
  try {
    $desktop = [Environment]::GetFolderPath('Desktop')
    $lnkPath = Join-Path $desktop "Affiliate Dashboard.lnk"
    $pwshExe = (Get-Process -Id $PID).Path; if (-not $pwshExe) { $pwshExe = "pwsh.exe" }
    $scriptPath = Join-Path $PSScriptRoot "build-dashboard.ps1"
    $ws = New-Object -ComObject WScript.Shell
    $sc = $ws.CreateShortcut($lnkPath)
    $sc.TargetPath = $pwshExe
    $sc.Arguments = "-NoProfile -WindowStyle Hidden -File `"$scriptPath`" -Open"
    $sc.WorkingDirectory = $repoRoot
    $sc.Description = "Rebuild + open the affiliate cockpit"
    $sc.IconLocation = "shell32.dll,21"
    $sc.Save()
    Write-Host "  Desktop shortcut: $lnkPath" -ForegroundColor Cyan
  } catch { Write-Host "  (shortcut skipped: $($_.Exception.Message))" -ForegroundColor Yellow }
}

if ($Open) { Start-Process $outPath }
exit 0

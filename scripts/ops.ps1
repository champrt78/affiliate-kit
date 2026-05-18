# Affiliate Kit — Operations Dashboard generator
#
# Reads real repo state (content files, research notes, TODO, git log) and
# emits a single self-contained HTML page at docs/ops.html. Dark mode,
# editorial register. Open in any browser to see "what's next."
#
# Usage:
#   pwsh scripts/ops.ps1            # regenerate dashboard
#   pwsh scripts/ops.ps1 -Open      # regenerate + open in default browser
#
# Idempotent. Safe to re-run. No side effects beyond writing docs/ops.html.

param(
    [switch]$Open
)

$ErrorActionPreference = "Stop"

$repoRoot   = Split-Path -Parent $PSScriptRoot
$sitesDir   = Join-Path $repoRoot "sites"
$docsDir    = Join-Path $repoRoot "docs"
$researchDir = Join-Path $docsDir "research"
$todoPath   = Join-Path $docsDir "TODO.md"
$outPath    = Join-Path $docsDir "ops.html"

# === Constants ===
$commitmentStart = [datetime]"2026-05-18"
$commitmentDays  = 365
$heroSite        = "mywildlifecam"
$satelliteCold   = @("fussybean", "starteraquarium", "gameovergear")
$satelliteWarm   = @("detailerpicks")
$today           = Get-Date
$todayIso        = $today.ToString("yyyy-MM-dd")
$daysIn          = [int]($today - $commitmentStart).TotalDays
$daysRemaining   = $commitmentDays - $daysIn

# Cadence targets (days between pieces)
$cadenceTargets = @{
    "mywildlifecam"   = 7
    "detailerpicks"   = 18
    "fussybean"       = 180
    "starteraquarium" = 180
    "gameovergear"    = 180
}

# 12-month piece targets per site — adds to 50 (the $100/mo math threshold)
$pieceTargets = @{
    "mywildlifecam"   = 30   # hero — 1/week pace, ships ~30 realistically out of 52 weeks
    "detailerpicks"   = 15   # warm satellite — 1 per 2-3 weeks
    "fussybean"       = 5    # cold, only if hero is ahead
    "starteraquarium" = 0    # dormant until hero proves model
    "gameovergear"    = 0    # dormant until hero proves model
}
$totalTarget = ($pieceTargets.Values | Measure-Object -Sum).Sum

# === Helpers ===

function Get-PieceState {
    param([string]$Path)

    $raw = Get-Content $Path -Raw -ErrorAction SilentlyContinue
    if (-not $raw) { return $null }

    # Frontmatter is between the first pair of --- lines
    $fmMatch = [regex]::Match($raw, "(?s)^---\r?\n(.+?)\r?\n---")
    if (-not $fmMatch.Success) { return $null }
    $fm = $fmMatch.Groups[1].Value

    # Parse fields with light regex
    $title       = [regex]::Match($fm, 'title:\s*"([^"]*)"').Groups[1].Value
    $pubDateStr  = [regex]::Match($fm, 'pubDate:\s*(\S+)').Groups[1].Value
    $lastUpdStr  = [regex]::Match($fm, 'lastUpdated:\s*(\S+)').Groups[1].Value
    $verdict     = [regex]::Match($fm, 'verdict:\s*"([^"]*)"').Groups[1].Value

    # DRAFT detection — empty verdict OR body contains the placeholder
    $isDraft = ($verdict.Trim() -eq "") -or ($raw -match "_The Bottom Line is being written\._")

    $pubDate = $null
    if ($pubDateStr) {
        try { $pubDate = [datetime]::ParseExact($pubDateStr.Trim(), "yyyy-MM-dd", $null) } catch {}
    }

    [pscustomobject]@{
        Path        = $Path
        Slug        = [System.IO.Path]::GetFileNameWithoutExtension($Path)
        Title       = $title
        PubDate     = $pubDate
        LastUpdated = $lastUpdStr
        Verdict     = $verdict
        IsDraft     = $isDraft
        AgeDays     = if ($pubDate) { [int]($today - $pubDate).TotalDays } else { $null }
    }
}

function Get-SiteState {
    param([string]$SiteSlug)

    $contentDir = Join-Path $sitesDir "$SiteSlug/src/content"
    $pieces = @()

    foreach ($subdir in @("reviews", "buyers-guides")) {
        $dir = Join-Path $contentDir $subdir
        if (Test-Path $dir) {
            Get-ChildItem -Path $dir -Filter "*.md" | ForEach-Object {
                $state = Get-PieceState -Path $_.FullName
                if ($state) {
                    $state | Add-Member -NotePropertyName Type -NotePropertyValue $subdir -Force
                    $state | Add-Member -NotePropertyName Site -NotePropertyValue $SiteSlug -Force
                    $pieces += $state
                }
            }
        }
    }

    $live = $pieces | Where-Object { -not $_.IsDraft }
    $drafts = $pieces | Where-Object { $_.IsDraft }

    $lastShipped = $null
    if ($live) {
        $lastShipped = ($live | Sort-Object -Property PubDate -Descending | Select-Object -First 1).PubDate
    }
    $daysSinceLast = if ($lastShipped) { [int]($today - $lastShipped).TotalDays } else { $null }

    $target = $cadenceTargets[$SiteSlug]
    $health = "cold"
    if ($live.Count -eq 0) {
        $health = "cold"
    } elseif ($daysSinceLast -le $target) {
        $health = "green"
    } elseif ($daysSinceLast -le ($target * 1.5)) {
        $health = "amber"
    } else {
        $health = "red"
    }

    [pscustomobject]@{
        Slug          = $SiteSlug
        Pieces        = $pieces
        LiveCount     = $live.Count
        DraftCount    = $drafts.Count
        Drafts        = $drafts
        LastShipped   = $lastShipped
        DaysSinceLast = $daysSinceLast
        CadenceTarget = $target
        Health        = $health
    }
}

function Get-NextActionForSite {
    param([pscustomobject]$Site)

    $slug = $Site.Slug

    # Priority 1: any DRAFT piece waiting on Bottom Line
    if ($Site.DraftCount -gt 0) {
        $first = $Site.Drafts | Select-Object -First 1
        return [pscustomobject]@{
            Headline = "Write Bottom Line on $($first.Slug)"
            Reason   = "Piece is scaffolded and noindex-gated. Highest leverage — already 90% shipped."
            Command  = "/bottom-line-helper $($first.Slug)"
            Priority = "high"
        }
    }

    # Cold satellites: defer until hero proves the model
    if ($satelliteCold -contains $slug) {
        return [pscustomobject]@{
            Headline = "Defer"
            Reason   = "Hero-first phase. Revisit when mywildlifecam hits 15+ pieces (currently $((Get-SiteState $heroSite).LiveCount))."
            Command  = ""
            Priority = "defer"
        }
    }

    # Priority 2: behind cadence
    if ($Site.DaysSinceLast -gt $Site.CadenceTarget) {
        return [pscustomobject]@{
            Headline = "Behind cadence ($($Site.DaysSinceLast)d since last; target $($Site.CadenceTarget)d)"
            Reason   = "Ship the next piece. Run /scout-topics to surface candidates, then /research-product + /scaffold-piece."
            Command  = "/scout-topics"
            Priority = "high"
        }
    }

    # Priority 3: on clock
    $daysToNext = $Site.CadenceTarget - $Site.DaysSinceLast
    return [pscustomobject]@{
        Headline = "On clock — next piece due in ~$daysToNext day(s)"
        Reason   = "Cadence healthy. Use the time to scout topics or queue research for next piece."
        Command  = "/scout-topics"
        Priority = "ok"
    }
}

function Get-TodoNow {
    if (-not (Test-Path $todoPath)) { return @() }
    $raw = Get-Content $todoPath -Raw
    $nowMatch = [regex]::Match($raw, "(?s)## Now\s*(.+?)(?=##\s|\Z)")
    if (-not $nowMatch.Success) { return @() }

    $section = $nowMatch.Groups[1].Value
    $items = @()
    foreach ($line in $section -split "`r?`n") {
        if ($line -match '^\s*-\s*\[\s*\]\s*(.+)$') {
            $items += $Matches[1].Trim()
        }
    }
    return $items
}

function Get-ResearchNotes {
    if (-not (Test-Path $researchDir)) { return @() }
    Get-ChildItem -Path $researchDir -Filter "*.md" | ForEach-Object {
        $first = Get-Content $_.FullName -TotalCount 5 | Select-String -Pattern '^#\s+(.+)$' | Select-Object -First 1
        $title = if ($first) { $first.Matches.Groups[1].Value } else { $_.BaseName }
        [pscustomobject]@{
            File  = $_.Name
            Title = $title
            Path  = $_.FullName
            Age   = [int]($today - $_.LastWriteTime).TotalDays
        }
    }
}

function Get-RecentCommits {
    Push-Location $repoRoot
    try {
        $log = git log --since="14 days ago" --format="%h|%s|%ad" --date=short 2>$null
        if (-not $log) { return @() }
        $log | ForEach-Object {
            $parts = $_ -split '\|'
            [pscustomobject]@{
                Hash    = $parts[0]
                Subject = $parts[1]
                Date    = $parts[2]
            }
        } | Select-Object -First 10
    } finally {
        Pop-Location
    }
}

# === Compute all state ===

$allSites = @("mywildlifecam", "detailerpicks", "fussybean", "starteraquarium", "gameovergear")
$siteStates = @{}
foreach ($s in $allSites) {
    $siteStates[$s] = Get-SiteState -SiteSlug $s
}

$totalLive   = ($siteStates.Values | Measure-Object -Property LiveCount -Sum).Sum
$totalDrafts = ($siteStates.Values | Measure-Object -Property DraftCount -Sum).Sum

$todoNow      = Get-TodoNow
$researchNotes = Get-ResearchNotes
$recentCommits = Get-RecentCommits

# Refresh sweep candidates — live pieces > 90 days old
$refreshCandidates = @()
foreach ($s in $siteStates.Values) {
    $refreshCandidates += $s.Pieces | Where-Object { -not $_.IsDraft -and $_.AgeDays -ne $null -and $_.AgeDays -gt 90 }
}

# Goal trajectory — pace projection
$paceFraction = if ($daysIn -gt 0) { $daysIn / $commitmentDays } else { 0 }
$expectedByNow = [math]::Round($totalTarget * $paceFraction, 1)
$paceDelta = $totalLive - $expectedByNow
$piecesPerDayActual = if ($daysIn -gt 0) { $totalLive / $daysIn } else { 0 }
$projectedYearEnd = [math]::Round($piecesPerDayActual * $commitmentDays, 0)

$paceLabel = if ([math]::Abs($paceDelta) -lt 1) { "on pace" }
             elseif ($paceDelta -gt 0) { "$([math]::Round($paceDelta,1)) ahead" }
             else { "$([math]::Round([math]::Abs($paceDelta),1)) behind" }

$paceColor = if ($paceDelta -ge 0) { "green" } elseif ($paceDelta -gt -3) { "amber" } else { "red" }

# === Render HTML ===

# Goal-progress bar chart rows (per-site)
$goalRowsHtml = ""
foreach ($slug in $allSites) {
    $s = $siteStates[$slug]
    $target = $pieceTargets[$slug]
    $actual = $s.LiveCount
    $pct = if ($target -gt 0) { [math]::Min(100, [math]::Round(($actual / $target) * 100, 1)) } else { 0 }
    $isDormant = ($target -eq 0)

    $fillClass = if ($isDormant) { "fill-dormant" } elseif ($pct -ge 100) { "fill-done" } elseif ($pct -ge 50) { "fill-mid" } else { "fill-low" }
    $targetLabel = if ($isDormant) { "dormant" } else { "$actual / $target" }
    $widthStyle = if ($isDormant) { "width: 0%" } else { "width: $pct%" }

    $goalRowsHtml += @"
    <div class="goal-row">
      <div class="goal-label">$slug</div>
      <div class="goal-track">
        <div class="goal-fill $fillClass" style="$widthStyle"></div>
        <div class="goal-value">$targetLabel</div>
      </div>
    </div>
"@
}

# Total progress bar
$totalPct = if ($totalTarget -gt 0) { [math]::Round(($totalLive / $totalTarget) * 100, 1) } else { 0 }
$paceFractionPct = [math]::Round($paceFraction * 100, 1)

$siteCardsHtml = ""
foreach ($slug in $allSites) {
    $s = $siteStates[$slug]
    $next = Get-NextActionForSite -Site $s

    $healthClass = "h-$($s.Health)"
    $healthLabel = switch ($s.Health) {
        "green" { "ON CADENCE" }
        "amber" { "BEHIND" }
        "red"   { "STALE" }
        "cold"  { "DORMANT" }
    }
    $lastStr = if ($s.LastShipped) { "$($s.DaysSinceLast)d ago" } else { "never" }
    $cmdHtml = if ($next.Command) { "<code class=`"cmd`">$($next.Command)</code>" } else { "" }
    $priorityClass = "p-$($next.Priority)"

    $siteCardsHtml += @"
  <article class="site-card $healthClass $priorityClass">
    <header class="site-card__head">
      <div>
        <div class="site-card__slug">$slug</div>
        <div class="site-card__stats">$($s.LiveCount) live · $($s.DraftCount) draft · last $lastStr</div>
      </div>
      <span class="health-pill">$healthLabel</span>
    </header>
    <div class="site-card__action">
      <div class="action-headline">$($next.Headline)</div>
      <p class="action-reason">$($next.Reason)</p>
      $cmdHtml
    </div>
  </article>
"@
}

# DRAFT high-leverage band
$draftsHtml = ""
$allDrafts = @()
foreach ($s in $siteStates.Values) { $allDrafts += $s.Drafts }
if ($allDrafts.Count -gt 0) {
    $items = ""
    foreach ($d in $allDrafts) {
        $items += "<li><strong>$($d.Site)</strong> · <span class=`"slug-mono`">$($d.Slug)</span> <code class=`"cmd`">/bottom-line-helper $($d.Slug)</code></li>"
    }
    $draftsHtml = @"
  <section class="band band--warning">
    <h2>$($allDrafts.Count) piece(s) waiting on Bottom Line</h2>
    <p class="band__sub">Highest leverage — scaffolded, lint-clean, sitting at noindex until you write the verdict.</p>
    <ul class="draft-list">$items</ul>
  </section>
"@
}

# Refresh sweep
$refreshHtml = ""
if ($refreshCandidates.Count -gt 0) {
    $items = ""
    foreach ($p in $refreshCandidates) {
        $items += "<li><strong>$($p.Site)</strong> · <span class=`"slug-mono`">$($p.Slug)</span> <span class=`"muted`">($($p.AgeDays)d old)</span></li>"
    }
    $refreshHtml = @"
  <section class="card-section">
    <h2>Refresh sweep candidates ($($refreshCandidates.Count))</h2>
    <p class="muted-sub">Pieces past 90 days. Re-check prices, links, stale year mentions.</p>
    <ul class="plain-list">$items</ul>
  </section>
"@
} else {
    $refreshHtml = @"
  <section class="card-section">
    <h2>Refresh sweep candidates</h2>
    <p class="muted-sub">No pieces past 90 days yet (system is still young — first ones won't age in until ~2026-08).</p>
  </section>
"@
}

# TODO Now items
$todoHtml = ""
if ($todoNow.Count -gt 0) {
    $items = ""
    foreach ($t in $todoNow) {
        $items += "<li>$t</li>"
    }
    $todoHtml = @"
  <section class="card-section">
    <h2>TODO · Now</h2>
    <p class="muted-sub">From <code>docs/TODO.md</code>. $($todoNow.Count) open.</p>
    <ul class="plain-list">$items</ul>
  </section>
"@
}

# Research notes
$researchHtml = ""
if ($researchNotes.Count -gt 0) {
    $items = ""
    foreach ($r in $researchNotes) {
        $items += "<li><span class=`"slug-mono`">$($r.File)</span> <span class=`"muted`">($($r.Age)d old)</span><br><span class=`"research-title`">$($r.Title)</span></li>"
    }
    $researchHtml = @"
  <section class="card-section">
    <h2>Research notes available ($($researchNotes.Count))</h2>
    <p class="muted-sub">Material ready to mine for the next piece. Use with <code>/scaffold-piece</code>.</p>
    <ul class="plain-list">$items</ul>
  </section>
"@
}

# Recent commits
$commitsHtml = ""
if ($recentCommits.Count -gt 0) {
    $items = ""
    foreach ($c in $recentCommits) {
        $items += "<li><span class=`"commit-hash`">$($c.Hash)</span> <span class=`"muted`">$($c.Date)</span> $($c.Subject)</li>"
    }
    $commitsHtml = @"
  <section class="card-section">
    <h2>Recent commits (last 14 days)</h2>
    <ul class="plain-list compact">$items</ul>
  </section>
"@
}

# === Final HTML ===

$genTime = $today.ToString("yyyy-MM-dd HH:mm")
$daysPct = [math]::Round(($daysIn / $commitmentDays) * 100, 1)

$html = @"
<!doctype html>
<html lang="en">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width,initial-scale=1">
<title>Affiliate Kit · Ops</title>
<meta name="robots" content="noindex, nofollow">
<link rel="preconnect" href="https://fonts.googleapis.com">
<link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
<link href="https://fonts.googleapis.com/css2?family=Instrument+Serif:ital@0;1&family=Inter+Tight:wght@400;500;600;700&family=JetBrains+Mono:wght@400;500&display=swap" rel="stylesheet">
<style>
  :root {
    --bg:         #0B0E13;
    --surface:    #161B22;
    --surface-2:  #1C2128;
    --surface-3:  #232A33;
    --line:       #2A3038;
    --line-soft:  #1F252C;
    --ink:        #E6EAEF;
    --ink-soft:   #C2C9D3;
    --muted:      #8B98A8;
    --muted-deep: #5E6976;
    --steel:      #4A8FD4;
    --steel-deep: #2C5E8C;
    --green:      #5FB37C;
    --amber:      #E8B86A;
    --red:        #E07B7B;
    --highlight:  #F7E9C8;
    --font-serif: "Instrument Serif", Georgia, serif;
    --font-sans:  "Inter Tight", -apple-system, BlinkMacSystemFont, "Segoe UI", sans-serif;
    --font-mono:  "JetBrains Mono", ui-monospace, Consolas, monospace;
  }

  *, *::before, *::after { box-sizing: border-box; }
  html { font-size: 16px; }
  body {
    margin: 0;
    background: var(--bg);
    color: var(--ink);
    font-family: var(--font-sans);
    font-size: 15px;
    line-height: 1.55;
    -webkit-font-smoothing: antialiased;
    text-rendering: optimizeLegibility;
  }

  .wrap {
    max-width: 1180px;
    margin: 0 auto;
    padding: 56px 32px 80px;
  }

  /* ===== Header ===== */
  header.top {
    display: flex;
    justify-content: space-between;
    align-items: flex-end;
    gap: 32px;
    padding-bottom: 28px;
    margin-bottom: 40px;
    border-bottom: 1px solid var(--line);
  }
  .brand {
    font-family: var(--font-serif);
    font-size: 38px;
    line-height: 1.05;
    letter-spacing: -0.012em;
    color: var(--ink);
    margin: 0;
  }
  .brand em { font-style: italic; color: var(--steel); }
  .brand__sub {
    font-family: var(--font-sans);
    font-size: 11px;
    font-weight: 600;
    letter-spacing: 0.16em;
    text-transform: uppercase;
    color: var(--muted);
    margin-top: 8px;
    display: flex;
    align-items: center;
    gap: 14px;
  }
  .brand__sub::before {
    content: '';
    display: inline-block;
    width: 28px; height: 1px;
    background: var(--steel);
  }
  .stamp {
    text-align: right;
    font-family: var(--font-mono);
    font-size: 12px;
    color: var(--muted);
    line-height: 1.7;
  }
  .stamp .stamp__line { display: block; }

  /* ===== Goal trajectory section ===== */
  .goal {
    background: var(--surface);
    border: 1px solid var(--line-soft);
    border-radius: 4px;
    padding: 28px 32px;
    margin-bottom: 40px;
  }
  .goal__head {
    display: flex;
    justify-content: space-between;
    align-items: baseline;
    margin-bottom: 4px;
    gap: 16px;
    flex-wrap: wrap;
  }
  .goal h2 {
    font-family: var(--font-serif);
    font-size: 28px;
    line-height: 1.1;
    margin: 0;
    color: var(--ink);
  }
  .goal h2 em { font-style: italic; color: var(--steel); }
  .goal__pace {
    font-family: var(--font-mono);
    font-size: 12px;
    padding: 4px 10px;
    border-radius: 2px;
    letter-spacing: 0.02em;
  }
  .goal__pace.pace-green { background: rgba(95,179,124,0.12); color: var(--green); }
  .goal__pace.pace-amber { background: rgba(232,184,106,0.12); color: var(--amber); }
  .goal__pace.pace-red   { background: rgba(224,123,123,0.12); color: var(--red); }
  .goal__sub {
    font-size: 13px;
    color: var(--muted);
    margin: 0 0 22px;
  }

  /* Total progress bar — bigger and at top */
  .goal-total {
    margin-bottom: 28px;
    padding-bottom: 24px;
    border-bottom: 1px solid var(--line-soft);
  }
  .goal-total__head {
    display: flex;
    justify-content: space-between;
    align-items: baseline;
    margin-bottom: 10px;
  }
  .goal-total__label {
    font-family: var(--font-sans);
    font-size: 11px;
    font-weight: 600;
    letter-spacing: 0.14em;
    text-transform: uppercase;
    color: var(--muted);
  }
  .goal-total__value {
    font-family: var(--font-serif);
    font-size: 22px;
    color: var(--ink);
  }
  .goal-total__value em { font-style: italic; color: var(--steel); }
  .goal-total__track {
    position: relative;
    height: 14px;
    background: var(--surface-3);
    border-radius: 2px;
    overflow: hidden;
  }
  .goal-total__fill {
    position: absolute;
    inset: 0 auto 0 0;
    background: linear-gradient(90deg, var(--steel-deep) 0%, var(--steel) 100%);
    transition: width 400ms ease;
  }
  /* Time marker on the total bar */
  .goal-total__marker {
    position: absolute;
    top: -3px;
    bottom: -3px;
    width: 2px;
    background: var(--highlight);
    opacity: 0.85;
  }
  .goal-total__marker::after {
    content: 'day ' attr(data-day);
    position: absolute;
    top: -18px;
    left: 50%;
    transform: translateX(-50%);
    font-family: var(--font-mono);
    font-size: 10px;
    color: var(--highlight);
    white-space: nowrap;
  }

  /* Per-site rows */
  .goal-rows {
    display: flex;
    flex-direction: column;
    gap: 14px;
  }
  .goal-row {
    display: grid;
    grid-template-columns: 140px 1fr;
    gap: 16px;
    align-items: center;
  }
  .goal-label {
    font-family: var(--font-mono);
    font-size: 12px;
    color: var(--ink-soft);
    letter-spacing: 0.02em;
  }
  .goal-track {
    position: relative;
    height: 22px;
    background: var(--surface-3);
    border-radius: 2px;
    overflow: hidden;
  }
  .goal-fill {
    position: absolute;
    inset: 0 auto 0 0;
    transition: width 400ms ease;
  }
  .goal-fill.fill-low  { background: linear-gradient(90deg, #1F4060 0%, #4A8FD4 100%); }
  .goal-fill.fill-mid  { background: linear-gradient(90deg, #2C5E8C 0%, #5FB37C 100%); }
  .goal-fill.fill-done { background: linear-gradient(90deg, #2C8F4F 0%, #5FB37C 100%); }
  .goal-fill.fill-dormant { background: transparent; }
  .goal-value {
    position: absolute;
    right: 10px;
    top: 50%;
    transform: translateY(-50%);
    font-family: var(--font-mono);
    font-size: 11px;
    color: var(--ink);
    text-shadow: 0 1px 2px rgba(0,0,0,0.4);
    letter-spacing: 0.02em;
  }
  @media (max-width: 600px) {
    .goal-row { grid-template-columns: 1fr; gap: 4px; }
    .goal-label { font-size: 11px; }
  }

  /* ===== Overview row ===== */
  .overview {
    display: grid;
    grid-template-columns: repeat(4, 1fr);
    gap: 16px;
    margin-bottom: 40px;
  }
  .stat {
    background: var(--surface);
    border: 1px solid var(--line-soft);
    padding: 18px 20px;
    border-radius: 4px;
  }
  .stat__label {
    font-size: 10px;
    font-weight: 600;
    letter-spacing: 0.14em;
    text-transform: uppercase;
    color: var(--muted);
    margin-bottom: 8px;
  }
  .stat__value {
    font-family: var(--font-serif);
    font-size: 32px;
    line-height: 1;
    color: var(--ink);
  }
  .stat__value em { font-style: italic; color: var(--steel); }
  .stat__sub {
    font-size: 12px;
    color: var(--muted-deep);
    margin-top: 6px;
  }
  @media (max-width: 760px) {
    .overview { grid-template-columns: repeat(2, 1fr); }
  }

  /* ===== High-leverage band (drafts waiting) ===== */
  .band {
    background: linear-gradient(135deg, #2D2218 0%, #1F1810 100%);
    border: 1px solid #553F22;
    border-left: 3px solid var(--amber);
    border-radius: 4px;
    padding: 24px 28px;
    margin-bottom: 32px;
  }
  .band h2 {
    font-family: var(--font-serif);
    font-size: 26px;
    line-height: 1.1;
    margin: 0 0 6px;
    color: var(--highlight);
  }
  .band__sub {
    color: var(--ink-soft);
    margin: 0 0 16px;
    font-size: 14px;
  }
  .draft-list {
    list-style: none;
    padding: 0;
    margin: 0;
    display: flex;
    flex-direction: column;
    gap: 8px;
  }
  .draft-list li {
    padding: 10px 14px;
    background: rgba(0,0,0,0.25);
    border-radius: 3px;
    font-size: 14px;
    display: flex;
    flex-wrap: wrap;
    align-items: center;
    gap: 12px;
  }

  /* ===== Section heads ===== */
  h2.section-h {
    font-family: var(--font-serif);
    font-size: 28px;
    line-height: 1.1;
    letter-spacing: -0.012em;
    color: var(--ink);
    margin: 0 0 8px;
  }
  .section-eyebrow {
    font-size: 11px;
    font-weight: 600;
    letter-spacing: 0.16em;
    text-transform: uppercase;
    color: var(--steel);
    margin-bottom: 16px;
    display: flex;
    align-items: center;
    gap: 14px;
  }
  .section-eyebrow::before {
    content: '';
    display: inline-block;
    width: 28px; height: 1px;
    background: var(--steel);
  }

  /* ===== Site grid ===== */
  .site-grid-wrap { margin-bottom: 48px; }
  .site-grid {
    display: grid;
    grid-template-columns: repeat(2, 1fr);
    gap: 18px;
  }
  @media (max-width: 760px) {
    .site-grid { grid-template-columns: 1fr; }
  }
  .site-card {
    background: var(--surface);
    border: 1px solid var(--line-soft);
    border-left: 3px solid var(--muted-deep);
    border-radius: 4px;
    padding: 22px 24px;
    display: flex;
    flex-direction: column;
    gap: 16px;
    transition: border-color 200ms ease;
  }
  .site-card.h-green  { border-left-color: var(--green); }
  .site-card.h-amber  { border-left-color: var(--amber); }
  .site-card.h-red    { border-left-color: var(--red); }
  .site-card.h-cold   { border-left-color: var(--muted-deep); opacity: 0.7; }
  .site-card.p-high   { border-color: rgba(232, 184, 106, 0.3); }
  .site-card__head {
    display: flex;
    justify-content: space-between;
    align-items: flex-start;
    gap: 12px;
  }
  .site-card__slug {
    font-family: var(--font-serif);
    font-size: 22px;
    line-height: 1.1;
    letter-spacing: -0.008em;
    color: var(--ink);
  }
  .site-card__stats {
    font-family: var(--font-mono);
    font-size: 11px;
    color: var(--muted);
    margin-top: 4px;
    letter-spacing: 0.02em;
  }
  .health-pill {
    font-family: var(--font-sans);
    font-size: 10px;
    font-weight: 600;
    letter-spacing: 0.12em;
    padding: 4px 8px;
    border-radius: 2px;
    text-transform: uppercase;
    background: var(--surface-3);
    color: var(--muted);
    flex-shrink: 0;
  }
  .h-green .health-pill { background: rgba(95, 179, 124, 0.15); color: var(--green); }
  .h-amber .health-pill { background: rgba(232, 184, 106, 0.15); color: var(--amber); }
  .h-red   .health-pill { background: rgba(224, 123, 123, 0.15); color: var(--red); }

  .action-headline {
    font-family: var(--font-sans);
    font-size: 15px;
    font-weight: 600;
    color: var(--ink);
    margin-bottom: 6px;
    line-height: 1.4;
  }
  .action-reason {
    font-size: 13px;
    color: var(--muted);
    margin: 0 0 14px;
    line-height: 1.55;
  }
  code.cmd {
    display: inline-block;
    font-family: var(--font-mono);
    font-size: 12px;
    font-weight: 500;
    color: var(--steel);
    background: rgba(74, 143, 212, 0.08);
    border: 1px solid rgba(74, 143, 212, 0.2);
    padding: 6px 10px;
    border-radius: 3px;
    letter-spacing: 0.01em;
    user-select: all;
  }

  /* ===== Card sections (below the fold) ===== */
  .section-row {
    display: grid;
    grid-template-columns: 1fr 1fr;
    gap: 24px;
    margin-bottom: 40px;
  }
  @media (max-width: 760px) {
    .section-row { grid-template-columns: 1fr; }
  }
  .card-section {
    background: var(--surface);
    border: 1px solid var(--line-soft);
    border-radius: 4px;
    padding: 24px 26px;
  }
  .card-section h2 {
    font-family: var(--font-serif);
    font-size: 22px;
    line-height: 1.1;
    margin: 0 0 4px;
    color: var(--ink);
  }
  .muted-sub {
    font-size: 13px;
    color: var(--muted);
    margin: 0 0 16px;
  }
  .plain-list {
    list-style: none;
    padding: 0;
    margin: 0;
    display: flex;
    flex-direction: column;
    gap: 10px;
  }
  .plain-list.compact { gap: 6px; }
  .plain-list li {
    font-size: 13px;
    line-height: 1.5;
    padding: 8px 0;
    border-bottom: 1px solid var(--line-soft);
    color: var(--ink-soft);
  }
  .plain-list li:last-child { border-bottom: 0; }
  .slug-mono {
    font-family: var(--font-mono);
    font-size: 12px;
    color: var(--ink-soft);
  }
  .commit-hash {
    font-family: var(--font-mono);
    font-size: 11px;
    color: var(--steel);
    margin-right: 6px;
  }
  .research-title {
    font-size: 12px;
    color: var(--muted);
    font-style: italic;
  }
  .muted { color: var(--muted-deep); font-size: 11px; }

  /* ===== Footer ===== */
  .foot {
    margin-top: 56px;
    padding-top: 24px;
    border-top: 1px solid var(--line);
    text-align: center;
    color: var(--muted-deep);
    font-size: 12px;
    line-height: 1.7;
  }
  .foot code {
    font-family: var(--font-mono);
    background: var(--surface-2);
    padding: 2px 6px;
    border-radius: 2px;
    color: var(--ink-soft);
  }
</style>
</head>
<body>
<div class="wrap">

  <header class="top">
    <div>
      <h1 class="brand">Affiliate <em>Kit</em> · Ops</h1>
      <div class="brand__sub">What to do next</div>
    </div>
    <div class="stamp">
      <span class="stamp__line">Generated $genTime</span>
      <span class="stamp__line">Day $daysIn / $commitmentDays · $daysPct% in</span>
      <span class="stamp__line">Target: \$100/mo by month 12</span>
    </div>
  </header>

  <section class="overview">
    <div class="stat">
      <div class="stat__label">Total live pieces</div>
      <div class="stat__value">$totalLive</div>
      <div class="stat__sub">across 5 sites</div>
    </div>
    <div class="stat">
      <div class="stat__label">DRAFT (waiting on Bottom Line)</div>
      <div class="stat__value">$totalDrafts</div>
      <div class="stat__sub">noindex-gated</div>
    </div>
    <div class="stat">
      <div class="stat__label">Days into 12-month run</div>
      <div class="stat__value">$daysIn</div>
      <div class="stat__sub">$daysRemaining remaining</div>
    </div>
    <div class="stat">
      <div class="stat__label">Pieces this week</div>
      <div class="stat__value">$(($recentCommits | Where-Object { $_.Subject -match 'feat\(.+?\):.*piece|review|guide|Bottom Line' }).Count)</div>
      <div class="stat__sub">target: 1 hero/week</div>
    </div>
  </section>

  <section class="goal">
    <div class="goal__head">
      <h2>Goal · <em>$totalTarget pieces</em> by month 12</h2>
      <span class="goal__pace pace-$paceColor">$paceLabel</span>
    </div>
    <p class="goal__sub">Target maps to the `$100/mo` realized-revenue line — affiliate-site math typically needs ~50 pieces before meaningful traffic compounds. Time marker shows where today sits on the 365-day track.</p>

    <div class="goal-total">
      <div class="goal-total__head">
        <span class="goal-total__label">Total progress</span>
        <span class="goal-total__value"><em>$totalLive</em> / $totalTarget · $totalPct%</span>
      </div>
      <div class="goal-total__track">
        <div class="goal-total__fill" style="width: $totalPct%"></div>
        <div class="goal-total__marker" data-day="$daysIn" style="left: $paceFractionPct%"></div>
      </div>
    </div>

    <div class="goal-rows">
$goalRowsHtml
    </div>
  </section>

$draftsHtml

  <div class="site-grid-wrap">
    <div class="section-eyebrow">Per-site next action</div>
    <h2 class="section-h" style="margin-bottom: 22px;">Where to point the work</h2>
    <div class="site-grid">
$siteCardsHtml
    </div>
  </div>

  <div class="section-row">
$todoHtml
$refreshHtml
  </div>

  <div class="section-row">
$researchHtml
$commitsHtml
  </div>

  <footer class="foot">
    Generated from real repo state by <code>pwsh scripts/ops.ps1</code>. Re-run any time to refresh.<br>
    Sources: <code>sites/&lt;slug&gt;/src/content/</code>, <code>docs/research/</code>, <code>docs/TODO.md</code>, <code>git log</code>.
  </footer>

</div>
</body>
</html>
"@

# Write the file
$html | Out-File -FilePath $outPath -Encoding UTF8 -NoNewline

Write-Host "[ok] Generated $outPath"
Write-Host "     $totalLive live pieces · $totalDrafts drafts · $($recentCommits.Count) commits in last 14d"

if ($Open) {
    Start-Process $outPath
    Write-Host "     Opened in default browser."
} else {
    Write-Host "     Open with: start $outPath"
}

# Affiliate Kit — Operations Dashboard generator
#
# Reads real repo state (content files, research notes, TODO, git log) and
# emits a single self-contained HTML page at docs/ops.html. Dark mode,
# editorial app shell: top "Do this next" strip + left sidebar of sites +
# right drill-down pane.
#
# Usage:
#   pwsh scripts/ops.ps1            # regenerate dashboard
#   pwsh scripts/ops.ps1 -Open      # regenerate + open in default browser

param(
    [switch]$Open
)

$ErrorActionPreference = "Stop"

$repoRoot     = Split-Path -Parent $PSScriptRoot
$sitesDir     = Join-Path $repoRoot "sites"
$docsDir      = Join-Path $repoRoot "docs"
$researchDir  = Join-Path $docsDir "research"
$todoPath     = Join-Path $docsDir "TODO.md"
$outPath      = Join-Path $docsDir "ops.html"

# === Commitment constants ===
$commitmentStart = [datetime]"2026-05-18"
$commitmentDays  = 365
$heroSite        = "mywildlifecam"
$satelliteCold   = @("fussybean", "starteraquarium", "gameovergear")
$today           = Get-Date
$daysIn          = [int]($today - $commitmentStart).TotalDays
$daysRemaining   = $commitmentDays - $daysIn

$cadenceTargets = @{
    "mywildlifecam"   = 7
    "detailerpicks"   = 18
    "fussybean"       = 180
    "starteraquarium" = 180
    "gameovergear"    = 180
}

$pieceTargets = @{
    "mywildlifecam"   = 30
    "detailerpicks"   = 15
    "fussybean"       = 5
    "starteraquarium" = 0
    "gameovergear"    = 0
}
$totalTarget = ($pieceTargets.Values | Measure-Object -Sum).Sum

# Map a site to keyword tokens used to match research notes / topics
$siteKeywords = @{
    "mywildlifecam"   = @("trail-cam", "trail cam", "wildlife", "cellular", "tactacam", "spypoint", "moultrie", "stealth cam", "bushnell", "muddy", "browning")
    "detailerpicks"   = @("detail", "wash", "foam", "soap", "ceramic", "polish", "wheel", "wax", "sealant", "mitt", "shampoo")
    "fussybean"       = @("coffee", "espresso", "grinder", "pour-over", "decaf")
    "starteraquarium" = @("aquarium", "fish", "tank", "filter", "heater", "planted")
    "gameovergear"    = @("retro", "arcade", "crt", "controller", "emulator", "gaming")
}

# === Data extraction ===

function Get-PieceState {
    param([string]$Path)
    $raw = Get-Content $Path -Raw -ErrorAction SilentlyContinue
    if (-not $raw) { return $null }

    $fmMatch = [regex]::Match($raw, "(?s)^---\r?\n(.+?)\r?\n---")
    if (-not $fmMatch.Success) { return $null }
    $fm = $fmMatch.Groups[1].Value

    $title       = [regex]::Match($fm, 'title:\s*"([^"]*)"').Groups[1].Value
    $pubDateStr  = [regex]::Match($fm, 'pubDate:\s*(\S+)').Groups[1].Value
    $lastUpdStr  = [regex]::Match($fm, 'lastUpdated:\s*(\S+)').Groups[1].Value
    $verdict     = [regex]::Match($fm, 'verdict:\s*"([^"]*)"').Groups[1].Value

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

    $live   = @($pieces | Where-Object { -not $_.IsDraft })
    $drafts = @($pieces | Where-Object { $_.IsDraft })

    $lastShipped = $null
    if ($live.Count -gt 0) {
        $lastShipped = ($live | Sort-Object -Property PubDate -Descending | Select-Object -First 1).PubDate
    }
    $daysSinceLast = if ($lastShipped) { [int]($today - $lastShipped).TotalDays } else { $null }

    $target = $cadenceTargets[$SiteSlug]
    $health = "cold"
    if ($live.Count -eq 0) { $health = "cold" }
    elseif ($daysSinceLast -le $target) { $health = "green" }
    elseif ($daysSinceLast -le ($target * 1.5)) { $health = "amber" }
    else { $health = "red" }

    [pscustomobject]@{
        Slug          = $SiteSlug
        Pieces        = $pieces
        Live          = $live
        Drafts        = $drafts
        LiveCount     = $live.Count
        DraftCount    = $drafts.Count
        LastShipped   = $lastShipped
        DaysSinceLast = $daysSinceLast
        CadenceTarget = $target
        Health        = $health
    }
}

function Get-NextActionForSite {
    param([pscustomobject]$Site)
    $slug = $Site.Slug

    if ($Site.DraftCount -gt 0) {
        $first = $Site.Drafts | Select-Object -First 1
        return [pscustomobject]@{
            Headline = "Write Bottom Line on $($first.Slug)"
            Reason   = "Already scaffolded and noindex-gated. Highest leverage — 90% shipped."
            Command  = "/bottom-line-helper $($first.Slug)"
            Priority = 1
            PriorityLabel = "high"
        }
    }

    if ($satelliteCold -contains $slug) {
        $heroState = Get-SiteState $heroSite
        return [pscustomobject]@{
            Headline = "Defer — hero-first phase"
            Reason   = "Revisit when mywildlifecam hits 15+ pieces (currently $($heroState.LiveCount))."
            Command  = ""
            Priority = 9
            PriorityLabel = "defer"
        }
    }

    if ($Site.LiveCount -eq 0 -or $Site.DaysSinceLast -gt $Site.CadenceTarget) {
        $sinceLast = if ($Site.DaysSinceLast) { "$($Site.DaysSinceLast)d since last" } else { "no pieces yet" }
        return [pscustomobject]@{
            Headline = "Ship the next piece — behind cadence"
            Reason   = "$sinceLast, target $($Site.CadenceTarget)d. Run /scout-topics for candidates."
            Command  = "/scout-topics"
            Priority = 2
            PriorityLabel = "high"
        }
    }

    $daysToNext = $Site.CadenceTarget - $Site.DaysSinceLast
    return [pscustomobject]@{
        Headline = "On clock — next piece due in ~$daysToNext day(s)"
        Reason   = "Cadence healthy. Use the time to scout topics or queue research."
        Command  = "/scout-topics"
        Priority = 5
        PriorityLabel = "ok"
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

function Get-ResearchForSite {
    param([string]$SiteSlug, [array]$AllNotes)
    $keywords = $siteKeywords[$SiteSlug]
    if (-not $keywords) { return @() }
    $AllNotes | Where-Object {
        $name = $_.File.ToLower() + " " + $_.Title.ToLower()
        $matched = $false
        foreach ($k in $keywords) { if ($name -match [regex]::Escape($k)) { $matched = $true; break } }
        $matched
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
        } | Select-Object -First 12
    } finally {
        Pop-Location
    }
}

# === Compute portfolio state ===

$allSites = @("mywildlifecam", "detailerpicks", "fussybean", "starteraquarium", "gameovergear")
$siteStates = [ordered]@{}
foreach ($s in $allSites) { $siteStates[$s] = Get-SiteState -SiteSlug $s }

$totalLive   = ($siteStates.Values | Measure-Object -Property LiveCount -Sum).Sum
$totalDrafts = ($siteStates.Values | Measure-Object -Property DraftCount -Sum).Sum
$todoNow      = Get-TodoNow
$researchNotes = Get-ResearchNotes
$recentCommits = Get-RecentCommits

# Refresh sweep candidates (>90d live pieces)
$refreshCandidates = @()
foreach ($s in $siteStates.Values) {
    $refreshCandidates += $s.Pieces | Where-Object { -not $_.IsDraft -and $_.AgeDays -ne $null -and $_.AgeDays -gt 90 }
}

# Per-site next actions
$siteActions = @{}
foreach ($s in $allSites) { $siteActions[$s] = Get-NextActionForSite -Site $siteStates[$s] }

# Highest-priority single action across portfolio
$rankedActions = $allSites | ForEach-Object {
    $a = $siteActions[$_]
    [pscustomobject]@{
        Site = $_
        Action = $a
        Priority = $a.Priority
    }
} | Sort-Object Priority
$topAction = $rankedActions | Select-Object -First 1

# Goal trajectory math
$paceFraction = if ($daysIn -gt 0) { $daysIn / $commitmentDays } else { 0 }
$expectedByNow = [math]::Round($totalTarget * $paceFraction, 1)
$paceDelta = $totalLive - $expectedByNow
$paceLabel = if ([math]::Abs($paceDelta) -lt 1) { "on pace" }
             elseif ($paceDelta -gt 0) { "$([math]::Round($paceDelta,1)) ahead" }
             else { "$([math]::Round([math]::Abs($paceDelta),1)) behind" }
$paceColor = if ($paceDelta -ge 0) { "green" } elseif ($paceDelta -gt -3) { "amber" } else { "red" }
$totalPct = if ($totalTarget -gt 0) { [math]::Round(($totalLive / $totalTarget) * 100, 1) } else { 0 }
$paceFractionPct = [math]::Round($paceFraction * 100, 1)

# === Render helpers ===

function HtmlEscape {
    param([string]$Text)
    if (-not $Text) { return "" }
    return $Text.Replace("&", "&amp;").Replace("<", "&lt;").Replace(">", "&gt;").Replace('"', "&quot;")
}

function Format-RecentPieces {
    param([array]$Pieces, [int]$Limit = 20)
    $live = $Pieces | Where-Object { -not $_.IsDraft } | Sort-Object -Property PubDate -Descending | Select-Object -First $Limit
    if ($live.Count -eq 0) { return "<p class='empty'>No pieces yet.</p>" }
    $items = ""
    foreach ($p in $live) {
        $age = if ($p.AgeDays -ne $null) { "$($p.AgeDays)d" } else { "?" }
        $type = if ($p.Type -eq "reviews") { "review" } else { "guide" }
        $title = HtmlEscape $p.Title
        $items += "<li><div class='piece-meta'><span class='piece-age'>$age</span><span class='piece-type'>$type</span></div><div class='piece-title'>$title</div><div class='piece-slug'>$($p.Slug)</div></li>"
    }
    return "<ul class='piece-list'>$items</ul>"
}

# === Build sidebar site list ===

$sidebarItems = ""
foreach ($slug in $allSites) {
    $s = $siteStates[$slug]
    $pillClass = "pill-" + $s.Health
    $pillLabel = switch ($s.Health) {
        "green" { "•" }; "amber" { "•" }; "red" { "•" }; "cold" { "•" }
    }
    $stats = "$($s.LiveCount) live"
    if ($s.DraftCount -gt 0) { $stats += " · $($s.DraftCount) draft" }
    $sidebarItems += @"
      <li><a href="#site-$slug" data-site="$slug">
        <span class="nav-pill $pillClass"></span>
        <span class="nav-text">
          <span class="nav-slug">$slug</span>
          <span class="nav-stats">$stats</span>
        </span>
      </a></li>
"@
}

# === Build per-site drill-downs ===

function Build-SiteDrillDown {
    param([string]$SiteSlug, [pscustomobject]$Site, [pscustomobject]$Action, [array]$AllResearch)

    $healthLabel = switch ($Site.Health) {
        "green" { "ON CADENCE" }; "amber" { "BEHIND" }; "red" { "STALE" }; "cold" { "DORMANT" }
    }
    $lastStr = if ($Site.LastShipped) { "$($Site.DaysSinceLast)d ago ($($Site.LastShipped.ToString('yyyy-MM-dd')))" } else { "never" }
    $target = $pieceTargets[$SiteSlug]
    $progress = if ($target -gt 0) { "$($Site.LiveCount) / $target pieces toward 12-mo target" } else { "dormant (revisit when hero ships 15+)" }
    $pct = if ($target -gt 0) { [math]::Min(100, [math]::Round(($Site.LiveCount / $target) * 100, 1)) } else { 0 }

    $cmdHtml = if ($Action.Command) { "<code class=`"cmd-pill`">$($Action.Command)</code>" } else { "" }

    # DRAFTs for this site
    $draftHtml = ""
    if ($Site.DraftCount -gt 0) {
        $items = ""
        foreach ($d in $Site.Drafts) {
            $items += "<li><strong>$($d.Slug)</strong> · <code class='cmd-pill cmd-pill--inline'>/bottom-line-helper $($d.Slug)</code></li>"
        }
        $draftHtml = @"
    <section class="panel panel--warning">
      <h3>$($Site.DraftCount) waiting on Bottom Line</h3>
      <ul class="bare-list">$items</ul>
    </section>
"@
    }

    # Recent pieces
    $recentHtml = Format-RecentPieces -Pieces $Site.Pieces -Limit 5

    # Research notes filtered by site
    $relevant = Get-ResearchForSite -SiteSlug $SiteSlug -AllNotes $AllResearch
    $researchHtml = ""
    if ($relevant.Count -gt 0) {
        $items = ""
        foreach ($r in $relevant) {
            $title = HtmlEscape $r.Title
            $items += "<li><div class='piece-meta'><span class='piece-age'>$($r.Age)d</span><span class='piece-type'>research</span></div><div class='piece-title'>$title</div><div class='piece-slug'>$($r.File)</div></li>"
        }
        $researchHtml = "<ul class='piece-list'>$items</ul>"
    } else {
        $researchHtml = "<p class='empty'>No research notes filed for this site yet. Use <code class='inline'>/research-product</code> or <code class='inline'>/scout-topics --&lt;category&gt;</code>.</p>"
    }

    # Refresh candidates for this site
    $siteRefresh = $Site.Pieces | Where-Object { -not $_.IsDraft -and $_.AgeDays -ne $null -and $_.AgeDays -gt 90 }
    $refreshHtml = ""
    if ($siteRefresh.Count -gt 0) {
        $items = ""
        foreach ($p in $siteRefresh) {
            $items += "<li><strong>$($p.Slug)</strong> · $($p.AgeDays)d old</li>"
        }
        $refreshHtml = "<ul class='bare-list'>$items</ul>"
    } else {
        $refreshHtml = "<p class='empty'>No pieces past 90 days.</p>"
    }

    $panelClass = "do-next-panel do-next-panel--$($Action.PriorityLabel)"

    return @"
  <section id="site-$SiteSlug" class="drill drill--site">
    <header class="drill__head">
      <div>
        <div class="drill__eyebrow">Site drill-down</div>
        <h2 class="drill__title">$SiteSlug</h2>
        <p class="drill__stats">$($Site.LiveCount) live · $($Site.DraftCount) draft · last shipped $lastStr</p>
      </div>
      <span class="health-pill health-$($Site.Health)">$healthLabel</span>
    </header>

    <section class="$panelClass">
      <div class="do-next-panel__eyebrow">Do this next</div>
      <h3 class="do-next-panel__title">$(HtmlEscape $Action.Headline)</h3>
      <p class="do-next-panel__reason">$(HtmlEscape $Action.Reason)</p>
      $cmdHtml
    </section>

    <section class="panel panel--progress">
      <div class="panel__eyebrow">12-month progress</div>
      <p class="progress-line">$progress</p>
      <div class="mini-track"><div class="mini-fill" style="width: $pct%"></div></div>
    </section>

$draftHtml

    <div class="panel-grid panel-grid--3col flex-fill">
      <section class="panel">
        <h3>Recent pieces</h3>
        $recentHtml
      </section>
      <section class="panel">
        <h3>Research notes</h3>
        $researchHtml
      </section>
      <section class="panel">
        <h3>Refresh sweep ($($siteRefresh.Count))</h3>
        $refreshHtml
      </section>
    </div>
  </section>
"@
}

$drillDownsHtml = ""
foreach ($slug in $allSites) {
    $drillDownsHtml += Build-SiteDrillDown -SiteSlug $slug -Site $siteStates[$slug] -Action $siteActions[$slug] -AllResearch $researchNotes
}

# === Build "all sites" default view ===

# Goal per-site rows
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

$commitItemsHtml = ""
foreach ($c in $recentCommits) {
    $subj = HtmlEscape $c.Subject
    if ($subj.Length -gt 70) { $subj = $subj.Substring(0, 67) + "..." }
    $commitItemsHtml += "<li><span class='commit-hash'>$($c.Hash)</span> <span class='muted'>$($c.Date)</span> $subj</li>"
}

$researchAllItemsHtml = ""
foreach ($r in $researchNotes) {
    $title = HtmlEscape $r.Title
    $researchAllItemsHtml += "<li><div class='piece-meta'><span class='piece-age'>$($r.Age)d</span><span class='piece-type'>research</span></div><div class='piece-title'>$title</div></li>"
}

# === Build TODO list items ===
$todoSidebarHtml = ""
if ($todoNow.Count -gt 0) {
    foreach ($t in $todoNow) {
        $clean = HtmlEscape ($t -replace '\*\*([^*]+)\*\*', '$1' -replace '`([^`]+)`', '$1')
        $todoSidebarHtml += "<li>$clean</li>"
    }
}

# === Render top "Do this next" strip ===

$topSite = $topAction.Site
$topActionData = $topAction.Action
$topCmd = if ($topActionData.Command) { "<code class=`"cmd-pill cmd-pill--xl`">$($topActionData.Command)</code>" } else { "" }

# === Final HTML ===

$genTime = $today.ToString("yyyy-MM-dd HH:mm")
$daysPct = [math]::Round(($daysIn / $commitmentDays) * 100, 1)
$weekCommits = ($recentCommits | Where-Object { $_.Subject -match 'feat\(.+?\):.*piece|review|guide|Bottom Line' }).Count

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
  html, body { margin: 0; padding: 0; }
  html { font-size: 16px; }
  body {
    background: var(--bg);
    color: var(--ink);
    font-family: var(--font-sans);
    font-size: 13px;
    line-height: 1.5;
    -webkit-font-smoothing: antialiased;
    height: 100vh;
    display: flex;
    flex-direction: column;
    overflow: hidden;
  }

  /* ========================================
     TOP BAR
     ======================================== */
  .topbar {
    display: flex;
    justify-content: space-between;
    align-items: center;
    padding: 10px 20px;
    border-bottom: 1px solid var(--line);
    background: var(--bg);
    flex-shrink: 0;
    gap: 20px;
  }
  .topbar__left {
    display: flex;
    align-items: center;
    gap: 18px;
    min-width: 0;
  }
  .topbar__brand {
    font-family: var(--font-serif);
    font-size: 18px;
    color: var(--ink);
    letter-spacing: -0.01em;
    white-space: nowrap;
  }
  .topbar__brand em { font-style: italic; color: var(--steel); }

  .site-select {
    appearance: none;
    background: var(--surface);
    color: var(--ink);
    border: 1px solid var(--line);
    border-radius: 3px;
    padding: 6px 28px 6px 10px;
    font-family: var(--font-mono);
    font-size: 12px;
    line-height: 1.3;
    cursor: pointer;
    min-width: 220px;
    background-image: linear-gradient(45deg, transparent 50%, var(--steel) 50%),
                      linear-gradient(135deg, var(--steel) 50%, transparent 50%);
    background-position: calc(100% - 14px) 50%, calc(100% - 9px) 50%;
    background-size: 5px 5px, 5px 5px;
    background-repeat: no-repeat;
  }
  .site-select:hover { border-color: var(--steel); }
  .site-select:focus { outline: 1px solid var(--steel); outline-offset: 1px; }

  .topbar__right {
    display: flex;
    align-items: center;
    gap: 18px;
    flex-shrink: 0;
  }
  .topbar__stamp {
    font-family: var(--font-mono);
    font-size: 10px;
    color: var(--muted);
    text-align: right;
    line-height: 1.5;
    white-space: nowrap;
  }
  .topbar__goal {
    display: flex;
    align-items: center;
    gap: 10px;
    padding: 5px 12px;
    background: var(--surface);
    border: 1px solid var(--line-soft);
    border-radius: 3px;
  }
  .topbar__goal-value {
    font-family: var(--font-mono);
    font-size: 11px;
    color: var(--ink);
    white-space: nowrap;
  }
  .topbar__goal-value em { font-style: italic; color: var(--steel); }
  .topbar__goal-track {
    position: relative;
    width: 80px;
    height: 6px;
    background: var(--surface-3);
    border-radius: 1px;
    overflow: hidden;
  }
  .topbar__goal-fill {
    position: absolute;
    inset: 0 auto 0 0;
    background: linear-gradient(90deg, var(--steel-deep), var(--steel));
  }
  .topbar__goal-marker {
    position: absolute;
    top: -1px;
    bottom: -1px;
    width: 1px;
    background: var(--highlight);
  }
  .topbar__pace {
    font-family: var(--font-mono);
    font-size: 10px;
    padding: 2px 6px;
    border-radius: 2px;
  }
  .topbar__pace.pace-green { background: rgba(95,179,124,0.15); color: var(--green); }
  .topbar__pace.pace-amber { background: rgba(232,184,106,0.15); color: var(--amber); }
  .topbar__pace.pace-red   { background: rgba(224,123,123,0.15); color: var(--red); }

  /* ========================================
     "DO THIS NEXT" — priority-aware
     ======================================== */
  .do-next-panel {
    padding: 14px 18px;
    border-radius: 4px;
    background: linear-gradient(135deg, #1A2030 0%, #0E1318 100%);
    border: 1px solid var(--line);
    border-left: 3px solid var(--highlight);
    position: relative;
    flex-shrink: 0;
  }
  .do-next-panel--high { padding: 18px 22px; border-left-width: 3px; }
  .do-next-panel--ok   { padding: 10px 14px; border-left-color: var(--steel-deep); }
  .do-next-panel--defer { padding: 8px 12px; border-left-color: var(--muted-deep); opacity: 0.75; }

  .do-next-panel__eyebrow {
    font-family: var(--font-sans);
    font-size: 9px;
    font-weight: 700;
    letter-spacing: 0.2em;
    text-transform: uppercase;
    color: var(--highlight);
    display: flex;
    align-items: center;
    gap: 12px;
    margin-bottom: 8px;
  }
  .do-next-panel__eyebrow::before {
    content: '';
    width: 20px; height: 1px;
    background: var(--highlight);
  }
  .do-next-panel--ok .do-next-panel__eyebrow { color: var(--muted); margin-bottom: 6px; }
  .do-next-panel--ok .do-next-panel__eyebrow::before { background: var(--muted); }
  .do-next-panel--defer .do-next-panel__eyebrow { color: var(--muted-deep); margin-bottom: 4px; }

  .do-next-panel__title {
    font-family: var(--font-serif);
    font-size: 24px;
    line-height: 1.1;
    letter-spacing: -0.012em;
    color: var(--ink);
    margin: 0 0 6px;
  }
  .do-next-panel--high .do-next-panel__title { font-size: 28px; margin-bottom: 8px; }
  .do-next-panel--ok .do-next-panel__title { font-size: 16px; font-family: var(--font-sans); font-weight: 500; margin-bottom: 4px; letter-spacing: 0; }
  .do-next-panel--defer .do-next-panel__title { font-size: 14px; font-family: var(--font-sans); font-weight: 500; margin: 0; color: var(--ink-soft); }

  .do-next-panel__title em { font-style: italic; color: var(--steel); }
  .do-next-panel__site {
    display: inline-block;
    font-family: var(--font-mono);
    font-size: 11px;
    color: var(--highlight);
    background: rgba(247, 233, 200, 0.08);
    padding: 3px 9px;
    border-radius: 2px;
    margin-bottom: 10px;
  }
  .do-next-panel__reason {
    font-size: 13px;
    color: var(--ink-soft);
    margin: 0 0 12px;
    max-width: 620px;
    line-height: 1.5;
  }
  .do-next-panel--ok .do-next-panel__reason { font-size: 12px; color: var(--muted); margin-bottom: 8px; }
  .do-next-panel--defer .do-next-panel__reason { display: none; }

  .cmd-pill {
    display: inline-block;
    font-family: var(--font-mono);
    font-size: 12px;
    font-weight: 500;
    color: var(--steel);
    background: rgba(74, 143, 212, 0.08);
    border: 1px solid rgba(74, 143, 212, 0.25);
    padding: 6px 12px;
    border-radius: 3px;
    letter-spacing: 0.01em;
    user-select: all;
  }
  .cmd-pill--xl {
    font-size: 14px;
    padding: 10px 16px;
  }
  .cmd-pill--inline {
    margin-left: 8px;
    font-size: 11px;
    padding: 3px 8px;
  }

  /* ========================================
     APP SHELL — single full-width pane
     ======================================== */
  .app {
    flex: 1;
    min-height: 0;
    overflow: hidden;
    display: flex;
    flex-direction: column;
  }

  .sidebar__section {
    padding: 0;
    margin: 0;
  }
  .sidebar__head {
    font-family: var(--font-sans);
    font-size: 9px;
    font-weight: 700;
    letter-spacing: 0.18em;
    text-transform: uppercase;
    color: var(--muted-deep);
    margin: 0 0 10px;
  }

  .nav-list {
    list-style: none;
    margin: 0;
    padding: 0;
  }
  .nav-list a {
    display: flex;
    align-items: center;
    gap: 10px;
    padding: 7px 10px;
    margin: 0 -10px 1px;
    border-radius: 3px;
    text-decoration: none;
    color: var(--ink-soft);
    transition: background 120ms ease, color 120ms ease;
  }
  .nav-list a:hover { background: var(--surface-3); color: var(--ink); }
  .nav-list a.is-active {
    background: rgba(74, 143, 212, 0.10);
    color: var(--ink);
  }
  .nav-list a.is-active .nav-slug { color: var(--steel); font-weight: 500; }

  .nav-pill {
    width: 8px;
    height: 8px;
    border-radius: 50%;
    background: var(--muted-deep);
    flex-shrink: 0;
  }
  .nav-pill.pill-green { background: var(--green); }
  .nav-pill.pill-amber { background: var(--amber); }
  .nav-pill.pill-red   { background: var(--red); }
  .nav-pill.pill-cold  { background: var(--muted-deep); }
  .nav-text {
    display: flex;
    flex-direction: column;
    gap: 1px;
    font-size: 12px;
  }
  .nav-slug { color: inherit; }
  .nav-stats {
    font-family: var(--font-mono);
    font-size: 9px;
    color: var(--muted);
    letter-spacing: 0.02em;
  }

  /* Mini goal in sidebar */
  .mini-goal__value {
    font-family: var(--font-serif);
    font-size: 18px;
    color: var(--ink);
    margin-bottom: 4px;
  }
  .mini-goal__value em { font-style: italic; color: var(--steel); }
  .mini-goal__sub {
    font-family: var(--font-mono);
    font-size: 10px;
    color: var(--muted);
    margin-bottom: 8px;
  }
  .mini-track {
    position: relative;
    height: 8px;
    background: var(--surface-3);
    border-radius: 2px;
    overflow: hidden;
  }
  .mini-fill {
    position: absolute;
    inset: 0 auto 0 0;
    background: linear-gradient(90deg, var(--steel-deep) 0%, var(--steel) 100%);
  }
  .mini-marker {
    position: absolute;
    top: -2px;
    bottom: -2px;
    width: 2px;
    background: var(--highlight);
  }

  /* TODO sidebar list */
  .sidebar-todo {
    list-style: none;
    padding: 0;
    margin: 0;
  }
  .sidebar-todo li {
    font-size: 11px;
    color: var(--ink-soft);
    line-height: 1.4;
    padding: 5px 0;
    border-bottom: 1px solid var(--line-soft);
  }
  .sidebar-todo li:last-child { border-bottom: 0; }

  /* ========================================
     MAIN — full-width pane (NO scroll anywhere)
     ======================================== */
  .main {
    padding: 14px 22px;
    overflow: hidden;
    min-height: 0;
    flex: 1;
    display: flex;
    flex-direction: column;
  }
  .drill {
    display: none;
    flex: 1;
    min-height: 0;
    flex-direction: column;
    gap: 10px;
  }
  .drill.drill--default { display: flex; }
  .drill:target { display: flex; }
  .drill:target ~ .drill--default { display: none; }

  /* The flexible bottom row of the drill — absorbs remaining viewport height */
  .flex-fill {
    flex: 1;
    min-height: 0;
  }
  .flex-fill > .panel {
    min-height: 0;
    display: flex;
    flex-direction: column;
    overflow: hidden;
    margin-bottom: 0;
  }
  /* Sticky panel header — title stays put, list scrolls below */
  .flex-fill > .panel > h3 {
    flex-shrink: 0;
    margin: 0 0 8px;
    padding-bottom: 6px;
    border-bottom: 1px solid var(--line-soft);
  }
  .flex-fill > .panel > ul,
  .flex-fill > .panel > .scroll-area {
    flex: 1;
    min-height: 0;
    overflow-y: auto;
    overscroll-behavior: contain;
  }
  /* Thin dark-mode scrollbar inside panels */
  .flex-fill > .panel > ul::-webkit-scrollbar { width: 6px; }
  .flex-fill > .panel > ul::-webkit-scrollbar-track { background: var(--surface-2); border-radius: 3px; }
  .flex-fill > .panel > ul::-webkit-scrollbar-thumb { background: var(--surface-3); border-radius: 3px; }
  .flex-fill > .panel > ul::-webkit-scrollbar-thumb:hover { background: var(--muted-deep); }

  .drill__head {
    display: flex;
    justify-content: space-between;
    align-items: flex-start;
    gap: 20px;
    padding-bottom: 10px;
    border-bottom: 1px solid var(--line);
    flex-shrink: 0;
  }
  .drill__eyebrow {
    font-size: 9px;
    font-weight: 700;
    letter-spacing: 0.18em;
    text-transform: uppercase;
    color: var(--steel);
    margin-bottom: 4px;
    display: flex;
    align-items: center;
    gap: 10px;
  }
  .drill__eyebrow::before {
    content: '';
    width: 20px; height: 1px;
    background: var(--steel);
  }
  .drill__title {
    font-family: var(--font-serif);
    font-size: 26px;
    line-height: 1.05;
    letter-spacing: -0.018em;
    color: var(--ink);
    margin: 0 0 3px;
  }
  .drill__stats {
    font-family: var(--font-mono);
    font-size: 11px;
    color: var(--muted);
    margin: 0;
    letter-spacing: 0.02em;
  }
  .health-pill {
    font-family: var(--font-sans);
    font-size: 10px;
    font-weight: 600;
    letter-spacing: 0.14em;
    padding: 5px 10px;
    border-radius: 2px;
    text-transform: uppercase;
    background: var(--surface-3);
    color: var(--muted);
    flex-shrink: 0;
  }
  .health-green { background: rgba(95, 179, 124, 0.15); color: var(--green); }
  .health-amber { background: rgba(232, 184, 106, 0.15); color: var(--amber); }
  .health-red   { background: rgba(224, 123, 123, 0.15); color: var(--red); }

  /* Panels */
  .panel {
    background: var(--surface);
    border: 1px solid var(--line-soft);
    border-radius: 4px;
    padding: 12px 14px;
    margin-bottom: 0;
    flex-shrink: 0;
  }
  .panel h3 {
    font-family: var(--font-serif);
    font-size: 16px;
    line-height: 1.1;
    margin: 0 0 8px;
    color: var(--ink);
  }
  .panel p { margin: 0 0 8px; color: var(--ink-soft); font-size: 12px; }
  .panel p:last-child { margin-bottom: 0; }

  .panel--action {
    border-left: 3px solid var(--steel);
  }
  .panel--action h3 { font-size: 22px; }
  .panel--warning {
    background: linear-gradient(135deg, #2D2218 0%, #1F1810 100%);
    border-color: #553F22;
    border-left: 3px solid var(--amber);
  }
  .panel--warning h3 { color: var(--highlight); }
  .panel--progress {
    border-left: 3px solid var(--green);
  }

  .panel__eyebrow {
    font-size: 10px;
    font-weight: 600;
    letter-spacing: 0.16em;
    text-transform: uppercase;
    color: var(--muted);
    margin-bottom: 8px;
  }

  .progress-line {
    font-family: var(--font-mono);
    font-size: 12px;
    color: var(--ink-soft);
    margin: 0 0 10px;
  }

  .panel-grid {
    display: grid;
    grid-template-columns: 1fr 1fr;
    gap: 10px;
  }
  .panel-grid--3col { grid-template-columns: 1fr 1fr 1fr; }
  @media (max-width: 760px) {
    .panel-grid { grid-template-columns: 1fr; }
  }
  .panel-grid .panel { margin-bottom: 0; }

  /* Lists */
  .bare-list {
    list-style: none;
    padding: 0;
    margin: 0;
  }
  .bare-list li {
    padding: 5px 0;
    font-size: 12px;
    color: var(--ink-soft);
    border-bottom: 1px solid var(--line-soft);
  }
  .bare-list li:last-child { border-bottom: 0; }

  .piece-list {
    list-style: none;
    padding: 0;
    margin: 0;
  }
  .piece-list li {
    padding: 6px 0;
    border-bottom: 1px solid var(--line-soft);
  }
  .piece-list li:last-child { border-bottom: 0; }
  .piece-meta {
    display: flex;
    gap: 10px;
    font-family: var(--font-mono);
    font-size: 10px;
    color: var(--muted);
    margin-bottom: 3px;
    letter-spacing: 0.02em;
  }
  .piece-age {
    color: var(--steel);
  }
  .piece-type {
    text-transform: uppercase;
    letter-spacing: 0.1em;
  }
  .piece-title {
    font-size: 12px;
    color: var(--ink);
    line-height: 1.35;
    margin-bottom: 1px;
  }
  .piece-slug {
    font-family: var(--font-mono);
    font-size: 9px;
    color: var(--muted-deep);
  }

  .empty {
    font-size: 12px;
    color: var(--muted);
    font-style: italic;
    margin: 0;
  }
  code.inline {
    font-family: var(--font-mono);
    font-size: 11px;
    background: var(--surface-3);
    padding: 1px 5px;
    border-radius: 2px;
    color: var(--steel);
  }
  .muted { color: var(--muted); font-size: 11px; font-family: var(--font-mono); }
  .commit-hash {
    font-family: var(--font-mono);
    font-size: 11px;
    color: var(--steel);
    margin-right: 6px;
  }

  /* ===== Default "All sites" view ===== */
  .overview-stats {
    display: grid;
    grid-template-columns: repeat(4, 1fr);
    gap: 10px;
    flex-shrink: 0;
  }
  @media (max-width: 760px) {
    .overview-stats { grid-template-columns: repeat(2, 1fr); }
  }
  .stat-box {
    background: var(--surface);
    border: 1px solid var(--line-soft);
    padding: 10px 12px;
    border-radius: 4px;
  }
  .stat-box__label {
    font-size: 9px;
    font-weight: 600;
    letter-spacing: 0.14em;
    text-transform: uppercase;
    color: var(--muted);
    margin-bottom: 4px;
  }
  .stat-box__value {
    font-family: var(--font-serif);
    font-size: 22px;
    line-height: 1;
    color: var(--ink);
  }
  .stat-box__value em { font-style: italic; color: var(--steel); }

  /* Goal big bar */
  .goal-section {
    background: var(--surface);
    border: 1px solid var(--line-soft);
    border-radius: 4px;
    padding: 12px 14px;
    flex-shrink: 0;
  }
  .goal-section__head {
    display: flex;
    justify-content: space-between;
    align-items: baseline;
    margin-bottom: 10px;
    gap: 12px;
    flex-wrap: wrap;
  }
  .goal-section h3 {
    font-family: var(--font-serif);
    font-size: 17px;
    margin: 0;
    color: var(--ink);
  }
  .goal-section h3 em { font-style: italic; color: var(--steel); }
  .goal-pace {
    font-family: var(--font-mono);
    font-size: 11px;
    padding: 4px 10px;
    border-radius: 2px;
  }
  .pace-green { background: rgba(95,179,124,0.12); color: var(--green); }
  .pace-amber { background: rgba(232,184,106,0.12); color: var(--amber); }
  .pace-red   { background: rgba(224,123,123,0.12); color: var(--red); }

  .goal-total {
    margin-bottom: 18px;
    padding-bottom: 18px;
    border-bottom: 1px solid var(--line-soft);
  }
  .goal-total__head {
    display: flex;
    justify-content: space-between;
    margin-bottom: 8px;
    font-family: var(--font-mono);
    font-size: 11px;
  }
  .goal-total__head .label { color: var(--muted); }
  .goal-total__head .value { color: var(--ink); }
  .goal-total__head .value em { color: var(--steel); font-style: italic; }
  .goal-total__track {
    position: relative;
    height: 12px;
    background: var(--surface-3);
    border-radius: 2px;
    overflow: hidden;
  }
  .goal-total__fill {
    position: absolute;
    inset: 0 auto 0 0;
    background: linear-gradient(90deg, var(--steel-deep) 0%, var(--steel) 100%);
  }
  .goal-total__marker {
    position: absolute;
    top: -3px;
    bottom: -3px;
    width: 2px;
    background: var(--highlight);
  }
  .goal-rows {
    display: flex;
    flex-direction: column;
    gap: 10px;
  }
  .goal-row {
    display: grid;
    grid-template-columns: 120px 1fr;
    gap: 12px;
    align-items: center;
  }
  .goal-label {
    font-family: var(--font-mono);
    font-size: 11px;
    color: var(--ink-soft);
  }
  .goal-track {
    position: relative;
    height: 16px;
    background: var(--surface-3);
    border-radius: 2px;
    overflow: hidden;
  }
  .goal-fill {
    position: absolute;
    inset: 0 auto 0 0;
  }
  .goal-fill.fill-low  { background: linear-gradient(90deg, #1F4060 0%, #4A8FD4 100%); }
  .goal-fill.fill-mid  { background: linear-gradient(90deg, #2C5E8C 0%, #5FB37C 100%); }
  .goal-fill.fill-done { background: linear-gradient(90deg, #2C8F4F 0%, #5FB37C 100%); }
  .goal-fill.fill-dormant { background: transparent; }
  .goal-value {
    position: absolute;
    right: 8px;
    top: 50%;
    transform: translateY(-50%);
    font-family: var(--font-mono);
    font-size: 10px;
    color: var(--ink);
  }
</style>
</head>
<body>

<header class="topbar">
  <div class="topbar__left">
    <span class="topbar__brand">Affiliate <em>Kit</em> · Ops</span>
    <select id="site-select" class="site-select" onchange="window.location.hash = this.value">
      <option value="all">All sites · portfolio view</option>
$($allSites | ForEach-Object {
  $s = $siteStates[$_]
  $stats = "$($s.LiveCount) live"
  if ($s.DraftCount -gt 0) { $stats += " · $($s.DraftCount) draft" }
  $health = switch ($s.Health) { "green" {"●"}; "amber" {"●"}; "red" {"●"}; "cold" {"○"} }
  "      <option value=`"site-$_`">$health $_ · $stats</option>"
} | Out-String)
    </select>
  </div>
  <div class="topbar__right">
    <div class="topbar__goal" title="Total pieces toward $totalTarget by month 12">
      <span class="topbar__goal-value"><em>$totalLive</em> / $totalTarget</span>
      <div class="topbar__goal-track">
        <div class="topbar__goal-fill" style="width: $totalPct%"></div>
        <div class="topbar__goal-marker" style="left: $paceFractionPct%"></div>
      </div>
      <span class="topbar__pace pace-$paceColor">$paceLabel</span>
    </div>
    <div class="topbar__stamp">
      Day $daysIn / $commitmentDays<br>refreshed $genTime
    </div>
  </div>
</header>

<div class="app">

  <main class="main">

$drillDownsHtml

    <section id="all" class="drill drill--default">
      <header class="drill__head">
        <div>
          <div class="drill__eyebrow">Portfolio overview</div>
          <h2 class="drill__title">All sites</h2>
          <p class="drill__stats">$totalLive live · $totalDrafts draft · $weekCommits piece commits in last 14d</p>
        </div>
      </header>

      <section class="do-next-panel do-next-panel--$($topActionData.PriorityLabel)">
        <div class="do-next-panel__eyebrow">Do this next · highest priority</div>
        <div class="do-next-panel__site">$topSite</div>
        <h3 class="do-next-panel__title">$(HtmlEscape $topActionData.Headline)</h3>
        <p class="do-next-panel__reason">$(HtmlEscape $topActionData.Reason)</p>
        $topCmd
      </section>

      <div class="overview-stats">
        <div class="stat-box">
          <div class="stat-box__label">Total live</div>
          <div class="stat-box__value">$totalLive</div>
        </div>
        <div class="stat-box">
          <div class="stat-box__label">DRAFT waiting</div>
          <div class="stat-box__value">$totalDrafts</div>
        </div>
        <div class="stat-box">
          <div class="stat-box__label">Day of 365</div>
          <div class="stat-box__value">$daysIn</div>
        </div>
        <div class="stat-box">
          <div class="stat-box__label">Pieces this week</div>
          <div class="stat-box__value">$weekCommits</div>
        </div>
      </div>

      <section class="goal-section">
        <div class="goal-section__head">
          <h3>Goal · <em>$totalTarget pieces</em> by month 12</h3>
          <span class="goal-pace pace-$paceColor">$paceLabel</span>
        </div>
        <div class="goal-total">
          <div class="goal-total__head">
            <span class="label">Total progress</span>
            <span class="value"><em>$totalLive</em> / $totalTarget · $totalPct%</span>
          </div>
          <div class="goal-total__track">
            <div class="goal-total__fill" style="width: $totalPct%"></div>
            <div class="goal-total__marker" style="left: $paceFractionPct%"></div>
          </div>
        </div>
        <div class="goal-rows">
$goalRowsHtml
        </div>
      </section>

      <div class="panel-grid panel-grid--3col flex-fill">
        <section class="panel">
          <h3>TODO Now ($($todoNow.Count))</h3>
          $( if ($todoSidebarHtml) { "<ul class='bare-list'>$todoSidebarHtml</ul>" } else { "<p class='empty'>Nothing in TODO Now.</p>" } )
        </section>
        <section class="panel">
          <h3>Research notes ($($researchNotes.Count))</h3>
          <ul class='piece-list'>$researchAllItemsHtml</ul>
        </section>
        <section class="panel">
          <h3>Recent commits (14d)</h3>
          <ul class='bare-list'>$commitItemsHtml</ul>
        </section>
      </div>
    </section>

  </main>
</div>

<script>
  // Sync site dropdown with current hash + vice versa
  (function () {
    var sel = document.getElementById('site-select');
    if (!sel) return;
    function syncFromHash() {
      var h = (window.location.hash || '#all').slice(1);
      sel.value = h;
    }
    window.addEventListener('hashchange', syncFromHash);
    document.addEventListener('DOMContentLoaded', syncFromHash);
    syncFromHash();
  })();
</script>

</body>
</html>
"@

$html | Out-File -FilePath $outPath -Encoding UTF8 -NoNewline

Write-Host "[ok] Generated $outPath"
Write-Host "     $totalLive live pieces / $totalTarget target ($totalPct%, $paceLabel)"
Write-Host "     Top action: $($topActionData.Headline) [$topSite]"

if ($Open) {
    Start-Process $outPath
    Write-Host "     Opened in default browser."
}

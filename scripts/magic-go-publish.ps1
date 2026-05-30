<#
.SYNOPSIS
  Magic Go publish-batch — verify verdicts, build, mark a run published.

.DESCRIPTION
  Build step 8 of the orchestrator (plan §6.I). The deploy moment for a
  completed run, once Ray has written the Bottom Lines.

  IMPORTANT (CE coherence finding): there is NO manual noindex toggle. The
  page templates emit `index, follow` automatically once bottomLine.verdict is
  non-empty (keyed in sites/<site>/src/pages/{reviews,buyers-guides}/[...slug].astro).
  So publish-batch's real job is:
    1. verify EVERY non-quarantined/non-discarded piece has BOTH (a) a non-empty
       verdict (in its .md frontmatter) AND (b) qa_status == "passed" in the
       manifest (the pre-publish front-end QA gate, recorded by magic-go.md) —
       refuse + list the gaps otherwise. A piece missing either does not go live;
    2. run `pnpm --filter <site> build` across the affected sites — confirm green;
    3. confirm the working tree is pushed (per-piece commits already landed the
       verdicts; CF auto-deploys on push) — this script does NOT invent a new
       commit unless there are uncommitted verdict edits;
    4. mark the manifest `published`.

  Deploy itself is Cloudflare's `git push -> matrix` (deploy.yml). This script
  is the guard + status flip, not the deployer.

.PARAMETER RunId   Run to publish. Default: most recent.
.PARAMETER DryRun  Verify + build only; do not flip manifest status.

.EXAMPLE
  pwsh scripts/magic-go-publish.ps1
  pwsh scripts/magic-go-publish.ps1 -RunId 2026-05-29-0230 -DryRun
#>

param(
  [string]$RunId = "",
  [switch]$DryRun
)

$ErrorActionPreference = "Stop"
$repoRoot = Split-Path -Parent $PSScriptRoot
. (Join-Path $PSScriptRoot "lib/magic-go-manifest.ps1")

if (-not $RunId) { $RunId = Find-LatestMagicGoRunId }
if (-not $RunId) { Write-Host "No Magic Go runs found." -ForegroundColor Yellow; exit 1 }

$m = Read-MagicGoManifest -RunId $RunId
if ($null -eq $m) { Write-Host "Manifest not found for run $RunId." -ForegroundColor Red; exit 1 }

# Pieces that should be live (exclude quarantined + discarded)
$publishable = @($m.pieces | Where-Object { @("quarantined","discarded") -notcontains $_.status })
if ($publishable.Count -eq 0) {
  Write-Host "Run $RunId has no publishable pieces (all quarantined/discarded)." -ForegroundColor Yellow
  exit 1
}

# --- 1. verify every publishable piece has a non-empty verdict in its .md ---
#        AND has passed the pre-publish front-end QA gate (qa_status == "passed").
#        A piece needs BOTH to go live. The verdict lives in the .md frontmatter
#        (Ray writes it there); qa_status lives ONLY in the manifest piece object
#        ($p), written by the QA-gate phase in magic-go.md via Update-MagicGoPiece.
#        Fail-closed: $null (pieces predating this field), "none", "failed" all
#        refuse — only an explicit "passed" clears the gate.
$placeholder = "_The Bottom Line is being written._"
$missing = @()
$qaMissing = @()
$sitesTouched = @{}
foreach ($p in $publishable) {
  $path = Join-Path $repoRoot $p.content_path
  if (-not (Test-Path -LiteralPath $path)) { $missing += "$($p.slug) (file missing: $($p.content_path))"; continue }
  $c = Get-Content -Raw -LiteralPath $path
  $fm = if ($c -match '(?s)^---(.*?)\r?\n---') { $matches[1] } else { $c }
  $verdict = $null
  if ($fm -match '(?ms)^bottomLine:\s*\r?\n(?:\s+.*\r?\n)*?\s+verdict:\s*(.+)$') { $verdict = $matches[1].Trim().Trim("'`"") }
  $verdictOk = $true
  if ((-not $verdict) -or ($verdict -eq "") -or ($verdict -match [regex]::Escape($placeholder))) {
    $missing += "$($p.slug) (empty Bottom Line)"
    $verdictOk = $false
  }
  # QA gate: read qa_status off the manifest piece object, NOT the .md.
  $qa = $p.qa_status
  if ($qa -ne "passed") {
    $shown = if ([string]::IsNullOrEmpty($qa)) { "none" } else { $qa }
    $note = if ([string]::IsNullOrEmpty($p.qa_notes)) { "" } else { " — $($p.qa_notes)" }
    $qaMissing += "$($p.slug) (qa_status=$shown — front-end QA not passed$note)"
  }
  if ($verdictOk -and ($qa -eq "passed")) { $sitesTouched[$p.site] = $true }
}

if ($missing.Count -gt 0) {
  Write-Host ""
  Write-Host "REFUSING to publish run $RunId — $($missing.Count) piece(s) still need a Bottom Line:" -ForegroundColor Red
  foreach ($x in $missing) { Write-Host "  - $x" -ForegroundColor Yellow }
  Write-Host ""
  Write-Host "Write the remaining verdicts (open the queue: pwsh scripts/magic-go-queue.ps1 -Open), then re-run." -ForegroundColor Cyan
  exit 1
}

if ($qaMissing.Count -gt 0) {
  Write-Host ""
  Write-Host "REFUSING to publish run $RunId — $($qaMissing.Count) piece(s) have not passed the pre-publish front-end QA gate:" -ForegroundColor Red
  foreach ($x in $qaMissing) { Write-Host "  - $x" -ForegroundColor Yellow }
  Write-Host ""
  Write-Host "Run the front-end QA review (ce-design-implementation-reviewer) per plugin/commands/magic-go.md," -ForegroundColor Cyan
  Write-Host "fix any failures, re-QA, and record qa_status='passed' in the manifest. Then re-run." -ForegroundColor Cyan
  exit 1
}

Write-Host "All $($publishable.Count) publishable piece(s) have verdicts AND passed front-end QA." -ForegroundColor Green

# --- 2. build affected sites ---
$failedBuilds = @()
foreach ($site in $sitesTouched.Keys) {
  Write-Host ">> building $site ..." -ForegroundColor Cyan
  & pnpm --filter $site build *> $null
  if ($LASTEXITCODE -ne 0) { $failedBuilds += $site }
}
if ($failedBuilds.Count -gt 0) {
  Write-Host "BUILD FAILED for: $($failedBuilds -join ', '). Fix before publishing." -ForegroundColor Red
  exit 1
}
Write-Host "All affected sites build green: $($sitesTouched.Keys -join ', ')." -ForegroundColor Green

# --- 3. confirm pushed (verdict edits commit per-piece; flag any stragglers) ---
$dirty = (git -C $repoRoot status --porcelain -- sites/ | Where-Object { $_ })
if ($dirty) {
  Write-Host ""
  Write-Host "NOTE: uncommitted changes under sites/ — the verdict-write flow normally commits per piece." -ForegroundColor Yellow
  Write-Host "Commit + push them so Cloudflare deploys, then re-run, OR commit now:" -ForegroundColor Yellow
  $dirty | ForEach-Object { Write-Host "  $_" -ForegroundColor DarkGray }
  if (-not $DryRun) { Write-Host "(not auto-committing — review the stragglers first)" -ForegroundColor Yellow; exit 1 }
}

if ($DryRun) {
  Write-Host ""
  Write-Host "DRY RUN: verdicts present, builds green. Would mark run $RunId published. (No status change.)" -ForegroundColor Cyan
  exit 0
}

# --- 4. mark published ---
Set-MagicGoRunStatus -RunId $RunId -Status "published"
Write-Host ""
Write-Host "Run $RunId marked PUBLISHED. $($publishable.Count) pieces live (index,follow) on next deploy." -ForegroundColor Green
Write-Host "Cloudflare auto-deploys on the latest push (deploy.yml matrix, ~3 min)." -ForegroundColor Cyan
exit 0

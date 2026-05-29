<#
.SYNOPSIS
  Magic Go run-manifest helpers — the durable source of truth for a run.

.DESCRIPTION
  Build step 3 of the orchestrator. Dot-source:  . "$PSScriptRoot/lib/magic-go-manifest.ps1"

  The manifest at docs/magic-go/runs/<runid>/manifest.json is committed to git
  (outside dist/) and is the single source of truth: a crash resumes from it.

  Status vocabulary (CE finding V16 — phases the runner executes vs post-phase
  states the human drives):
    runner phases: scouted -> researched -> scaffolded -> body-filled ->
                   options-drafted -> ready -> committed
    human states : verdict-written, discarded, published
    failure state: quarantined  (+ failed_at phase + verbatim error)
    kv state     : kv_status (registered | failed | none) per piece (V10)

  All writes are ATOMIC (temp-file + rename, CE finding V10) so a mid-write
  crash can't corrupt the source of truth.
#>

$script:MG_RUNS_DIR_REL = "docs/magic-go/runs"
# Capture the lib's OWN directory at dot-source time. $PSScriptRoot at top-level
# of a dot-sourced file is that file's dir (here scripts/lib); $PSCommandPath
# inside a dot-sourced function is unreliable. repoRoot = two levels up
# (scripts/lib -> scripts -> repoRoot). (Bug fixed 2026-05-28: was one level
# too shallow, writing runs to scripts/docs/magic-go/runs/.)
$script:MG_LIB_DIR = $PSScriptRoot

function Get-MagicGoRunsDir {
  $repoRoot = Split-Path -Parent (Split-Path -Parent $script:MG_LIB_DIR)
  return (Join-Path $repoRoot $script:MG_RUNS_DIR_REL)
}

function New-MagicGoManifest {
  param(
    [Parameter(Mandatory)][int]$RequestedN,
    [Parameter(Mandatory)][hashtable]$Allocation,   # @{ slug = count }
    [string]$RunId = ""
  )
  if (-not $RunId) { $RunId = (Get-Date -Format "yyyy-MM-dd-HHmm") }
  $runDir = Join-Path (Get-MagicGoRunsDir) $RunId
  New-Item -ItemType Directory -Force -Path $runDir | Out-Null
  $manifest = [ordered]@{
    runid       = $RunId
    status      = "in-progress"            # in-progress | complete | published
    requested_n = $RequestedN
    allocation  = $Allocation
    started     = (Get-Date).ToString("o")
    updated     = (Get-Date).ToString("o")
    pieces      = @()
  }
  Write-MagicGoManifest -RunId $RunId -Manifest $manifest
  return $RunId
}

function Get-MagicGoManifestPath {
  param([Parameter(Mandatory)][string]$RunId)
  return (Join-Path (Join-Path (Get-MagicGoRunsDir) $RunId) "manifest.json")
}

function Read-MagicGoManifest {
  param([Parameter(Mandatory)][string]$RunId)
  $p = Get-MagicGoManifestPath -RunId $RunId
  if (-not (Test-Path -LiteralPath $p)) { return $null }
  return (Get-Content -Raw -LiteralPath $p | ConvertFrom-Json)
}

function Write-MagicGoManifest {
  param(
    [Parameter(Mandatory)][string]$RunId,
    [Parameter(Mandatory)]$Manifest
  )
  $p = Get-MagicGoManifestPath -RunId $RunId
  $dir = Split-Path -Parent $p
  New-Item -ItemType Directory -Force -Path $dir | Out-Null
  # touch updated
  if ($Manifest -is [hashtable] -or $Manifest -is [System.Collections.Specialized.OrderedDictionary]) {
    $Manifest.updated = (Get-Date).ToString("o")
  } else {
    $Manifest | Add-Member -NotePropertyName updated -NotePropertyValue ((Get-Date).ToString("o")) -Force
  }
  # ATOMIC: write temp then rename (V10 — a crash mid-write can't corrupt the manifest)
  $tmp = "$p.tmp"
  ($Manifest | ConvertTo-Json -Depth 8) | Set-Content -LiteralPath $tmp -Encoding utf8
  Move-Item -LiteralPath $tmp -Destination $p -Force
}

function Find-LatestMagicGoRunId {
  # most-recent run dir by name (runids are date-time sortable)
  $runs = Get-MagicGoRunsDir
  if (-not (Test-Path -LiteralPath $runs)) { return $null }
  $dirs = Get-ChildItem -Directory -LiteralPath $runs -ErrorAction SilentlyContinue | Sort-Object Name -Descending
  if (-not $dirs -or $dirs.Count -eq 0) { return $null }
  return $dirs[0].Name
}

function Add-MagicGoPiece {
  param(
    [Parameter(Mandatory)][string]$RunId,
    [Parameter(Mandatory)][hashtable]$Piece   # must include slug, site, type
  )
  $m = Read-MagicGoManifest -RunId $RunId
  if ($null -eq $m) { throw "manifest not found for run $RunId" }
  $defaults = [ordered]@{
    slug = ""; site = ""; type = "review"; title = ""; product = ""
    status = "scouted"; research_note = ""; content_path = ""
    bottom_line_options = @(); supporting = ""; verdict_written = $false
    failed_at = $null; error = $null; kv_status = "none"; last_commit = ""
  }
  foreach ($k in $Piece.Keys) { $defaults[$k] = $Piece[$k] }
  $list = @($m.pieces) + (New-Object psobject -Property $defaults)
  $m.pieces = $list
  Write-MagicGoManifest -RunId $RunId -Manifest $m
}

function Update-MagicGoPiece {
  param(
    [Parameter(Mandatory)][string]$RunId,
    [Parameter(Mandatory)][string]$Slug,
    [Parameter(Mandatory)][hashtable]$Set    # fields to overwrite, e.g. @{ status="ready"; last_commit="abc123" }
  )
  $m = Read-MagicGoManifest -RunId $RunId
  if ($null -eq $m) { throw "manifest not found for run $RunId" }
  $found = $false
  foreach ($pc in $m.pieces) {
    if ($pc.slug -eq $Slug) {
      foreach ($k in $Set.Keys) {
        $pc | Add-Member -NotePropertyName $k -NotePropertyValue $Set[$k] -Force
      }
      $found = $true
    }
  }
  if (-not $found) { throw "piece '$Slug' not in run $RunId" }
  Write-MagicGoManifest -RunId $RunId -Manifest $m
}

function Set-MagicGoRunStatus {
  param(
    [Parameter(Mandatory)][string]$RunId,
    [Parameter(Mandatory)][ValidateSet("in-progress","complete","published")][string]$Status
  )
  $m = Read-MagicGoManifest -RunId $RunId
  if ($null -eq $m) { throw "manifest not found for run $RunId" }
  $m | Add-Member -NotePropertyName status -NotePropertyValue $Status -Force
  Write-MagicGoManifest -RunId $RunId -Manifest $m
}

function Get-FirstNonTerminalPiece {
  # for crash-resume: first piece not in a terminal state
  param([Parameter(Mandatory)][string]$RunId)
  $terminal = @("committed","quarantined","discarded","published")
  $m = Read-MagicGoManifest -RunId $RunId
  if ($null -eq $m) { return $null }
  foreach ($pc in $m.pieces) { if ($terminal -notcontains $pc.status) { return $pc } }
  return $null
}

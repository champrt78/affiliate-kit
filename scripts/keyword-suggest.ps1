<#
.SYNOPSIS
  Free keyword-discovery tool. Pulls Google Autocomplete suggestions for one or
  more seed phrases via the public `suggestqueries.google.com` endpoint — the
  same real-query data the paid tools (and the open-source GitHub repos) wrap,
  with no API key, no account, no cost.

.DESCRIPTION
  This is the repo-native replacement for installing a third-party keyword repo:
  every open-source "keyword research tool" essentially does this one call. We
  own it instead of taking a dependency.

  For each seed it harvests:
    1. The seed's direct autocomplete suggestions.
    2. Optionally (-Expand), alphabet + modifier expansions
       ("<seed> a", "<seed> b", ... "<seed> for", "<seed> vs", "<seed> best",
       "<seed> review", "<seed> worth it", "<seed> under") — the trick that
       surfaces the long-tail, buyer-intent tails a new site can actually rank
       for. These are intent-rich: "vs", "review", "worth it", "for [x]",
       "under [$]" are the money modifiers.

  It does NOT return search volumes (no free source gives true volume). Demand
  signal = a phrase APPEARING in autocomplete at all (Google only suggests
  queries with real volume) + how many expansions surface it. For winnability
  (who ranks page 1), read the SERP separately — autocomplete tells you WHAT
  people search, the SERP tells you whether you can win it.

.PARAMETER Seed     One or more seed phrases (e.g. "best aquarium heater").
.PARAMETER Expand   Also run alphabet + buyer-modifier expansions per seed.
.PARAMETER BuyerOnly  With -Expand, only the buyer-intent modifiers (skip a-z).
.PARAMETER Out       Write the deduped suggestion list to this file too.

.EXAMPLE
  pwsh scripts/keyword-suggest.ps1 -Seed "best aquarium heater" -Expand
.EXAMPLE
  pwsh scripts/keyword-suggest.ps1 -Seed "anbernic rg40xx","8bitdo pro 2" -Expand -BuyerOnly
#>
param(
  [Parameter(Mandatory)][string[]]$Seed,
  [switch]$Expand,
  [switch]$BuyerOnly,
  [string]$Out
)
$ErrorActionPreference = "Stop"

$buyerMods = @("", " vs", " review", " worth it", " for", " best", " under", " or", " alternative", " problems")
$alpha = [char[]](97..122) | ForEach-Object { " $_" }

function Get-Suggest([string]$q) {
  $u = "https://suggestqueries.google.com/complete/search?client=firefox&q=" + [uri]::EscapeDataString($q)
  try {
    $raw = & curl.exe -s -A "Mozilla/5.0" --max-time 15 $u
    if (-not $raw) { return @() }
    $parsed = $raw | ConvertFrom-Json
    # firefox client returns [query, [suggestions...]]
    if ($parsed.Count -ge 2) { return @($parsed[1]) }
    return @()
  } catch { return @() }
}

$all = [System.Collections.Generic.List[string]]::new()
foreach ($s in $Seed) {
  $queries = @($s)
  if ($Expand) {
    $queries += ($buyerMods | Where-Object { $_ } | ForEach-Object { "$s$_" })
    if (-not $BuyerOnly) { $queries += ($alpha | ForEach-Object { "$s$_" }) }
  }
  foreach ($q in ($queries | Select-Object -Unique)) {
    foreach ($sug in (Get-Suggest $q)) {
      if ($sug -and -not $all.Contains($sug)) { $all.Add($sug) }
    }
    Start-Sleep -Milliseconds 120  # be polite to the endpoint
  }
}

$sorted = $all | Sort-Object
Write-Host ""
Write-Host "Keyword suggestions ($($sorted.Count) unique) for: $($Seed -join ', ')" -ForegroundColor Cyan
Write-Host "  (autocomplete = real queries with demand; read the SERP to judge winnability)" -ForegroundColor DarkGray
Write-Host ""
# group buyer-intent tails first (the money phrases)
$buyer = $sorted | Where-Object { $_ -match '\b(vs|versus|review|worth|best|under|\$|for|alternative|problem)' }
$rest  = $sorted | Where-Object { $_ -notmatch '\b(vs|versus|review|worth|best|under|\$|for|alternative|problem)' }
if ($buyer) { Write-Host "BUYER-INTENT tails:" -ForegroundColor Green; $buyer | ForEach-Object { Write-Host "  $_" } }
if ($rest)  { Write-Host ""; Write-Host "Other:" -ForegroundColor Yellow; $rest | ForEach-Object { Write-Host "  $_" } }

if ($Out) {
  $sorted | Set-Content -LiteralPath $Out -Encoding utf8
  Write-Host ""
  Write-Host "Wrote $($sorted.Count) suggestions to $Out" -ForegroundColor Green
}
exit 0

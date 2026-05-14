# Writes a structured affiliate-link envelope to the production KV namespace.
#
# The KV value shape (per U10) is:
#   { url, tag?, merchant, status: "active", updated: <today-iso> }
#
# The KV key is `<Site>:<Slug>` — storage stays namespaced even though the
# public URL shape (post-U9) is the clean `/go/<slug>`.
#
# --remote is baked in. Phase 1 got bit by wrangler defaulting to local state.

[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$Site,

    [Parameter(Mandatory = $true)]
    [string]$Slug,

    [Parameter(Mandatory = $true)]
    [string]$Url,

    [string]$Tag = "",

    [ValidateSet("amazon", "other")]
    [string]$Merchant = "amazon"
)

$ErrorActionPreference = "Stop"

$repoRoot = Split-Path -Parent $PSScriptRoot
$wranglerToml = Join-Path $repoRoot "workers/link-cloaker/wrangler.toml"

if (-not (Test-Path $wranglerToml)) {
    Write-Host "[err] Could not find $wranglerToml" -ForegroundColor Red
    exit 1
}

# Parse the [[kv_namespaces]] block (note: double-bracket form — TOML array of tables).
$namespaceId = $null
$inKv = $false
foreach ($line in Get-Content $wranglerToml) {
    $trimmed = $line.Trim()
    if ($trimmed -match '^\[\[kv_namespaces\]\]') {
        $inKv = $true
        continue
    }
    if ($inKv -and $trimmed -match '^\[') {
        $inKv = $false
        continue
    }
    if ($inKv -and $trimmed -match '^id\s*=\s*"([^"]+)"') {
        $namespaceId = $Matches[1]
        break
    }
}

if (-not $namespaceId) {
    Write-Host "[err] Could not find a [[kv_namespaces]] id in $wranglerToml" -ForegroundColor Red
    exit 1
}

if (-not (Get-Command wrangler -ErrorAction SilentlyContinue)) {
    Write-Host "[err] wrangler is not on PATH. Install via 'npm i -g wrangler' or 'pnpm i -g wrangler'." -ForegroundColor Red
    exit 1
}

$today = (Get-Date).ToString("yyyy-MM-dd")

$envelope = [ordered]@{
    url      = $Url
    merchant = $Merchant
    status   = "active"
    updated  = $today
}
if ($Tag -and $Tag.Trim().Length -gt 0) {
    $envelope.tag = $Tag
}

$json = ($envelope | ConvertTo-Json -Compress)
$key = "${Site}:${Slug}"

Write-Host "[..] Writing $key -> $json"

# --remote is REQUIRED. wrangler defaults to local state otherwise.
& wrangler kv key put --remote --namespace-id=$namespaceId $key $json
if ($LASTEXITCODE -ne 0) {
    Write-Host "[err] wrangler kv key put failed (exit $LASTEXITCODE)" -ForegroundColor Red
    exit $LASTEXITCODE
}

Write-Host "[ok] Wrote $key to KV (namespace $namespaceId)"
Write-Host ""
Write-Host "Next:"
Write-Host "  - Hit https://${Site}.<tld>/go/${Slug} to verify the 302."
Write-Host "  - Or: pwsh scripts/list-links.ps1 -Site $Site"

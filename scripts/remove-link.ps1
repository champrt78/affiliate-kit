# Deletes an affiliate-link key from the production KV namespace.
#
# Prompts for confirmation unless -Force is supplied.
# Deletes from REMOTE (production) KV. --remote is passed only if the installed
# wrangler supports it (older wrangler needed it; 3.60+ rejects it — remote is now
# the default). We probe `kv key delete --help` and add it conditionally.

[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$Site,

    [Parameter(Mandatory = $true)]
    [string]$Slug,

    [switch]$Force
)

$ErrorActionPreference = "Stop"

$repoRoot = Split-Path -Parent $PSScriptRoot
$wranglerToml = Join-Path $repoRoot "workers/link-cloaker/wrangler.toml"

if (-not (Test-Path $wranglerToml)) {
    Write-Host "[err] Could not find $wranglerToml" -ForegroundColor Red
    exit 1
}

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

$key = "${Site}:${Slug}"

if (-not $Force) {
    Write-Host "About to DELETE key '$key' from production KV (namespace $namespaceId)."
    $reply = Read-Host "Type 'yes' to confirm"
    if ($reply -ne "yes") {
        Write-Host "[abort] Aborted (no confirmation)."
        exit 1
    }
}

Write-Host "[..] Deleting $key"

$remoteArgs = @()
if ((& wrangler kv key delete --help 2>&1 | Out-String) -match '--remote') { $remoteArgs = @('--remote') }

& wrangler kv key delete @remoteArgs --namespace-id=$namespaceId $key
if ($LASTEXITCODE -ne 0) {
    Write-Host "[err] wrangler kv key delete failed (exit $LASTEXITCODE)" -ForegroundColor Red
    exit $LASTEXITCODE
}

Write-Host "[ok] Deleted $key from KV (namespace $namespaceId)"
Write-Host ""
Write-Host "Next:"
Write-Host "  - Verify with: pwsh scripts/list-links.ps1 -Site $Site"

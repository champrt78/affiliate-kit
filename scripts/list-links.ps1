# Lists keys in the production KV namespace.
#
# Pass -Site <slug> to filter to that site's prefix (`<Site>:`). With no -Site,
# lists every key in the namespace.
#
# --remote is baked in. Local state is not what you want.

[CmdletBinding()]
param(
    [string]$Site = ""
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

$raw = & wrangler kv key list --remote --namespace-id=$namespaceId
if ($LASTEXITCODE -ne 0) {
    Write-Host "[err] wrangler kv key list failed (exit $LASTEXITCODE)" -ForegroundColor Red
    exit $LASTEXITCODE
}

# wrangler emits a JSON array; parse and pluck name fields.
try {
    $entries = $raw | ConvertFrom-Json
} catch {
    Write-Host "[err] could not parse wrangler output as JSON. Raw:" -ForegroundColor Red
    Write-Host $raw
    exit 1
}

$names = @($entries | ForEach-Object { $_.name })

if ($Site -and $Site.Trim().Length -gt 0) {
    $prefix = "${Site}:"
    $names = $names | Where-Object { $_.StartsWith($prefix) }
}

if (-not $names -or $names.Count -eq 0) {
    if ($Site) {
        Write-Host "[ok] No keys found for site '$Site'."
    } else {
        Write-Host "[ok] KV namespace is empty."
    }
    exit 0
}

foreach ($name in $names) {
    Write-Host $name
}

Write-Host ""
Write-Host "[ok] $($names.Count) key(s)"

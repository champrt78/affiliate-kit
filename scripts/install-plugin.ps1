# Copies plugin/ to ~/.claude/plugins/affiliate-kit/
# Does NOT overwrite config.json (which holds secrets).

$ErrorActionPreference = "Stop"

$repoRoot = Split-Path -Parent $PSScriptRoot
$src = Join-Path $repoRoot "plugin"
$dest = Join-Path $env:USERPROFILE ".claude/plugins/affiliate-kit"

if (-not (Test-Path $dest)) {
    New-Item -ItemType Directory -Path $dest -Force | Out-Null
}

$preserveConfig = $null
$configPath = Join-Path $dest "config.json"
if (Test-Path $configPath) {
    $preserveConfig = Get-Content $configPath -Raw
}

Copy-Item -Path "$src/*" -Destination $dest -Recurse -Force

if ($preserveConfig) {
    Set-Content -Path $configPath -Value $preserveConfig -NoNewline
    Write-Host "[ok] Plugin installed; preserved existing config.json"
} else {
    Write-Host "[ok] Plugin installed to $dest"
    Write-Host ""
    Write-Host "Next:"
    Write-Host "  - Create $configPath with your Cloudflare API token and account id."
    Write-Host "  - See docs/BASEMENT_SETUP.md for the full first-time walkthrough."
}

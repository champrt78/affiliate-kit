# Installs the Affiliate Kit on this machine.
#
# What this does:
#   1. Copies every slash command from `plugin/commands/*.md` into `~/.claude/commands/`
#      so Claude Code can invoke them by bare name (e.g. /capture, /scaffold-piece).
#   2. Preserves `~/.claude/plugins/affiliate-kit/config.json` (holds Cloudflare secrets).
#   3. Prints the post-install checklist of external accounts and API keys to claim.
#
# Idempotent — re-run any time to refresh commands after a `git pull`.

$ErrorActionPreference = "Stop"

$repoRoot   = Split-Path -Parent $PSScriptRoot
$srcCmds    = Join-Path $repoRoot "plugin/commands"
$destCmds   = Join-Path $env:USERPROFILE ".claude/commands"
$configDir  = Join-Path $env:USERPROFILE ".claude/plugins/affiliate-kit"
$configPath = Join-Path $configDir "config.json"

# --- Step 1. Install slash commands -----------------------------------------

if (-not (Test-Path $destCmds)) {
    New-Item -ItemType Directory -Path $destCmds -Force | Out-Null
}

$installed = @()
Get-ChildItem -Path "$srcCmds/*.md" | ForEach-Object {
    Copy-Item -Path $_.FullName -Destination $destCmds -Force
    $installed += "/" + $_.BaseName
}

Write-Host "[ok] Installed $($installed.Count) slash commands into $destCmds"
Write-Host "     $($installed -join ', ')"

# --- Step 2. Preserve config.json -------------------------------------------

if (-not (Test-Path $configDir)) {
    New-Item -ItemType Directory -Path $configDir -Force | Out-Null
}

if (-not (Test-Path $configPath)) {
    Write-Host ""
    Write-Host "[note] No config.json found at $configPath."
    Write-Host "       Create it (gitignored, never committed) with:"
    Write-Host '       {'
    Write-Host '         "monorepo_path": "C:/Users/<you>/documents/github/affiliate-sites",'
    Write-Host '         "tokens": {'
    Write-Host '           "cloudflare_api": "<your CF API token>",'
    Write-Host '           "cloudflare_account_id": "<your CF account id>"'
    Write-Host '         }'
    Write-Host '       }'
}

# --- Step 3. Setup checklist ------------------------------------------------

Write-Host ""
Write-Host "=========================================="
Write-Host " Affiliate Kit installed."
Write-Host "=========================================="
Write-Host ""
Write-Host "Next steps for a fresh machine (see docs/SYSTEM.md for the full picture):"
Write-Host ""
Write-Host "  External accounts:"
Write-Host "    - Cloudflare (Pages + Workers + DNS)        - 5 domains added, API token created"
Write-Host "    - Google Search Console                     - verify each site, submit sitemap-index.xml"
Write-Host "    - Bing Webmaster Tools                      - import from GSC"
Write-Host "    - Amazon Associates                         - one account, list each site as a domain"
Write-Host "    - Awin, AvantLink                           - alternative affiliate networks (pending approval)"
Write-Host "    - Visualping                                - product-page change monitoring (5 free jobs)"
Write-Host ""
Write-Host "  API keys (write into ~/.config/last30days/.env):"
Write-Host "    - CANOPY_API_KEY                            - Amazon product data (free tier exists)"
Write-Host "    - FIRECRAWL_API_KEY                         - scrape spec pages reliably"
Write-Host "    - SCRAPECREATORS_API_KEY                    - Reddit comments + TikTok/IG (100 free)"
Write-Host "    - GROQ_API_KEY (or OPENAI_API_KEY)          - Whisper fallback for /watch when captions missing"
Write-Host "    - BRAVE_API_KEY, EXA_API_KEY                - alternative web search"
Write-Host ""
Write-Host "  Tooling on the machine (one-time):"
Write-Host "    - Node 20+, pnpm, wrangler                  - run `pnpm install` in the repo"
Write-Host "    - ffmpeg, yt-dlp                            - for /watch (auto-installs via /watch on first run)"
Write-Host "    - git, gh                                   - clone + push"
Write-Host ""
Write-Host "Re-run `pnpm install-plugin` any time to pull in new commands after `git pull`."

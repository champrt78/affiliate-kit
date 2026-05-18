# Affiliate Kit — plugin source

The `plugin/` folder is the source of truth for the Affiliate Kit's slash commands and config. `scripts/install-plugin.ps1` reads this folder and installs commands into `~/.claude/commands/` so Claude Code can invoke them by bare name.

## Install

```powershell
pnpm install-plugin
```

Run again any time after `git pull` to refresh commands. Idempotent — preserves existing `config.json`.

## Slash commands provided

| Command | Purpose |
|---|---|
| `/capture <idea>` | File a sidetrack idea into the Second Brain `ideas/` inbox without breaking the current conversation. Detects project from cwd. |
| `/research-product <topic>` | Multi-source research pipeline. Parallel-fires Firecrawl search, `/last30days`, `/watch` on top YouTube reviewer, and Canopy ASIN verify. Output: `docs/research/<date>-<slug>.md`. |
| `/scaffold-piece <args>` | Wraps `scripts/new-review.ps1` or `scripts/buyers-guide.ps1` + KV cloaker registration + voice lint + astro build. Stops short of commit so the DRAFT gate stays Ray's call. |
| `/bottom-line-helper <slug>` | Reads a DRAFT-gated piece's frontmatter (scorecard, buyIf, flaws) + prior shipped Bottom Lines on the same site for voice anchor, drafts 3 verdict options + a supporting paragraph. Never writes to the file. |

## What lives in `plugin/`

- `commands/` — slash command sources (markdown with YAML frontmatter)
- `plugin.json` — kit metadata (name, version, description)
- `README.md` — this file

## What does NOT live here

- **API keys / Cloudflare token** → `~/.claude/plugins/affiliate-kit/config.json` (gitignored, never committed)
- **External-service API keys** → `~/.config/last30days/.env` (Canopy, Firecrawl, ScrapeCreators, Groq, etc.)
- **The actual Astro sites** → `sites/<slug>/` in the monorepo root
- **The link-cloaker Worker** → `workers/link-cloaker/`
- **The Phase-1 toolkit scripts** → `scripts/` in the monorepo root

## Architecture

See `docs/SYSTEM.md` in the monorepo root for the full stack picture (this repo + AIOS + Second Brain + Cloudflare + external SaaS) with data flows between them.

## What changed from the original design

The original `docs/2026-05-12-affiliate-kit-design.md` envisioned a `/aff-next`, `/aff-status`, `/aff-cycle`, `/aff-refresh` slash-command suite. Those were never built — replaced by `docs/TODO.md` as the canonical "what's next" list and by Visualping as the cheap-version refresh sweep. Archived plan docs at `docs/archive/`.

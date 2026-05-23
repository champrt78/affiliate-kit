# Affiliate Kit — plugin source

The `plugin/` folder is the source of truth for the Affiliate Kit's slash commands and config. `scripts/install-plugin.ps1` reads this folder and installs commands into `~/.claude/commands/` so Claude Code can invoke them by bare name.

## Install

```powershell
pnpm install-plugin
```

Run again any time after `git pull` to refresh commands. Idempotent — preserves existing `config.json`.

## Slash commands provided

**Two user-facing commands.** Everything else is an internal mechanic that `/aff` reads inline.

### User surface

| Command | Purpose |
|---|---|
| `/aff` | State-aware router across MWC + DTP. Surveys portfolio state, computes posture, opens with ONE next-move proposal + Y/N. No flags. Plain language both ways. The one command Ray types. |
| `/aff-idea <text>` | Sidetrack capture into Second Brain `ideas/` inbox without breaking the active `/aff` thread. Renamed from `/capture` to avoid colliding with moonlit-meadow's `/idea`. |

### Internal mechanics (not for direct use)

These appear in `/help` (Claude Code has no mechanism to suppress slash listing — confirmed via CE feasibility review 2026-05-20), but Ray ignores them. Their `description:` starts with `Internal —`. `/aff` `Read`s these `.md` files inline and executes their steps in the same conversation turn.

| Command | Read inline by `/aff` when |
|---|---|
| `/scout-topics` | Posture is `hero-behind-cadence`, `dp-behind-cadence`, or `ready-for-next-topic`. |
| `/research-product` | After a scout pick lands. Synthesizes Firecrawl + last30days + /watch + Canopy into `docs/research/<date>-<slug>.md`. |
| `/scaffold-piece` | Posture is `research-ready-to-scaffold`. Has entry-mode B accepting already-collected context from `/aff`. |
| `/bottom-line-helper` | Posture is `draft-needs-bottom-line`. Read-only — drafts 3 verdict options. |
| `/ops` | Folded into `/aff`'s state survey (`Step 2`) and `where-are-we` flow. Still usable standalone for the static HTML dashboard render. |

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

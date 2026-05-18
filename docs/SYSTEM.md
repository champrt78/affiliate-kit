# The Affiliate Kit — System Architecture

**The single picture of how all the pieces fit together.** This is the doc that replaces "it lives in Ray's memory." If you move to a new machine, lose context, or onboard someone else, start here.

**Last refreshed:** 2026-05-18

---

## TL;DR

The Affiliate Kit is **one monorepo (`affiliate-sites/`) + four external dependencies**. The monorepo holds 5 affiliate sites, a link-cloaker Worker, shared packages, scaffolding scripts, and the source for 4 slash commands. The external dependencies are documented below.

```
┌────────────────────────────────────────────────────────────────────┐
│                   affiliate-sites (this repo)                      │
│                                                                    │
│  sites/        packages/       workers/        scripts/   plugin/  │
│  ├ mywildli..  ├ shared-ui     └ link-cloaker  │          └ commands│
│  ├ detailerp.. ├ shared-utils                  │            ├ /capture
│  ├ fussybean   ├ shared-styles                 │            ├ /research-product
│  ├ starteraq.. └ tokens                        │            ├ /scaffold-piece
│  └ gameovergr.                                 │            └ /bottom-line-helper
│                                                ▼
│                                          install-plugin.ps1
│                                                │
└────────────────────────────────────────────────┼───────────────────┘
                                                 │ copies to
                                                 ▼
                                       ~/.claude/commands/*.md
                                       (Claude Code reads here)

External:
  ┌─ Cloudflare ────────┐  ┌─ AIOS (separate repo) ───┐  ┌─ Second Brain (separate repo) ─┐
  │ Pages × 5 sites     │  │ affiliate_link_health    │  │ ideas/  ← /capture writes here │
  │ Workers (cloaker)   │◀─│ nightly job reads KV     │  │ daily/                          │
  │ KV (AFFILIATE_LINKS)│  │ from this repo's worker  │  │ projects/                       │
  │ DNS × 5 domains     │  └──────────────────────────┘  └─────────────────────────────────┘
  └─────────────────────┘

  ┌─ SaaS accounts ─────────────────────────────────────────────────────────────┐
  │ Google Search Console, Bing Webmaster, Amazon Associates, Awin, AvantLink,  │
  │ Visualping (5 watch jobs), Canopy, Firecrawl, ScrapeCreators, Groq, Brave   │
  └──────────────────────────────────────────────────────────────────────────────┘
```

---

## Inside this repo

| Path | What it is | Source of truth for |
|---|---|---|
| `sites/<slug>/` | Astro site per niche | Per-site content, layouts, public/ assets |
| `packages/shared-ui/` | Astro components shared across all 5 sites | `BaseLayout`, `Hero`, `CTA`, `ReviewCard`, `ProductCard`, `ComparisonTable`, `AffiliateDisclosure` |
| `packages/shared-utils/` | TypeScript helpers | `cloakedLink()`, `productSchema()`, `reviewSchema()`, `faqSchema()`, KV envelope |
| `packages/shared-styles/` | Design tokens | Palette, typography, spacing — overridable per site via `src/data/site-config.json` |
| `workers/link-cloaker/` | Cloudflare Worker | Routes `<apex>/go/<slug>` → KV lookup → 302 to affiliate URL with tag applied |
| `scripts/` | PowerShell helpers | `new-review.ps1`, `buyers-guide.ps1`, `add-link.ps1`, `lint-voice.ps1`, `deploy.ps1`, `install-plugin.ps1` |
| `plugin/commands/` | Slash command sources | `/capture`, `/research-product`, `/scaffold-piece`, `/bottom-line-helper` |
| `tools/bootstrap/` | TypeScript CLI | Used historically by `/aff-bootstrap`; retired (no 6th site planned) |
| `templates/site-template/` | Astro skeleton | Copied into `sites/<slug>/` at bootstrap time |
| `docs/` | Knowledge base | See "Documentation map" below |
| `.github/workflows/deploy.yml` | GitHub Actions | Matrix-builds + deploys all 5 sites in parallel on push to `main` |

---

## External dependencies

### Cloudflare

| Resource | What it does | How configured |
|---|---|---|
| 5 Pages projects | One per site, auto-deploy from `main` via GitHub Actions | `.github/workflows/deploy.yml` matrix |
| `link-cloaker` Worker | Single Worker, route `<apex>/go/*` on every site | `workers/link-cloaker/wrangler.toml` |
| `AFFILIATE_LINKS` KV namespace | Structured envelope `{ url, tag, merchant, status, updated }` per slug | `scripts/add-link.ps1` writes; Worker reads |
| DNS for 5 apexes | Nameservers point to Cloudflare from registrar | One-time setup per domain |

**Account ID** + **API token** live in `~/.claude/plugins/affiliate-kit/config.json` (gitignored). GitHub Actions secrets: `CLOUDFLARE_ACCOUNT_ID`, `CLOUDFLARE_API_TOKEN`.

### AIOS workflows (`../AIOS/`, separate repo)

| Workflow | What it does | Schedule |
|---|---|---|
| `affiliate_link_health` | HEAD-requests every `/go/<slug>` cloaker URL + product hero image URLs across all 5 sites. Logs to SQLite, surfaces broken links. | Manual today; cron-scheduled deferred |

**Coupling:** AIOS reads this repo's KV namespace + walks `sites/<slug>/src/content/` for image URLs. The path coupling is convention-only — if affiliate-sites moves, AIOS breaks silently. Documented here so the breakage is findable.

### Second Brain (`../second-brain/`, separate repo)

| Folder | What it holds | Who writes here |
|---|---|---|
| `ideas/` | Sidetrack inbox | `/capture` slash command |
| `daily/` | Daily notes | Manual |
| `projects/` | Cross-project context (including affiliate-sites portfolio) | Manual |
| `people/` | People + relationships | Manual |

**Coupling:** `/capture` writes to a hardcoded path (`~/documents/github/second-brain/ideas/`). If second-brain moves, `/capture` breaks. Brad's PostToolUse hook auto-commits writes to that vault.

### SaaS accounts

| Service | Purpose | Free tier? |
|---|---|---|
| Google Search Console | Indexing, ranking signal, sitemap submission | Free |
| Bing Webmaster Tools | Indexing on Bing (mirror of GSC) | Free |
| Amazon Associates | Primary affiliate program (3% commission across most categories) | Free; 3-sale/180-day approval clock |
| Awin | Network for direct brand programs (alternative when Amazon doesn't carry a product) | Free, application-gated |
| AvantLink | Outdoor-niche network (Tactacam, etc.) | Free, application-gated |
| Visualping | Auto-monitor product pages for price/spec drift | Free up to 5 jobs |

### Research API keys (in `~/.config/last30days/.env`)

| Key | Used by | Free tier? |
|---|---|---|
| `CANOPY_API_KEY` | Amazon product data via GraphQL — verifies ASINs, current prices, MCP-compatible | Yes |
| `FIRECRAWL_API_KEY` | Scrape spec pages, JS-rendered SPAs, with cleanup | Yes (limited) |
| `SCRAPECREATORS_API_KEY` | Reddit comments + TikTok + Instagram captions | 100 free calls to start |
| `GROQ_API_KEY` or `OPENAI_API_KEY` | Whisper fallback for `/watch` when YouTube captions missing | Groq has generous free tier |
| `BRAVE_API_KEY`, `EXA_API_KEY` | Alternative web search backends | Yes |
| `XAI_API_KEY` | X/Twitter via Grok (currently no credits) | Application-gated |

---

## Slash commands (the Kit)

Source: `plugin/commands/*.md` in this repo.
Install destination: `~/.claude/commands/*.md` (Claude Code reads here).
Install command: `pnpm install-plugin`.

| Command | What it does | Calls into |
|---|---|---|
| `/capture <idea>` | Files an idea into Second Brain `ideas/` inbox without breaking the active conversation. Detects project from cwd. | `~/documents/github/second-brain/ideas/` |
| `/research-product <topic>` | Parallel-fires Firecrawl search, `/last30days`, `/watch` on top YouTube reviewer, and Canopy ASIN verify. Output: `docs/research/<date>-<slug>.md`. | Firecrawl + last30days + watch + Canopy |
| `/scaffold-piece <args>` | Wraps `scripts/new-review.ps1` or `scripts/buyers-guide.ps1` + `add-link.ps1` (KV cloaker) + `lint-voice.ps1` + `pnpm build`. Stops at DRAFT — won't commit until Ray writes Bottom Line. | `scripts/*.ps1` |
| `/bottom-line-helper <slug>` | Drafts 3 verdict options + supporting paragraph from a piece's frontmatter. Never writes to file. Preserves the human-Bottom-Line discipline. | Reads piece frontmatter + prior pieces |

---

## Documentation map

| Doc | Purpose | Current? |
|---|---|---|
| `docs/SYSTEM.md` | **This file.** The single architecture picture. | ✓ |
| `docs/TODO.md` | Canonical open-work list (Now / Next / Later / Blocked / Done). Update during sessions. | ✓ |
| `docs/PROJECT_STATE.md` | Running list of wins + milestones. High bar — milestones only, not every fix. | ✓ |
| `docs/voice-doctrine.md` | Single source of truth for forbidden phrases, preferred framings, direct-question responses. Drives `lint-voice.ps1`. | ✓ |
| `docs/PLAYBOOK.md` | Per-piece workflow + quarterly cycle prose. Transitional. | Mostly |
| `docs/cf-pages-github-setup.md` | Walkthrough for connecting a CF Pages project to GitHub | ✓ |
| `docs/brainstorms/` | ce-brainstorm output | Per-decision |
| `docs/research/` | `/research-product` output + manual research notes | Per-piece |
| `docs/playgrounds/` | Design mockups + comparison docs | Per-iteration |
| `docs/sessions/Session_*.md` | Day-by-day narrative log (NON-NEGOTIABLE — updated proactively) | Per-day |
| `docs/changelog/` | `/doc`-generated developer changelog entries (feature-completion artifacts) | Per-feature |
| `docs/archive/` | Stale plan docs kept for historical context (Phase 1 design, content-readiness plan, basement-setup) | Frozen |

---

## What a fresh machine needs

In order:

1. **Tooling.** Node 20+, pnpm, wrangler, git, gh, ffmpeg, yt-dlp, PowerShell 7 (`pwsh`).
2. **Clone the repo.** `git clone https://github.com/champrt78/affiliate-sites.git` into `~/documents/github/affiliate-sites/`.
3. **Workspace install.** `pnpm install` at repo root.
4. **Install the Kit's slash commands.** `pnpm install-plugin` — copies `plugin/commands/` into `~/.claude/commands/`.
5. **Configure Cloudflare.** Create `~/.claude/plugins/affiliate-kit/config.json` with API token + account ID. `wrangler login`.
6. **Configure research API keys.** Create `~/.config/last30days/.env` with `CANOPY_API_KEY`, `FIRECRAWL_API_KEY`, `SCRAPECREATORS_API_KEY`, `GROQ_API_KEY`.
7. **Clone Second Brain.** `git clone https://github.com/champrt78/second-brain.git` into `~/documents/github/second-brain/` so `/capture` has somewhere to write.
8. **Clone AIOS (optional, only if running workflows locally).** Into `~/documents/github/AIOS/`.
9. **Claim external accounts.** See the install-plugin output for the checklist (GSC, Bing, Amazon Associates, Awin, AvantLink, Visualping).

After step 4, `pnpm install-plugin` prints a checklist of everything else.

---

## Known coupling points (where the seams are)

These are conventions, not enforced contracts. Documented so future-you remembers:

- **AIOS workflow → this repo's KV.** Hardcoded path. Move affiliate-sites = AIOS breaks.
- **`/capture` → second-brain `ideas/`.** Hardcoded path. Move second-brain = `/capture` breaks.
- **`scripts/install-plugin.ps1` → `~/.claude/commands/`.** Claude Code's user-command directory. Change Claude Code's loader convention = needs update.
- **GitHub Actions deploy → 5 Pages projects.** Per-site project names hardcoded in `.github/workflows/deploy.yml` matrix.
- **`config.json` schema.** Plugin scripts read `monorepo_path` + `tokens.cloudflare_api` + `tokens.cloudflare_account_id` by name. Change a key = audit every script.
- **`docs/voice-doctrine.md` → `scripts/lint-voice.ps1`.** Lint parses literal forbidden phrases from this file. Don't change the format without updating the parser.

---

## What's deliberately NOT in this repo

- **Brand assets (Semper Fi Studios, Starwatch Station)** — those live in their own repos. Affiliate Kit is one product line; Semper Fi Studios is the Phase 2 services business.
- **AIOS workflow source** — that's its own repo. This repo's data is the input.
- **Second Brain content** — vault lives in its own repo, written by `/capture` and by hand.
- **askbigchew (`bc/`)** — Ray's bulldog site, hands-on territory, different stack (Next.js + MDX). Doesn't follow Affiliate Kit conventions.

---

## When this doc is wrong

This is the architecture as of 2026-05-18. If you find a coupling that isn't listed, an external service the install script doesn't mention, or a slash command that exists but isn't in the table — fix this doc first, then keep working. Drift here is the exact thing this doc exists to prevent.

# Affiliate Kit — Design Spec

**Author:** Ray Champion
**Date:** 2026-05-12
**Status:** Design (pre-implementation)

## Purpose

Build a Claude Code plugin (`affiliate-kit`) plus an Astro monorepo (`affiliate-sites`) that together let me operate five affiliate sites with minimal active overhead. The system should be opinionated enough to make decisions for me (what to write next, what to refresh, when to push a cycle), light enough that I can ignore it for a month without breaking, and structurally honest enough to survive Google's helpful-content updates.

The five sites:

| Slug | Niche | Tier |
|---|---|---|
| `mywildlifecam` | Trail cameras / wildlife cams | **Hero** — full effort |
| `detailerpicks` | Car detailing | Tier 1 satellite |
| `fussybean` | Coffee / espresso | Tier 1 satellite |
| `starteraquarium` | Beginner aquariums | Tier 2 satellite |
| `gameovergear` | Retro gaming gear | Passion / Tier 2 |

## Strategic posture

- **One hero, four satellites.** mywildlifecam gets real time; others get the playbook on a slower clock. Lessons from the hero propagate.
- **Quarterly cycle clock.** Each site has a 90-day cycle. When it expires, the system nags. A cycle = 5 new reviews + a refresh sweep of existing pages.
- **AI-assisted, human-finished content.** AI scaffolds the draft with image slots and a blank `## My Take` section. I fill in My Take with something *specific and real*. For products I don't own, the page is framed as a buyer's guide, not a review.
- **Layered image policy.** Real product shots from Amazon Product Advertising API + brand affiliate media kits. AI-generated images only for scene/context (a deer at a feeder, a barista frothing milk). My own phone photos for the 1-3 products per site I actually own. No AI-generated product hero shots — they're fakes and Google catches them.
- **Static-first, fast.** Astro static output, deployed to Cloudflare Pages. Affiliate sites live or die on Core Web Vitals.
- **Self-chaining UX.** Every command ends with a `Next:` block telling me what to do next. I should rarely need to think "what now?" — the system tells me.

## Architecture

### Two pieces of the system

```
~/.claude/plugins/affiliate-kit/   # the Claude Code plugin (commands + skills + templates)
~/source/repos/affiliate-sites/    # the monorepo containing all 5 sites
```

The plugin knows where the monorepo is via `~/.claude/plugins/affiliate-kit/config.json`. Every command auto-routes there — I can run `/aff-next` from any directory and it works.

### Plugin layout

```
~/.claude/plugins/affiliate-kit/
  plugin.json
  config.json                     # local config: monorepo path, tone, API tokens
  commands/
    aff-next.md                   # ⭐ default entry point
    aff-help.md                   # cheatsheet
    aff-status.md                 # all-sites or per-site status
    aff-bootstrap.md              # scaffold a new site
    aff-cycle.md                  # run a full quarterly cycle for a site
    aff-new-review.md             # write one review
    aff-refresh.md                # refresh existing review(s)
  skills/
    affiliate-content/            # the review-writing playbook
    affiliate-images/             # legal image sourcing
    affiliate-seo/                # schema markup, internal linking, IndexNow
    affiliate-research/           # keyword research, competitor analysis
  templates/
    site/                         # Astro site skeleton — copied per site
    review.md.tmpl                # review template w/ image slots + My Take section
    buyers-guide.md.tmpl          # buyer's-guide template
    pages/                        # homepage, about, disclosure, privacy, contact
```

### Monorepo layout

```
~/source/repos/affiliate-sites/
  pnpm-workspace.yaml
  package.json
  README.md                       # overview + link to COMMANDS.md
  COMMANDS.md                     # persistent cheatsheet
  CLAUDE.md                       # conventions for Claude when working here
  packages/
    shared-ui/                    # Astro components (CTA, comparison table, hero, etc.)
    shared-utils/                 # link-cloaker helpers, schema generators, IndexNow client
    shared-styles/                # design tokens (colors, type) themable per site
  sites/
    mywildlifecam/
      astro.config.mjs
      src/
        content/
          reviews/                # individual product reviews
          buyers-guides/          # multi-product comparison guides
          learn/                  # informational / non-affiliate content
        components/
        layouts/
        pages/
      public/
      wrangler.toml               # Cloudflare Pages config (optional override)
    fussybean/
    detailerpicks/
    starteraquarium/
    gameovergear/
  tools/
    status/                       # the /aff-status engine (TypeScript CLI)
      sites.json                  # per-site state: last cycle date, cycle clock, last-scan results
      scanners/                   # broken-link, price-drift, age, GSC-rank-drop
    refresh-scanner/              # invoked by /aff-refresh
    review-builder/               # invoked by /aff-new-review
  workers/
    link-cloaker/                 # one CF Worker, routes /go/<site>/<slug>
      wrangler.toml
      src/
```

## Commands

| Command | Purpose | Frequency |
|---|---|---|
| `/aff-next` ⭐ | Default entry point. Shows top 3-5 priorities, lets you pick one. | Daily-ish |
| `/aff-help` | Cheatsheet. Same content as `COMMANDS.md`. | Occasional |
| `/aff-status [site]` | Show portfolio (or one site) state, sorted by urgency. | Weekly |
| `/aff-bootstrap <slug>` | Scaffold a new site. | ~5 times total |
| `/aff-cycle <site>` | Run the full quarterly cycle (5 new + refresh sweep). | Quarterly per site |
| `/aff-new-review <site> <product-or-keyword>` | Write one review. | Per review |
| `/aff-refresh <site> [page]` | Refresh existing reviews. | Per cycle / on demand |

### `/aff-next` (the one I'll actually type)

Reads `tools/status/sites.json`, runs the scanners, picks the top 3-5 issues across all sites, presents them ranked, and routes me into the right command for whichever I pick.

Flags:
- `--auto` — picks the top issue and starts it without asking. If nothing's urgent, prints a one-liner ("all healthy, next due in N days") and exits.
- `--site <slug>` — limit to one site

### `/aff-status`

Two modes:
- **All-sites (default):** one-line-per-site summary. Color-coded by severity.
- **Per-site (`/aff-status <slug>`):** page-by-page breakdown with rank, last-touched age, health status.

Flags:
- `--all` — every page across every site (rare)
- `--spicy` — unfiltered tone for motivation days
- `--html` — open a one-page HTML report in the browser

### `/aff-bootstrap <slug>`

Per-site one-time. Does the following in order:

1. Ask which of the 5 niches (or "custom") and confirm the domain.
2. Copy `templates/site/` into `sites/<slug>/`.
3. Generate homepage, about, affiliate-disclosure, privacy, contact pages from `templates/pages/`.
4. Wire Cloudflare:
   - Create Pages project bound to the monorepo
   - Add DNS records (CNAME → Pages, plus TXT for domain verification)
   - Add Worker route `<domain>/go/<slug>/*` → `link-cloaker` Worker
   - Create R2 bucket `<slug>-images`
5. Drop a starter taxonomy: `/reviews/`, `/buyers-guides/`, `/learn/`.
6. Add the site to `tools/status/sites.json`.
7. Print manual steps the human has to do:
   - Apply to relevant affiliate programs (list provided per niche)
   - Verify domain in Google Search Console
   - Verify domain ownership in Bing Webmaster Tools (for IndexNow)
   - Set Porkbun nameservers to Cloudflare if not already

### `/aff-new-review <site> <product-or-keyword>`

Phases:

1. **Research** — pull product specs, real prices, competitor angles (top 3 ranking pages for the target keyword), People-Also-Ask questions. Sources: Amazon PA-API (once approved), web scraping fallback, GSC for the site's existing related content.
2. **Classify** — review (I own/will own the product) vs. buyer's guide (I researched, don't own). Pick template accordingly.
3. **Draft** — write from template with explicit `[HERO]`, `[CONTEXT]`, `[COMPARISON]` image slots and a blank `## My Take` section. Include FAQ, comparison table, pros/cons, schema.
4. **Media** — fetch product hero from Amazon PA-API or brand asset library. Generate scene/context image via AI (DALL-E or Imagen) — atmospheric, not product fake. Upload to R2.
5. **Save** — drop into `sites/<slug>/src/content/reviews/<product-slug>.md`. Open in editor for human finishing.
6. **Print Next:** the cycle status — N more reviews to write, or refresh sweep pending, or My Take section waiting.

### `/aff-refresh <site> [page]`

Per page:

- Re-fetch current price; if body or comparison table differs by >10%, update inline and flag in the diff
- Test every affiliate link; if 404 or redirect-to-not-found, flag
- Scan body for stale references (year mentions, "new for X" claims)
- Check current Amazon listing for "discontinued" or "currently unavailable" — if so, flag the page as needing a replacement product
- Suggest internal links to newer reviews on the same site
- Bump `lastUpdated` frontmatter
- Show diff for human approval before commit

If `[page]` omitted: refresh everything flagged by the scanners for that site.

### `/aff-cycle <site>`

Orchestrator. Walks me through:

1. **Discovery** — AI presents 10-15 candidate products ranked by `commission_rate × search_volume ÷ ranking_difficulty`. I pick 5.
2. **Drafting loop** — for each of the 5: run `/aff-new-review`, I fill in My Take, approve.
3. **Refresh sweep** — run `/aff-refresh <site>` against everything flagged.
4. **Publish** — single git commit, push, Cloudflare auto-deploys, IndexNow pings Google/Bing.
5. **Tick the clock** — reset the 90-day timer in `sites.json`.

## The `Next:` chain

Every command's success output ends with a `Next:` block computed from current portfolio state. Failure outputs do the same: "this failed because X, try Y next." This is a cross-cutting requirement, not a per-command nicety.

Examples:

```
✓ /aff-bootstrap fussybean
Next:
  → Apply to affiliate programs (listed above) — required before /aff-new-review works
  → Verify fussybean.com in Google Search Console: https://search.google.com/...
  → When that's done, run /aff-next
```

```
✓ /aff-new-review fussybean breville-barista-express
Next:
  → Open the draft and write the "My Take" section (it's blank, waiting for you)
  → When you're happy, commit and push — Cloudflare will deploy
  → Or for the rest of this cycle: /aff-new-review fussybean <next-product> (4 more)
```

```
✓ /aff-status
Next:
  → fussybean's quarterly cycle due in 12 days — start gathering candidate products
  → Or: take the night off. The reviews aren't going anywhere.
```

The footer is generated by a shared helper in `tools/status/` that all commands import.

## Data sources

| Source | Used for | Setup | Cost |
|---|---|---|---|
| Cloudflare API | Pages, DNS, Workers, R2, Analytics | 1 API token | Free |
| Google Search Console API | Ranking drift, top queries, refresh signals | Service account + verify 5 properties | Free |
| Google Analytics 4 API | Traffic (HTML digest only — not core) | Service account | Free |
| PageSpeed Insights API | Core Web Vitals on demand | Free API key | Free |
| IndexNow | Notify Google/Bing on publish | Key file per site | Free |
| Amazon Product Advertising API | Product images, specs, current prices | Requires 3 qualifying sales in 180 days first | Free once approved |
| Cloudflare Workers Analytics | Cloaked-link click data | Free, automatic with Worker | Free |

Affiliate programs (manual signup):
- Amazon Associates (covers all 5 niches as fallback)
- mywildlifecam: Reconyx, Spypoint, Tactacam, Browning (mostly via Skimlinks/ShareASale)
- detailerpicks: Detailed Image, Chemical Guys, Adams Polishes, Griot's Garage
- fussybean: Trade Coffee, Atlas Coffee, Clive Coffee, Seattle Coffee Gear
- starteraquarium: Aquarium Co-Op, Marine Depot, BulkReefSupply
- gameovergear: eBay Partner Network, Castlemania, Stone Age Gamer (rougher landscape)

## Content templates

### Review template (`review.md.tmpl`)

```markdown
---
title: "[PRODUCT NAME] Review — [VERDICT IN 5 WORDS]"
description: "[155-char meta description with primary keyword]"
product:
  name: "[PRODUCT NAME]"
  brand: "[BRAND]"
  sku: "[SKU]"
  price: "[CURRENT PRICE]"
  affiliate:
    amazon: "[/go/<site>/<slug>-amazon]"
    direct: "[/go/<site>/<slug>-direct]"
rating: [1-5]
classification: review     # vs. buyers-guide
pubDate: [YYYY-MM-DD]
lastUpdated: [YYYY-MM-DD]
images:
  hero: "[R2 URL]"
  context: "[R2 URL]"
  comparison: "[R2 URL]"
---

## TL;DR

[Auto-generated 3-sentence summary]

## Why I Picked This

[Auto-generated buyer-intent framing]

## [HERO IMAGE]

## Specs

[Auto-generated spec table]

## Pros and Cons

[Auto-generated, derived from research]

## How It Compares

[Auto-generated comparison table — 2 alternatives]

## [COMPARISON IMAGE]

## My Take

> _Waiting for the human. Don't ship without this._

[BLANK — Ray writes this. Should be specific, opinionated, real. Even if I don't own it, write "Why I'd pick this for [use case]" with reasoning.]

## [CONTEXT IMAGE]

## FAQ

[Auto-generated from People-Also-Ask + JSON-LD FAQPage schema]

## Where to Buy

[CTA buttons → cloaked /go/ links]
```

### Buyer's-guide template (`buyers-guide.md.tmpl`)

Same shape, but `classification: buyers-guide`, covers 5-7 products, opinion section is "Why these and not those" instead of "My Take on this one."

## Configuration

A single config file lives at `~/.claude/plugins/affiliate-kit/config.json`. All commands read from here. API tokens live here (not in the monorepo) so they're never accidentally committed.

```json
{
  "monorepo_path": "/c/Users/rchampion/source/repos/affiliate-sites",
  "tone": "snarky",
  "snarky_phrases": ["...curated list..."],
  "spicy_phrases": ["...the unhinged ones..."],
  "tokens": {
    "cloudflare_api": "...",
    "gsc_service_account_path": "~/.claude/plugins/affiliate-kit/gsc-key.json",
    "amazon_paapi_access": "...",
    "amazon_paapi_secret": "...",
    "indexnow_key": "..."
  }
}
```

`tone` values:

- `polite` — "Heads up: fussybean's Breville review is 8 months old. Worth a refresh."
- `snarky` (default) — "fussybean's Breville review is 8 months old and still ranking. You're leaving money on the table."
- `spicy` — unfiltered. Reserved for `--spicy` flag, not the default.

## Out of scope (deliberate YAGNI)

- A web-based dashboard. Native tools (GA4, GSC, Cloudflare) already exist; rebuilding their UI adds nothing.
- Multi-user support. This is a one-developer operation.
- WordPress, headless CMS, or any non-Astro stack alternative.
- Pinterest, social media auto-posting. Out of scope for v1.
- Email newsletter integration. Out of scope for v1.
- Comment system. Out of scope for v1.
- Programmatic SEO (10,000-page auto-generation). Explicitly anti-goal.
- A full-blown observability stack. Cloudflare Analytics + GA4 + GSC are enough.

## Success criteria

The plugin is successful if, six months from launch:

- All five sites are deployed and indexed
- Hero site (mywildlifecam) has 20+ reviews and is earning enough to cover the year's domain costs ($60-100)
- Quarterly cycles are happening consistently for the hero, occasionally for satellites
- I run `/aff-next` instead of staring at five sites wondering what to do
- I can ignore the system for 30 days and come back to a clear "here's what's overdue" report instead of decay

The plugin is a failure if:

- I'm typing more than `/aff-next` and one follow-up most days
- I'm fighting the template more than using it
- Google de-indexes any of the sites
- I'm avoiding the system because it's noisy or annoying

## Build order (high-level)

These will be properly decomposed in the implementation plan, but for context:

1. Monorepo skeleton (pnpm workspaces, shared packages, `README.md`, `COMMANDS.md`, `CLAUDE.md`, one site placeholder)
2. Astro site template (`templates/site/` and `templates/pages/`)
3. Link-cloaker Worker
4. `/aff-bootstrap` end-to-end for mywildlifecam (hero gets the first real run)
5. Review template + `/aff-new-review`
6. Refresh scanners + `/aff-refresh`
7. Status engine + `/aff-status` + `/aff-next` + `/aff-help`
8. Cycle orchestrator `/aff-cycle`
9. `Next:` footer helper, retrofitted across all commands
10. Bootstrap the other 4 sites
11. First quarterly cycle on the hero

## Open questions for the implementation plan

- Which scraping library / approach for product price/spec fetching when Amazon PA-API isn't approved yet — Playwright? cheerio? a paid service like ScrapingBee?
- Image generation: DALL-E 3 (OpenAI) or Imagen (Google)? Cost per image and quality on "atmospheric scene" prompts.
- IndexNow: per-site key file or shared key across sites? (Probably per-site — cleaner.)
- The CLAUDE.md inside the monorepo: what conventions does Claude need to know that aren't already in the plugin's skills?
- Click-tracking storage: Cloudflare Analytics Engine (newer, structured) or just D1 (SQL-friendly)?

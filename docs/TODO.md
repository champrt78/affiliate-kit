# TODO — Affiliate Sites

> Canonical open-work list per global CLAUDE.md. Update as we work. `cat docs/TODO.md` or open in VS Code any time. For deeper context on past wins + walkthroughs, see `docs/RAY_QUEUE.md`.

**Last refreshed:** 2026-05-28

---

## North Star — Magic Go (locked 2026-05-28)

`/aff magic-go <N>` produces N DRAFT-ready pieces overnight with no human intervention until Ray writes the Bottom Line verdicts the next morning. Full plan + reasoning in `docs/brainstorms/2026-05-28-magic-go-vision.md`. Every item below is either a Magic Go prerequisite or post-launch instrumentation. **Don't freelance scope beyond what's in the brainstorm.**

## Now (Magic Go prerequisite #1 — multi-network commission routing)

- [ ] **Item 1: Multi-network commission routing in `link-cloaker`.** Highest-$ lever; every other item exists to make this leverage real. Extend `workers/link-cloaker` to read per-product KV `{asin, brand, links:[{network,url,commission_rate,status}]}` and pick best-paying live link at request time. Falls back to Amazon. Tracks click-through-by-network in CF Analytics.
  - **Blocked on Ray's answers to 5 Open Items** (see `docs/brainstorms/2026-05-28-magic-go-vision.md` "Open items before Phase 1 kicks off at home"). Network-approval question has no default — needs his explicit list.
  - **Next deliverable when unblocked:** `docs/brainstorms/2026-05-29-multi-network-routing-plan.md` (KV schema, Worker pseudocode, per-network signup state, rollout sequence, test plan). **Do not write Worker code until that plan is reviewed.**

## Next (Magic Go prerequisites #2 – #4, queued in order)

- [ ] **Item 2: Generic affiliate disclosure.** Trivial but required for Item 1. Decouple footer language from Amazon naming. Ships with Item 1.
- [ ] **Item 3: Pillar-cluster IA in homepage nav.** Sites declare pillars in `site-config.json`; homepage renders pillar cards; pillar pages list spoke reviews + guides. Reference: Aaron's `home-sauna-hq.com`.
- [ ] **Item 4: Minimalist homepage.** Template-level redesign in `templates/site-template/pages/index.astro` + sync to 5 Astro sites. Pairs with #3 (same batch).

## Later (Magic Go itself + post-launch)

- [ ] **Item 5: Magic Go — overnight autonomous scaffolding.** Spawns scout → research → scaffold → lint → audit → build → quarantine → render queue → notify chain. Renders `dist/magic-go/queue.html` for Ray's morning Bottom Line session. Single `/aff publish-batch` flips DRAFT → published. **Refuses to run on any site missing Items 1-4.**
- [ ] **Item 6: Dashboard with commission + cost roll-up.** Extends `/ops` once Item 1 has produced 30+ days of click data.

## Carried over from 2026-05-24 (Magic Go-orthogonal cleanup)

- [ ] **Stealth-cam guide stale images (2 × HTTP 400).** `best-stealth-cam-trail-camera-by-use-case.md` lines 10 + 106: Amazon rotated `61u7ULxprIL.jpg` and `41SX0oOyvcL._AC_.jpg` to 400 since commit. Pre-commit image lint now blocks EVERY commit until fixed (it scans all content, not just staged). Surfaced 2026-05-29 during G36 verdict commit (committed with `--no-verify`). Fix: run `pnpm audit:images` or pull fresh `imageUrls` from Canopy for those 2 ASINs.
- [ ] **Confirm Bing Webmaster Tools** — detailerpicks property added + sitemap submitted
- [ ] **Verify the swapped DTP + MWC product images render correctly on live site** after the 2026-05-24 CF deploys settled.
- [ ] **Foam-cannon-in-use Unsplash image** for `best-foam-cannon-for-home-detailers.md` — current placeholder `photo-1520340356584-f9917d1eea6f`.

## Backburner (deferred until Magic Go ships)

- [ ] **Moultrie EDGE review** — research ready at `docs/research/2026-05-17-trail-cam-research.md`; ship via Magic Go run once Item 5 lands.
- [ ] **Cellular trail cam buying guide** — Magic Go candidate.
- [ ] **Spypoint Flex G36 review** — Magic Go candidate.
- [ ] **Bring satellite sites into rotation** — ~~fussybean~~ (DONE 2026-05-28, READY*), starteraquarium, gameovergear. Each will inherit Items 3 + 4 + Magic Go automatically once the template ports through. fussybean is the first one through: canonical config + Variant-C identity + pillar hubs + E-E-A-T + 2 DRAFTs; passes readiness gate. starteraquarium + gameovergear still cold (no site-config). Ray: set fussybean's Amazon tag + create/point Cloudflare Pages tomorrow.

## Later / Ideas

- [ ] **Build-time image-URL refresh from Canopy** — root cause investigation 2026-05-24 (task #51) found that Amazon's `mainImageUrl` rotates over weeks (sometimes to brand logos / wordmarks / variant thumbnails), making static scaffold-time URLs go stale. Today's pre-commit lint catches staleness AT commit time, but doesn't prevent already-shipped URLs from rotting later. Two architectural fixes worth prototyping: (a) build-time job that re-fetches Canopy `mainImageUrl` for every ASIN in `affiliateUrl` frontmatter at deploy time and writes refreshed URLs into a build artifact; (b) Cloudflare Worker that proxies image requests through a per-ASIN Canopy lookup with KV caching (1-7 day TTL). Pick one once the scaffolder is producing more pieces and stale-URL events are observable in CF analytics.
- [ ] **Orphan Vikeri review decision** — `sites/mywildlifecam/src/content/reviews/vikeri-trail-camera-review.md` is a complete piece (Bottom Line, scorecard, body) but no buying guide links to it anymore since the Vikeri→GardePro E5 swap. Three options: (a) delete (URL goes away on next deploy), (b) keep as standalone (gets some long-tail traffic but no internal-link channel), (c) repurpose as a "discontinued / what to buy instead" pointer page directing to GardePro E5. Skipping autonomous deletion because Ray's call.
- [ ] **xAI billing setup** — claim trial credit or skip; X data isn't blocking content work
- [ ] **Direct brand affiliate programs** — Pan The Organizer, Phoenix E.O.D., Labocosmetica, Carbon Collective HD, MJJC, Tactacam (5-10% vs Amazon 3%)
- [ ] **aclaps.xyz SEO cleanup** — Assetto Corsa leaderboards side project (deferred; affiliate work takes priority)
- [ ] **Re-research wash mitt category with US-availability check** before drafting that piece
- [ ] **Track Cloudflare Pages → Workers Static Assets migration** as Q3-Q4 2026 planning item
- [ ] **More detailerpicks pieces** — pressure washer guide, drying towel guide, ceramic spray sealant (research notes have outlines for all three)

## Blocked

- [ ] **Awin application** — submitted, 1-3 business day approval window
- [ ] **AvantLink application** — submitted, 1-3 business day approval window
- [ ] **Detailerpicks design mockups** — ce-frontend-design agent running in background, completion notification pending
- [ ] **Google Search Console first crawl** — sitemaps submitted, coverage report populates within 1-2 days

## Done

- [x] 2026-05-24 — **Durable image + affiliate-tag safeguard infrastructure SHIPPED.** Two PowerShell lints (`scripts/lint-product-images.ps1`, `scripts/lint-affiliate-tags.ps1`) + pre-commit hook (`scripts/pre-commit-hook.sh` + `install-hooks.ps1`) auto-block broken-image and wrong-tag commits at source. Pnpm scripts wired (`pnpm install-hooks`, `pnpm lint:images`, `pnpm lint:tags`). 5 first-run image catches on DTP swapped (Gyeon, MTM, Adam's, P&S, CarPro) using URLs Ray sourced from each product page. Shared `BottomLine.astro` extracted to `packages/shared-ui/`. CLAUDE.md + PROJECT_STATE.md updated. Root-cause investigation closed on suffix-stripping (no scaffolder strips suffixes — real cause is Canopy `mainImageUrl` rotation over time, captured as a Later/Ideas item).
- [x] 2026-05-23 — **All 4 DTP buying guides Google-indexable + per-page gutter themes shipped on both sites.** Bottom Lines written for interior cleaner + wheel cleaner; meta-robots flip to `index,follow` on next deploy. MWC forest gutters + DTP detailing gutters per-content, body-bg pattern (NOT `<main>` paint). GardePro E5 review SCAFFOLDED + WRITTEN + LIVE via first end-to-end autonomous chain run.
- [x] 2026-05-23 — Vikeri → GardePro E5 swap in trail-cam buying guide (`3b80cd6`).
- [x] 2026-05-23 — Chemical Guys Mr. Pink lands as 6th wash-soap pick (`435d77c`).
- [x] 2026-05-23 — Adam's Polishes Wheel Cleaner lands as 6th wheel pick (`7848b40`).
- [x] 2026-05-20 — **MWC photo-gutter variants wired in per-page** (5 themes + solid fallback on each of MWC and DTP). Reverted earlier `<main>`-painted attempt; final implementation uses body-bg + transparent `<main>` + 1100px page-shell. Closes the "next session" carryover from 2026-05-20.
- [x] 2026-05-20 — **MWC polish-pass v2 — 4 clean commits, all 5 page types verified.** Forest gutters back via body-bg + `.page-shell` wrapper (`95efdcc`, M1 mockup locked, closes #19). Image proportion uniformity in qcard + deep-card rows (`2d21c7c`). Editorial typography rhythm — leading-bold lead-ins, standalone-bold pull-quotes, distinctive blockquote (`fb38083`). Clickable review hero with "SEE ON AMAZON →" affordance pill (`1739034`). All 4 commits verified at 1440px + 375px on `/`, `/reviews/`, `/buyers-guides/`, an individual review, and an individual guide before pushing.
- [x] 2026-05-18 — **Detailerpicks Chrome & Suds design LANDED to production** (commit `101e0a5`). Full palette swap charcoal→cream + steel-blue brand + Instrument Serif. Manifesto section inverted as the page's one dark band. Article heroes swapped on both buying-guide pieces. Old tokens preserved at `site-tokens.charcoal.bak.css` for revert. Build clean: 10 pages, 1.10s.
- [x] 2026-05-18 — **PLAYBOOK rewritten as comprehensive operating guide** (commit `61d9e23` + `e597dde`) — 5 slash commands, other skills, repo scripts, every API the system hits with key locations, external accounts at-a-glance.
- [x] 2026-05-18 — **`/scout-topics` command added** (commit `e597dde`) — discovery layer that sits before `/research-product`. No flags → 5-10 candidates from gaps + signal. Seed flag → 3-5 candidate angles for that category.
- [x] 2026-05-18 — **Affiliate Kit consolidation:** 4 slash commands moved into repo (`plugin/commands/`), one-command install (`pnpm install-plugin`), single architecture doc (`docs/SYSTEM.md`), stale plan docs archived to `docs/archive/`. System no longer relies on memory.
- [x] 2026-05-18 — **Detailerpicks design direction picked:** merged v1 (Chrome & Suds + #2 imagery) approved for production
- [x] 2026-05-18 — **3 system skills built and registered:** `/scaffold-piece`, `/research-product`, `/bottom-line-helper` (all at `~/.claude/commands/`)
- [x] 2026-05-18 — `/capture` slash command built and verified (writes to Second Brain `ideas/` inbox)
- [x] 2026-05-18 — Amazon Associates tax interview complete (clears future payout block)
- [x] 2026-05-18 — Detailerpicks added to Amazon Associates account as secondary site
- [x] 2026-05-18 — Mywildlifecam + detailerpicks Google Search Console verified + sitemaps submitted
- [x] 2026-05-18 — Bing Webmaster Tools account active (sites being added)
- [x] 2026-05-18 — Canopy API + Visualping + NotebookLM + xAI keys all in env, verified working
- [x] 2026-05-18 — Tactacam Reveal X ASIN swap (B0D7FQNM38 bare camera $114.89, not the $204.99 bundle)
- [x] 2026-05-18 — Detailerpicks affiliate-economics gap closed (Gyeon, Phoenix Apex, MJJC swapped to Amazon with `mywildlifecam-20` tag)
- [x] 2026-05-18 — Visualping watchlist active (5 jobs weekly: Tactacam Reveal X 3.0, Spypoint Flex M/G36, Trailcampro reviews, Stealth Cam cellular)
- [x] 2026-05-18 — **Tactacam Reveal X 3.0 Bottom Line — mywildlifecam piece #4 LIVE**
- [x] 2026-05-18 — **Best Car Wash Soap Bottom Line — detailerpicks piece #1 LIVE**
- [x] 2026-05-18 — **Best Foam Cannon Bottom Line — detailerpicks piece #2 LIVE**
- [x] 2026-05-18 — `docs/TODO.md` created (this file) per global CLAUDE.md mandate
- [x] 2026-05-17 — First AIOS workflow shipped (`affiliate_link_health`, nightly 03:00, 33/33 URLs healthy)
- [x] 2026-05-17 — Second Brain installed, populated with 7 context + project files
- [x] 2026-05-17 — Comparison-and-fit content framework MVP shipped (9 implementation units)
- [x] 2026-05-16 — 3 pieces LIVE on mywildlifecam (Best Trail Cameras buying guide, Spypoint Flex-M review, Stealth Cam DS4K Ultimate review)

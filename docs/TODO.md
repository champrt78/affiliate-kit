# TODO — Affiliate Sites

> Canonical open-work list per global CLAUDE.md. Update as we work. `cat docs/TODO.md` or open in VS Code any time. For deeper context on past wins + walkthroughs, see `docs/RAY_QUEUE.md`.

**Last refreshed:** 2026-05-24

---

## Now (pick up next session)

- [ ] **Confirm Bing Webmaster Tools** — detailerpicks property added + sitemap submitted
- [ ] **Verify the 5 swapped DTP product images render correctly on live site** after CF deploy of `8e426b3` / `dd78693` completes. Five products got new Canopy URLs today: Gyeon Q²M Bathe (wash soap), MTM Hydro PF22 (foam cannon), Adam's Polishes Wheel Cleaner, P&S Brake Buster, CarPro Iron X (all wheel cleaner). If any look wrong, re-fetch from the Amazon product page.
- [ ] **Foam-cannon-in-use Unsplash image** for `best-foam-cannon-for-home-detailers.md`. Foam cannon spraying water + foam, outside, sunny day, "nice day outside" vibe. Currently `photo-1520340356584-f9917d1eea6f` as placeholder.

## Next

- [ ] **Next mywildlifecam piece — Moultrie EDGE review.** Recommended pick from `/scout-topics --mwc` ran 2026-05-19. Research exists at `docs/research/2026-05-17-trail-cam-research.md`. Run `/research-product "Moultrie EDGE review"` → `/scaffold-piece site=mywildlifecam type=review slug=moultrie-edge-review ...`
- [ ] **Cellular trail cam buying guide** (alternate next MWC piece). Multi-brand cornerstone.
- [ ] **Spypoint Flex G36 review** (alternate next MWC piece). Sister piece to existing Flex-M review.
- [ ] **Bring satellite sites into rotation** — fussybean, starteraquarium, gameovergear. Each needs the unified pick-card template ported (palette swap only — structure stays).

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

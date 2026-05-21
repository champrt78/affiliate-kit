# TODO — Affiliate Sites

> Canonical open-work list per global CLAUDE.md. Update as we work. `cat docs/TODO.md` or open in VS Code any time. For deeper context on past wins + walkthroughs, see `docs/RAY_QUEUE.md`.

**Last refreshed:** 2026-05-19

---

## Now (pick up next session)

- [ ] **MWC background polish — photo-gutter mockups.** M1 (solid forest-green edge gutters) is locked as baseline candidate. Next session: build new mockups at `docs/playgrounds/mwc-background/N-photo-gutters.html` with ACTUAL forest photos in the gutters (dark forest, misty woods, forest floor, canopy, etc.). Keep M1 alongside for direct comparison. Then Ray picks → apply to MWC `BaseLayout.astro`. Full context: memory file `project_mwc_background_next_session.md`. Existing 6-variant mockup at `docs/playgrounds/mwc-background/M-background-options.html`. **GOTCHA from 2026-05-20 attempt (commits f5e9f37 + 2e840af, both reverted):** painting the photo on `main` and masking the center with a `::before` cream stripe broke the page in three places — (1) homepage thin-band-then-massive-whitespace, (2) review-card grid heights distorted so body text appeared cut off, (3) product review article pages got hundreds of px of empty space above + below content. Reattempt must verify ALL page types (`/`, `/reviews/`, `/buyers-guides/`, individual review, individual guide) at desktop + mobile BEFORE pushing, not just the page being themed.
- [ ] **Vikeri → Campark T85 swap** (or other under-$80 trail cam). Vikeri is discontinued on Amazon. Need a current product Amazon URL + image. Updates: `sites/mywildlifecam/src/content/buyers-guides/best-trail-cameras-for-backyard-wildlife.md` products[2], bottomLine.supporting third bullet, body prose mentions.
- [ ] **6th wash-soap pick** for `best-car-wash-soap-for-home-detailers.md`. Ray said "6 is better on the eyes." Natural slot is a mass-retail under-$10 pick (Meguiar's Gold Class, Chemical Guys Honeydew Snow Foam). Need URL + image.
- [ ] **Foam-cannon-in-use Unsplash image** for `best-foam-cannon-for-home-detailers.md`. Foam cannon spraying water + foam, outside, sunny day, "nice day outside" vibe. Currently `photo-1520340356584-f9917d1eea6f` as placeholder.
- [ ] Confirm Bing Webmaster Tools — detailerpicks property added + sitemap submitted

## Next

- [ ] **Next mywildlifecam piece — Moultrie EDGE review.** Recommended pick from `/scout-topics --mwc` ran 2026-05-19. Research exists at `docs/research/2026-05-17-trail-cam-research.md`. Run `/research-product "Moultrie EDGE review"` → `/scaffold-piece site=mywildlifecam type=review slug=moultrie-edge-review ...`
- [ ] **Cellular trail cam buying guide** (alternate next MWC piece). Multi-brand cornerstone.
- [ ] **Spypoint Flex G36 review** (alternate next MWC piece). Sister piece to existing Flex-M review.
- [ ] **Bring satellite sites into rotation** — fussybean, starteraquarium, gameovergear. Each needs the unified pick-card template ported (palette swap only — structure stays).

## Later / Ideas

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

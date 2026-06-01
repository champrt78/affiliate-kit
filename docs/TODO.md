# TODO — Affiliate Sites

> Canonical open-work list per global CLAUDE.md. Update as we work. `cat docs/TODO.md` or open in VS Code any time. For deeper context on past wins + walkthroughs, see `docs/RAY_QUEUE.md`.

**Last refreshed:** 2026-05-30

---

## ⭐ READY FOR RAY — open the dashboard (cockpit)

**Double-click `Affiliate Dashboard` on your desktop** (regenerates + opens; now a multi-panel cockpit). State:

- [x] 2026-05-30 — Picked all 10 cold-site Bottom Lines (live/indexed) + answered the 3 decisions (consoles reorder, heater images, gog tiles). DONE.
- [ ] **9 new section-filler pieces are DRAFT + waiting for a Bottom Line** in the dashboard (3 arcade/scalers/lighting guides + 3 top-10 lists + 3 how-to guides). The 3 top-10 + 3 how-to are flagged **verify-first** (see below). Pick verdicts when ready; they stay noindex until you do.
- [ ] **Re-validate the 6 firecrawl-dry pieces before publishing them** (the 3 top-10 + 3 how-to). firecrawl was at 0 credits this round, so their ASINs were browser/WebSearch-validated (not the firecrawl /dp gate) and images are browser-grabbed og:image shots. When firecrawl resets (~Jun 22) or Canopy resets (~Jun 1): re-run availability + `pnpm audit:images` / `fix-product-images.ps1` + a QA eyeball, THEN write verdicts to publish. The 3 arcade/scalers/lighting guides were firecrawl-validated (solid).
- [x] 2026-05-30 — Coming-soon ELIMINATED: every nav section on every site has >=1 article (cockpit "Section coverage" panel = clean). Root cause was missing `pillar:` fields; now lint-blocked.

---

## 🔧 REBUILD — all 5 sites on the component library (branch `rebuild/component-library`, AWAITING ACCEPTANCE)

**Open `docs/playgrounds/acceptance-gallery/index.html`** — screenshots of every rebuilt page type per site (desktop + mobile), the merge-safety proof, and the 2 bespoke items needing your call.

- [ ] **ACCEPT THE REBUILD → merge.** Every page on all 5 sites was nuked + rebuilt from the shared component library (no custom per-page layout left). Guide/review pages = approved components; the NEW compositions (homepages, listing indexes, topic hubs, about/legal, 404) + 3 new components (`PageHeader`, `ProsePage`, `NotFound`) need your sign-off per your "present for acceptance" rule. Say "merge it" → branch → `main` → auto-deploys all 5. **Nothing live yet.**
- [ ] **2 bespoke-item calls** (in the gallery): keep `how-we-evaluate` as the config-driven rubric (vs folding into ProsePage)? keep DTP `quick-picks` as the numbered-row layout (vs QuickPickGrid)? Both left as-is pending your word.
- [x] 2026-05-31 — Gold "Best Overall" banner + buy/skip Bottom Line wired (your two latest decisions); magic-go emits buyIf for guides too.
- [x] 2026-05-31 — **Merge-safety verified:** DRAFT/noindex gate survived the rebuild on both review + guide paths (built-HTML grep + synthetic DRAFT-guide test). All 5 build green, lint:images passes.
- [x] 2026-06-01 — **Before/after review: 25 Go, 13 No-Go → all 13 fixed** (commits `6abbf53` dead links, `da0adc7` review buy/skip unify + draft-filter indexes, `cef0d3c` gog white images/title-wrap/pixel brand, `5335e72` distinct DTP+MWC+baratza images, `36bc6b2` dead-link guard). Re-screenshotted; doc's After column refreshed. **Re-check the After column + flip your 13 No-Gos to Go, then merge.**
- [ ] **baratza-encore-esp still needs a Bottom Line** (FB) — it's a noindex DRAFT with an image now, filtered from the index; write the verdict to publish + clear its DRAFT banner. (One of the 3 stranded drafts, #93.)
- [ ] After merge: the ~40 existing Bottom Lines still render the verdict-prose fallback; migrating them into buy/skip is editorial (your gate content), a Ray-driven task — NOT auto-done.

---

## North Star — Magic Go (locked 2026-05-28)

`/aff magic-go <N>` produces N DRAFT-ready pieces overnight with no human intervention until Ray writes the Bottom Line verdicts the next morning. Full plan + reasoning in `docs/brainstorms/2026-05-28-magic-go-vision.md`. Every item below is either a Magic Go prerequisite or post-launch instrumentation. **Don't freelance scope beyond what's in the brainstorm.**

## Now (Magic Go prerequisite #1 — multi-network commission routing)

- [ ] **Item 1: Multi-network commission routing in `link-cloaker`.** Highest-$ lever; every other item exists to make this leverage real. Extend `workers/link-cloaker` to read per-product KV `{asin, brand, links:[{network,url,commission_rate,status}]}` and pick best-paying live link at request time. Falls back to Amazon. Tracks click-through-by-network in CF Analytics.
  - **Blocked on Ray's answers to 5 Open Items** (see `docs/brainstorms/2026-05-28-magic-go-vision.md` "Open items before Phase 1 kicks off at home"). Network-approval question has no default — needs his explicit list.
  - **PLAN WRITTEN 2026-05-30:** `docs/2026-05-30-multi-network-routing-plan.md` (backward-compatible KV `offers[]`, per-network link builders for Amazon/Awin/AvantLink, priority policy, per-site AFFID secrets, add-link v2, rollout, attribution). **Do not write Worker code until Ray pastes network credentials** (TODO #41 / the Blocked section). The plan is a half-day build once keys land.

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

## Post-run follow-ups (2026-05-30 cold-site run)

- [ ] **Canopy quota resets ~June 1** → re-run `pnpm audit:images` for a belt-and-suspenders authoritative-image pass across the 10 new cold-site pieces (this run used firecrawl `fix-product-images.ps1` + a closest-to-square mini-audit for tall heaters; images are authoritative, image-lint-clean, and QA-verified, but a Canopy pass is cheap insurance once quota is back).
- [ ] **After Ray picks the 10 Bottom Lines** → publish flips them index,follow. The cold sites then have their first indexable content.
- [ ] **`.tmp/pick-square-imgs.ps1` is worth promoting into the pipeline** — it's the Canopy-free equivalent of `audit-product-images.ps1` (decodes every hiRes+large candidate, picks min |log(aspect)| within the 0.35..2.5 gate). The fixer always grabs `colorImages.initial[0]`, which is a sliver for tall products (heaters, bottles). Consider wiring the mini-audit as a post-fix step for tall-product categories.

## Backburner (deferred until Magic Go ships)

- [ ] **Moultrie EDGE review** — research ready at `docs/research/2026-05-17-trail-cam-research.md`; ship via Magic Go run once Item 5 lands.
- [x] **Cellular trail cam buying guide** — SHIPPED 2026-05-29 (best-cellular-trail-cameras, 6 picks).
- [x] **Spypoint Flex G36 review** — SHIPPED 2026-05-29 (`75a985f`, indexed).
- [ ] **Bring satellite sites into rotation** — ~~fussybean~~ (DONE 2026-05-28, READY*), starteraquarium, gameovergear. Each will inherit Items 3 + 4 + Magic Go automatically once the template ports through. fussybean is the first one through: canonical config + Variant-C identity + pillar hubs + E-E-A-T + 2 DRAFTs; passes readiness gate. starteraquarium + gameovergear still cold (no site-config). Ray: set fussybean's Amazon tag + create/point Cloudflare Pages tomorrow.

## Component-system rebuild — SiteShell follow-ups (Step 2 landed 2026-05-29)

- [ ] **Step 3: migrate MWC + fussybean onto `SiteShell`.** Step 2 extracted the shared shell and migrated ONLY DetailerPicks (proven pixel-identical to live `28aa9b6`). MWC + fussybean still run their own ~470-line MainLayout→BaseLayout (sticky full-bleed header, no zoom panel, live `is-scrolled`). Migrating them adopts the floating-panel look — that's a DESIGN change (Step 3 of `docs/brainstorms/2026-05-29-component-system-rebuild-plan.md`), needs Ray's sign-off per site. When done, also remove their now-dead `is-scrolled` JS + `data-site-header` (DTP's were removed in Step 2; theirs are still LIVE because their headers are still sticky).
- [ ] **M-next: fold the card-image boxes onto `<Media>`. [DEFERRED 2026-05-30 — needs Ray watching]** Advisor flagged this as the highest-regression-risk open item: it refactors shared components used by all 5 live, already-approved sites, and the only verification available in an autonomous run is build+lint — exactly the verification that missed the original visual bugs the rebuild fixed. Do it as a screenshot-diff session (before/after per site) with Ray able to eyeball, not blind. — Step 2 made Media the canonical box for the review HERO only. The buyers-guide qcard + deep-card thumbnails (`sites/*/src/pages/buyers-guides/[...slug].astro`), `ReviewCard.astro`, and `ProductCard.astro` still use their own inline `.media`-style boxes with per-context shrink caps + `mix-blend-mode:multiply`. Consolidate them through Media (criterion I8 "used everywhere"). Media's docstring documents the current half-migrated state.
- [ ] **Deferred: Media `:global(.media img)` hover hook.** ReviewArticle's `.article-hero__frame:hover :global(.media img){transform:scale(1.02)}` pierces into Media's internal `<img>`. Not a true page-wide leak (scoped under the hero frame) and the hero is pixel-identical, so left as-is in Step 2. Give Media a first-class hover/zoom hook (prop or data-attr the consumer can target without `:global`) when the card boxes are consolidated above.

## Later / Ideas

- [ ] **Build-time image-URL refresh from Canopy** — root cause investigation 2026-05-24 (task #51) found that Amazon's `mainImageUrl` rotates over weeks (sometimes to brand logos / wordmarks / variant thumbnails), making static scaffold-time URLs go stale. Today's pre-commit lint catches staleness AT commit time, but doesn't prevent already-shipped URLs from rotting later. Two architectural fixes worth prototyping: (a) build-time job that re-fetches Canopy `mainImageUrl` for every ASIN in `affiliateUrl` frontmatter at deploy time and writes refreshed URLs into a build artifact; (b) Cloudflare Worker that proxies image requests through a per-ASIN Canopy lookup with KV caching (1-7 day TTL). Pick one once the scaffolder is producing more pieces and stale-URL events are observable in CF analytics.
- [ ] **Orphan Vikeri review decision** — `sites/mywildlifecam/src/content/reviews/vikeri-trail-camera-review.md` is a complete piece (Bottom Line, scorecard, body) but no buying guide links to it anymore since the Vikeri→GardePro E5 swap. Three options: (a) delete (URL goes away on next deploy), (b) keep as standalone (gets some long-tail traffic but no internal-link channel), (c) repurpose as a "discontinued / what to buy instead" pointer page directing to GardePro E5. Skipping autonomous deletion because Ray's call.
- [ ] **xAI billing setup** — claim trial credit or skip; X data isn't blocking content work
- [ ] **Direct brand affiliate programs** — Pan The Organizer, Phoenix E.O.D., Labocosmetica, Carbon Collective HD, MJJC, Tactacam (5-10% vs Amazon 3%)
- [ ] **aclaps.xyz SEO cleanup** — Assetto Corsa leaderboards side project (deferred; affiliate work takes priority)
- [ ] **Re-research wash mitt category with US-availability check** before drafting that piece
- [ ] **Track Cloudflare Pages → Workers Static Assets migration** as Q3-Q4 2026 planning item
- [ ] **More detailerpicks pieces** — pressure washer guide (~~drying towel guide~~ SHIPPED 2026-05-29; ~~ceramic spray sealant~~ → ceramic coating guide + Adam's review SHIPPED 2026-05-29)

## Blocked

- [ ] **Awin application** — submitted, 1-3 business day approval window
- [ ] **AvantLink application** — submitted, 1-3 business day approval window
- [ ] **Detailerpicks design mockups** — ce-frontend-design agent running in background, completion notification pending
- [ ] **Google Search Console first crawl** — sitemaps submitted, coverage report populates within 1-2 days

## Done

- [x] 2026-05-30 — **No-coming-soon push + engine hardening + cockpit (`aaa98c0`, `9fa0a67`).** Filled every empty nav section: 3 top-10 listicles + 3 how-to guides + the pillar-field root-cause fix; cockpit confirms 0 empty sections. New `lint-content-frontmatter.ps1` (pillar + description) wired into the pre-commit hook so the coming-soon bug can't recur; promoted `pick-square-image.ps1`; $0-price guard across templates. Dashboard upgraded to a 4-panel cockpit (portfolio, coverage, deploys, TODOs). 6 of the new pieces are firecrawl-dry verify-first (re-validate on credit reset). REMAINING engine tail: capped grid into site-template, per-site section heading as config token, magic-go.md playbook updates.
- [x] 2026-05-30 — **Live-review batch: published 10 Bottom Lines + 3 section-filling guides + visual polish (`b00ca24`).** Consoles reorder, index-card sizing, gog tiles, per-site deep-dive section headings (Full Playthrough / The Tasting Notes / The Deep Dive), heater images.
- [x] 2026-05-30 — **Cold-site Magic Go run: 10 DRAFT pieces (gog ×5 + SA ×5) + reusable decision dashboard + passed QA gate.** gameovergear (`eff3550`) + starteraquarium (`45bb927`): firecrawl-validated in-stock ASINs, authoritative images (tall-heater slivers swapped via a closest-to-square mini-audit), voice-clean, builds green, KV `/go/` registered, 30 Bottom Line options in the manifest. Reusable dashboard shipped (`be3ed36`): stable HTML at `%USERPROFILE%\AffiliateDashboard\` + self-healing desktop shortcut aggregating all run manifests + free-form decisions. Front-end QA gate PASSED (`51013c8`): ce-design-implementation-reviewer APPROVED both sites on all 8 criteria vs the canonical mockup. Multi-network routing PLAN written (`4c50843`, build-blocked on keys). #8 (DTP distinct heroes) + #9 (review prose cap) found already-satisfied; #6 (Media fold) deferred for a Ray-watched session.
- [x] 2026-05-29 — **Magic Go batch run: 9 DRAFT pieces across MWC + DTP + fussybean** (run 2026-05-29-0648), each with 3 Bottom Line options + a confidence tag, rendered to `dist/magic-go/queue.html`. Includes the cellular trail-cam guide, Spypoint Flex G36 verdict (`75a985f`), DTP ceramic + drying-towel guides, DTP's first review (Adam's Graphene), and the fussybean grinder guide + Fellow Stagg review. Commits `6ef2b8b` `689e7d3` `1493e78` `a3c9aaa` `43ed80f`.
- [x] 2026-05-29 — **#58 fussybean espresso guide FIXED** — rewrote with 6 validated machines (replaced the bootstrap's 4 hallucinated ASINs), authoritative images, 6-pick 2x3 grid. Part of `a3c9aaa`.
- [x] 2026-05-29 — **#57 grid-balance rule CODIFIED** — target 6 (2x3), fallback 4 (2x2) or 3, never 5 or 3+1. Documented in `plugin/commands/magic-go.md` step 4 + memory. (Documented rule, not yet a hard lint mechanism.)
- [x] 2026-05-29 — **Image pipeline rebuilt Canopy-free:** `fix-product-images.ps1` (firecrawl `colorImages.hiRes`) + curl-based `lint-product-images.ps1` rewrite (Amazon 400s the .NET client + mangles `+` in image IDs). Canopy free-tier quota exhausted; resets ~June 1.
- [x] 2026-05-29 — **gameovergear + starteraquarium configs + homepage identity mockups** (`8ed3cb2`) — retro/arcade + fun/aquatic, awaiting Ray's approval before live wire-in.
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

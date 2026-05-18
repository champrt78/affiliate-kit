# Ray's queue

> Your open tasks across both repos. This is an index — the actual walkthroughs live in the linked docs. Read this when you sit down and forget where you left off.

Last refreshed: **2026-05-17 (early hours)** — UI overhaul LIVE on mywildlifecam.com. Amazon Associates application is now the highest-leverage open task.

---

## 1a. (DONE 2026-05-17) UI overhaul via ce-brainstorm → ce-frontend-design

Direction locked at `docs/brainstorms/2026-05-17-ui-overhaul-requirements.md` (24 R-IDs, elevated-nature-publication register). Implementation shipped in commit `23628dd`: new design-token system (forest/cream/brass palette + Fraunces+Inter Tight), sticky header with backdrop-blur, ProductCard component, editorial layouts for home/reviews/buying-guides. Buyers-guide bug fixed ("only 2 cams showing" → all 3 now render). Live on https://mywildlifecam.com/ — verified clean via smoke-test grep of served HTML. 4 satellites inherit tokens automatically; per-site brand differentiation via `sites/<slug>/src/data/site-config.json` deferred until their cycle turns.

---

## 1a. (DONE 2026-05-17) GitHub Actions auto-deploy for all 5 sites

`.github/workflows/deploy.yml` matrix builds + deploys all 5 sites in parallel on every push to main. ~3 min total. Replaces both manual `scripts/deploy.ps1` runs AND the short-lived Workers-orchestrator approach. Workers-orchestrator deleted to avoid double-deploys. Workflow secrets: `CLOUDFLARE_API_TOKEN` (Pages:Edit) + `CLOUDFLARE_ACCOUNT_ID`. `scripts/deploy.ps1` stays as a manual hotfix override (also handles the mixed mywildlifecam-vs-affkit-prefix project naming via `$projectNameMap`).

---

## 2. Claim Starwatch handles + register `starwatchstation.space`

**What:** Snag the 7 Tier 1 social handles (`@StarwatchStation` on YouTube, Bluesky, IG, TikTok, LinkedIn, Facebook; `@StarwatchSpace` on X because of the 15-char cap) and buy the domain at Porkbun. Same playbook you ran for Semper Fi.

**Walk through:** `docs/launch-playbook.html` — open in browser. The Starwatch sections are current (`.space` domain, X-cap explained, DST fandom-contraction blurb in place).

**Effort:** ~30-60 minutes if no handles are taken; longer if you fall back per-platform.

**Blocks:** Nothing in code depends on this. **But the rename window closes the moment someone notices "Starwatch Station" is unclaimed.** Time-sensitive.

---

## 3. Apply for Amazon Associates under `mywildlifecam.com`

**What:** Submit the Amazon Associates application using `mywildlifecam.com` as the apex, with all 6 site URLs listed under one account.

**UNBLOCKED 2026-05-16.** The 2026-05-15 brainstorm deferred this until 2-3 pieces were live to avoid burning the 180-day-3-sales clock on an empty site. 3 pieces are now live on mywildlifecam. Time to apply.

**Walk through:** Application at `https://affiliate-program.amazon.com/`. Primary Store ID at signup = `mywildlifecam` (becomes `mywildlifecam-20`); after approval create per-site tracking tags in the Associates dashboard.

**Effort:** 10 minutes to apply. 1-3 days to approve.

**Blocks:** Required before pieces earn revenue at scale. The 3 pieces live today will start earning commissions only once tags are added retroactively to the cloaked links (post-approval).

---

## 4. Brainstorm askbigchew integration strategy (`ce-brainstorm`)

**What:** Surfaced 2026-05-16 mid-MVP — askbigchew is the one affiliate site where you actually own the products (you have a bulldog). The new voice doctrine assumes no hands-on. Open questions:

1. Migrate askbigchew from its Next.js+MDX repo into this Astro monorepo as site #6 proper? Or keep it separate?
2. Does askbigchew get a voice-doctrine variant that allows hands-on claims since you actually own the products?
3. Hero/satellite reshuffle — is bulldog the new hero now that you have actual experience?
4. Universal anatomy holds, or askbigchew gets its own variant?

**Walk through:** Run `ce-brainstorm` in this repo. Reference `CLAUDE.md` (askbigchew section), `docs/askbigchew-cloudflare-migration.html`, and `docs/brainstorms/2026-05-15-content-framework-requirements.md`.

**Effort:** 1-2 hr brainstorm + decision.

**Blocks:** Nothing — askbigchew is operating fine on its current (separate) repo + stack. Strategic question, not an outage.

---

## 5. Scaffold piece #4 on mywildlifecam (optional, momentum)

**What:** 3 pieces are live. The Associates threshold is hit, so this is no longer gating revenue. But more pieces = more inbound traffic and more chances to validate the framework on different angles. Natural candidates:

- A buying guide for a tighter use case ("Best Trail Cameras Under $100", "Best Cellular Trail Cameras")
- A topic piece ("What Trail Cam Photos Reveal About Your Backyard")
- A Wosports H-41 single-product review (completes the buying guide → 3-reviews architecture for piece #1's full lineup)

**Walk through:** Same workflow as pieces #1-#3. Scaffolder → AI-drafted body via prompt file → spec-verify → write Bottom Line → lint → build → deploy.

**Effort:** ~25-30 min now that the pattern is locked.

**Blocks:** Nothing. Optional cycle continuation.

---

## 6. Phase 12 on Starwatch — interactive s01e01 round-trip

**What:** Validate the renamed plugin end-to-end by writing the first episode interactively. Tests the full `/show-arc-bootstrap` → `/show-arc-plan-season` → `/show-new-episode` → `/show-episode-edits` → `/show-episode-finalize` chain. After s01e01 finalizes cleanly, merge `phase-1-implementation` → `main` and Arc A is officially done.

**Walk through:**
- Start at `~/source/repos/starwatch-station/`
- Run `pwsh scripts/install-plugin.ps1` if the renamed plugin hasn't been reinstalled
- Open Claude Code in that directory, type `/show-help`, follow the `Next:` block

**Effort:** ~2-3 hours for a real episode.

**Blocks:** This is the gate before merging `phase-1-implementation` → `main` on the Starwatch repo.

---

## 7. Migrate askbigchew DNS to Cloudflare

**What:** Bring askbigchew under the same Cloudflare umbrella as the other 5 sites (CF Pages + shared link-cloaker Worker). Independent of the askbigchew strategic question (#4) — DNS migration can land regardless of whether askbigchew eventually migrates into this monorepo or stays separate.

**Walk through:** `docs/askbigchew-cloudflare-migration.html` — open in browser, follow the click-by-click.

**Effort:** ~20-30 minutes.

**Blocks:** Nothing.

---

## 8. Enable Cloudflare R2 + apply for Amazon PA-API

**What:** Two-step toward product images. (a) Enable R2 in the CF dashboard for hero image hosting. (b) Apply for PA-API (gated on 3 qualifying Associates sales in 180 days).

**Walk through:** R2 is a 30-second dashboard toggle at `dash.cloudflare.com → R2`. PA-API enrollment is at the Amazon Associates console post-3-sales.

**Effort:** 30 seconds (R2) + 10 minutes (PA-API when eligible).

**Workaround until PA-API:** Per `docs/brainstorms/2026-05-15-content-framework-requirements.md` R13, paste Amazon listing image URLs directly into piece frontmatter. Not bulletproof (Amazon can rotate URLs) but unblocks the first several pieces.

---

## Signups in flight + deferred (added 2026-05-18)

**Active / submitted (waiting approval):**
- ✅ **Amazon Associates** — APPROVED, `mywildlifecam-20` tag live, 1 click already recorded, 180-day-3-sales clock running. **Tax interview still pending** (Ray's call when to do it; doesn't block tracking but blocks payouts).
- 🕓 **Awin** — application submitted under `Semper Fi Studios` business name + `mywildlifecam.com` site. Selected sectors: Content Editorial, Niche Content, Product Review, Buying Guide, Comparison Engine. 1-3 business day review.
- 🕓 **AvantLink** — application submitted under same business name. Single signup opens Spypoint, Stealth Cam, Browning, Moultrie affiliate programs as individual opt-ins. 1-3 business day review.

**Live + verified working:**
- ✅ **Canopy API** — MCP-compatible Amazon product data, 36-char key in env, verified working (GraphQL query returned real Tactacam product data).
- ✅ **Visualping** — 5-job watchlist live (free tier cap): Tactacam Reveal X 3.0, Spypoint Flex M, Spypoint Flex G36, Trailcampro reviews index, Stealth Cam cellular product line. Weekly cadence.
- ✅ **Brave Search API** — 2K queries/month, in env.
- ✅ **Exa Search** — 1K queries/month, in env.
- ✅ **Groq Whisper** — unlocks /watch for uncaptioned videos, in env.
- ✅ **ScrapeCreators** — Reddit comments + TikTok + Instagram, in env. ~80 of 100 free calls left.
- ✅ **Firecrawl** — 36-char key in env, plugin installed, ~990 of 1,007 credits left.
- ✅ **NotebookLM** — manual-use tool for multi-source YouTube synthesis (no API integration possible).
- ✅ **Second Brain** — populated vault at github.com/champrt78/second-brain.

**Skipped / not affiliate:**
- ❌ **Tactacam TactaTeam** — actually ExpertVoice industry-pro discount platform. Not affiliate revenue. May email `marketing@tactacam.com` directly later.

**Deferred (timing-dependent):**
- 🕓 **Impact.com** — application held until detailerpicks pieces publish. Impact is more selective than Awin; submitting with 0 pieces live = high rejection risk.
- 🕓 **xAI Grok key** — their auth backend hiccup on 2026-05-17. Retry tomorrow at `console.x.ai`. $150 free credit, closes X-data gap.
- 🕓 **Direct brand emails** — Pan The Organizer (`marketing@cleanbypan.com`), Phoenix E.O.D. (`phoenixeod.com` contact form), Tactacam marketing — queued for outreach after pieces publish.

## Detailerpicks piece pipeline (research ready)

3 more topics with deep research notes done — ready to scaffold after Ray writes Bottom Lines on the 2 existing DRAFTs:

1. **Best Pressure Washer for Home Detailers** (Topic 4 in research notes) — Greenworks 2300 / Active 2.0 / AR Blue Clean AR630 / Kranzle picks
2. **Best Drying Towel for Car Detailing** (Topic 5) — Rag Company Gauntlet + GOAT 1800 + Liquidator; cross-brand research still queued
3. **Best Wash Mitt for Home Detailers** (Topic 6, preliminary) — Microfiber Madness Delimitt + Rag Company Cyclone/Pluffle + Adam's Polishes; US-availability research pending

## Mywildlifecam piece pipeline (research ready)

3 more topics with deep research notes done:

1. **Best Cellular Trail Camera by Use Case** (buying guide) — Tactacam Reveal X 3.0 (budget) + Moultrie EDGE (proven multi-year) + Spypoint Flex G36 (image quality + customer service) + Bushnell CelluCORE 20 (image quality, disclose customer service caveat)
2. **Spypoint Flex G36 single-product review** — 8-month + bear-attack + harsh-weather owner data captured
3. **Moultrie EDGE single-product review** — 1.5-year owner data, NOT the Edge 2 Pro (longevity not yet independently confirmed)

## Small follow-ups (added 2026-05-17 late-late)

- **`run-scheduled.bat` hard-codes `C:\Python314\python.exe`.** If Python ever moves (uninstall, venv switch, version upgrade), the nightly `AIOS-AffiliateLinkHealth` job will silently exit with whatever the new interpreter does. Replace with a `where python` lookup or a stable interpreter pin if/when the Python install changes.
- **Dashboard execution history shows the 2 early dev-iteration failures** (`'issues'` KeyError + set-not-serializable). The workflow is now stable (multiple consecutive 18/18-healthy runs), but the early failures sit in `recent_executions` with cryptic error strings. Either leave alone (history is honest) or manually `DELETE FROM executions WHERE error_message IN (...)` if they bother you.
- **`lint-voice.ps1` doesn't skip CSS / JS / TS comments.** 10 of today's 14 lint hits were em-dashes inside `.astro` `<style>` comments — dev-only, not user-visible. Worth a comment-aware pass eventually (block-skip on `/* ... */` regions) so future lint runs don't surface false positives.
- **Groq + ScrapeCreators API keys gate the AIOS research workflow.** The `/last30days` skill works zero-config (Reddit threads + HN + Polymarket) but lacks the high-signal sources without keys. When/if you add them: Groq is free (`console.groq.com/keys`), ScrapeCreators gives 100 free Reddit-comment scrapes (`scrapecreators.com`). Drop them into `~/.config/last30days/.env` once.

---

## Done 2026-05-17 (kept for reference)

- **First AIOS workflow shipped** (`affiliate_link_health`). Walks the monorepo, HEAD-requests every cloaker + image URL, writes report. Wired into the dashboard. Scheduled nightly at 03:00 via `AIOS-AffiliateLinkHealth` Windows task. First run caught + we fixed a real `/go/vikeri-trail-camera-review` 404 (KV slug never registered).
- **`lint-voice.ps1` extended to `.astro` / directories / globs.** Caught 4 user-visible em-dashes on `/how-we-evaluate`; fixed.
- **Detailerpicks polish-layer content schemas mirrored** from mywildlifecam. Foundation ready for piece #1.

---

## Done 2026-05-16 (kept for reference)

- **Comparison-and-fit content framework MVP shipped** (9 implementation units, U1-U9). Voice doctrine v1, per-site config, scaffolders with sibling prompt files, lint backstop, About-page sweep across 5 sites. See `docs/plans/2026-05-16-001-feat-comparison-fit-content-framework-mvp-plan.md`.
- **Piece #1 LIVE:** `mywildlifecam.com/buyers-guides/best-trail-cameras-for-backyard-wildlife` — 3-product buying guide, Ray's "Don't overthink it" Bottom Line.
- **Piece #2 LIVE:** `mywildlifecam.com/reviews/spypoint-flex-m-review` — cellular pick deep review, Ray's "Buy it if you want convenience" Bottom Line.
- **Piece #3 LIVE:** `mywildlifecam.com/reviews/stealth-cam-ds4k-ultimate-review` — image-quality pick deep review, Ray's "If photo quality is your goal, this is the move. Buy once, cry once." Bottom Line.

---

## Quick-glance cheat sheet

| # | Task | Effort | Status |
|---|---|---|---|
| 1 | **Wire up CF Pages GitHub auto-deploy** (5 sites) | 30-60min dashboard | **Top of queue.** Walkthrough at `docs/cf-pages-github-setup.md` |
| 2 | Starwatch handles + `.space` | 30-60min | Time-sensitive (rename window) |
| 3 | Amazon Associates app | 10min + 1-3d wait | Unblocked 2026-05-16 (3 pieces live) |
| 4 | askbigchew strategy brainstorm | 1-2hrs ce-brainstorm | Strategic, not blocking |
| 5 | Piece #4 on mywildlifecam | 25-30min | Optional momentum |
| 6 | Starwatch Phase 12 (s01e01) | 2-3hrs | Own session |
| 7 | askbigchew DNS migration | 20-30min | Standalone |
| 8 | R2 + PA-API | 30s + later | Imagery |

**Suggested order:** #1 first (closes the silent-deploy gap; needed before any future piece reliably ships). #2 is time-sensitive. #3 is now-or-never (the Associates application can be filed any time but waiting longer leaves money on the table). #4 settles a real strategic fork.

---

## Where to find me again

- This file (`docs/RAY_QUEUE.md`) — start here when you forget what's next
- `docs/PROJECT_STATE.md` — running history of what's been done (most recent on top)
- `docs/sessions/Session_*.md` — narrative context from a specific day
- `docs/voice-doctrine.md` — the live source of truth for content tone
- `docs/cf-pages-github-setup.md` — CF Pages auto-deploy walkthrough (top-of-queue task)
- `docs/brainstorms/2026-05-15-content-framework-requirements.md` — the locked content strategy
- `docs/plans/2026-05-16-001-feat-comparison-fit-content-framework-mvp-plan.md` — architectural decisions from the MVP build
- `docs/launch-playbook.html` — brand-launch click-by-click (Starwatch + Semper Fi handles)
- `docs/PLAYBOOK.md` — operational cadence (90-day cycles, refresh sweeps, KV ops); per-piece content rules stale post-2026-05-15 framework
- `scripts/deploy.ps1` — manual CF Pages deploy (one command per site; needed until task #1 lands)
- `scripts/lint-voice.ps1` — pre-commit voice-doctrine backstop
- `scripts/new-review.ps1` / `scripts/buyers-guide.ps1` — content scaffolders

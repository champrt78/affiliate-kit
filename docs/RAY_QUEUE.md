# Ray's queue

> Your open tasks across both repos. This is an index — the actual walkthroughs live in the linked docs. Read this when you sit down and forget where you left off.

Last refreshed: **2026-05-16 (evening)** — comparison-and-fit framework MVP shipped + piece #1 LIVE on mywildlifecam. Piece #2 is the new top item.

---

## 1. Scaffold piece #2 on mywildlifecam

**What:** Piece #1 ("Best Trail Cameras for Backyard Wildlife") shipped 2026-05-16 evening. The framework is proven end-to-end on real content. Piece #2 builds toward the 2-3-pieces-live threshold needed before applying for Amazon Associates (task #4). It also exercises the framework against a new product or topic to surface any edge cases the first piece didn't hit.

**Topic candidates for piece #2:**
- A single-product review (different shape from piece #1's buying-guide). Real example: a deep review of the Stealth Cam DS4K Ultimate (the piece #1 image-quality pick) — "review" piece type tests the other half of the framework.
- A buying-guide for a tighter use case: "Best Trail Cameras Under $100" or "Best Trail Cameras for Apartment Balconies" (urban wildlife angle).
- A topic-led piece: "What Trail Cam Photos Reveal About Your Backyard" (informational, drives traffic, can link to piece #1).

**Walk through:**

```pwsh
# Single-product piece
pwsh scripts/new-review.ps1 -Site mywildlifecam -Slug <slug> -ProductName "..." -Brand "..." -AmazonUrl "https://amzn.to/..."

# Buyer's guide piece
pwsh scripts/buyers-guide.ps1 -Site mywildlifecam -Slug <slug> -ProductName "..." -Brand "..." -AmazonUrl "https://amzn.to/..."
```

Then: paste `<slug>.prompt.md` into Claude, AI drafts body, you spec-verify (REQUIRED — piece #1's review caught a fictional "Wosports H7" before publish), you write the Bottom Line, lint, build, push.

**Effort:** ~60-90 min now that you've shipped one. Spec-verification eats 15-20 min; Bottom Line 5-10 min; rest is mechanical.

**Blocks:** Amazon Associates app (#4) needs 2-3 pieces live. Cellular R2 image hosting (#7) would be nicer-to-have than required.

**Reference docs:** Same as before. `docs/voice-doctrine.md` is the live source of truth; lint backstop catches forbidden phrases including em dashes. `sites/mywildlifecam/src/data/site-config.json` has the reader segments.

---

## 1a. (DONE 2026-05-16) Piece #1 — "Best Trail Cameras for Backyard Wildlife"

Live at `mywildlifecam.com/buyers-guides/best-trail-cameras-for-backyard-wildlife`. 3 picks (Spypoint Flex-M, Stealth Cam DS4K Ultimate, Wosports H-41). Validates the comparison-and-fit framework end-to-end. Lessons learned (em dashes banned, defensive exclusions banned) folded into voice doctrine.

---

## 2. Claim Starwatch handles + register `starwatchstation.space`

**What:** Snag the 7 Tier 1 social handles (`@StarwatchStation` on YouTube, Bluesky, IG, TikTok, LinkedIn, Facebook; `@StarwatchSpace` on X because of the 15-char cap) and buy the domain at Porkbun. Same playbook you ran for Semper Fi.

**Walk through:** `docs/launch-playbook.html` — open in browser. The Starwatch sections are current (`.space` domain, X-cap explained, DST fandom-contraction blurb in place).

**Effort:** ~30-60 minutes if no handles are taken; longer if you fall back per-platform.

**Blocks:** Nothing in code depends on this. **But the rename window closes the moment someone notices "Starwatch Station" is unclaimed.** Time-sensitive.

---

## 3. Brainstorm askbigchew integration strategy (`ce-brainstorm`)

**What:** Surfaced 2026-05-16 mid-MVP — askbigchew is the one affiliate site where you actually own the products (you have a bulldog). The new voice doctrine assumes no hands-on. Open questions:

1. Migrate askbigchew from its Next.js+MDX repo into this Astro monorepo as site #6 proper? Or keep it separate?
2. Does askbigchew get a voice-doctrine variant that allows hands-on claims since you actually own the products?
3. Hero/satellite reshuffle — is bulldog the new hero now that you have actual experience?
4. Universal anatomy holds, or askbigchew gets its own variant?

**Walk through:** Run `ce-brainstorm` in this repo. Reference `CLAUDE.md` (askbigchew section), the current migration walkthrough at `docs/askbigchew-cloudflare-migration.html`, and the content framework at `docs/brainstorms/2026-05-15-content-framework-requirements.md`.

**Effort:** 1-2 hr brainstorm + decision. Could be slotted in alongside piece #1 work or as its own session.

**Blocks:** Nothing — askbigchew is operating fine on its current (separate) repo + stack. This is a strategic question, not an outage.

---

## 4. Apply for Amazon Associates under `mywildlifecam.com` (DEFERRED)

**What:** Submit the Amazon Associates application using `mywildlifecam.com` as the apex, with all 6 site URLs listed under one account.

**DEFERRED per 2026-05-15 brainstorm Key Decision.** The 180-day-3-sales clock starts at approval; applying with zero published pieces burns the clock. Apply AFTER 2-3 pieces are live on mywildlifecam.

**Walk through:** Application at `https://affiliate-program.amazon.com/`. Primary Store ID at signup = `mywildlifecam` (becomes `mywildlifecam-20`); after approval create per-site tracking tags in the Associates dashboard.

**Effort:** 10 minutes to apply. 1-3 days to approve.

**Blocks:** Required before pieces #3+ earn revenue at scale. Pieces #1-2 will ship without working Amazon affiliate tags; links cloak fine via the Worker but zero commission until tags are added retroactively.

---

## 5. Phase 12 on Starwatch — interactive s01e01 round-trip

**What:** Validate the renamed plugin end-to-end by writing the first episode interactively. Tests the full `/show-arc-bootstrap` → `/show-arc-plan-season` → `/show-new-episode` → `/show-episode-edits` → `/show-episode-finalize` chain. After s01e01 finalizes cleanly, merge `phase-1-implementation` → `main` and Arc A is officially done.

**Walk through:**
- Start at `~/source/repos/starwatch-station/`
- Run `pwsh scripts/install-plugin.ps1` if the renamed plugin hasn't been reinstalled
- Open Claude Code in that directory, type `/show-help`, follow the `Next:` block

**Effort:** ~2-3 hours for a real episode.

**Blocks:** This is the gate before merging `phase-1-implementation` → `main` on the Starwatch repo.

---

## 6. Migrate askbigchew DNS to Cloudflare

**What:** Bring askbigchew under the same Cloudflare umbrella as the other 5 sites (CF Pages + shared link-cloaker Worker). Independent of the askbigchew strategic question (#3) — DNS migration can land regardless of whether askbigchew eventually migrates into this monorepo or stays separate.

**Walk through:** `docs/askbigchew-cloudflare-migration.html` — open in browser, follow the click-by-click.

**Effort:** ~20-30 minutes.

**Blocks:** Nothing.

---

## 7. Enable Cloudflare R2 + apply for Amazon PA-API

**What:** Two-step toward product images. (a) Enable R2 in the CF dashboard for hero image hosting. (b) Apply for PA-API (gated on 3 qualifying Associates sales in 180 days).

**Walk through:** R2 is a 30-second dashboard toggle at `dash.cloudflare.com → R2`. PA-API enrollment is at the Amazon Associates console post-3-sales.

**Effort:** 30 seconds (R2) + 10 minutes (PA-API when eligible).

**Workaround until PA-API:** Per `docs/brainstorms/2026-05-15-content-framework-requirements.md` R13, paste Amazon listing image URLs directly into review frontmatter. Not bulletproof (Amazon can rotate URLs) but unblocks the first few pieces.

---

## Quick-glance cheat sheet

| # | Task | Effort | Blocks |
|---|---|---|---|
| 1 | **Scaffold piece #2 on mywildlifecam** | 60-90 min | Amazon Associates threshold (need 2-3 live). **Top of queue.** |
| 2 | Starwatch handles + `.space` | 30-60min | Brand cohesion; window closes when someone notices |
| 3 | askbigchew strategy brainstorm | 1-2hrs ce-brainstorm | Piece #1 on askbigchew (not piece #1 on mywildlifecam) |
| 4 | Amazon Associates app (deferred) | 10min + 1-3d wait | Pieces #3+ revenue; gated on 2-3 pieces live |
| 5 | Starwatch Phase 12 (s01e01) | 2-3hrs | Starwatch Arc A → main merge |
| 6 | askbigchew DNS migration | 20-30min | Brings askbigchew under CF umbrella |
| 7 | R2 + PA-API | 30s + later | Piece imagery (workaround = Amazon hotlinks) |

**Suggested order:** #1 keeps the content cycle alive (piece #2 → #3 → trigger Amazon Associates app). #2 is time-sensitive. #3 slots alongside any session. #4 unlocks after #1 hits 2-3 pieces. #5 is its own session.

---

## Where to find me again

- This file (`docs/RAY_QUEUE.md`) — start here when you forget what's next
- `docs/PROJECT_STATE.md` — running history of what's been done (most recent on top)
- `docs/sessions/Session_*.md` — narrative context from a specific day
- `docs/voice-doctrine.md` — the live source of truth for content tone (read this before drafting)
- `docs/brainstorms/2026-05-15-content-framework-requirements.md` — the locked content strategy
- `docs/plans/2026-05-16-001-feat-comparison-fit-content-framework-mvp-plan.md` — architectural decisions from the MVP build
- `docs/launch-playbook.html` — brand-launch click-by-click (Starwatch + Semper Fi handles)
- `docs/PLAYBOOK.md` — operational cadence (90-day cycles, refresh sweeps, KV ops); per-piece content rules stale post-2026-05-15 framework

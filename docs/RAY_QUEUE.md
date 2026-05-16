# Ray's queue

> Your open tasks across both repos. This is an index — the actual walkthroughs live in the linked docs. Read this when you sit down and forget where you left off.

Last refreshed: **2026-05-16** — comparison-and-fit content framework MVP shipped tonight; piece #1 is now the active build.

---

## 1. Scaffold piece #1 on mywildlifecam under the new framework

**What:** The MVP shipped tonight (2026-05-16). 9 implementation units, all committed to main + pushed. The full pipeline is live: voice doctrine v1 + per-site config + scaffolders that emit a sibling `.prompt.md` artifact + a `lint-voice.ps1` back-stop. Now you actually use it to write piece #1.

**Walk through:**

```pwsh
# 1. Pick a product. Target reader: homeowners / property owners / first-time buyers / gift buyers. NOT hunters.
# Example: Spypoint Flex-M (cellular trail cam) or Stealth Cam DS4K (SD-card trail cam under $150).

# 2. Scaffold
pwsh scripts/new-review.ps1 -Site mywildlifecam -Slug <product-slug> -ProductName "..." -Brand "..." -AmazonUrl "https://amzn.to/..."

# This produces TWO files:
#   sites/mywildlifecam/src/content/reviews/<slug>.md          ← the scaffold
#   sites/mywildlifecam/src/content/reviews/<slug>.prompt.md   ← the AI prompt (sibling)

# 3. Open the .prompt.md file, copy its contents, paste into Claude (or your AI of choice).
#    Ask Claude to draft the body sections (everything except ## Bottom Line).

# 4. Review the AI draft against docs/voice-doctrine.md. Edit anything that drifts.

# 5. Write your ## Bottom Line section in your own voice.
#    The placeholder "> _The Bottom Line is being written._" must be replaced or the page renders DRAFT + noindex.

# 6. Back-stop check before commit
pwsh scripts/lint-voice.ps1 sites/mywildlifecam/src/content/reviews/<slug>.md

# 7. Preview locally
pnpm --filter mywildlifecam dev

# 8. Commit + push when ready
git add sites/mywildlifecam/src/content/reviews/<slug>.md
git commit -m "feat(content): mywildlifecam — <slug>"
git push
```

**Effort:** 2-3 hours for the first piece (you're learning the prompt template, the AI dance, the voice doctrine in practice). Subsequent pieces should hit the 60-75 min target.

**Blocks:** Nothing for piece #1. Amazon Associates application (task #4) waits on 2-3 pieces being live first.

**Reference docs:**
- `docs/voice-doctrine.md` — forbidden phrases + preferred framings + direct-question responses
- `docs/brainstorms/2026-05-15-content-framework-requirements.md` — the locked strategy
- `docs/plans/2026-05-16-001-feat-comparison-fit-content-framework-mvp-plan.md` — what's in place
- `sites/mywildlifecam/src/data/site-config.json` — your reader-segment + niche metadata

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
| 1 | **Scaffold piece #1 on mywildlifecam** | 2-3hrs first piece; 60-75 min after | Amazon Associates app + R2 + the whole content cycle. **Top of queue.** |
| 2 | Starwatch handles + `.space` | 30-60min | Brand cohesion; window closes when someone notices |
| 3 | askbigchew strategy brainstorm | 1-2hrs ce-brainstorm | Piece #1 on askbigchew (not piece #1 on mywildlifecam) |
| 4 | Amazon Associates app (deferred) | 10min + 1-3d wait | Pieces #3+ revenue; gated on 2-3 pieces live |
| 5 | Starwatch Phase 12 (s01e01) | 2-3hrs | Starwatch Arc A → main merge |
| 6 | askbigchew DNS migration | 20-30min | Brings askbigchew under CF umbrella |
| 7 | R2 + PA-API | 30s + later | Piece imagery (workaround = Amazon hotlinks) |

**Suggested order:** #1 is the active build (the whole point of last few sessions). #2 is time-sensitive (handles window). #3 can slot in alongside #1 work. #4 is gated by #1 progressing. #5 is its own session.

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

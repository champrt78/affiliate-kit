# Ray's queue

> Your open tasks across both repos. This is an index — the actual walkthroughs live in the linked docs. Read this when you sit down and forget where you left off.

Last refreshed: **2026-05-15**

---

## 1. Address 3 quick-fix findings from ce-doc-review, then ce-plan the content framework

**What:** The 2026-05-15 brainstorm pivoted the content strategy to comparison-and-fit (never claim hands-on). Requirements doc at `docs/brainstorms/2026-05-15-content-framework-requirements.md`. Autonomous `ce-doc-review` run surfaced 26 findings — 3 have one obvious fix and should land before re-planning:

1. R9/R14 product-database contradiction — add MVP carve-out to R9
2. DRAFT_MARKER sync — add note to R14 listing the 7-file sync (template + 5 forked sites)
3. Buyer's-guide template hands-on disclaimer — note in R14 that MVP deletes the existing `templates/buyers-guide.md.tmpl` lines

Then either re-run `ce-doc-review` (Round 2) or jump to `ce-plan` and let it address remaining findings at unit level. Then `ce-work` to execute the MVP minimum-change set (~3-6 hr of Claude work + your review).

**Walk through:** `docs/sessions/Session_2026-05-15.md` has the full breakdown of all 26 findings organized by severity.

**Effort:** 15-30 min to apply quick-fixes; 1-2 hr for ce-plan; 3-6 hr for ce-work MVP execution.

**Blocks:** Everything downstream — piece #1 cannot ship under the new framework until the MVP units land.

---

## 2. Claim Starwatch handles + register `starwatchstation.space`

**What:** Snag the 7 Tier 1 social handles (`@StarwatchStation` on YouTube, Bluesky, IG, TikTok, LinkedIn, Facebook; `@StarwatchSpace` on X because the 15-char cap breaks the 16-char full name — `@StarwatchSpace` at 14 fits and echoes the `.space` domain) and buy the domain at Porkbun.

**Walk through:** `docs/launch-playbook.html` — open in browser. The Starwatch sections are rewritten and current (`.space` domain noted, X-cap explained inline, DST fandom-contraction blurb in place). Same click-by-click style you used for Semper Fi last night.

**Effort:** ~30-60 minutes if no handles are taken; longer if you have to fall back per-platform (Step 2b in the playbook covers reclamation paths).

**Blocks:** Nothing depends on this for code, but **the rename window closes the moment someone notices "Starwatch Station" is unclaimed.** Do this first.

---

## 3. Apply for Amazon Associates under `mywildlifecam.com` (DEFERRED)

**What:** Submit the Amazon Associates application using `mywildlifecam.com` as the apex, with all 6 site URLs listed under one account.

**DEFERRED per 2026-05-15 brainstorm Key Decision.** The 180-day-3-sales clock starts at approval; applying with zero published pieces burns the clock before any conversion content exists. Apply AFTER 2-3 pieces are live on mywildlifecam.

**Walk through:** Application at `https://affiliate-program.amazon.com/`. Primary Store ID at signup = `mywildlifecam` (becomes `mywildlifecam-20`); after approval create per-site tracking tags in the Associates dashboard (`detailerpicks-20`, `fussybean-20`, etc.).

**Effort:** 10 minutes to apply. 1-3 days to approve. Zero code on your side.

**Blocks:** Required before pieces #3+ can earn revenue at scale. Pieces #1-2 will ship without working Amazon affiliate tags — links cloak fine via the Worker, just zero commission until tag is added retroactively.

**Note:** Sequence is intentional: ship pieces 1-2 under the new framework FIRST (proves the strategy + gives Amazon something to evaluate at approval), THEN apply, THEN backfill tags.

---

## 4. Phase 12 on Starwatch — interactive s01e01 round-trip

**What:** Validate the renamed plugin end-to-end by writing the first episode interactively. Tests the full `/show-arc-bootstrap` → `/show-arc-plan-season` → `/show-new-episode` → `/show-episode-edits` → `/show-episode-finalize` chain. After s01e01 finalizes cleanly, merge `phase-1-implementation` → `main` and Arc A is officially done.

**Walk through:**
- Start at `~/source/repos/starwatch-station/`
- Run `pwsh scripts/install-plugin.ps1` if you haven't reinstalled the renamed plugin (creates `~/.claude/plugins/starwatch-station/`)
- Open Claude Code in that directory, type `/show-help`, follow the `Next:` block
- Detailed expected flow: `starwatch-station/docs/sessions/Session_2026-05-13.md` → "Next Steps (when Ray returns to this)" — gives the exact command sequence including all flags

**Effort:** ~2-3 hours for a real episode (depends how much polish you want before finalizing). Pre-flight `pwsh scripts/lint.ps1` once after bootstrap before drafting — catches schema drift cheaply.

**Blocks:** This is the gate before merging `phase-1-implementation` → `main` on the Starwatch repo. The branch has 19+ commits, never been merged, ready when you are.

---

## 5. Enable Cloudflare R2 + apply for Amazon PA-API

**What:** Two-step toward product images. (a) Enable R2 in the CF dashboard so we have a bucket to host hero images. (b) Apply for Amazon PA-API (gated on 3 qualifying Associates sales in 180 days — chicken-and-egg with task #2).

**Walk through:** Not built yet, no dedicated doc. R2 is a dashboard toggle at `dash.cloudflare.com → R2`. PA-API enrollment is at the Amazon Associates console post-3-sales.

**Effort:** R2 enable = 30 seconds. PA-API enrollment when eligible = 10 minutes.

**Blocks:** Review #1 image hosting. **Workaround until then:** paste Amazon image URLs directly into review frontmatter (`images.hero: "https://m.media-amazon.com/..."`). Not bulletproof (Amazon can rotate URLs) but unblocks the first few reviews.

---

## Quick-glance cheat sheet

| # | Task | Effort | Blocks |
|---|---|---|---|
| 1 | Content framework: fixes → plan → MVP | 4-8hrs across sessions | Piece #1 cannot ship under new strategy until MVP lands |
| 2 | Starwatch handles + `.space` | 30-60min | Brand cohesion; window closes when someone notices |
| 3 | Amazon Associates app (deferred) | 10min + 1-3d wait | Pieces #3+ revenue; explicitly waits for 2-3 pieces published first |
| 4 | Starwatch Phase 12 (s01e01) | 2-3hrs | Starwatch Arc A → main merge |
| 5 | R2 + PA-API | 30s + later | Piece imagery (workaround = Amazon hotlinks per MVP) |

**Suggested order:** #1 is the active build (most of next session). #2 stays time-sensitive (handle window). #3 is gated by #1 progressing to "pieces 1-2 live." #4 is its own session. #5a (R2 toggle) is a 30-second standalone.

---

## Where to find me again

- Open this file (`docs/RAY_QUEUE.md`) when you forget what's next.
- `docs/PROJECT_STATE.md` is the running history of what's been done.
- `docs/sessions/Session_*.md` for narrative context from a specific day.
- `docs/PLAYBOOK.md` is your per-review workflow once you're actually writing.
- `docs/launch-playbook.html` is the brand-launch click-by-click for handle claims.

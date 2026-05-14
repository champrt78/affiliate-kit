# Ray's queue

> Your open tasks across both repos. This is an index — the actual walkthroughs live in the linked docs. Read this when you sit down and forget where you left off.

Last refreshed: **2026-05-14**

---

## 1. Claim Starwatch handles + register `starwatchstation.space`

**What:** Snag the 7 Tier 1 social handles (`@StarwatchStation` on YouTube, Bluesky, IG, TikTok, LinkedIn, Facebook; `@StarwatchSpace` on X because the 15-char cap breaks the 16-char full name — `@StarwatchSpace` at 14 fits and echoes the `.space` domain) and buy the domain at Porkbun.

**Walk through:** `docs/launch-playbook.html` — open in browser. The Starwatch sections are rewritten and current (`.space` domain noted, X-cap explained inline, DST fandom-contraction blurb in place). Same click-by-click style you used for Semper Fi last night.

**Effort:** ~30-60 minutes if no handles are taken; longer if you have to fall back per-platform (Step 2b in the playbook covers reclamation paths).

**Blocks:** Nothing depends on this for code, but **the rename window closes the moment someone notices "Starwatch Station" is unclaimed.** Do this first.

---

## 2. Apply for Amazon Associates under `mywildlifecam.com`

**What:** Submit the Amazon Associates application using `mywildlifecam.com` as the apex. The site is HTTP 200, has Disclosure + Privacy + About pages — qualifies. Apply, wait 1-3 days for approval, then plug the tracking tag into `scripts/add-link.ps1` calls.

**Walk through:** No dedicated doc. Briefly mentioned in `docs/PLAYBOOK.md` under "Before review #1." The application itself is at `https://affiliate-program.amazon.com/`.

**Effort:** 10 minutes to apply. 1-3 days to approve. Zero code on your side.

**Blocks:** Required before review #1 can earn revenue. Every Amazon link you ship without a tracking tag = unattributable click. Do this in parallel with handles tonight.

**Note:** No tracking tag yet means `scripts/add-link.ps1 -Tag <yourtag>` will warn. The script still works without a tag (link cloaks, just no commission). Add the tag retroactively to existing KV entries once approved.

---

## 3. Phase 12 on Starwatch — interactive s01e01 round-trip

**What:** Validate the renamed plugin end-to-end by writing the first episode interactively. Tests the full `/show-arc-bootstrap` → `/show-arc-plan-season` → `/show-new-episode` → `/show-episode-edits` → `/show-episode-finalize` chain. After s01e01 finalizes cleanly, merge `phase-1-implementation` → `main` and Arc A is officially done.

**Walk through:**
- Start at `~/source/repos/starwatch-station/`
- Run `pwsh scripts/install-plugin.ps1` if you haven't reinstalled the renamed plugin (creates `~/.claude/plugins/starwatch-station/`)
- Open Claude Code in that directory, type `/show-help`, follow the `Next:` block
- Detailed expected flow: `starwatch-station/docs/sessions/Session_2026-05-13.md` → "Next Steps (when Ray returns to this)" — gives the exact command sequence including all flags

**Effort:** ~2-3 hours for a real episode (depends how much polish you want before finalizing). Pre-flight `pwsh scripts/lint.ps1` once after bootstrap before drafting — catches schema drift cheaply.

**Blocks:** This is the gate before merging `phase-1-implementation` → `main` on the Starwatch repo. The branch has 19+ commits, never been merged, ready when you are.

---

## 4. Enable Cloudflare R2 + apply for Amazon PA-API

**What:** Two-step toward product images. (a) Enable R2 in the CF dashboard so we have a bucket to host hero images. (b) Apply for Amazon PA-API (gated on 3 qualifying Associates sales in 180 days — chicken-and-egg with task #2).

**Walk through:** Not built yet, no dedicated doc. R2 is a dashboard toggle at `dash.cloudflare.com → R2`. PA-API enrollment is at the Amazon Associates console post-3-sales.

**Effort:** R2 enable = 30 seconds. PA-API enrollment when eligible = 10 minutes.

**Blocks:** Review #1 image hosting. **Workaround until then:** paste Amazon image URLs directly into review frontmatter (`images.hero: "https://m.media-amazon.com/..."`). Not bulletproof (Amazon can rotate URLs) but unblocks the first few reviews.

---

## Quick-glance cheat sheet

| # | Task | Effort | Blocks |
|---|---|---|---|
| 1 | Starwatch handles + `.space` | 30-60min | Brand cohesion; window closes when someone notices |
| 2 | Amazon Associates app | 10min + 1-3d wait | Review #1 revenue |
| 3 | Starwatch Phase 12 (s01e01) | 2-3hrs | Starwatch Arc A → main merge |
| 4 | R2 + PA-API | 30s + later | Review #1 hero images (workaround exists) |

**Suggested order tonight:** #1 (immediate, time-sensitive), #2 (fire-and-forget while #1 runs), #4a (R2 dashboard toggle — 30 seconds). #3 is its own session — fun, not urgent.

---

## Where to find me again

- Open this file (`docs/RAY_QUEUE.md`) when you forget what's next.
- `docs/PROJECT_STATE.md` is the running history of what's been done.
- `docs/sessions/Session_*.md` for narrative context from a specific day.
- `docs/PLAYBOOK.md` is your per-review workflow once you're actually writing.
- `docs/launch-playbook.html` is the brand-launch click-by-click for handle claims.

---
description: Internal — topic discovery layer that `/aff` reads inline when posture is `hero-behind-cadence`, `dp-behind-cadence`, or `ready-for-next-topic`. Surfaces candidate topics across the portfolio (three modes: portfolio-wide / site-scoped / category-seed). Ray uses `/aff` as the entry point — this file is invocable directly only for debugging.
---

You are being invoked to surface candidate topics. Two entry contexts:

**Direct slash invocation** (`/scout-topics [--site <slug>] [--<seed>]`): Ray typed the command with optional flags. Parse the flags per the decision tree below.

**Read inline by `/aff`**: `/aff` has already determined the scope from its source posture during Step 6.D. Skip flag parsing — use the scope passed in conversation context:
- `hero-behind-cadence` posture → scope is Mode B mwc (treat as if `--mwc` was passed)
- `dp-behind-cadence` posture → scope is Mode B dp (treat as if `--dp` was passed)
- `ready-for-next-topic` posture → scope is Mode A portfolio-wide (no flags)
- Mode C (`--<category-seed>`) is reachable only via direct slash invocation today; `/aff` does not route to it. If Ray wants a category deep-dive, he types `/scout-topics --wheel-cleaning` directly.

## Three modes

**Quick decision tree (for direct slash invocation only):**
- `--site <slug>` alone (or shorthand `--mwc`, `--dp`, `--fb`, `--sa`, `--gog`) → **Mode B (site focus)**
- `--<category-seed>` alone (e.g. `--wheel-cleaning`) → **Mode C (category deep-dive)** — routes to whichever site matches the keyword
- `--site <slug> --<category-seed>` together → **Mode C scoped to that site**
- No flags → **Mode A (portfolio-wide)**

Shorthand site aliases:
- `--mwc` = `--site mywildlifecam`
- `--dp` = `--site detailerpicks`
- `--fb` = `--site fussybean`
- `--sa` = `--site starteraquarium`
- `--gog` = `--site gameovergear`

### Mode A — No seed flag

Ray says `/scout-topics` (no args). Surface 5-10 candidate topics across the portfolio. Sources of signal:

1. **Existing content gaps.** Read `sites/<slug>/src/content/reviews/` and `sites/<slug>/src/content/buyers-guides/` across the 5 sites. Identify category pillars from each site's `src/data/site-config.json` `categoryPillars` field that have ZERO or ONE piece. Those are gaps.
2. **`docs/TODO.md`** — pull the explicit "next piece" notes already queued. These are not yet "to-write" — they're "to-research-then-write." Surface them as already-warm candidates.
3. **`docs/research/`** — pieces already researched but not yet scaffolded. Highest-readiness candidates.
4. **`docs/PROJECT_STATE.md`** — recent wins indicate the pace + the most-recently-shipped niche. The next piece should diversify from the most-recent unless we're in a deliberate streak.
5. **Hero vs satellite cadence rule.** Per `docs/PLAYBOOK.md`: hero (`mywildlifecam`) gets ~1 piece per week, satellites get ~1 per 2-3 weeks. Weight proposals accordingly — if hero hasn't shipped this week, hero candidates come first.
6. **Optional: a quick `/last30days` scan** for "best <category> 2026" against the top 1-2 categories with content gaps. Skip this if it'd take more than 2 minutes — keep the scout fast.

Output format:

```
## Topic candidates — <date>

### High-readiness (research notes exist)
1. **<topic>** — site: <slug>, type: <review|guide>, research at `docs/research/<file>.md`. <One-line angle.>

### Medium-readiness (category gap, no research yet)
2. **<topic>** — site: <slug>, type: <review|guide>. <Why this category, what's missing.>

### Speculative (community signal, needs validation)
3. **<topic>** — site: <slug>, type: <review|guide>. <Where the signal came from.>
```

End with a `Next:` line recommending ONE: `Next: /research-product "<top pick>" — then /scaffold-piece + Bottom Line.`

### Mode B — Site focus (`--site <slug>` or shorthand `--mwc` / `--dp` / etc.)

Ray says `/scout-topics --site mywildlifecam` or `/scout-topics --mwc`. Scope the scout to ONE site. NO web research needed — pull entirely from local data because the site's content + research notes already exist.

Steps:

1. **Survey the site.** List shipped pieces in `sites/<slug>/src/content/{reviews,buyers-guides}/` with their slugs + types.

2. **Pull site config.** Read `sites/<slug>/src/data/site-config.json` to see `categoryPillars` + reader segments. Categories with ZERO or ONE piece shipped are gaps.

3. **Pull research notes for this site.** Walk `docs/research/` and filter to files whose names or content match the site's keywords (use the keyword map: mywildlifecam = trail-cam, cellular, tactacam, spypoint, moultrie, stealth cam, bushnell, muddy, browning; detailerpicks = detail, wash, foam, soap, ceramic, polish, wheel, wax, sealant, mitt, shampoo; etc.). Surface every piece-shaped subsection in those notes as a candidate.

4. **Cross-reference shipped vs research-ready.** A candidate is "high readiness" if research exists AND it hasn't been shipped yet.

5. **Apply cadence pressure.** Use the site's cadence target (mywildlifecam = 7d, detailerpicks = 18d, others = 180d). If days-since-last-shipped exceeds the target, mark this scout as "behind cadence — pick one now."

Output format:

```
## Scout: <site> · <X> live · last shipped <N>d ago

### Already shipped on this site (skip these)
- <slug> (<review|guide>)
- ...

### HIGH readiness (research exists, not yet shipped)
1. **<piece title>** — type: review|guide. Why this is loaded: <1-line citing the research>. Picks/products if known: <list>.
2. ...

### MEDIUM readiness (category gap, no research yet)
- **<piece title>** — type: <review|guide>. Why this category matters: <site-config rationale>.

### SPECULATIVE (needs /research-product first)
- <topic>

### Recommended next
**<title>** — type: <review|guide>. <Why this one over the others — keyword volume / cross-link potential / cadence pressure.>

Run: `/scaffold-piece site=<slug> type=<review|guide> slug=<slug> ...` to ship it as DRAFT.
```

End with the literal `/scaffold-piece ...` command pre-filled with the recommended pick's args so Ray can run it.

### Mode C — Category seed (`--<seed>` without `--site`)

Ray says `/scout-topics --wheel-cleaning` or `/scout-topics --cellular-trail-cam` or similar. The seed is the category/topic to dig into.

Steps:
1. **Identify the target site** by mapping the seed to niche:
   - Trail-cam, wildlife-cam, cellular-trail-cam → `mywildlifecam`
   - Wash-soap, foam-cannon, wheel-cleaning, ceramic-coating, polish, drying-towel, wash-mitt → `detailerpicks`
   - Coffee, espresso, grinder, pour-over, decaf, milk-frother → `fussybean`
   - Aquarium, fish-tank, filter, heater, planted-tank → `starteraquarium`
   - Retro-gaming, arcade-stick, CRT, controller, emulator → `gameovergear`
   - Unclear → ask Ray which site

2. **Fire 2-3 quick parallel research jobs** for the seed (Bash `run_in_background: true`):
   - **Firecrawl search** for "best <seed> 2026" — finds the comparison content currently ranking
   - **`/last30days`** on "<seed> 2026" — gets community signal across Reddit/X/YouTube
   - **Optional Canopy lookup** if the seed is a specific product (skip for category-level seeds)

3. **While they run, scan the codebase** for any existing pieces touching the seed:
   - `git grep -l "<seed>"` in `sites/<slug>/src/content/` to find existing references
   - Read site config to check if seed is in `categoryPillars`

4. **When research returns, synthesize 3-5 candidate angles:**
   - **Single-product review** candidates (specific named products with strong owner reports)
   - **Buying-guide** candidates (3-5 products mapped to distinct reader segments)
   - **Cross-link opportunities** (does an existing piece on the site need a sister piece on this seed?)

Output format:

```
## Scout: <seed> (site: <slug>)

### Existing coverage
<file paths if any, "none" if not>

### Community signal (last30days)
<3-5 highest-signal threads/comments with attribution>

### Currently-ranking comparison content (Firecrawl)
<top 3-5 ranking URLs with one-line angle each>

### Candidate pieces (3-5 ranked)
1. **<piece title>** — type: review|guide. <Why this angle. What products. What reader segment.>
2. ...

### Recommended next step
Pick one: `/research-product "<title>"` to do the full multi-source deep-dive, then `/scaffold-piece`.
```

## Constraints

- Use Bash for shell calls; run jobs in parallel via `run_in_background: true` to keep total time under 5 minutes for mode B.
- DO NOT scaffold or commit anything. This is discovery only.
- DO NOT do a full `/research-product` synthesis (that's the next-step command for the candidate Ray picks).
- Voice doctrine applies to any output text that might end up in eventual content — no em dashes, no hands-on claims, attribute every quote.
- Hero-bias: when in doubt about prioritization, default to `mywildlifecam` candidates unless `docs/TODO.md` or recent commit history shows hero is already over-served this week.

## Example invocations

```
/scout-topics                              # Mode A — portfolio-wide ranking
/scout-topics --mwc                        # Mode B — scope to mywildlifecam (shorthand)
/scout-topics --site mywildlifecam         # Mode B — same as --mwc, explicit
/scout-topics --dp                         # Mode B — scope to detailerpicks
/scout-topics --wheel-cleaning             # Mode C — category deep-dive (routes to detailerpicks)
/scout-topics --cellular-trail-cam         # Mode C — category deep-dive (routes to mywildlifecam)
/scout-topics --mwc --browning-strike-force # Mode B+C — site + category
```

## When NOT to use this

- When Ray already knows the topic — go straight to `/research-product`
- When Ray is mid-piece and asking about a related sub-topic — answer inline, don't scout
- When the seed is a SPECIFIC product (e.g. `--browning-strike-force`) — that's `/research-product` territory, not scouting

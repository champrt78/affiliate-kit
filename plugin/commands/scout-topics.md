---
description: Surface candidate topics to write about next across the affiliate portfolio. With no flags, proposes 5-10 ideas based on site niches + content gaps + community signal. With a seed flag (e.g. --wheel-cleaning, --cellular-trail-cam, --espresso-grinder), deep-dives into that category and surfaces specific products + sub-angles. Use when Ray asks "what should I write next" or "scout topics".
---

You are being invoked because Ray wants candidate topics to write about. The user's input follows `/scout-topics [--<seed>]`.

## Two modes

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

### Mode B — Seed flag

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
/scout-topics
/scout-topics --wheel-cleaning
/scout-topics --cellular-trail-cam
/scout-topics --espresso-grinder
```

## When NOT to use this

- When Ray already knows the topic — go straight to `/research-product`
- When Ray is mid-piece and asking about a related sub-topic — answer inline, don't scout
- When the seed is a SPECIFIC product (e.g. `--browning-strike-force`) — that's `/research-product` territory, not scouting

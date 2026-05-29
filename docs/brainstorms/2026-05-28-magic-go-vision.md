# Steal-from-Aaron + `/aff` Autonomy Plan

**Date:** 2026-05-28
**Author:** Ray (via Claude, work PC session)
**Status:** Draft — picked up at home PC, resume from here
**Source conversation:** Email thread with Aaron Champion (10:50 AM – 1:50 PM, 2026-05-28) + analysis of his shipped site `home-sauna-hq.com` + comparison to current `affiliate-kit` repo state.

---

## Why this doc exists

Ray's friend Aaron is running a parallel affiliate-site operation with different tooling (Kimi.com for one site, `ruflo` in Claude Code for 5 others, mission-control dashboard at https://affiliate-dashboard-69h.pages.dev/). Aaron's stated strategy is volume (target: 500–1k pages/site, multi-network link auto-routing, fully hands-off VPS automation). His actually-shipped site `home-sauna-hq.com` is 10 articles + 4 utility pages — same order of magnitude as Ray's sites. So the steal-list is calibrated against what's *real*, not what's *aspirational*.

Goal of this doc:
1. Lock the prioritized backlog of ideas worth stealing.
2. Decide what "build into `/aff` so it runs autonomously" actually means, given the existing Bottom Line gate.
3. Leave Claude enough context to resume cold at the home PC.

---

## The ordered backlog

**Sequence is firm.** Each item ships fully before the next starts. No parallel WIP.

**The end state is Item 5 — Magic Go.** Items 1–4 are the foundations that make the overnight run produce *good* drafts. Item 6 is the post-launch dashboard.

### 1. Multi-network commission routing in `link-cloaker`
**The highest-$ lever on the list.** Today the cloaker routes only to Amazon. Aaron's dashboard auto-swaps to whichever network (Awin/AvantLink/CJ/Rakuten/Amazon) pays the best commission for that product. Even a 10–20% RPM lift on existing DTP/MWC traffic outweighs everything else combined.

**Scope:**
- Extend `workers/link-cloaker` to read a per-product KV entry: `{ asin, brand, sku, links: [{network, url, commission_rate, status}] }`.
- Pick best-paying live link at request time (filter by `status: active`, sort by `commission_rate` desc).
- Fall back to Amazon if no other network has the product.
- Track click-through-by-network in Cloudflare Analytics for later RPM comparison.

**Pairs with:** Item 2 (disclosure swap) — both ship together since decoupling the cloaker from Amazon-only requires generic disclosure copy.

**Open questions to answer before scoping:**
- (a) Which networks is Ray actually approved in *right now* — fully approved + can pull links, vs. still pending? Confirmed in Avant + Awin per email; status of AvantLink, CJ, Rakuten unknown. Doc/sign up before kicking off this work.
- (b) Click-time vs. scaffold-time decision: fetch commission rates live (accurate, more Worker cost) or bake into KV when product is registered (simple, requires manual refresh)? **Recommendation: scaffold-time with a monthly refresh job.** Commission rates change slowly; live-fetching on every click is overkill.
- (c) Per-site or portfolio-wide rollout? **Recommendation: DTP first (most traffic), then MWC, then satellites.** Single Worker, but enable per-site via `site-config.json` flag.

### 2. Generic affiliate disclosure (decouple from Amazon naming)
**Trivial but required for Item 1.** Aaron's footer says "we may earn a small commission at no extra cost to you" — no network named. Lets the cloaker swap networks behind the scenes without rewriting disclosure on every page.

**Scope:** Single edit to `templates/site-template/src/components/Footer.astro` (and per-site copies if they've diverged). Audit `docs/voice-doctrine.md` for any Amazon-specific disclosure language to neutralize.

### 3. Pillar-cluster IA in homepage nav
Aaron's `home-sauna-hq.com` surfaces pillars *as the nav itself* — `outdoor / barrel / infrared / portable / accessories / installation`. Buying guides slot under each pillar. Ray's sites currently nav-flat (`/reviews/`, `/guides/`) which leaves topical-authority on the table.

**Scope:** Per-site nav rework. Each site declares its pillars in `src/data/site-config.json` (`navigation.pillars: [{slug, label, parent_category}]`). Homepage renders pillar cards. Pillar pages list spoke reviews + spoke guides. Inter-link spokes back to pillar.

### 4. Minimalist homepage
Same site reference: one hero photo, text-heavy pillar index, no card-grid overload. Cleaner than current DTP/MWC homes (probably — eyeball at home).

**Scope:** Template-level redesign of `pages/index.astro` in `templates/site-template/`. Sync to all 5 Astro sites. `askbigchew` (Next.js) gets its own pass.

**Pairs with #3** — both touch homepage + nav components, so do as one batch.

### 5. Magic Go — overnight autonomous scaffolding to a Bottom Line queue
**This is the centerpiece. Items 1–4 exist to make this work.**

Command: `/aff magic-go <N>` (default 25). Spawns autonomous workflow that does, in sequence, with no human in the loop until it's done:

1. **Scout topics** across the portfolio. Uses existing `/scout-topics` mechanic. Distributes N across sites per cadence-deficit (sites furthest behind their quarterly target get more allocation).
2. **Research each pick.** Existing `/research-product` flow: Firecrawl + Canopy + last30days price/spec + voice notes.
3. **Scaffold each piece** into the comparison-and-fit framework with `## Bottom Line` left empty. Uses #1 (multi-network routing) to pick the highest-paying affiliate link for every product at scaffold time. Uses #3 (pillar IA) to slot the piece into the correct pillar.
4. **Auto-pass safety net.** Every scaffolded piece runs through:
   - `lint-voice.ps1` — voice doctrine grep
   - `lint-product-images.ps1` — Canopy URL validation
   - `lint-affiliate-tags.ps1` — site-config tag match
   - `audit-product-images.ps1` — square-aspect picks from Canopy array
   - `pnpm build` — Astro builds without error
5. **Quarantine failures.** Any piece that fails a lint or build goes to a `failures/` queue with the error inline. Ray can choose to fix/discard at review time.
6. **Render the queue.** When the run finishes (or hits a configurable deadline), produce `dist/magic-go/queue.html` — a static page listing every scaffolded piece with: title, pillar, product, AI-drafted 3-option Bottom Line, link to the full DRAFT.
7. **Notify Ray.** Push notification or simple "queue ready: 25 drafts" message.

Ray's morning workflow:
1. Open the queue page.
2. For each piece: skim, pick/edit one of the 3 Bottom Line options, save.
3. When all 25 are done, single command `/aff publish-batch` flips DRAFT → published, removes noindex, deploys.
4. High-five, look at Ferraris.

**Prerequisites in order:**
- #1 (multi-network routing) — every scaffolded link uses it.
- #2 (disclosure swap) — required for #1.
- #3 (pillar IA) — scaffolder needs to know where to slot pieces.
- #4 (minimalist homepage) — auto-regenerates with new pieces, needs the new template first.

If any prerequisite is incomplete, Magic Go either falls back to the old behavior (Amazon-only, flat IA) or refuses to run for that site. Prefer refuse-to-run for cleanliness — partial states create drift.

### 6. Dashboard with commission + cost roll-up
Aaron has a portfolio mission-control dashboard. Ray has `/ops` which is pipeline-state only (no $$). Add a revenue layer once Item 1 is generating per-network click data.

**Scope:** Extend `plugin/commands/ops.md` + new `tools/revenue-report.ps1` that pulls Cloudflare Analytics + per-network commission reports + Anthropic/Cloudflare/Porkbun spend → renders to `dist/ops/index.html`.

**Defer until #1 has shipped and run for at least 30 days** so there's data to dashboard.

---

## Not now (explicit "do not steal" list)

Recorded so it doesn't keep coming up:

- **Niche scoring matrix.** Ray has 6 sites and isn't scouting #7. Dead weight until that changes.
- **Domain availability check via Cloudflare/Porkbun API.** Same — only useful when picking new niches.
- **500–1000 page volume play.** Aaron's actually-shipped site has 10 articles. The volume claim is unverified; current strategy is fine.
- **Mass overnight content generation without quality gates.** Voice doctrine + Bottom Line gate + image audits are the moat. Trading them for page count loses the differentiator.
- **Amazon PA-API for product images.** Already on the roadmap in `CLAUDE.md`, gated on Amazon Associates sales volume. Stay the course.
- **Hermes / OpenClaw on Windows VPS for fully hands-off browser automation.** Premature. Playwright MCP locally is sufficient for current needs.

---

## The vision: Magic Go button

**Decision (2026-05-28):** The goal of all the work below is a single command — `/aff magic-go 25` (or whatever number) — that runs autonomously overnight and presents Ray with a single batch of 25 Bottom Lines to write in one sitting the next morning.

The deal:
- **Ray's only job is writing Bottom Lines.** That gate is non-negotiable; it's the moat against Aaron-style slop.
- **Everything else is automated:** niche/topic scouting across portfolio, product research (Firecrawl + Canopy + price/spec), scaffolding into the comparison-and-fit framework, voice lint, image audit, multi-network link routing, DRAFT/noindex publish, schema generation.
- **One batch session, one high-five.** Wake up, see queue of 25, bang them out, hit publish.

This reframes Item 5 (overnight batch scaffolding) from "future polish" to **the centerpiece**. Items 1–4 are the prerequisites that make Item 5 produce *good* DRAFTs instead of broken ones. Item 6 is the post-launch dashboard for tracking the wins.

What Magic Go does NOT do (and never will):
- Write `## Bottom Line` — Ray's gate, always.
- Publish without Bottom Line — DRAFT/noindex stays armed.
- Bypass voice lint, image audit, schema validation — those are the safety net that lets Ray trust the queue.

---

## How this lives inside `/aff`

Goal: every item above is invokable as a workflow inside the state-aware `/aff` router. No new top-level slash commands — they stay internal mechanics per the existing surface rule in `CLAUDE.md`.

Posture additions to `plugin/commands/aff.md`:

| Posture | Trigger | Action |
|---|---|---|
| `link-routing-stale` | KV entry older than 30 days OR any product missing network coverage | Run `/refresh-network-links` internal flow: re-pull commission rates per product, update KV |
| `disclosure-needs-swap` | Any site footer still names Amazon | Run `/swap-disclosure` |
| `pillar-ia-pending` | Site missing `navigation.pillars` in `site-config.json` | Walk Ray through declaring pillars + regenerate nav + spoke pages |
| `homepage-needs-redesign` | Site's `pages/index.astro` matches old template signature | Apply minimalist template, sync per-site |
| `magic-go-ready` | Items 1–4 complete for at least one site | Surface "click Magic Go" CTA. `/aff magic-go <N>` kicks off autonomous run |
| `magic-go-running` | A Magic Go run is in-flight | Status display: pieces scaffolded, lint pass/fail counts, ETA |
| `bottom-line-queue-pending` | A Magic Go run completed with N pieces awaiting verdicts | Open `dist/magic-go/queue.html`, walk Ray through clearing the queue piece-by-piece |
| `magic-go-failed-pieces` | Any pieces in `failures/` from the last run | Surface each failure with inline error, prompt fix/discard |
| `publish-batch-ready` | All pieces in current Magic Go batch have verdicts | `/aff publish-batch` — flip DRAFT → published, remove noindex, deploy all in one push |
| `revenue-report-ready` | Last revenue snapshot >7 days old | Run `/revenue-report` internal flow, render to `/ops` HTML |

All of these are **internal mechanics**. User-facing surface stays `/aff` + `/aff-idea` + `/aff magic-go <N>` + `/aff publish-batch`.

---

## Open items before Phase 1 kicks off at home

Answer these and Claude can write `docs/brainstorms/2026-05-29-multi-network-routing-plan.md` (the implementation plan for Item 1):

1. **Affiliate network approval status.** For each of: Avant, Awin, AvantLink, CJ, Rakuten — am I approved + can I pull tracking links right now? Or still pending?
2. **Phase 1 rollout site.** Start on DTP only (most traffic, lowest blast radius if buggy), or all 5 Astro sites at once? Default DTP.
3. **Commission refresh cadence.** Monthly cron? Manual on Ray's command? Default monthly via GitHub Actions schedule.
4. **Magic Go default size.** Ray said 25. Lock 25 as default? Allow override via `/aff magic-go <N>`? **Recommend:** default 25, allow override.
5. **Magic Go cross-site distribution.** When Ray clicks magic-go 25, how should the 25 distribute across MWC + DTP + FB + SA + GOG + BC? By cadence-deficit (sites furthest behind get more) or even split (5+5+5+5+5)? **Recommend:** cadence-deficit, since the whole point is to keep all sites on the quarterly cycle.

---

## Resume-from-here instructions for Claude (home PC)

If Ray hands you this doc on the home PC, do this in order:

1. Confirm you've read this doc and the latest `Session_2026-05-2*.md` files.
2. Ask Ray to answer the five "Open items" above. Don't proceed without answers — the network-approval question has no default.
3. Once answered, write `docs/brainstorms/2026-05-29-multi-network-routing-plan.md` with: KV schema, Worker pseudocode, per-network signup/credentials state, rollout sequence, test plan.
4. Do NOT start writing Worker code until that plan is reviewed.
5. Items 2–6 stay queued — do not start them until Item 1 is shipped and producing click data on DTP.

**Don't freelance.** Don't expand scope, don't add items that aren't here, don't reorder. If a new idea surfaces, file it via `/aff-idea` to Second Brain inbox and keep moving on Item 1.

**The North Star:** every line of code, every refactor, every template change exists to make `/aff magic-go 25` produce 25 DRAFT-ready pieces overnight with no human intervention until Ray writes the verdicts in the morning. Anything that doesn't move us toward that — cut.

---
project_name: Affiliate Kit
status: active
completion_percent: 72
next_task: "Apply 3 quick-fix findings from ce-doc-review, then ce-plan the content framework MVP"
open_milestone_count: 7
last_milestone_date: 2026-05-15
---

# Affiliate Kit — Hub Metadata

5 niche affiliate sites on Cloudflare Pages + link-cloaker Worker, plus the askbigchew sister site. Phase 1 toolkit + Phase 2a content-production capability both SHIPPED 2026-05-14. Phase 2b content-strategy pivot SCOPED 2026-05-15: comparison-and-fit content with dance-around voice doctrine (never claim hands-on use), requirements doc at `docs/brainstorms/2026-05-15-content-framework-requirements.md`. MVP framework build is the immediate next stretch — minimum changes to ship piece #1 under the new strategy.

## What we're building right now

**Strategic pivot (locked 2026-05-15):** Content across all 6 sites moves to **comparison-and-fit** — confident, spec-driven, use-case-framed recommendations that never claim hands-on product use. Ray doesn't own and won't buy the products covered; sites were picked for affiliate-revenue potential, not personal interest. The framework keeps the publisher legally defensible ("nah dawg, never said I used it") via a voice doctrine that forbids first-person experience claims at AI-generation time, plus a positive-framed methodology disclosure on each site's About page that documents the research process without explicitly disclaiming hands-on.

**Framework essence:**
- **Universal anatomy + per-niche tuning** — same skeleton across all 6 sites; feature axes and reader segments tune per niche
- **Two piece types** — single-product (review-style with comparison embedded) + buying-guide (multi-product, use-case matchmaker)
- **Answer-first structure** — `## Bottom Line` at the TOP of every piece (anti-recipe-page design principle, also the hard DRAFT/noindex gate that requires Ray's own prose to clear), followed by `## Who This Is For`, spec sections, comparison sections, and user-reports
- **Voice doctrine** — single source-of-truth doc with forbidden phrases (first-person experience, fabricated quotes, group-of-testers fiction, etc.) and preferred framings (spec-driven claims, use-case fit, honest aggregate of user reports). Scaffolding scripts pull AI prompts from this doc so AI never produces forbidden phrases at generation time.
- **Shared per-site product database** — verify product specs once with source URLs + verified-date, reference from multiple pieces. Built incrementally after piece #1.
- **MVP-first execution** — minimum framework changes ship piece #1 (~3-4 hr of combined work); full system grows across pieces 2-5. Avoids the "die crafting perfection" failure mode.

**mywildlifecam (hero) reader profile:** homeowners, property owners, first-time/gift buyers; backpackers secondary; explicitly NOT hunters (tone mismatch, brand mismatch).

**Current state:** Requirements doc shipped tonight. Autonomous `ce-doc-review` surfaced 26 findings — 3 quick-fixes (R9/R14 contradiction, DRAFT_MARKER 7-file sync, buyer's-guide template hands-on disclaimer removal), 8 P1 decisions requiring Ray's judgment, 15 P2/P3 + FYI items. Full breakdown in `docs/sessions/Session_2026-05-15.md`.

**Immediate next stretch:** Apply the 3 quick-fixes → `ce-plan` → `ce-work` MVP units → ship piece #1 on mywildlifecam under the new framework. Then 2-3 more pieces before applying for Amazon Associates (180-day-clock management).

## Source-of-truth pointers
- `docs/PROJECT_STATE.md` — running wins ledger
- `docs/RAY_QUEUE.md` — canonical "what to do next" file (covers cross-project tasks too)
- `docs/PLAYBOOK.md` — per-review workflow (NOTE: codifies old "I tested it" model; will be rewritten as part of full-framework rollout post-MVP)
- `docs/brainstorms/2026-05-15-content-framework-requirements.md` — new content strategy + framework requirements
- `docs/sessions/Session_2026-05-15.md` — full ce-doc-review findings (26 items surfaced for review)
- `docs/launch-playbook.html` — brand-launch click-by-click (Starwatch + Semper Fi; shared resource)

## What "72% complete" means
Phase 1 (toolkit) done. Phase 2a (content-production infrastructure) done. Phase 2b (content STRATEGY) scoped via requirements doc 2026-05-15; doc review surfaced 3 quick-fix findings + 23 substantive findings. Remaining work: address 3 quick-fixes → ce-plan → ce-work MVP → ship piece #1. Amazon Associates application explicitly deferred until 2-3 pieces are live (180-day-clock management). R2 + PA-API still blocked on Associates approval + 3 sales.

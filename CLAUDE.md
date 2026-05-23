# Affiliate Kit — Conventions

This file teaches Claude the conventions for working inside this monorepo. Read it before making changes.

## Session Documentation (NON-NEGOTIABLE — applies to every session in this repo)

**Two files, two different bars. Don't conflate them.**

### Session log (`docs/sessions/Session_YYYY-MM-DD.md`)
**Day-by-day narrative. Helps Ray and Claude remember what was done the day before.** Updated PROACTIVELY after every meaningful action — not at end of session, not as a batched catch-up.

- After every commit → bullet in "What We Did" with short hash + one-line description. Immediately.
- After a decision → write it to "Decisions" with rationale, while rationale is fresh.
- After any discovery/gotcha/surprise → "Discoveries / Gotchas" section. Immediately. This is the explicit channel for surfacing "weird dev things" Ray didn't see during execution (subtle build-time gotchas, schema constraints, tool oddities, non-obvious failure modes — things that happened in a subagent's output or mid-edit verification).
- When subagents return → orchestrator updates the session log on return; don't rely on the subagent to do it.

### Project state (`docs/PROJECT_STATE.md`)
**Overall project state. Big wins and milestones only.** High bar. Not every commit, not every bug fix, not every tracker refresh.

- Examples that ARE PROJECT_STATE-worthy: "Phase 1 complete," "MVP shipped," "Strategic pivot locked," "First piece scaffolded as DRAFT," "Show title locked," "All 5 sites live on Cloudflare."
- Examples that are NOT PROJECT_STATE-worthy: bug fixes, tracker refreshes, smoke tests, refactors, in-progress work. Those live only in the session log.
- The bar: would you tell someone "today we shipped X" in a status update? If yes, PROJECT_STATE-worthy. If it's "we made progress and fixed a bug along the way," session-log-only.

### Why this is non-negotiable here
- **It keeps Ray honest and real.** Reading the narrative is how he prevents drift, self-deception, and duplicate efforts. HIS workflow, not just an AI convenience.
- **Session log is the channel for "weird dev things"** Ray didn't see during execution — an explicit deliverable, not a side effect.
- **Memory files are NOT a substitute.** Memory is for indexed facts; session log is for narrative.

Full rule with audiences and rationale lives in `~/.claude/CLAUDE.md` "Session Documentation." Project rule mirrors it; this section makes the bar visible in-repo.

## The big picture

**Start at `docs/SYSTEM.md` — that's the architecture doc.** It shows how this repo fits with Cloudflare, AIOS, Second Brain, and external SaaS. If anything below conflicts with `docs/SYSTEM.md`, SYSTEM.md wins.

## Deploy

- 5 sites live on Cloudflare Pages. Apexes: `mywildlifecam.com`, `detailerpicks.com`, `fussybean.com`, `starteraquarium.com`, `gameovergear.games`.
- **`git push origin main` auto-deploys all 5 sites in parallel via `.github/workflows/deploy.yml` matrix.** ~3 min from push to live.
- `scripts/deploy.ps1` is the manual override for hotfixes / force redeploy without committing. Wraps `pnpm --filter <site> build` + `wrangler pages deploy`.

## Layout
- `packages/` — shared code (utils, UI components, styles). Published as workspace packages.
- `templates/site-template/` — Astro skeleton copied per site at bootstrap. Edit here to change something across sites; manually sync to the 5 `sites/<slug>/` after.
- `sites/<slug>/` — per-site Astro projects. Each site is independent and can diverge from the template once spawned.
- `workers/` — Cloudflare Workers (one per Worker, currently just `link-cloaker`).
- `tools/` — internal CLIs and helpers (the original bootstrap CLI; retired now that all 5 sites exist).
- `plugin/` — Affiliate Kit slash command sources. `scripts/install-plugin.ps1` copies `plugin/commands/*.md` into `~/.claude/commands/`. See `plugin/README.md`.
- `scripts/` — PowerShell helpers (`new-review`, `buyers-guide`, `add-link`, `lint-voice`, `deploy`, `install-plugin`).
- `docs/` — knowledge base. Map at `docs/SYSTEM.md`. Stale plan docs live in `docs/archive/`.

## Strategy
- One hero site (`mywildlifecam`) gets the real effort. Five satellites (`detailerpicks`, `fussybean`, `starteraquarium`, `gameovergear`, `askbigchew`) get the playbook on a slower clock. Don't suggest equal effort across all 6.
- Quarterly cycle = 5 new reviews + refresh sweep, per site, every 90 days.
- `askbigchew` lives in its own repo (`champrt78/askbigchew`, locally `bc/`) and uses Next.js + MDX instead of the Astro template. Don't try to bootstrap it via `/aff-bootstrap`; it follows a different deploy path documented in `docs/askbigchew-cloudflare-migration.html`. Once on Cloudflare DNS, it shares the same link-cloaker Worker as the others.

## Content rules
- **Comparison-and-fit content framework** (locked 2026-05-15; full requirements at `docs/brainstorms/2026-05-15-content-framework-requirements.md`). Never claim hands-on product use; voice doctrine at `docs/voice-doctrine.md` is the single source of truth for forbidden phrases + preferred framings + direct-question responses.
- AI scaffolds the draft. Human fills in `## Bottom Line` (located at the TOP of every piece — anti-recipe-page design principle, and the hard DRAFT/noindex gate). Never publish with `## Bottom Line` empty.
- Both piece types (single-product and buying-guide) use the same universal anatomy with `## Bottom Line` at the top, followed by `## Who This Is For` (AI-drafted, not gated), then supporting spec/comparison/user-reports sections.
- After AI drafting, run `pwsh scripts/lint-voice.ps1 <piece>.md` to grep for forbidden phrases as a back-stop before commit.
- AI-generated product images are banned. AI for scene/context only. Product hero shots come from Amazon PA-API or the brand's affiliate media kit.

## Style
- TypeScript strict mode. No `any` without a `// reason:` comment.
- Test the hard parts (Worker logic, helpers, schema generators). Don't unit-test Astro templates — `astro build` is the test.
- Conventional commits: `feat:`, `fix:`, `refactor:`, `docs:`, `chore:`, `test:`.
- Frequent commits; one logical change per commit.

## Web vitals — image dimensions are mandatory
**Every `<img>` tag MUST have `width` and `height` attributes.** No exceptions, even when CSS uses `aspect-ratio` on the container or `width:100%; height:100%; object-fit:cover` on the image. The HTML attrs are an aspect-ratio HINT the browser uses during parse, before CSS arrives — without them, the browser reserves 0 height and the image pops in late, causing a layout shift (CLS).

**This bit us on 2026-05-20:** Cloudflare Web Analytics flagged detailerpicks.com homepage with CLS = 0.458 on `#main > article.guide-card` ("Poor" tier; threshold is 0.1). Root cause: `<img>` in `Hero.astro`, `BuyersGuideCard.astro`, `ReviewCard.astro`, `ProductCard.astro`, `ReviewArticle.astro`, and several per-site `[...slug].astro` pages all rendered dimensionless. CSS aspect-ratio was set but didn't save us — there's a parse-time window where the browser doesn't know the eventual size.

**The fix is just attributes:** the actual pixel values are aspect-ratio hints, not display sizes. CSS still controls real layout via `width:100%; height:100%`. Defaults to use:
- Hero / cover photo (16:9): `width="1600" height="900"`
- Guide card thumbnail (4:3): `width="1600" height="1200"`
- Review article hero (8:5): `width="1600" height="1000"`
- Product card / square thumb: `width="1200" height="1200"`
- Amazon product image (PA-API): `width="500" height="500"` (Amazon's standard)

If the source image has a specific known aspect, use that ratio. Match the container's CSS aspect-ratio when possible — but the *exact* numbers don't matter, only the ratio.

Quick check before committing any page or component with images:
```powershell
Select-String -Path "**\*.astro" -Pattern "<img\s" | Where-Object { $_.Line -notmatch 'width=' }
```
If anything prints, fix it.

## Tone of generated output
- Tone is currently fixed at snarky-but-friendly. Configurable tone is deferred until a concrete consumer exists.

## Slash command surface (NON-NEGOTIABLE)

**Two user-facing commands. That's it.**

- **`/aff`** — state-aware router. Surveys portfolio state across MWC + DTP, computes posture, opens with ONE next-move proposal + Y/N. Plain language both ways. No flags. Walks Ray through whatever the next correct step is: write Bottom Lines, scaffold, scout, unblock, or report state.
- **`/aff-idea <text>`** — sidetrack capture. Files an idea into Second Brain `ideas/` inbox without breaking the active `/aff` thread.

**Everything else in `plugin/commands/` is an internal mechanic.** They appear in `/help` (Claude Code has no mechanism to suppress slash-command listing — confirmed via CE feasibility review 2026-05-20), but Ray ignores them. Their `description:` starts with `Internal —` so they're visually distinct in any picker.

| Internal command | What it does | Read inline by `/aff` when |
|---|---|---|
| `/scout-topics` | Topic discovery across portfolio | posture is `hero-behind-cadence`, `dp-behind-cadence`, `ready-for-next-topic` |
| `/research-product` | Firecrawl + Canopy + last30days + /watch synthesis | After scout produces a pick |
| `/scaffold-piece` | Scaffolder + KV + voice lint + build | `research-ready-to-scaffold` posture; has entry-mode B for already-collected context |
| `/bottom-line-helper` | 3 verdict drafts (read-only) | `draft-needs-bottom-line` posture |
| `/ops` | Static HTML dashboard | Folded into `/aff` state survey; still usable standalone for the HTML render |

**Dispatch model:** Slash commands cannot invoke other slash commands. `/aff` `Read`s the relevant playbook `.md` file inline and executes its steps in the same conversation turn.

**When Ray's plain-language request maps to an `/aff` workflow** — "let's write the next DTP piece", "where are we?", "research X", "I had a thought" — **announce the dispatch in one line** ("Running `/aff` under the hood now") **and walk through `plugin/commands/aff.md` verbatim.** Do NOT freelance scout/research/scaffold/bottom-line/capture logic. The internal mechanics encode voice-doctrine lint, DRAFT/noindex gates, KV registration, schema validation, `pnpm build`. Freelancing skips the safety net and produces subtly broken work.

## When in doubt
- Architecture / how everything connects → `docs/SYSTEM.md`
- What's open right now → `docs/TODO.md`
- Voice / forbidden phrases → `docs/voice-doctrine.md`
- Per-piece workflow → `docs/PLAYBOOK.md`
- Historical plan docs (original design, phase-1 plan, content-readiness plan) → `docs/archive/`

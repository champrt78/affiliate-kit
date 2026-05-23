# /aff Router Proposal — v2 (post-review)

**Author:** Ray + Claude
**Date:** 2026-05-20
**Status:** REVISED post 5-persona CE doc-review — ready to implement

> **v2 changelog:** Cut postures 10 → 6 (dropped `satellite-rotation`, `tooling-regression`, `cf-deploy-broken`). Scoped state survey to MWC + DTP full, satellites on demand. Opener leads with ONE move + Y/N (not a ranked menu). Renamed second command `/idea` → `/aff-idea` to avoid colliding with moonlit-meadow's `/idea`. Dropped "hide from /help" framing — Claude Code has no mechanism to suppress slash-command listing; "internal" is description-prefix + social enforcement only. Dispatch model is "Read the playbook .md and execute inline," not slash-to-slash. /ops folded into /aff's state survey. Per-step Y/N gates on multi-step actions. Verbatim opener template per kept posture.

## Problem statement

The affiliate-kit currently exposes 5+ user-facing slash commands: `/scout-topics`, `/research-product`, `/scaffold-piece`, `/bottom-line-helper`, `/capture`, `/ops`. Each is its own entry point with its own argument shape. Ray has to remember which command maps to which phase of the workflow, scope each one to the right site, and read the portfolio state himself before picking. When he forgets a command exists, he freelances — which skips voice-doctrine lint, DRAFT/noindex gates, and other safety nets.

Same problem moonlit-meadow solved with `/mm`. Ray's exact ask:

> *"the goal is for me to never have to type any commands other than aff , after that you ask , i answer in plain language , and YOU go do the things , you can prompt me on Y/N answers"*

## Reference: moonlit-meadow `/mm`

Read `~/.claude/plugins/cache/moonlit-meadow/moonlit-meadow/0.1.0/commands/mm.md` for the full pattern. Summary: one state-aware front door + one sidetrack capture command. State survey → posture → opener → conversational dispatch → loop back. Internal mechanics are named `Internal mechanic —` in the description and enforced via project CLAUDE.md.

## Architecture (v2)

### Surface area

- **`/aff`** — state-aware router across MWC + DTP (satellites scoped on demand). Opens with ONE move + Y/N. Plain-language conversation thereafter.
- **`/aff-idea <text>`** — sidetrack capture (renamed from `/capture` because `/idea` is already owned by moonlit-meadow).

### Realistic posture re: "hidden" commands

Claude Code has no mechanism to suppress slash-command listing — every `plugin/commands/*.md` will appear in `/help`. Ray will see `/aff`, `/aff-idea`, `/scout-topics`, `/research-product`, `/scaffold-piece`, `/bottom-line-helper`, `/ops` all listed. The "hiding" is achieved via:

1. **`description:` frontmatter prefix** — each internal command's `description:` starts with `Internal —`.
2. **Project CLAUDE.md social enforcement** — "Use `/aff` and `/aff-idea`. Don't surface the internal mechanics in primary docs."
3. **`plugin/README.md`** — internal mechanics listed in a separate "Internal mechanics (not for direct use)" section.

This matches moonlit-meadow exactly. The framing in the doc and onboarding is "two user-facing commands" — Ray learns to ignore the rest.

### Dispatch model (corrected from v1)

`/aff` does NOT slash-invoke other commands. Slash commands are single-shot expansions; one slash → one expansion. Instead, `/aff` `Read`s the relevant playbook `.md` file (e.g. `plugin/commands/scaffold-piece.md`) and executes its steps inline as instruction prose. The "loop back to state survey" pattern works because everything happens in one long instruction file.

**Implication for internal mechanics:** they need to be structured as standalone playbooks that work whether (a) invoked directly via slash with CLI-style args, OR (b) read as instruction prose by `/aff` with already-collected conversational context. The existing 6 are mostly already this shape; `/scaffold-piece`'s "parse Ray's input" step needs an entry-mode that accepts pre-collected context (matching `/mm`'s pattern: *"skip the input-collection step — you already collected the inputs conversationally"*).

### Internal mechanics

These keep existing in `plugin/commands/`. `Internal —` prefix in `description:`. Read inline by `/aff` when its posture dispatches there.

| Internal command | Read by /aff when posture is | Side effects |
|---|---|---|
| `/scout-topics` | `ready-for-next-topic` | Reads portfolio state; produces ranked candidate list |
| `/research-product` | After scout produces a pick | Writes `docs/research/<date>-<slug>.md` |
| `/scaffold-piece` | After research lands | Writes content file, registers KV, runs voice-lint + `pnpm build` |
| `/bottom-line-helper` | `draft-needs-bottom-line` | Read-only — drafts 3 verdict options |
| `/ops` | Folded into /aff's state survey | Read-only — state report |

### State survey (scoped, not cached)

No daemon, no cache file. Just scope the reads.

**MWC + DTP — full survey:**
- List `sites/<slug>/src/content/{reviews,buyers-guides}/*.md` filenames (cheap, no body reads).
- Read frontmatter only of each piece (Astro content collections, so this is just a top-of-file YAML parse).
- Count shipped vs DRAFT (DRAFT = `bottomLine.verdict.trim() === ""`).
- Latest pubDate, days since last shipped.
- Open site-scoped TODOs from `docs/TODO.md` (grep for slug).
- Research notes ready to scaffold: `docs/research/*.md` exists for topic with no matching piece.

**Satellites (fussybean, starteraquarium, gameovergear) — single metric:**
- Days since most recent `git log` touch of `sites/<slug>/`. That's it. Full survey only if Ray asks ("what about fussybean?").

**Portfolio-level:**
- Today's commits, days since last commit.
- Urgent blockers from `docs/TODO.md` Now-queue.

Estimated cold-start survey: ~5-15 seconds. Acceptable for a once-per-conversation greeting.

### Posture table (6 postures, first-match-wins)

Postures evaluated in this exact order. **First match wins** — once a posture matches, stop evaluating. The order encodes the leverage hierarchy.

| # | Posture | Match condition | Routes to |
|---|---|---|---|
| 1 | `urgent-blocker` | TODO Now-queue has an item whose body contains a "need your input" marker (URL drop, image source) | Ask Ray inline for the input; apply it; loop back |
| 2 | `draft-needs-bottom-line` | Any piece anywhere (MWC or DTP) has `bottomLine.verdict.trim() === ""` | Read `bottom-line-helper.md` inline; offer 3 options; ask which; commit Bottom Line; loop back |
| 3 | `research-ready-to-scaffold` | `docs/research/*.md` exists for a topic that has no piece scaffolded in `sites/<slug>/src/content/` | Read `scaffold-piece.md` inline; confirm slug+type; scaffold + lint + build; commit; loop back |
| 4 | `hero-behind-cadence` | MWC last `git log` touch > 7 days ago AND no in-flight draft for MWC | Read `scout-topics.md` inline scoped to MWC; propose 1-3 candidates; pick one; route to research → scaffold |
| 5 | `dp-behind-cadence` | DTP last touch > 18 days ago AND no in-flight draft AND ≥1 DTP Bottom Line landed | Same chain scoped to DTP |
| 6 | `ready-for-next-topic` | All docs current, no drafts, hero on cadence | Read `scout-topics.md` inline portfolio-wide; propose next; loop |
| — | `where-are-we` | Reactive only — user response is a state-query | Print the full state survey output (this is the folded `/ops` flow) |

**Postures cut from v1** (re-add only when they fire empirically twice):
- `satellite-rotation` — contradicts the dormant-by-design strategy in project CLAUDE.md
- `tooling-regression` — requires AIOS `affiliate_link_health` integration not yet wired
- `cf-deploy-broken` — Ray sees CF dashboard + git push output natively

### Opener format — ONE move + Y/N (not a menu)

The opener has three jobs: (a) name the current state in one short line, (b) propose ONE specific next move, (c) ask Y/N. The ranked list of "everything else open" is available behind the response "what else?" — it does not lead.

**Verbatim opener templates per posture:**

`urgent-blocker`:
> *"`/aff` — TODO Now-queue has a blocker that needs your input: `<task body>`. Want to drop the answer right now? (Or type 'later' to push past and do other work.)"*

`draft-needs-bottom-line`:
> *"`/aff` — `<N>` piece(s) sitting at DRAFT with empty Bottom Line, blocking Google indexing. Highest-leverage piece: `<site>/<slug>`. Want to draft 3 verdict options for it now? (y/n / 'all' to walk through every draft / 'what else?' to see the full board)"*

`research-ready-to-scaffold`:
> *"`/aff` — research notes for `<title>` are ready at `docs/research/<date>-<slug>.md`, no piece scaffolded yet. Want to scaffold it now? (y/n / 'what else?')"*

`hero-behind-cadence`:
> *"`/aff` — MWC last shipped `<N>` days ago, hero target is 7d. No in-flight draft. Top scout candidate: `<title>`. Want to research + scaffold it? (y/n / 'pick something else' / 'what else?')"*

`dp-behind-cadence`:
> *"`/aff` — DTP last shipped `<N>` days ago, target is 18d. No in-flight draft. Top scout candidate: `<title>`. Want to research + scaffold? (y/n / 'pick something else' / 'what else?')"*

`ready-for-next-topic`:
> *"`/aff` — caught up. MWC on cadence, no DRAFTs, no blockers. Want to scout the next topic? (y/n — defaults to MWC unless you say otherwise / 'show me the board' for the full state report)"*

`where-are-we` (reactive only):
> Prints the full state survey output (per-site shipped/DRAFT counts, days since last ship, open TODOs, research-ready notes). Folded `/ops` flow. Ends with: *"Want to keep going, or pause?"*

### Intent routing (plain-language → action)

User responses to the opener parsed against this table. Cases that don't match → re-ask with a short list of valid moves.

| User says | Action |
|---|---|
| "yes" / "y" / "let's go" / "do it" | Accept proposed move |
| "no" / "n" / "skip" / "not that" | Re-rank, offer next-best posture or ask what instead |
| "what else?" / "show the board" / "everything open" | Print full state survey (the dashboard) |
| "let's do `<thing>`" (named pivot) | Switch to that flow; re-survey |
| "`<URL drop>`" / "the answer is `<X>`" | Treat as input to unblock current `urgent-blocker` |
| "where are we?" / "what's the status?" | Switch to `where-are-we` flow |
| "I had a thought about `<X>`" / "capture this:" | Tell Ray to type `/aff-idea <text>` (one-shot capture); end |
| "pause" / "stop" / "later" / "I'll come back" | Stop cleanly. Print: *"Stopped. Run /aff when you're ready — I'll re-survey."* |
| "all" / "do all of them" (for multi-draft postures) | Walk each one with per-step Y/N gate (see below) |
| Ambiguous / multi-intent / numbered pick | Re-ask: *"Want me to <interpretation A> or <interpretation B>?"* |

### Multi-step durability

Slash commands have no persistent process; conversations compact and crash. So multi-step actions ("write all 4 DTP Bottom Lines") commit between sub-steps so file-system state is the source of truth.

- Each Bottom Line: draft → ask Ray to pick / edit → write to frontmatter → commit → push → loop to next.
- Each scaffold: research → confirm slug → scaffold → lint → build → commit → push → loop to where-are-we.
- If conversation crashes mid-flow, next `/aff` re-surveys, sees the remaining work, picks up from there.

No silent N-step batches. Every gate is observable.

### Interaction states (the missing ones design-lens flagged)

- **Browse without committing:** Ray types `/aff` to see what's open without picking a move. Handled by the `"what else?"` intent — prints the board, no dispatch.
- **Pause/cancel midway:** any "pause" / "stop" / "later" → stop cleanly, print resume hint, exit. File-system state is durable so resume is automatic.
- **Post-completion loop-back:** after a dispatched flow finishes, `/aff` re-surveys (Step 2) and re-fires its opener with the new state. Ray sees one "what just happened + what's next" line.

### Self-healing canon (minimal)

Read site slugs from filesystem at runtime: `Glob` `sites/*/src/data/site-config.json`. Don't hardcode `mwc`/`dp`/etc. Cadence targets per site come from `site-config.json` (add if missing — single-line addition).

### Enforcement layer (project CLAUDE.md)

Add this section:

> ## Slash command surface
>
> **Two user-facing commands:** `/aff` (state-aware router) and `/aff-idea` (sidetrack capture). Everything else (`/scout-topics`, `/research-product`, `/scaffold-piece`, `/bottom-line-helper`, `/ops`) is an **internal mechanic** that `/aff` reads inline. Their `description:` frontmatter starts with `Internal —`. They appear in `/help` (Claude Code has no mechanism to suppress this), but Ray ignores them.
>
> **When Ray's plain-language request maps to an `/aff` workflow** — "let's write the next DTP piece", "where are we?", "research X", "I had a thought" — **announce the dispatch** ("Running `/aff` under the hood") **and walk through `plugin/commands/aff.md` verbatim.** Don't freelance scout/research/scaffold/bottom-line/capture logic. The internal mechanics encode voice-doctrine lint, DRAFT/noindex gates, KV registration, schema validation, `pnpm build`. Skipping them produces subtly broken work.

## Implementation plan

1. Write `plugin/commands/aff.md` (~200 lines, /mm-style structure).
2. Rename `plugin/commands/capture.md` → `plugin/commands/aff-idea.md`. Update description.
3. Prefix `description:` of `/scout-topics`, `/research-product`, `/scaffold-piece`, `/bottom-line-helper`, `/ops` with `Internal —`.
4. Add entry-mode flexibility note to `/scaffold-piece` (accept already-collected context).
5. Update project CLAUDE.md with the enforcement section above.
6. Update `docs/SYSTEM.md` to point at `/aff` as canonical entry.
7. Update `plugin/README.md` to list `/aff` + `/aff-idea` as the user surface; demote others to "Internal mechanics."
8. `pnpm install-plugin` to copy commands into `~/.claude/commands/`.
9. Smoke-test: type `/aff` from a fresh session, verify it surveys state, computes posture, opens correctly.
10. Commit + push.

Estimated effort: ~90 minutes.

## Risks (post-revision)

- **State survey could miss edge cases.** Mitigation: explicit `where-are-we` fallback always available; Ray can override the proposed move.
- **First-match-wins ordering could surface wrong priority as the portfolio grows.** Mitigation: the ordering is explicit in the posture table (1-6) and revisitable. If draft-needs-bottom-line is winning when it shouldn't (e.g. urgent CF deploy break), Ray says so and we add the posture.
- **Multi-step gates feel slow if Ray wants batch processing.** Mitigation: `"all"` accepts the batch but still commits between sub-steps so any failure is recoverable.
- **Naming `/aff-idea` is uglier than `/idea`.** Tradeoff for cross-project safety. Could revisit if we ever isolate moonlit-meadow + affiliate-kit to different machines, but unlikely.

## What's no longer in scope

- 10-posture table → 6
- Multi-site full survey → MWC+DTP full, satellites on demand
- Ranked-menu opener → single-move opener
- Slash-to-slash dispatch → Read-playbook-inline
- 5-min in-memory cache → no cache, just survey scoping
- "Hide from /help" → `Internal —` description prefix + social enforcement
- /idea name → /aff-idea
- Start-over option → wrap existing mechanics, decided
- Multi-step silent batches → per-step commits/gates always

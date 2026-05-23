---
description: The single conversational entry point for affiliate-kit. Surveys portfolio state across MWC + DTP, computes posture, opens with ONE next-move proposal, walks through whatever flow fits — bottom-line writing, scaffolding, scouting, blocker unblocking, or state report. Plain language both ways. No flags.
---

# /aff

The one command Ray ever needs to type for affiliate-kit. `/aff` reads the portfolio state, figures out where Ray is in the lifecycle, opens with a single state-aware proposal, and walks him through whatever the next correct step is. Internally it reads internal-mechanic playbooks inline — Ray never needs to remember which.

The user never types flags. This command asks for what's needed and announces what's running so Ray can stop it if it picked wrong.

## How to run this

The user invoked `/aff` with no arguments. There is no flag interface — the conversation collects everything it needs.

### Step 1: Resolve the monorepo path

The affiliate-kit repo path detection:

1. If `./CLAUDE.md` exists and contains "Affiliate Kit" or "affiliate-sites" in the first ~20 lines, use cwd.
2. Otherwise, error per **On failure**.

### Step 2: Survey current state (scoped, not full-fat)

Read state signals in order. Be efficient — list filenames first, only read frontmatter, defer full body reads.

**MWC + DTP — full survey:**

For each of `sites/mywildlifecam/` and `sites/detailerpicks/`:

1. **Content inventory.** `Glob` `sites/<slug>/src/content/{reviews,buyers-guides}/*.md`. For each file, `Read` the frontmatter only (top of file through the closing `---`). Capture: `pubDate`, `lastUpdated`, `bottomLine.verdict`, `bottomLine.supporting`. Determine DRAFT status (`bottomLine.verdict.trim() === ""` or contains placeholder string).
2. **Last-shipped.** Latest `pubDate` across shipped (non-DRAFT) pieces. Days since today.
3. **Cadence target.** MWC = 7 days (hero). DTP = 18 days (emerging hero).
4. **Site-scoped TODOs.** Grep `docs/TODO.md` for occurrences of the site slug.
5. **Research-ready notes.** `Glob` `docs/research/*.md`. For each, parse the slug from filename. Check whether `sites/<slug>/src/content/{reviews,buyers-guides}/<slug>.md` exists. If not, it's a candidate for `research-ready-to-scaffold`.

**Satellites — single metric on demand:**

For `sites/fussybean/`, `sites/starteraquarium/`, `sites/gameovergear/`: capture only `git log -1 --format=%cr -- sites/<slug>/` (most-recent touch). Do NOT walk content. Full survey ONLY if Ray asks ("what about fussybean?").

**Portfolio-level:**

6. **TODO Now-queue.** Read `docs/TODO.md` `## Now` section. Capture each line. Flag any with explicit "need your input" markers: phrases like "Need a current product Amazon URL", "Need URL + image", "pending Ray's URL drop", "blocked on", "drop the".
7. **Recent commits.** `git log --since="3 days ago" --format='%h %ar %s'`. Captures session momentum.
8. **Today's commits count.** `git log --since="today 00:00" --format='%h' | wc -l`.

Capture everything into a state snapshot. Preserve filenames, slugs, dates verbatim.

### Step 3: Compute posture (first-match-wins)

Evaluate in this exact order. Once a posture matches, STOP — do not evaluate further. The order encodes leverage hierarchy.

| # | Posture | Match condition |
|---|---|---|
| 1 | `urgent-blocker` | Step 2.6 found ≥1 TODO Now-queue item with a "need your input" marker |
| 2 | `draft-needs-bottom-line` | Any piece (MWC or DTP) has empty Bottom Line per Step 2.1 |
| 3 | `research-ready-to-scaffold` | Step 2.5 produced ≥1 research note with no matching piece scaffolded |
| 4 | `hero-behind-cadence` | MWC last-ship > 7 days ago AND no MWC piece in DRAFT |
| 5 | `dp-behind-cadence` | DTP last-ship > 18 days ago AND no DTP piece in DRAFT AND ≥1 DTP Bottom Line landed |
| 6 | `ready-for-next-topic` | None of the above match |
| — | `where-are-we` | Reactive only — when user response in Step 5 is a state-query |

### Step 4: Open with ONE move + Y/N (verbatim templates)

Pick the matched posture and open with the corresponding template. Substitute the bracketed values from the state survey.

**`urgent-blocker`:**

> *"`/aff` — TODO Now-queue has a blocker that needs your input:*
> *  • `<task body, first 80 chars>`*
>
> *Want to drop the answer right now? (Or type 'later' to push past and do other work.)"*

If multiple urgent blockers, list up to 3 by bullet; ask Ray to pick one or say "later" / "all".

**`draft-needs-bottom-line`:**

> *"`/aff` — `<N>` piece(s) sitting at DRAFT with empty Bottom Line, blocking Google indexing.*
> *Highest-leverage piece: `<site>/<slug>` (`<piece title>`).*
>
> *Want to draft 3 verdict options for it now? (y/n / 'all' to walk through every draft / 'what else?' for the full board)"*

**`research-ready-to-scaffold`:**

> *"`/aff` — research notes for '`<title from research filename>`' are ready at `docs/research/<filename>.md`, but no piece scaffolded yet.*
>
> *Want to scaffold it now? (y/n / 'what else?')"*

**`hero-behind-cadence`:**

> *"`/aff` — MWC last shipped `<N>` days ago. Hero cadence target is 7d.*
> *No in-flight draft. Time to start the next piece.*
>
> *Want me to scout MWC topics now? (y/n / 'I have a specific topic in mind' / 'what else?')"*

**`dp-behind-cadence`:**

> *"`/aff` — DTP last shipped `<N>` days ago. Cadence target is 18d.*
> *No in-flight draft.*
>
> *Want me to scout DTP topics now? (y/n / 'I have a topic' / 'what else?')"*

**`ready-for-next-topic`:**

> *"`/aff` — caught up. MWC `<X>` shipped (last `<N>`d ago, on cadence). DTP `<Y>` shipped (last `<N>`d ago). No DRAFTs. No blockers.*
>
> *Want to scout the next topic? (y/n — defaults to MWC unless you say otherwise / 'show me the board' for full state)"*

**`where-are-we`** (reactive only — see Step 5):

Print the full state survey output. Format:

```
Portfolio status — <date>

MWC:
  Shipped: <N>  |  DRAFT: <N>  |  Last shipped: <N>d ago (target 7d — <on-cadence|behind>)
  Open TODOs: <N>  |  Research-ready: <N>
  <If any URL-drop blockers, list them>

DTP:
  Shipped: <N>  |  DRAFT: <N>  |  Last shipped: <N>d ago (target 18d — <on-cadence|behind>)
  Open TODOs: <N>  |  Research-ready: <N>

Satellites:
  fussybean: last touched <relative>
  starteraquarium: last touched <relative>
  gameovergear: last touched <relative>

Recent commits (3d): <count>
Today's commits: <count>

Up next per posture: <highest-priority posture's recommended action>
```

End with: *"Want to keep going, or pause?"*

### Step 5: Intent routing

User responds in plain language. Parse against this table. If nothing matches cleanly, re-ask with a short list of valid moves.

| User says | Action |
|---|---|
| "yes" / "y" / "let's go" / "do it" / "go" / "sure" | Continue to Step 6 with the proposed move |
| "no" / "n" / "skip" / "not that" | Re-evaluate. Offer next-best posture OR ask "what would you like to do instead?" |
| "what else?" / "show me the board" / "everything open" | Print full state survey (the `where-are-we` template) without dispatch |
| "all" / "do all of them" (only valid for draft-needs-bottom-line posture) | Walk each DRAFT piece with per-step Y/N gate per Step 6.B |
| "let's do `<thing>`" / "actually I want to `<X>`" | Switch flow per Step 6 to the matching mechanic. Re-survey. |
| URL-like string / "the URL is `<X>`" / "answer is `<X>`" | Treat as input to the current `urgent-blocker` task. Apply per Step 6.A. |
| "where are we?" / "what's the status?" / "what's left?" | Switch to `where-are-we` flow (Step 4's reactive template) |
| "I had a thought about `<X>`" / "capture this:" / "quick idea" | Tell Ray: *"Type `/aff-idea <text>` to capture it without breaking flow. Come back to `/aff` when you're done."* End politely. |
| "pause" / "stop" / "later" / "I'll come back" | Stop cleanly. Print: *"Stopped. Run `/aff` when you're ready — I'll re-survey from the current state."* |
| Ambiguous / multi-intent / numbered pick | Re-ask: *"Want me to <interpretation A> or <interpretation B>?"* |

### Step 6: Flow dispatch

Each posture routes to one of these flows. Dispatch means: `Read` the relevant playbook `.md` file inline, announce the dispatch in one line, and execute its steps in this same conversation turn. **Slash commands cannot invoke other slash commands** — every step of every flow happens inside `/aff`.

#### Step 6.A: Urgent-blocker unblock flow

1. Confirm with Ray: *"OK — applying `<URL/answer>` to `<task slug>`. Confirm? (y/n)"*
2. Apply the change. Examples:
   - URL drop: update the relevant content file's `products[].affiliateUrl` + `body` mentions; register cloaker KV via `pwsh scripts/add-link.ps1`.
   - Image source: update `images.hero` or `products[].image`; verify the URL responds 200 (HEAD request).
3. Run voice-lint + build to verify the piece still passes.
4. Commit: `fix(<site>): unblock <slug> — <one-line description>`.
5. Push.
6. Loop back to Step 2 (re-survey).

#### Step 6.B: Bottom Line writing flow

For the proposed piece (or each piece if Ray said "all"):

1. Announce: *"Running `bottom-line-helper` under the hood now for `<site>/<slug>`."*
2. `Read` `plugin/commands/bottom-line-helper.md`. Execute its steps inline with the piece path as input.
3. Print the 3 options Bottom Line helper produced.
4. Ask Ray: *"Pick #1, #2, #3, or paste your own. (Or 'edit #2' if you want to tweak one.)"*
5. Apply the chosen Bottom Line to the piece's frontmatter (`bottomLine.verdict` + `bottomLine.supporting`) AND to the `## Bottom Line` body section.
6. Run voice-lint to verify.
7. Run build to verify the page now ships `<meta name="robots" content="index, follow">`.
8. Commit: `feat(<site>): write Bottom Line for <slug>`.
9. Push.
10. If "all" mode AND more DRAFTs remain, loop to next DRAFT.
11. Else loop back to Step 2 (re-survey).

#### Step 6.C: Research-then-scaffold flow

1. Announce: *"Running `research-product` under the hood now for '<title>'."*
2. If research note doesn't exist yet: `Read` `plugin/commands/research-product.md`. Execute its steps with the topic. Output lands at `docs/research/<date>-<slug>.md`.
3. If research note exists: skip step 2.
4. Confirm with Ray: *"Research is in. Ready to scaffold the piece? Site: `<slug>`, type: `<review|buyers-guide>`, slug: `<slug>`. (y/n / 'adjust')"*
5. Announce: *"Running `scaffold-piece` under the hood now."*
6. `Read` `plugin/commands/scaffold-piece.md`. **Use entry-mode B (context-from-/aff): skip its Step 1 "parse Ray's input" — pass the already-collected site/type/slug/etc. directly.** Execute its remaining steps (writes content file, registers KV via `add-link.ps1`, runs voice-lint, runs `pnpm --filter <site> build`).
7. Commit + push the scaffold + any voice-lint fixes as separate commits.
8. Print: *"Scaffolded as DRAFT. Bottom Line is empty — page is noindex'd. Want to write the Bottom Line now? (y/n / 'later')"*
9. If yes → Step 6.B. If no → loop back to Step 2.

#### Step 6.D: Scout flow

1. Announce: *"Running `scout-topics` under the hood now (scope: `<mwc|dp|portfolio>`)."*
2. `Read` `plugin/commands/scout-topics.md`. Execute the matching mode (Mode A portfolio-wide, Mode B site-scoped) per the posture.
3. Print the ranked candidate list.
4. Ask Ray: *"Pick one (e.g. 'go with #2' or paste a different topic). Or 'none for tonight' to bail."*
5. On pick → Step 6.C (research-then-scaffold).
6. On "none" → loop back to Step 2.

#### Step 6.E: Where-are-we report (folded /ops)

Print the full state survey output per Step 4's `where-are-we` template. Do NOT dispatch any flow. End with the keep-going-or-pause question. If Ray says "keep going" without specifying a flow, re-fire Step 3 (posture computation) and Step 4 (opener).

### Step 7: Announce dispatch on mechanic transitions only

Per Step 6, every transition to a new internal mechanic gets a one-line announcement:

> *"Running `<mechanic-name>` under the hood now."*

Do NOT announce sub-steps inside the same mechanic. Don't repeat the announcement on every loop iteration in multi-step flows ("all" mode walks 4 Bottom Lines; the announcement fires once at the start, not 4 times).

### Step 8: Loop-back rule

When a flow from Step 6 completes (successful commit + push), automatically loop back to Step 2 (re-survey). Re-fire Step 3 + Step 4 with fresh state. Print one bridging line: *"OK, `<previous flow>` done. Re-checking the board..."* then the new opener.

If the loop produces the SAME posture (e.g. another DRAFT still needs a Bottom Line), Ray will get a repeat opener — that's expected, "all" mode is one way to short-circuit this.

If the loop produces `ready-for-next-topic`, congratulate briefly and ask if Ray wants to keep going or stop.

### Step 9: Per-step durability rule

Multi-step flows (Step 6.B "all" mode, Step 6.C scaffold which has several sub-commits) commit + push between sub-steps. File-system state is the source of truth — if conversation crashes mid-flow, next `/aff` re-surveys and sees only the unfinished work.

Never silently batch multiple file-mutations into one commit. Every dispatched action is observable in `git log`.

## Pre-flight

Before any work:

1. The repo path must resolve per Step 1.
2. Step 2's state survey must complete without errors. If a critical file is unreadable, report it per **On failure**.

## On failure

- **Path resolution fails.** *"Couldn't confirm this is the affiliate-kit repo. Run `/aff` from inside the `affiliate-sites` checkout."* Stop.
- **TODO.md missing.** *"`docs/TODO.md` is missing — required for blocker detection. Restore from git or recreate per global CLAUDE.md spec."* Stop.
- **An internal-mechanic playbook .md is missing.** *"`plugin/commands/<file>` is missing — the dispatched flow can't run. Restore from git."* Stop.
- **User cancels mid-conversation.** Stop gracefully. Don't leave half-written files uncommitted. Print: *"Stopped. Run `/aff` again whenever you're ready — I'll pick up from the file-system state."*
- **A build or voice-lint fails inside a dispatched flow.** Stop the loop. Print the error verbatim. Commit any work that DID succeed (so re-running `/aff` picks up from the right point). Print: *"Build failed mid-flow. `<commit-hash>` has what landed so far. Fix and re-run `/aff`."*
- **State is ambiguous** (e.g. two postures could match). Apply Step 3's first-match-wins rule. If still ambiguous, ask Ray.

## What this command is NOT

- **NOT a replacement for the internal mechanics.** They still exist at `plugin/commands/{scout-topics,research-product,scaffold-piece,bottom-line-helper,ops}.md` and are invocable directly for debugging. Their `description:` starts with `Internal —`.
- **NOT magic.** It's a state-survey + posture-router + conversational dispatcher + loop-back layer.
- **NOT skipping preflight.** The underlying playbooks still run their checks.
- **NOT a chat companion.** This is a production tool. Stay on task.
- **NOT a menu.** The opener proposes ONE move. The full board appears only on "what else?" or "where are we?"

## The principle

Ray is the operator. He types `/aff` and gets walked through whatever the next correct step is, with the portfolio's current state baked into every suggestion. Internal mechanics encode the safety net (voice-doctrine lint, DRAFT/noindex gate, KV registration, build verification). Slash commands cannot invoke each other, so dispatch happens via `Read`-the-playbook-inline.

**Correctness via the internal mechanics. Ergonomics via this wrapper. Compounding via per-step commits.**

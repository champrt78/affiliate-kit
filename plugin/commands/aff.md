---
description: The single conversational entry point for affiliate-kit. Surveys portfolio state across MWC + DTP, computes posture, opens with ONE next-move proposal, walks through whatever flow fits — bottom-line writing, scaffolding, scouting, blocker unblocking, or state report. Plain language both ways. No flags.
---

# /aff

The one command Ray ever needs to type for affiliate-kit. `/aff` reads the portfolio state, figures out where Ray is in the lifecycle, opens with a single state-aware proposal, and walks him through whatever the next correct step is. Internally it reads internal-mechanic playbooks inline — Ray never needs to remember which.

The user never types flags. This command asks for what's needed and announces what's running so Ray can stop it if it picked wrong.

## Configuration (edit these to tune)

These values are referenced by name throughout the file — edit them HERE, not inline in templates.

| Name | Value | Used for |
|---|---|---|
| `MWC_CADENCE_TARGET` | `7 days` | Step 3 row #4 match condition; Step 4 hero-behind-cadence + ready-for-next-topic + where-are-we templates |
| `DTP_CADENCE_TARGET` | `18 days` | Step 3 row #5 match condition; Step 4 dp-behind-cadence + ready-for-next-topic + where-are-we templates |
| `URGENT_BLOCKER_REGEX` | `(?i)(need\|pending\|waiting\|awaiting\|TBD\|drop the\|blocked on)\W*.*(URL\|link\|image\|asin\|ASIN)` | Step 2.6 blocker detection |
| `AMBIGUITY_STRIKES` | `2` | Step 5 — re-ask twice on ambiguous response, then surface the full intent table |

To change a value: edit this block. Every reference in the file uses the name, not the literal value.

## How to run this

The user invoked `/aff` with no arguments. There is no flag interface — the conversation collects everything it needs.

### Step 1: Resolve the monorepo path

The affiliate-kit repo path detection:

1. If `./CLAUDE.md` exists and contains "Affiliate Kit" or "affiliate-sites" in the first ~20 lines, use cwd.
2. Otherwise, error per **On failure**.

### Step 2: Survey current state (scoped, not full-fat)

Read state signals in order. Be efficient — list filenames first, only read frontmatter, defer full body reads. **Use the Bash tool for shell commands**, not PowerShell, since this command must work cross-platform.

**Optimization rule:** If Step 2.6 (TODO Now-queue) produces a hit matching `URGENT_BLOCKER_REGEX`, posture #1 will fire and you can skip 2.1-2.5 (their state isn't needed). Survey 2.6 first when efficiency matters.

**MWC + DTP — full survey:**

For each of `sites/mywildlifecam/` and `sites/detailerpicks/`:

1. **Content inventory.** `Glob` `sites/<slug>/src/content/{reviews,buyers-guides}/*.md`. For each file, `Read` the frontmatter only (top of file through the closing `---`). Capture: `pubDate`, `lastUpdated`, the nested `bottomLine: {verdict, supporting}` map. Determine DRAFT status: a piece is DRAFT iff `bottomLine.verdict.trim() === ""` OR contains a placeholder string like `"_The Bottom Line is being written._"`. (YAML shape is a nested map, not a dotted scalar — descend into the `bottomLine` key.)
2. **Last-shipped.** Latest `pubDate` across shipped (non-DRAFT) pieces. Days since today.
3. **Cadence target.** MWC = `MWC_CADENCE_TARGET`. DTP = `DTP_CADENCE_TARGET`.
4. **Site-scoped TODOs.** Grep `docs/TODO.md` for occurrences of the site slug.
5. **Research-ready notes.** `Glob` `docs/research/*.md`. For each, `Read` its frontmatter and look for `target_slug:` (single slug) OR `target_slugs:` (list of slugs). For each named target, check whether `sites/<site>/src/content/{reviews,buyers-guides}/<target_slug>.md` exists. If no target exists, the research note is a candidate for `research-ready-to-scaffold`. **Research notes WITHOUT a `target_slug(s):` field are treated as "exploratory" and never flagged as ready-to-scaffold** — they require Ray to scope them first.

**Satellites — single metric on demand:**

For `sites/fussybean/`, `sites/starteraquarium/`, `sites/gameovergear/`: capture only `git log -1 --format=%cr -- sites/<slug>/` (most-recent touch). Do NOT walk content. Full survey ONLY if Ray asks ("what about fussybean?").

**Portfolio-level:**

6. **TODO Now-queue.** Read `docs/TODO.md` `## Now` section. Capture each line. Flag each that matches `URGENT_BLOCKER_REGEX`. The regex catches "Need a current product Amazon URL", "Need URL + image", "pending Ray's URL drop", "waiting on", "awaiting", "TBD URL", "blocked on", "drop the", and similar — broader than a closed phrase list.
7. **Recent commits.** `git log --since="3 days ago" --format='%h %ar %s'`. Captures session momentum.
8. **Today's commits count.** `git log --since="today 00:00" --format='%h'` piped through wc -l via the Bash tool.

Capture everything into a state snapshot. Preserve filenames, slugs, dates verbatim.

**Empty states are NOT errors.** Empty `docs/research/`, zero git commits today, zero TODOs — all valid states. Capture as zero/empty; continue.

### Step 3: Compute posture (first-match-wins)

Evaluate in this exact order. Once a posture matches, STOP — do not evaluate further. The order encodes leverage hierarchy (Ray's call 2026-05-23: urgent blockers always come before drafts because a 30-second URL drop unblocks future Google indexing forever).

| # | Posture | Match condition | Routes to |
|---|---|---|---|
| 1 | `urgent-blocker` | Step 2.6 found ≥1 TODO Now-queue item matching `URGENT_BLOCKER_REGEX` | Step 6.A |
| 2 | `draft-needs-bottom-line` | Any piece (MWC or DTP) has empty Bottom Line per Step 2.1 | Step 6.B |
| 3 | `research-ready-to-scaffold` | Step 2.5 produced ≥1 research note with a `target_slug:` whose piece doesn't exist yet | Step 6.C |
| 4 | `hero-behind-cadence` | MWC last-ship > `MWC_CADENCE_TARGET` ago AND no MWC piece in DRAFT | Step 6.D (scope: mwc) |
| 5 | `dp-behind-cadence` | DTP last-ship > `DTP_CADENCE_TARGET` ago AND no DTP piece in DRAFT AND ≥1 DTP piece shipped (non-DRAFT) | Step 6.D (scope: dp) |
| 6 | `ready-for-next-topic` | None of the above match | Step 6.D (scope: portfolio) |
| — | `where-are-we` | Reactive only — when user response in Step 5 is a state-query | Step 6.E |

**Note on the leverage-hiding gotcha:** posture #2 fires on a DRAFT in EITHER site, so if DTP is also behind cadence AND has a stuck draft, posture #2 wins and `dp-behind-cadence` never fires standalone. Step 4's `draft-needs-bottom-line` template therefore appends a "Plus DTP is behind cadence (N days vs target)" line when both conditions are true — see template below.

### Step 4: Open with ONE move + Y/N (verbatim templates)

Pick the matched posture and open with the corresponding template. Substitute the bracketed values from the state survey.

**`urgent-blocker`:**

> *"`/aff` — TODO Now-queue has a blocker that needs your input:*
> *  • `<task body, first 80 chars>`*
>
> *Want to drop the answer right now? (Or type 'later' to push past and do other work.)"*

If multiple urgent blockers, list up to 3 by bullet; ask Ray to pick one (e.g. "do #2"), say "all" (walk them all), or "later".

**`draft-needs-bottom-line`:**

> *"`/aff` — `<N>` piece(s) sitting at DRAFT with empty Bottom Line, blocking Google indexing.*
> *Highest-leverage piece: `<site>/<slug>` (`<piece title>`).*
> *`<If DTP is also behind cadence AND has the stuck draft: 'Plus DTP last shipped <N>d ago vs <DTP_CADENCE_TARGET> target.'>`*
>
> *Want to draft 3 verdict options for it now? (y/n / 'all' to walk through every draft / 'what else?' for the full board)"*

**`research-ready-to-scaffold`:**

> *"`/aff` — research notes for '`<title>`' (target: `<site>/<target_slug>`) are ready at `docs/research/<filename>.md`, but no piece scaffolded yet.*
>
> *Want to scaffold it now? (y/n / 'what else?')"*

**`hero-behind-cadence`:**

> *"`/aff` — MWC last shipped `<N>` days ago. Hero cadence target is `MWC_CADENCE_TARGET`.*
> *No in-flight draft. Time to start the next piece.*
>
> *Want me to scout MWC topics now? (y/n / 'I have a specific topic in mind' / 'what else?')"*

**`dp-behind-cadence`:**

> *"`/aff` — DTP last shipped `<N>` days ago. Cadence target is `DTP_CADENCE_TARGET`.*
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
  Shipped: <N>  |  DRAFT: <N>  |  Last shipped: <N>d ago (target MWC_CADENCE_TARGET — <on-cadence|behind>)
  Open TODOs: <N>  |  Research-ready: <N>
  <If any URL-drop blockers, list them>

DTP:
  Shipped: <N>  |  DRAFT: <N>  |  Last shipped: <N>d ago (target DTP_CADENCE_TARGET — <on-cadence|behind>)
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

User responds in plain language. Parse against this table. If nothing matches cleanly, re-ask with a short list of valid moves (track ambiguity strikes — see bottom of table).

| User says | Routes to |
|---|---|
| "yes" / "y" / "let's go" / "do it" / "go" / "sure" | Continue to the proposed posture's flow per Step 3's "Routes to" column |
| "no" / "n" / "skip" / "not that" | Re-evaluate. Offer next-best posture OR ask "what would you like to do instead?" |
| "what else?" / "show me the board" / "everything open" | Step 6.E (where-are-we state report, no dispatch) |
| "all" / "do all of them" | If posture is `draft-needs-bottom-line` → walk each DRAFT (Step 6.B). If `urgent-blocker` → walk each blocker (Step 6.A "all" branch). Otherwise → re-ask "all of what?" |
| "do #N" / "the second one" / numbered pick (multi-item postures only) | Pick that item, continue to the posture's flow |
| "let's do `<thing>`" / "actually I want to `<X>`" | Switch flow to the matching mechanic per Step 6. Re-survey first. |
| URL-like string / ASIN-like string (`https://...`, `amzn.to/...`, `B0XXXXXXXX`) / "the URL is `<X>`" / "answer is `<X>`" | If current posture is `urgent-blocker` → input to Step 6.A. Otherwise → ask "Is this for the current task, or do you want me to research this URL as a new topic?" |
| "where are we?" / "what's the status?" / "what's left?" | Step 6.E (where-are-we) |
| "I had a thought about `<X>`" / "capture this:" / "quick idea" | Tell Ray: *"Type `/aff-idea <text>` to capture it without breaking flow. Come back to `/aff` when you're done."* End politely. |
| "pause" / "stop" / "later" / "I'll come back" | Stop cleanly. Print: *"Stopped. Run `/aff` when you're ready — I'll re-survey from the current state."* |
| Ambiguous / multi-intent | Re-ask: *"Want me to <interpretation A> or <interpretation B>?"* Track strikes — after `AMBIGUITY_STRIKES` ambiguous responses, dump the full intent table and ask Ray to pick a row by name. |

### Step 6: Flow dispatch

Each posture routes to one of these flows. Dispatch means: `Read` the relevant playbook `.md` file inline, announce the dispatch in one line, and execute its steps in this same conversation turn. **Slash commands cannot invoke other slash commands** — every step of every flow happens inside `/aff`.

#### Step 6.A: Urgent-blocker unblock flow

For each blocker to handle (single by default, all matching blockers if Ray said "all"):

1. **Extract target file path from the TODO body.** First check the TODO body for an explicit `sites/<slug>/...md` path. If not present, Grep `sites/*/src/content/` for the bare filename or slug mentioned in the TODO. If neither resolves, ask Ray: *"Which file does this blocker apply to?"*
2. **Collect the answer (URL / ASIN / image source) from Ray** if not already pasted with his "yes" response. *"What's the URL/answer for `<task title>`?"*
3. **Confirm:** *"OK — applying `<answer>` to `<resolved file path>`. Confirm? (y/n)"*
4. **Apply the change.** Examples:
   - URL drop: update the relevant content file's `products[].affiliateUrl` (or `affiliate.amazon` for review pieces) + body mentions; register cloaker KV via `pwsh scripts/add-link.ps1` if the slug is new.
   - Image source: update `images.hero` or `products[].image`; verify the URL responds 200 (HEAD request via Bash `curl -I`).
5. **Run voice-lint** (`pwsh scripts/lint-voice.ps1 <piece>`) to verify.
6. **Run build** (`pnpm --filter <site> build`) to verify compilation succeeds. (Build verifies compilation, NOT the meta-robots tag — that's encoded in the source frontmatter.)
7. **Commit:** `fix(<site>): unblock <slug> — <one-line description>`.
8. **Push.**
9. If "all" mode and more blockers remain → loop to next blocker (jump to sub-step 1). Otherwise → loop back to Step 2 (re-survey).

#### Step 6.B: Bottom Line writing flow

For the proposed piece (or each piece if Ray said "all"):

1. **Announce:** *"Running `bottom-line-helper` under the hood now for `<site>/<slug>`."*
2. **`Read` `plugin/commands/bottom-line-helper.md`. Use Mode B** (entry-mode flexibility — pass the piece path as already-resolved context, skip its Step 1 input parsing).
3. **Print the 3 options.**
4. **Ask Ray:** *"Pick #1, #2, #3, or paste your own. (Or 'edit #2' if you want to tweak one.)"*
5. **Apply the chosen Bottom Line** to the piece's frontmatter (`bottomLine.verdict` + `bottomLine.supporting`) AND to the `## Bottom Line` body section.
6. **Run voice-lint** to verify.
7. **Run build** (`pnpm --filter <site> build`) to verify compilation. (Build verifies compilation; the noindex→index flip happens automatically because the DRAFT/noindex gate in the page template keys off `bottomLine.verdict.trim() === ""` — when verdict is non-empty, the template emits `<meta name="robots" content="index, follow">`.)
8. **Commit:** `feat(<site>): write Bottom Line for <slug>`.
9. **Push.**
10. If "all" mode AND more DRAFTs remain → loop to next DRAFT (sub-step 1).
11. Else → loop back to Step 2 (re-survey).

#### Step 6.C: Research-then-scaffold flow

1. **Announce:** *"Running `research-product` under the hood now for '<title>'."*
2. If research note doesn't exist yet: `Read` `plugin/commands/research-product.md`. **Use Mode B** (entry-mode flexibility — pass the topic + target site/type as context). Output lands at `docs/research/<date>-<slug>.md` with `target_slug:` + `target_site:` populated in the frontmatter.
3. If research note exists: skip step 2.
4. **Confirm:** *"Research is in (target: `<site>/<slug>`, type: `<review|buyers-guide>`). Ready to scaffold? (y/n / 'adjust')"* (Pull site/type/slug from the research note's frontmatter.)
5. **Announce:** *"Running `scaffold-piece` under the hood now."*
6. **`Read` `plugin/commands/scaffold-piece.md`. Use Mode B** (skip its Step 1 input parsing — pass the site/type/slug/product/brand/amazon_url/description directly from collected context).
7. Scaffolder writes the content file, registers KV via `add-link.ps1`, runs voice-lint, runs `pnpm --filter <site> build`. **Commit + push** as `feat(<site>): scaffold <slug> [DRAFT]`. Per Ray's call 2026-05-23: page goes live in DRAFT/noindex state — safe because the gate blocks Google, and committing makes the state durable across conversation crashes.
8. Print: *"Scaffolded as DRAFT. Bottom Line is empty — page is noindex'd. Want to write the Bottom Line now? (y/n / 'later')"*
9. If yes → Step 6.B. If no → loop back to Step 2.

#### Step 6.D: Scout flow

Mode selection by source posture:

- `hero-behind-cadence` → Mode B scoped to mwc (`/scout-topics --mwc` equivalent)
- `dp-behind-cadence` → Mode B scoped to dp (`/scout-topics --dp` equivalent)
- `ready-for-next-topic` → Mode A portfolio-wide (`/scout-topics` equivalent, no flags)

Steps:

1. **Announce:** *"Running `scout-topics` under the hood now (scope: `<mwc|dp|portfolio>`)."*
2. **`Read` `plugin/commands/scout-topics.md`. Use Mode B** (entry-mode flexibility — pass the scope as already-resolved context, skip its Step 1 flag parsing). Execute the matching Mode A or Mode B per the source posture.
3. **Print the ranked candidate list.**
4. **Ask Ray:** *"Pick one (e.g. 'go with #2' or paste a different topic). Or 'none for tonight' to bail."*
5. On pick → Step 6.C (research-then-scaffold).
6. On "none" → loop back to Step 2.

#### Step 6.E: Where-are-we report (folded /ops)

Print the full state survey output per Step 4's `where-are-we` template. Do NOT dispatch any flow. End with the keep-going-or-pause question. If Ray says "keep going" without specifying a flow, re-fire Step 3 (posture computation) and Step 4 (opener). **Why this exists as a separate flow rather than just `/ops`:** it inlines into the same `/aff` conversation so the next move is one Y/N away, not another slash command + scroll.

### Step 7: Announce dispatch on mechanic transitions

Every transition to a new internal mechanic (Step 6.A through 6.E) gets a one-line announcement:

> *"Running `<mechanic-name>` under the hood now."*

The initial Step 4 opener does NOT count as a transition — no announcement before Ray confirms with "yes." Don't repeat the announcement on every sub-iteration in multi-step flows ("all" mode walks N items; the announcement fires once at the start, not N times). Don't announce sub-steps inside the same mechanic.

### Step 8: Loop-back rule

When a flow from Step 6 completes (successful commit + push), automatically loop back to Step 2 and **re-read all state sources from scratch** — do NOT reuse the prior snapshot. The on-disk state has changed (a file got mutated, a commit landed) so derived signals like cadence-pressure and DRAFT count must be recomputed.

After re-survey, re-fire Step 3 + Step 4 with fresh state. Print one bridging line: *"OK, `<previous flow>` done. Re-checking the board..."* then the new opener.

**Mid-conversation flow switches (Step 5's "let's do `<X>` instead") also re-survey** — every flow entry re-reads its required state inputs before executing.

If the loop produces the SAME posture (e.g. another DRAFT still needs a Bottom Line), Ray gets a repeat opener — that's expected. "all" mode is the way to short-circuit this.

If the loop produces `ready-for-next-topic`, congratulate briefly and ask if Ray wants to keep going or stop.

### Step 9: Per-step durability rule

Multi-step flows (Step 6.A "all" mode, Step 6.B "all" mode, Step 6.C scaffold-then-bottom-line chain) commit + push between sub-steps. File-system state is the source of truth — if conversation crashes mid-flow, next `/aff` re-surveys and sees only the unfinished work.

Never silently batch multiple file-mutations into one commit. Every dispatched action is observable in `git log`.

**Build/lint failures mid-flow:** if voice-lint or build fails AFTER a file mutation, commit the file mutation anyway with a `[build-red — investigate]` suffix on the commit subject, push, then surface the error to Ray. This way re-running `/aff` doesn't double-write the same change.

## Pre-flight

Before any work:

1. The repo path must resolve per Step 1.
2. Step 2's state survey must complete. Empty directories, empty git logs, missing optional files (e.g. `docs/research/` not yet populated) are NOT errors — capture as empty and continue. Only fail if a CRITICAL file (CLAUDE.md, TODO.md, a referenced playbook .md) is missing per **On failure**.

## On failure

- **Path resolution fails.** *"Couldn't confirm this is the affiliate-kit repo. Run `/aff` from inside the `affiliate-sites` checkout."* Stop.
- **TODO.md missing.** *"`docs/TODO.md` is missing — required for blocker detection. Restore from git or recreate per global CLAUDE.md spec."* Stop.
- **An internal-mechanic playbook .md is missing.** *"`plugin/commands/<file>` is missing — the dispatched flow can't run. Restore from git."* Stop.
- **User cancels mid-conversation.** Stop gracefully. Don't leave half-written files uncommitted. Print: *"Stopped. Run `/aff` again whenever you're ready — I'll pick up from the file-system state."*
- **A build or voice-lint fails inside a dispatched flow.** See Step 9 — commit the mutation with `[build-red — investigate]` suffix, push, surface the error verbatim, halt the loop. Print: *"Build failed mid-flow. `<commit-hash>` has what landed so far. Fix and re-run `/aff`."*
- **State is ambiguous** (e.g. two postures could match). Apply Step 3's first-match-wins rule. If still ambiguous, ask Ray.

## What this command is NOT

- **NOT a replacement for the internal mechanics.** They still exist at `plugin/commands/{scout-topics,research-product,scaffold-piece,bottom-line-helper,ops}.md` and are invocable directly for debugging. Their `description:` starts with `Internal —`.
- **NOT magic.** It's a state-survey + posture-router + conversational dispatcher + loop-back layer.
- **NOT skipping preflight.** The underlying playbooks still run their checks.
- **NOT a chat companion.** This is a production tool. Stay on task.
- **NOT a menu.** The opener proposes ONE move. The full board appears only on "what else?" or "where are we?"

## How to extend this file

If you (Ray) want to add a new posture, change a cadence target, or add a new intent routing rule, here are the touchpoints — minimal edits, maximum impact:

### Add a new posture
1. **Configuration block** (top of file) — add any tunable values the posture depends on
2. **Step 2** — add the state signal sub-step that captures the data the posture needs (or note that an existing sub-step covers it)
3. **Step 3 posture table** — add a row in the right order (first-match-wins encodes leverage); pick a `Routes to` target
4. **Step 4** — add a verbatim opener template for the new posture
5. **Step 5 intent routing** — review whether any new intents are needed
6. **Step 6** — add a new flow sub-section (6.F, 6.G, ...) OR confirm an existing flow handles it

### Change a cadence target
Edit the **Configuration block** at the top. Every template + match condition references `MWC_CADENCE_TARGET` / `DTP_CADENCE_TARGET` by name. Single-source.

### Add a new internal mechanic (a 6th /aff-internal playbook)
1. Create `plugin/commands/<name>.md` with `description: Internal — ...` and Mode A / Mode B contracts (see scaffold-piece.md as the model — Mode A = direct slash with CLI args, Mode B = read inline by /aff with already-collected context)
2. Update Step 6 in this file with a new sub-section that Reads the new playbook
3. Update Step 3's posture-table `Routes to` column for any posture that should dispatch to it
4. Update `CLAUDE.md ## Slash command surface` to list the new mechanic in the Internal table
5. Update `plugin/README.md` similarly

### Add a new intent
Add a row to Step 5's intent routing table. If it needs new flow behavior, also update Step 6.

## The principle

Ray is the operator. He types `/aff` and gets walked through whatever the next correct step is, with the portfolio's current state baked into every suggestion. Internal mechanics encode the safety net (voice-doctrine lint, DRAFT/noindex gate, KV registration, build verification). Slash commands cannot invoke each other, so dispatch happens via `Read`-the-playbook-inline.

**Correctness via the internal mechanics. Ergonomics via this wrapper. Compounding via per-step commits.**

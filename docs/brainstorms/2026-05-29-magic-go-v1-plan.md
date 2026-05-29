# Magic Go v1 — Implementation Plan

**Date:** 2026-05-29
**Author:** Ray (via Claude, home PC session)
**Status:** Plan for review — NO code written yet. Reviewed before any build.
**Parent doc:** `docs/brainstorms/2026-05-28-magic-go-vision.md` (the north star — the 6-item backlog + the Magic Go vision). This plan implements **Item 5 only**, deliberately decoupled from the deferred prerequisites.

---

## Why this doc exists

The vision doc frames Magic Go as the endpoint of a 6-item chain where Items 1–4 are hard prerequisites. This plan makes a scoped bet: **Item 5 can ship against the CURRENT template + Amazon-only links + flat IA, today, without waiting on Items 1–4.** The vision's "refuse-to-run unless Items 1–4 complete" rule was written assuming Magic Go needs multi-network routing and pillar IA to produce good drafts. It doesn't. The GardePro E5 chain (scout → research → scaffold → lint → build, shipped LIVE 2026-05-23, `docs/sessions/Session_2026-05-23.md`) proved the chain end-to-end with exactly the current mechanics. Magic Go v1 is that proven chain, run N times, with quarantine + queue render + resumability bolted on.

The only net-new build is the **orchestration layer**. Everything it orchestrates already exists and works.

---

## 1. v1 scope statement + non-goals

### In scope

`/aff magic-go <N>` (default `N=25`) runs an autonomous, resumable chain that, for each allocated slot across every **content-ready** site:

1. Scouts a topic (existing `scout-topics` mechanic).
2. Researches the pick (existing `research-product` mechanic).
3. Scaffolds the piece into the comparison-and-fit framework with `## Bottom Line` left as the DRAFT placeholder (existing `new-review.ps1` / `buyers-guide.ps1` + `add-link.ps1`).
4. **Fills the body** (the step currently done manually by pasting `<slug>.prompt.md` into Claude — see §3.4, this is the one genuinely new judgment responsibility).
5. Runs the full safety net: `lint-voice.ps1`, `lint-product-images.ps1`, `lint-affiliate-tags.ps1`, `audit-product-images.ps1`, `pnpm --filter <site> build`.
6. Quarantines any piece that fails a lint/audit/build into a `failures/` queue with the error inline; the run continues.
7. Renders `dist/magic-go/queue.html` from the run manifest — every DRAFT with title, site, product, 3 AI-drafted Bottom Line options, link to the full DRAFT file.
8. Notifies Ray ("queue ready: N drafts") and opens the queue page.

Then Ray writes Bottom Lines in the morning and runs `/aff publish-batch` to deploy the whole batch in one push.

### Non-goals (deferred — explicitly NOT in v1)

These are from the vision doc and stay parked. Magic Go v1 is designed so it does NOT depend on any of them:

- **Item 1 — multi-network commission routing.** v1 uses Amazon-only links via the existing `add-link.ps1` (`-Merchant amazon`). Link work is parked behind the 5 Open Items + network-approval question (no default). Magic Go does not block on it.
- **Item 2 — generic disclosure.** Footer stays as-is. Not touched.
- **Item 3 — pillar IA.** Pieces land in the **current flat structure** (`/reviews/`, `/buyers-guides/`). The scaffolder does not slot into pillars. **Consequence for §2: the readiness gate must NOT require `categoryPillars`** — that is an Item-3 artifact, and requiring it would reject MWC (see §2.3).
- **Item 4 — minimalist homepage.** Homepage regeneration is whatever Astro already does at build. No template redesign.
- **Item 6 — dashboard / revenue roll-up.** No `$$` layer. `/ops` unchanged.

### The relationship to the vision's "refuse-to-run" rule

The vision said: refuse to run for any site missing Items 1–4. **This plan overrides that for v1** with Ray's explicit framing ("v1 runs only against content-ready sites; not hardcoded to MWC+DTP; per-site readiness gate"). The gate (§2) is the *content-readiness* gate, NOT the Items-1–4 gate. When Items 1–4 ship later, the gate gets stricter; v1 keeps it minimal.

---

## 2. Per-site readiness gate

### 2.1 Purpose

Magic Go iterates over `sites/*/` and runs ONLY against sites that pass the readiness gate. Sites that fail are **skipped with a clear note** in the run summary (never silently dropped, never error the whole run). Today MWC + DTP pass; FB / SA / GOG fail (no content templates wired yet); `askbigchew` is out of scope entirely (different repo, Next.js — see `CLAUDE.md`).

### 2.2 The exact check

A site at `sites/<slug>/` is **content-ready** iff ALL of these hold:

| # | Check | How |
|---|---|---|
| R1 | Site config present + parseable | `sites/<slug>/src/data/site-config.json` exists and `ConvertFrom-Json` succeeds |
| R2 | Config has the fields scaffold + research consume | niche (any shape — see §2.3), reader segments (any shape), feature axes (any shape) all resolvable to non-empty |
| R3 | Content collections wired | `sites/<slug>/src/content/config.ts` exists and defines BOTH `reviews` and `buyers-guides` collections with `bottomLine` in each schema |
| R4 | Page templates present | `sites/<slug>/src/pages/reviews/[...slug].astro` AND `sites/<slug>/src/pages/buyers-guides/[...slug].astro` both exist |
| R5 | DRAFT/noindex gate live in the templates | the template (or its shared component) keys `robots` off `bottomLine.verdict` — grep for `noindex` + `bottomLine` co-occurrence in the page template or `packages/shared-ui/src/components/{ReviewArticle,BottomLine}.astro` |

**Note: `categoryPillars` is deliberately NOT a gate check.** It exists on DTP's config but NOT on MWC's (`sites/mywildlifecam/src/data/site-config.json` has `featureAxes` but no `categoryPillars`). Requiring it would reject the hero site. It is an Item-3 (pillar IA) artifact and is deferred.

### 2.3 The schema-divergence gotcha (load-bearing)

**The two content-ready sites have DIFFERENT `site-config.json` shapes.** This is the single biggest correctness trap in the gate and the scaffold-context extraction:

- **MWC (flat):** `niche` is a string; segments are top-level arrays `primarySegments` / `secondarySegments` / `excludedSegments`; `featureAxes` is a flat array of strings. No `categoryPillars`.
- **DTP (nested):** `site.slug` / `site.name`; `niche.vertical` + `niche.subcategory`; `readerSegments.primary` / `.secondary` / `.excluded`; `featureAxes.default` is an array of `{name, weight, description}` objects. HAS `categoryPillars`.

The existing scaffolders (`new-review.ps1`, `buyers-guide.ps1`) read `$siteConfig.primarySegments`, `$siteConfig.niche`, `$siteConfig.brandTone` directly — i.e. they assume the **flat (MWC)** shape. For DTP those reads return `$null` and the prompt file falls back to `(none specified)`. **This already silently degrades on DTP today.** The readiness gate's R2 check and the new scaffold-context extractor MUST normalize both shapes via a small adapter (try flat key, then nested key). Recommended: a shared `Get-SiteConfigField` helper (PowerShell function) that resolves `niche`, `segments`, `axes` from either shape and is reused by the gate + the runner.

> **Open question O1 (for Ray):** Do we (a) write a config-shape adapter that tolerates both, or (b) normalize DTP's `site-config.json` to the flat MWC shape as a one-time migration so everything downstream is uniform? Adapter is less invasive; migration is cleaner long-term. Recommend (a) for v1 to avoid touching shipped site config mid-build, then (b) as cleanup later.

### 2.4 Where the gate lives

A standalone script: **`scripts/magic-go-readiness.ps1`**.

- Input: optional `-Site <slug>` (defaults to all of `sites/*` except `askbigchew` if it ever appears).
- Output: structured result per site — `{ slug, ready: bool, failed_checks: [R1..R5], notes: string }`. Emits JSON to stdout (consumed by the runner) and a human-readable table when run standalone.
- Exit 0 always (readiness is data, not an error) unless a setup precondition is broken.

Rationale for a script (not inline in `magic-go.md`): the gate is deterministic, testable in isolation, and reused by both the runner AND the `/aff` posture computation (so `/aff` can show "Magic Go ready: MWC, DTP; skipping FB/SA/GOG — no content templates"). Inline-in-playbook logic can't be unit-tested or reused by aff.md's Step 2 survey cleanly.

---

## 3. The orchestrator / chain runner

### 3.1 The dispatch constraint and the chosen model

**Constraint:** slash commands cannot invoke other slash commands. The existing mechanics (`scout-topics`, `research-product`, `scaffold-piece`, `bottom-line-helper`) are markdown playbooks that `/aff` executes by **reading them inline** and running their steps in the same conversation turn (aff.md Step 6).

**The steps split cleanly into two classes:**

- **Judgment steps that REQUIRE Claude (cannot be a script):** topic pick (scout ranking), research synthesis, **body-fill** (expanding the scaffold prose), and the 3 Bottom Line option drafts. These are model work.
- **Deterministic steps that SHOULD be scripts:** readiness gate, allocation math, the per-piece loop + manifest checkpointing, the scaffolders + KV write, all four lints/audit, build, quarantine move, queue render, per-piece commit.

### 3.2 Chosen model: supervised-resumable hybrid (a playbook + helper scripts)

**Magic Go v1 is a new internal-mechanic playbook — `plugin/commands/magic-go.md` — that `/aff` reads inline and drives, calling helper PowerShell scripts for every mechanical phase, checkpointing to a run manifest after each phase.**

Concretely:

- `/aff` (under `magic-go-ready` posture, §7) Reads `plugin/commands/magic-go.md` inline and executes it in-conversation. This is the SAME dispatch model the existing chain already uses — no new capability needed.
- For each allocated slot, the playbook drives the existing mechanics by reading THEM inline too (scout → research → scaffold → body-fill → bottom-line-helper), exactly as aff.md Step 6.C already chains research→scaffold. The judgment steps run as Claude; the mechanical steps call scripts.
- After every phase of every piece, the playbook writes the piece's status to the **run manifest** (§8) and commits. A crash resumes from the manifest.

**Why this over a fully-headless script:** A "PowerShell script shells out to `claude -p` for each judgment step, runs unattended overnight with zero human" model is what "autonomous overnight" literally implies. But:

1. Its quality on *unsupervised* research + body-fill is **unproven** — the GardePro proof had Ray in the loop at the pick + verdict moments.
2. 25 pieces × 3 background research jobs at 5–10 min each = **hours of wall-clock**, much of it waiting on Firecrawl/last30days/watch. The per-piece-checkpointed loop handles this gracefully (resume after any interruption); a monolithic headless script that dies at piece 18 loses less only if it too checkpoints — at which point it's the same architecture minus the supervision safety.
3. Body-fill is currently MANUAL (Ray pastes `<slug>.prompt.md` into Claude). Automating it is the one new judgment responsibility and a real quality risk worth keeping supervised in v1.

> **Open question O2 (for Ray):** v1 = supervised-resumable (Claude drives the loop in a long session, you can watch/interrupt, it resumes on crash) vs. fully-headless-unattended (a script runs the whole thing while you sleep, no Claude session open). Recommend supervised-resumable for v1 to prove body-fill quality, then graduate to headless once the manifest + quality are trusted. The manifest design (§8) makes headless a later drop-in, not a rewrite.

### 3.3 Helper scripts the runner calls

| Script | Status | Phase |
|---|---|---|
| `scripts/magic-go-readiness.ps1` | **NEW** (§2) | gate |
| `scripts/magic-go-allocate.ps1` | **NEW** (§3.5) | allocation |
| `scripts/new-review.ps1` / `scripts/buyers-guide.ps1` | exists | scaffold |
| `scripts/add-link.ps1` | exists | KV (Amazon-only, `-Merchant amazon`) |
| `scripts/lint-voice.ps1` | exists | safety net |
| `scripts/lint-product-images.ps1` | exists | safety net |
| `scripts/lint-affiliate-tags.ps1` | exists | safety net |
| `scripts/audit-product-images.ps1` | exists (slow; Canopy key) | safety net |
| `scripts/magic-go-queue.ps1` | **NEW** (§5) | render |
| `scripts/magic-go-run.ps1` | **NEW** (optional thin wrapper — see below) | loop/manifest |

`scripts/magic-go-run.ps1` is an optional thin driver that owns manifest creation, per-piece state transitions, quarantine moves, and per-piece commits — the deterministic spine. The playbook calls it phase-by-phase. (If we keep the loop entirely in the playbook, this collapses into manifest helper functions; recommend extracting the manifest read/write/transition logic into a script so both the playbook AND a future headless mode share it.)

### 3.4 Body-fill — the new judgment step, spelled out

Today: scaffolder writes `<slug>.md` (DRAFT) + `sites/<slug>/prompts/<slug>.prompt.md` (the AI-drafting prompt with voice doctrine + reader segments baked in). Ray manually pastes the prompt into Claude, reviews output, and the body gets filled.

Magic Go automates this: after scaffolding, the playbook **reads `<slug>.prompt.md`** (it already contains everything: voice doctrine forbidden phrases, preferred framings, reader segments, the scaffold to fill, and the explicit instruction "the `## Bottom Line` section STAYS as the placeholder"), drafts the body **in the same turn**, and writes it back into `<slug>.md` — leaving `## Bottom Line` as the placeholder. Then runs voice-lint as the back-stop. The prompt file already enforces the Bottom Line gate in its own instructions, which is a second guard against the model accidentally writing a verdict.

### 3.5 Allocation across passing sites (cadence-deficit)

Per the vision: distribute N by cadence-deficit (sites furthest behind their quarterly target get more). `scripts/magic-go-allocate.ps1`:

1. For each passing site, compute `days_since_last_ship` (latest `pubDate` among non-DRAFT pieces; aff.md Step 2.1 already derives DRAFT status from `bottomLine.verdict`).
2. Compute `deficit = max(0, days_since_last_ship - cadence_target)` where `cadence_target` = MWC 7d, DTP 18d, satellites 180d (same constants aff.md uses; pull from a shared source).
3. Allocate N proportional to deficit, with a floor of `ceil(N / passing_site_count / 2)` so no passing site gets zero, and rounding to integers that sum to N.

**Worked example (N=25, MWC + DTP both pass, MWC 10d-since vs 7d target → deficit 3, DTP 40d-since vs 18d target → deficit 22):** raw split ≈ MWC 3 / DTP 22 → proportional 25 × (3/25)=3, 25 × (22/25)=22. With a floor, MWC bumps up slightly. The point: when both sites are roughly on-cadence the split tends toward even; when one is badly behind it gets the bulk. **At N=25 across only two sites that's ~12–13 each in the even case** — which is why §10 tests at N=2 first.

> **Open question O3 (for Ray):** Confirm cadence-deficit allocation (recommended, matches the vision) vs. even split. And: should `magic-go <N>` accept a per-site override (e.g. `magic-go 10 --mwc-only`) for v1, or is portfolio-auto-distribute enough? Recommend auto-distribute only for v1; add overrides later.

### 3.6 Per-piece phase order (the chain)

For each allocated slot:

1. **scout** (Claude, reads `scout-topics.md` inline, scope = the site) → pick a topic. Manifest: `scouted`.
2. **research** (Claude, reads `research-product.md` Mode B) → research note at `docs/research/<date>-<slug>.md` with `target_site` + `target_slug`. Manifest: `researched`.
3. **scaffold** (script: `new-review.ps1` or `buyers-guide.ps1` + `add-link.ps1` Amazon-only) → DRAFT `.md` + `.prompt.md` + KV. Manifest: `scaffolded`.
4. **body-fill** (Claude, §3.4) → body written, Bottom Line stays placeholder. Manifest: `body-filled`.
5. **safety net** (scripts: voice → images → tags → audit → build). On ANY failure → quarantine (§4), manifest `quarantined`, continue to next slot. On pass → manifest `ready`.
6. **commit** (script: `feat(<site>): magic-go scaffold <slug> [DRAFT]`) + push. Manifest: `committed`.

Per-piece commit + push = aff.md Step 9 durability satisfied. A crash leaves only the in-flight piece unfinished; the next run re-reads the manifest and resumes.

---

## 4. Failure quarantine

### Structure

A quarantined piece is one that fails any safety-net check (voice lint finding, image lint failure, audit failure, or build error). The run does NOT stop — it records the failure and moves on.

- **Quarantine record** lives in the run manifest (§8): the piece entry gets `status: "quarantined"`, `failed_at: <phase>`, `error: <verbatim error text>`.
- **The scaffolded files stay in place** (committed in DRAFT/noindex state — safe, because the empty Bottom Line keeps it out of Google's index regardless). We do NOT move the `.md` out of `src/content/` — doing so would break the Astro build for the rest of the run. Instead the manifest flags it, and the queue render (§5) lists quarantined pieces in a separate "Needs attention" section with the inline error.

> **Design note:** the vision said "pieces go to a `failures/` queue." Interpreting `failures/` as a *logical* queue (manifest status + a queue-render section) rather than a *physical* directory move. Physically moving a DRAFT `.md` out of `src/content/` mid-run would red the build for every subsequent piece's `pnpm build` check. If Ray prefers a physical `docs/magic-go/failures/<date>/` copy of the failing piece + error log for offline triage, that's a cheap add — see O4.

> **Open question O4 (for Ray):** Quarantine as manifest-flag + queue-section (recommended — keeps build green) vs. physical move to a `failures/` dir (matches the vision's literal wording but risks breaking subsequent builds). Recommend logical quarantine; optionally also drop a `docs/magic-go/runs/<runid>/failures/<slug>.error.txt` for offline reading.

---

## 5. The queue render — `dist/magic-go/queue.html`

### What it shows

A single static HTML page, generated at the end of the run by `scripts/magic-go-queue.ps1`, listing every piece the run touched:

- **Ready section** (status `ready`/`committed`): for each piece — title, site, product name, piece type, a link to the DRAFT file (`file://` path to `sites/<slug>/src/content/<type>/<slug>.md` so Ray can open it), and the **3 AI-drafted Bottom Line options + supporting paragraph**.
- **Needs-attention section** (status `quarantined`): title, site, the failed phase, and the verbatim error inline.

### Where the data comes from

- Piece metadata (title, site, product, slug, type, file path): the **run manifest** (§8).
- The 3 Bottom Line options + supporting paragraph: generated during the run by reading `bottom-line-helper.md` Mode B for each `ready` piece (Claude judgment step), and **stored into the manifest** under the piece's `bottom_line_options` field. The queue renderer reads them from the manifest — it does NOT re-invoke Claude (the renderer is a dumb PowerShell template-filler).

**Critical:** `dist/` is a build output and is typically gitignored. So `dist/magic-go/queue.html` is a **regenerable view, NOT the source of truth.** The manifest (committed, outside `dist/`) is the source of truth. `queue.html` can be regenerated from the manifest at any time via `scripts/magic-go-queue.ps1`. This satisfies durability cleanly — losing `dist/` loses nothing.

---

## 6. Notification

Keep it simple for v1:

- At run end, the playbook prints `Queue ready: <N> drafts (<R> ready, <Q> quarantined). Open the queue?` and **`Start-Process`-opens `dist/magic-go/queue.html`** in the default browser (matches Ray's "open files, don't point at them" preference — memory `feedback_open_files_dont_point_at_them.md`).
- No push-notification infra in v1. (A push via ntfy / Pushover / a Cloudflare Worker is a clean later add once Ray wants the truly-overnight headless mode of O2 — at that point a "run finished" push matters because no session is open. Note it; don't build it.)

---

## 7. `/aff` integration

Ray gave explicit permission to "tear apart `/aff` and put it back together as needed." The five new postures fit the existing add-a-posture extension points (aff.md "How to extend this file"). The ordering is the delicate part.

### 7.1 New postures + first-match-wins ordering

The current first-match order (aff.md Step 3) is: 1 `urgent-blocker` → 2 `draft-needs-bottom-line` → 3 `research-ready-to-scaffold` → 4 `hero-behind-cadence` → 5 `dp-behind-cadence` → 6 `ready-for-next-topic`.

**The collision to resolve (analog of aff.md's existing "leverage-hiding gotcha"):** A finished Magic Go run = N DRAFTs with empty Bottom Lines. That is EXACTLY the match condition for posture #2 `draft-needs-bottom-line`. If we don't intercept it, #2 swallows the Magic Go queue and Ray gets the generic one-at-a-time Bottom Line opener instead of the batch queue opener. So the Magic-Go-aware postures that key off run-manifest state MUST sit ABOVE #2.

Proposed new order (manifest-driven postures inserted high; first-match-wins):

| New # | Posture | Trigger (manifest-driven unless noted) | Position rationale | Routes to |
|---|---|---|---|---|
| 1 | `urgent-blocker` | (unchanged) | unchanged — a URL drop is still highest leverage | 6.A |
| **2** | `magic-go-running` | run manifest exists with status `in-progress` (and not stale-abandoned) | a live/interrupted run must be resumed or reported before anything else | **6.F** |
| **3** | `magic-go-failed-pieces` | manifest `complete` AND ≥1 piece `quarantined` AND not yet triaged | surface failures before the verdict queue so Ray sees what's broken | **6.H** |
| **4** | `bottom-line-queue-pending` | manifest `complete` AND ≥1 `ready` piece without a written verdict | **must beat old #2** or `draft-needs-bottom-line` swallows it | **6.G** |
| **5** | `publish-batch-ready` | manifest `complete` AND ALL `ready` pieces now have non-empty verdicts | the deploy moment, once verdicts are in | **6.I** |
| 6 | `draft-needs-bottom-line` | (old #2) any DRAFT with empty Bottom Line **not part of an active manifest** | now scoped to exclude Magic-Go-managed drafts | 6.B |
| 7 | `research-ready-to-scaffold` | (old #3) | unchanged | 6.C |
| 8 | `magic-go-ready` | NO active/complete manifest AND ≥1 site passes readiness gate (§2) AND portfolio is at/behind cadence | the "click Magic Go" CTA — low priority because it's a fresh-start action, only surfaced when nothing else is pending | **6.J** |
| 9 | `hero-behind-cadence` | (old #4) | unchanged | 6.D |
| 10 | `dp-behind-cadence` | (old #5) | unchanged | 6.D |
| 11 | `ready-for-next-topic` | (old #6) | unchanged | 6.D |

**Key ordering calls:**
- `bottom-line-queue-pending` (#4) sits ABOVE `draft-needs-bottom-line` (#6) — resolves the swallow. To make #6 correct, its match condition gains an exclusion: a DRAFT that belongs to an active/complete manifest does NOT count for #6 (it's the queue's job).
- `magic-go-ready` (#8) sits LOW — it's a "start something new" CTA; anything pending (verdicts, failures, blockers) outranks starting a fresh run.

### 7.2 Step 2 survey addition

Add **Step 2.9: Magic Go manifest scan.** Glob `docs/magic-go/runs/*/manifest.json` (or the chosen manifest path, §8), read the most-recent run's manifest, capture: run status (`in-progress` / `complete`), counts (`ready` / `quarantined` / `verdict-written`), and the run id. Also call `scripts/magic-go-readiness.ps1` to capture which sites pass. This feeds postures 2–5 + 8.

### 7.3 Step 4 openers (verbatim templates)

**`magic-go-running`:**
> *"`/aff` — a Magic Go run (`<runid>`) is in progress: `<done>`/`<N>` pieces complete, `<Q>` quarantined. Resume it now? (y/n / 'status' for the per-piece board)"*

**`magic-go-failed-pieces`:**
> *"`/aff` — last Magic Go run finished with `<Q>` quarantined piece(s):*
> *  • `<site>/<slug>` — failed `<phase>`: `<error first 80 chars>`*
> *Want to walk the failures (fix or discard each)? (y/n / 'skip to the queue')"*

**`bottom-line-queue-pending`:**
> *"`/aff` — Magic Go queue ready: `<R>` DRAFTs waiting on your Bottom Lines. Open the queue and start clearing them? (y/n / 'all' to walk every piece in order)"*

**`publish-batch-ready`:**
> *"`/aff` — all `<R>` queued pieces have verdicts. Ready to publish the batch (flip to indexable + one deploy)? (y/n)"*

**`magic-go-ready`:**
> *"`/aff` — caught up, and `<sites>` pass the content-readiness gate (skipping `<skipped>`). Want to kick off a Magic Go run? Default 25 across the passing sites by cadence-deficit. (y / 'magic-go <N>' for a custom count / 'n')"*

### 7.4 Step 6 flows

**6.F — `magic-go-running` resume.** Read `plugin/commands/magic-go.md` inline. Read the manifest, find the first non-terminal piece, resume the chain from its last-completed phase (§3.6). Per-piece commit continues. On completion → loop back to Step 2 (which will now surface `bottom-line-queue-pending`).

**6.G — `bottom-line-queue-pending`.** `Start-Process` the queue HTML. Then walk pieces: for each `ready` piece without a verdict, present its 3 stored options (from the manifest, NOT re-drafted), Ray picks/edits/writes his own, apply to `bottomLine.verdict` + `bottomLine.supporting` + the `## Bottom Line` body section, mark `verdict-written` in the manifest, commit `feat(<site>): write Bottom Line for <slug>`. This reuses the existing 6.B flow's apply+commit logic almost verbatim — the only difference is the source of the 3 options (manifest, not a fresh `bottom-line-helper` call) and the manifest status update. Loop until all verdicts written → Step 2 surfaces `publish-batch-ready`.

**6.H — `magic-go-failed-pieces`.** For each quarantined piece: show the verbatim error, offer fix (re-run the failed phase + re-lint) or discard (delete the DRAFT `.md` + remove its KV entry + mark `discarded` in manifest). Commit each resolution. Loop → Step 2.

**6.I — `publish-batch-ready` / `/aff publish-batch`.** This is the batch deploy. **Important accuracy point: there is NO manual noindex toggle.** The page templates emit `index, follow` automatically once `bottomLine.verdict` is non-empty (confirmed in `sites/mywildlifecam/src/pages/buyers-guides/[...slug].astro:66` and `packages/shared-ui/src/components/ReviewArticle.astro:55–58`). So `publish-batch`'s real job is: (1) verify every queued piece has a non-empty verdict, (2) run a final `pnpm build` across affected sites to confirm green, (3) **one commit + one `git push`** → Cloudflare auto-deploys all sites in parallel (`.github/workflows/deploy.yml`). The "remove noindex" framing from the vision is satisfied passively by the verdict-write; publish-batch is fundamentally a *batched deploy*, not a metadata flip. Mark the manifest `published`, archive it, regenerate/clear the queue page.

**6.J — `magic-go-ready` kickoff.** Read `plugin/commands/magic-go.md` inline. Run readiness gate → allocate (§3.5) → confirm the per-site split with Ray ("25 = MWC 12, DTP 13 — go?") → create the run manifest (status `in-progress`) → enter the per-piece loop (§3.6).

### 7.5 New internal mechanic registration

`plugin/commands/magic-go.md` is a NEW internal mechanic. Per `CLAUDE.md`'s "How to extend" checklist: its `description:` starts with `Internal —`, it's listed in `CLAUDE.md`'s Internal-command table + `plugin/README.md`, and `/aff` reads it inline. User-facing surface stays `/aff` + `/aff-idea` + the two `/aff magic-go <N>` / `/aff publish-batch` sub-invocations (which are `/aff` arguments, not new top-level commands).

---

## 8. State / durability

### 8.1 The run manifest is the source of truth

Per aff.md Step 9: file-system state is the source of truth; per-piece commits make progress durable across conversation crashes. Magic Go's durable state is **the run manifest**, committed to git, outside `dist/`.

**Path:** `docs/magic-go/runs/<runid>/manifest.json` where `<runid>` = `<YYYY-MM-DD>-<HHMM>` (or a short ulid). One directory per run; the directory also holds optional `failures/<slug>.error.txt` (O4) and is the natural archive location.

**Manifest shape (illustrative):**
```jsonc
{
  "runid": "2026-05-29-0230",
  "status": "in-progress",          // in-progress | complete | published
  "requested_n": 25,
  "allocation": { "mywildlifecam": 12, "detailerpicks": 13 },
  "started": "2026-05-29T02:30:00Z",
  "pieces": [
    {
      "slug": "moultrie-edge-2-pro-review",
      "site": "mywildlifecam",
      "type": "review",
      "title": "Moultrie Edge 2 Pro Review",
      "product": "Moultrie Edge 2 Pro",
      "status": "ready",            // scouted|researched|scaffolded|body-filled|ready|quarantined|verdict-written|discarded|committed
      "research_note": "docs/research/2026-05-29-moultrie-edge-2-pro.md",
      "content_path": "sites/mywildlifecam/src/content/reviews/moultrie-edge-2-pro-review.md",
      "bottom_line_options": ["...A...", "...B...", "...C..."],
      "supporting": "...",
      "verdict_written": false,
      "failed_at": null,
      "error": null,
      "last_commit": "abc1234"
    }
  ]
}
```

### 8.2 Crash recovery

- Every phase transition writes the manifest + commits. A crash mid-run leaves the manifest with the last durable state.
- Next `/aff` → Step 2.9 reads the manifest → posture `magic-go-running` (§7.1 #2) fires → 6.F resumes from the first non-terminal piece.
- Because the scaffolded DRAFTs are committed in noindex state, a crash never leaks an un-gated page to Google.
- The queue HTML (`dist/`, gitignored) is disposable — regenerated from the manifest by `scripts/magic-go-queue.ps1` any time.

### 8.3 Stale-run handling

If a manifest is `in-progress` but its `started` timestamp is, say, >48h old with no recent commits, treat it as abandoned: `magic-go-running` opener offers "resume or abandon (archive as-is)." Prevents a dead run from blocking the posture table forever.

---

## 9. Build sequence (ordered, reviewable)

Each step is independently committable and testable. Do NOT start a step before the prior one is green.

1. **`scripts/magic-go-readiness.ps1`** + the `Get-SiteConfigField` two-shape adapter (§2.3). Test: prints MWC + DTP ready, FB/SA/GOG skipped-with-reason. *(Resolves O1 to (a) for now.)*
2. **`scripts/magic-go-allocate.ps1`** + shared cadence constants. Test: N=25 over MWC+DTP returns a split summing to 25; worked example (§3.5) matches.
3. **Manifest helpers** (`scripts/magic-go-run.ps1` or a lib): create/read/transition/commit. Test: round-trip a manifest, simulate a phase transition.
4. **`scripts/magic-go-queue.ps1`** — render `dist/magic-go/queue.html` from a hand-written sample manifest (ready + quarantined sections). Test: opens in browser, links resolve.
5. **`plugin/commands/magic-go.md`** — the playbook that chains the existing mechanics + calls scripts 1–4, with per-piece checkpointing + body-fill (§3.4). This is where scout/research/scaffold/body-fill/bottom-line-helper get wired inline.
6. **`/aff` integration** — Step 2.9 survey add; the 5 new postures + reorder (§7.1); the #6 exclusion on `draft-needs-bottom-line`; Step 4 openers; Step 6 flows F/G/H/I/J. Register the mechanic in `CLAUDE.md` + `plugin/README.md`.
7. **Quarantine + failures wiring** (§4) into the playbook + queue render.
8. **`publish-batch`** flow (6.I) — final build + single push + manifest archive.
9. **Docs:** session log + PROJECT_STATE milestone when v1 lands.

---

## 10. Test plan

Validate on small N before trusting `magic-go 25`.

1. **Readiness gate unit test.** Run `scripts/magic-go-readiness.ps1` standalone. Assert: MWC ready, DTP ready (proves the two-shape adapter works — this is the highest-risk gotcha, §2.3), FB/SA/GOG skipped with a clear reason. A passing DTP here is the proof the adapter handles the nested shape.
2. **Allocation unit test.** `scripts/magic-go-allocate.ps1 -N 2` over MWC+DTP → split sums to 2; `-N 25` → sums to 25, matches the worked example.
3. **Happy-path `magic-go 2`.** One MWC + one DTP slot. Walk the full chain. Assert: 2 DRAFTs committed in noindex state, manifest `complete` with 2 `ready`, queue HTML renders both with 3 Bottom Line options each, KV entries written, all lints + build green. Then `/aff` → confirm `bottom-line-queue-pending` fires (NOT `draft-needs-bottom-line` — this proves the posture-ordering fix, §7.1).
4. **Forced-quarantine test.** Run `magic-go 2` but seed one piece with a known-bad image URL (or a voice-lint trip word) so a safety-net check fails. Assert: that piece is `quarantined` with the verbatim error in the manifest + queue's needs-attention section; the OTHER piece completes; the run does NOT abort. *(Quarantine is untested by the happy path — this is the only way to exercise it.)*
5. **Crash-and-resume test.** Start `magic-go 2`, kill the session after the first piece's scaffold commit (before body-fill). Re-run `/aff`. Assert: `magic-go-running` posture fires, 6.F resumes from the unfinished piece (does NOT re-scaffold the completed one), run finishes correctly.
6. **End-to-end verdict + publish.** From a `complete` 2-piece run: walk `bottom-line-queue-pending` (write 2 verdicts), confirm `publish-batch-ready` fires, run `publish-batch`, confirm one push → both pages go `index, follow` on next deploy (verify the rendered `<meta robots>` post-deploy).
7. Only after 1–6 are green: trust `magic-go 25`.

---

## 11. Open questions for Ray

### Decisions LOCKED (2026-05-28, Ray)

- **O2 — autonomy: SUPERVISED-FIRST, then headless.** v1 first run is supervised at small N (`magic-go 2`); Ray watches the two auto-written bodies. If quality holds, flip the same manifest-driven machinery to fully-headless for `magic-go 25` overnight. Headless is the end state; supervised is the proof gate, not a permanent mode. Ray's framing: "do 2 I watch then we let it rip" + "when I come back to the PC I can approve, edit, and/or write the bottom line."
- **O1 — config shape: ADAPTER (a).** Write `Get-SiteConfigField` two-shape adapter; do NOT migrate DTP mid-build. (Note: the SEO research brief, `2026-05-29` agent run, recommends adopting DTP's nested shape as canonical + migrating MWC up to it as a SEPARATE framework-rebuild track. That migration is deferred to the SEO/bootstrap track; Magic Go v1 uses the adapter so it isn't blocked.)
- **O3 — allocation: cadence-deficit, no per-site overrides in v1.**
- **O4 — quarantine: logical (manifest flag + queue section).**
- **O5 — N default: 25, with `<N>` override.**
- **O6 — ship without Items 1–4: CONFIRMED.** Ray's "content-ready sites only" + "links later" direction. Not drift.

### Scope note (from the SEO research brief)

The magic-go-2 PROOF runs against the CURRENT framework (existing templates, Amazon-only links, flat IA) on MWC + DTP — the proven GardePro path. The SEO findings (schema `reviewSchema()` footgun, template voice-doctrine violation, pillar-cluster IA, `Organization`/`WebSite` schema gap) belong to a SEPARATE framework-rebuild + bootstrap track and do NOT block the orchestrator proof. They SHOULD land before the big `magic-go 25` run so the volume is SEO-strong, but the orchestrator can be built + proven first.

### Remaining (lower-stakes, defaulted unless Ray objects)

Pulled from the vision's still-relevant open items + the contradictions this plan had to resolve. (Link-routing-specific open items from the vision are dropped — Item 1 is deferred.)

1. **O1 — config-shape handling.** Two-shape adapter (recommended, non-invasive) vs. migrate DTP's `site-config.json` to MWC's flat shape (cleaner long-term). §2.3.
2. **O2 — supervised-resumable vs. fully-headless for v1.** Recommend supervised-resumable to prove body-fill quality; headless is a later drop-in via the same manifest. §3.2. *(This is the biggest design fork.)*
3. **O3 — allocation + overrides.** Confirm cadence-deficit (recommended) over even split; decide whether `magic-go <N>` needs per-site overrides in v1 (recommend no). §3.5.
4. **O4 — quarantine shape.** Logical (manifest flag + queue section, keeps build green — recommended) vs. physical `failures/` directory move (vision's literal wording, risks reddening subsequent builds). §4.
5. **N default.** Vision says 25. Lock 25 as default with `<N>` override? (Recommend yes — already assumed throughout.)
6. **Cross-check on the deferred-prerequisites override.** This plan ships Magic Go v1 WITHOUT Items 1–4, overriding the vision's "refuse-to-run unless 1–4 complete" rule, on the strength of the GardePro proof + Ray's "content-ready sites only" framing. Confirm that's the intended scoping and not a drift from the vision's sequence. §1.

---

## Recommended first build step

**Build `scripts/magic-go-readiness.ps1` + the `Get-SiteConfigField` two-shape config adapter (Build step 1).** Reasons:

- It's the v1 entry gate — nothing else runs without it, and `/aff`'s `magic-go-ready` posture depends on it.
- It forces an immediate resolution of the **single highest-risk gotcha** (the MWC-flat / DTP-nested `site-config.json` divergence, §2.3) in isolation, before that divergence can silently corrupt scaffold context downstream.
- It's deterministic, fully unit-testable (Test step 1) without any Claude-in-the-loop or API calls, and its passing/failing output is unambiguous.
- A green readiness gate that correctly reports "MWC ready, DTP ready, FB/SA/GOG skipped" is the cleanest possible proof-of-life that v1's targeting model is sound, and unblocks every subsequent step.

---

## v2 — CE doc-review revisions (2026-05-28)

Three reviewers (feasibility, adversarial, coherence) stress-tested this plan. Their findings change it materially. **This section overrides the body above where they conflict.** Build to this.

### BLOCKERS — must be resolved in the build, not hand-waved

**V1. Body-fill must produce the RICH FRONTMATTER format, not prose-only.** (feasibility F1, coherence F1)
The scaffolder template (`templates/review.md.tmpl`) emits prose-only body sections. But the 5 shipped MWC reviews render their structured widgets (scorecard, buy/skip cards, flaws, FAQ accordion) from FRONTMATTER fields (`scorecard`, `buyIf`, `flaws`, `faq`, `rubric`, `deck`) via `ReviewArticle.astro` (lines 183-251). The proof piece (moultrie-edge-2-review) came out prose-only and is the structural outlier. **Decision: body-fill produces BOTH the prose body AND the rich frontmatter.** The body-fill step (§3.4) and the prompt template must be upgraded so Claude emits `scorecard` (weighted axes + note), `buyIf` (buy/skip arrays), `flaws`, `faq`, `rubric`, `deck` as frontmatter, plus the prose body. The playbook parses the model output and writes frontmatter + body separately. New explicit build step (see V-seq below). The moultrie piece becomes the gold-standard exemplar to match (I restructure it to rich frontmatter as part of this).

**V2. Buyers-guides need MULTI-PRODUCT cards; the scaffolder seeds ONE bare product.** (feasibility F2)
`buyers-guide.ps1` seeds a single `products[]` entry with name/brand/affiliateUrl only. Shipped DTP guides have 5 products each with `bestFor`/`priceFrom`/`priceUnit`/`hook`/`reason`/`facts`/`body` (the locked unified pick-card system). Since cadence-deficit allocation sends most of N to DTP, and DTP only does buyers-guides, the dominant output format is the one the scaffolder can't produce. Body-fill for guides must produce the full multi-product frontmatter. This is a v1 blocker, not a polish item.

**V3. The config adapter must be wired into the SCAFFOLDERS, not just the gate.** (feasibility F3)
`new-review.ps1` (lines ~170) and `buyers-guide.ps1` (lines ~152) read flat config keys (`$siteConfig.primarySegments`, `.niche`, `.brandTone`, `.siteName`) directly when generating the `.prompt.md`. On DTP's nested config every read returns `(none specified)`, so DTP pieces get body-filled with NO reader-segment targeting — the core of comparison-and-fit, gone, on the site getting most of N. Build step: refactor BOTH scaffolders to use `Get-SiteConfigField`. The adapter in the gate alone is decorative.

**V4. Quarantine must split LINT-class from BUILD-class.** (adversarial F1)
§4's "keep it committed, don't move it" is correct for lint failures (content is schema-valid, Astro still compiles) but BACKWARDS for build/schema failures: Astro validates the whole collection, so one schema-invalid entry left in `src/content/` fails EVERY subsequent same-site build, cascading false-quarantines across the rest of the run. **Decision:** on a build/schema-class failure, MOVE the offending `.md` out of `src/content/` (to `docs/magic-go/runs/<runid>/failures/<slug>.md`) so it can't poison siblings; lint-class failures stay in place (noindex-safe). Add a build-class quarantine test (seed schema-invalid frontmatter, assert the NEXT same-site piece still builds green).

**V5. Add a PRODUCT-AVAILABILITY gate.** (adversarial F3)
The Moultrie case (original EDGE was 720p + multipack-only; pivoted to EDGE 2) already proved dead/multipack-only products slip through. Nothing verifies a product is currently sold as a single buyable unit. Add a research/safety-net check: flag discontinued / multipack-only / delisted ASINs before scaffolding. Cheapest highest-value guard; directly addresses an already-realized failure.

### SCALE GUARDS — required before any N>2 run (not before first build)

**V6. Replace the N=2→N=25 binary with a graduated ladder + fresh-context-per-piece.** (adversarial F2)
N=2 cannot exercise the real risks (context saturation, cumulative voice drift, topic exhaustion) that only appear at scale. **Decision:** ladder N=2 → 5 → 10 → 25, inspecting OUTPUT QUALITY (not just lint/build status) at each rung. Each piece's body-fill runs in an isolated sub-invocation (fresh context) so quality doesn't degrade with batch position — this also de-risks the eventual headless mode. Define an explicit N=2 quality bar beyond "Ray watched it."

**V7. Per-site allocation cap + DTP monetization prerequisite.** (adversarial F4)
Cadence-deficit gives DTP up to 22/25 — but DTP's `affiliate.amazonTag` is `""`, so `add-link.ps1` writes KV envelopes with NO tag → every DTP link earns $0, and the tag-lint skips empty tags silently so the safety net can't catch it. Also DTP has zero reviews and uses the nested config (unexercised review path). **Decisions:** (a) cap any single site at ~40% of N; (b) the readiness gate WARNS when a content-ready site has an empty `amazonTag` ("ready but non-monetizing"); (c) **Ray must set DTP's Amazon tag before any DTP volume run** (flagged to Ray; only he can do this). (d) Add a topic-supply check: confirm each allocated site has ≥its-allocation distinct candidate topics BEFORE committing the allocation.

**V8. The template voice-doctrine violation + schema footgun must land before N>2.** (adversarial F7)
Convert §11's "SHOULD land first" to a HARD gate: the framework-rebuild track's template voice fix + the orphaned `reviewSchema()` removal must be green before any N>2 run (the N=2 proof can run on current framework). Voice-lint checks content, not the template, so a template-level violation is invisible and multiplied 25×. (Fixing the template + adding the `hands-on` lint literal is being done now, ahead of the build — see the separate foundational-fix commit.)

### CORRECTNESS FIXES — fold into the build

- **V9. Idempotent scaffold on resume.** (feasibility F5) `new-review.ps1`/`buyers-guide.ps1` exit 1 if the `.md` exists. Resume path must pass `-Force` or the manifest records scaffold completion at file-write granularity (not just post-commit).
- **V10. Atomic manifest write + KV state field.** (feasibility F7) Write-temp-then-rename the manifest (a mid-write crash currently corrupts the single source of truth). Add a `kv_status` field per piece; `add-link.ps1` failures are currently swallowed as warnings, so a piece can publish with a dead `/go/<slug>`.
- **V11. audit-product-images once-per-run, not per-piece.** (feasibility F6) It's 5-10 min/sweep and deliberately excluded from the pre-commit hook for that reason; running it 25× in-loop is hours of Canopy calls. Move to a single post-run pass.
- **V12. Stale-manifest auto-demote, and a pre-scaffold slug-collision check.** (adversarial F6) A dead `in-progress` manifest (>48h, no recent commits) must AUTO-demote below posture #6 on the next survey (self-clearing), not just prompt. And before scaffolding, check the picked slug doesn't collide with an existing `.md` (any status) — never overwrite a hand-draft or shipped piece (data-loss vector).
- **V13. Headless is a real build item, not "a drop-in."** (feasibility F4, adversarial F5) The supervised playbook runs only in a live conversation; headless needs a net-new OS-process driver (`claude -p`/API per judgment step). Scope headless as its own build item OR honestly defer the overnight-N=25 goal. Also: a 25-piece run is multi-hour (research is ~5-8 min/piece/research-product.md), so "supervised" at N=25 isn't human-watchable — compute a cost + wall-clock + rate-limit budget before trusting `magic-go 25`, and add rate-limit backoff (a Firecrawl/Canopy 429 mid-run must retry, not misclassify as a content quarantine).

### COHERENCE FIXES (doc cleanups, low-risk)

- **V14.** Fix file citations: the noindex flip lives in the PAGE templates (`sites/<site>/src/pages/{reviews,buyers-guides}/[...slug].astro`, keyed off `bottomLine.verdict`), NOT `ReviewArticle.astro:55-58` (that's the draft banner). Gate check R5 greps the page template. (feasibility minor, coherence F3)
- **V15.** Resolve `bottom_line_options` timing: add an explicit per-piece phase "draft 3 Bottom Line options (reads bottom-line-helper.md Mode B) → store in manifest" AFTER body-fill, so §5's queue render reads them from the manifest. (coherence F2)
- **V16.** Pin the manifest status vocabulary: phases the runner executes (`scouted`→`researched`→`scaffolded`→`body-filled`→`options-drafted`→`ready`→`committed`) vs post-phase states Ray drives (`verdict-written`, `discarded`, `published`). Fix §3.5 worked-example arithmetic. (coherence F4, F5)

### Net build order change
Build step 5 (the playbook) MUST include the rich-frontmatter body-fill (V1/V2) and the wired-in adapter (V3) as explicit, testable sub-steps; quarantine (V4) moves into step 5 (the loop depends on it). V8's template fixes land BEFORE any N>2 run. The deterministic spine (gate+adapter+allocator, build steps 1-2) is unchanged and remains the validated first build step.

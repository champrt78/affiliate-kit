---
description: Internal — the Magic Go orchestrator. `/aff` reads this inline (magic-go-ready / magic-go-running postures) to run an autonomous scaffold batch across content-ready sites, then render a Bottom Line queue. Ray uses `/aff magic-go <N>`; invocable directly only for debugging. Built per docs/brainstorms/2026-05-29-magic-go-v1-plan.md (incl. the v2 CE-review revisions).
---

# /magic-go — autonomous content scaffolding to a Bottom Line queue

Runs the proven scout → research → scaffold → body-fill → lint → build chain
N times across content-ready sites, checkpointing every phase to a committed
run-manifest, quarantining failures, and rendering `dist/magic-go/queue.html`
for Ray to whip through verdicts. **The `## Bottom Line` gate stays Ray's —
this never writes a verdict.**

## Rendering: on-brand by construction (shared kit)

All 5 sites render through the **shared component kit** (`packages/shared-ui`:
`SiteShell` + `Media` + the unified guide/review templates — see the rebuild
plan `docs/brainstorms/2026-05-29-component-system-rebuild-plan.md`). Magic Go
produces only content (markdown frontmatter + per-site `site-config.json`); the
kit owns layout, scale, header, gutters, and image containment. So a new piece
is **on-brand, readable, and image-contained BY CONSTRUCTION** — the structural
acceptance criteria in `docs/STYLE_GUIDE.md` (calmer ~0.92 scale, `object-fit:
contain` Media boxes on white, full-width header, centered content shell,
balanced grids, web-vitals img dims) are satisfied by the templates, not by
per-piece work. The canonical structure these reproduce is the approved mockup
`docs/playgrounds/component-system/page.html`.

That construction is necessary but NOT sufficient: per-piece data can still
violate a criterion (a duplicate/oversized hero, a tall antenna-up product shot
that contains badly, a 5-card orphan grid, a too-long heading that wraps). The
**pre-publish front-end QA gate** below is the catch for that class — a piece
is verified on the real rendered page before its noindex flips.

## Entry modes

- **Mode B — read inline by `/aff`** (normal): `/aff` matched `magic-go-ready`
  (fresh run) or `magic-go-running` (resume) and read this file. N + allocation
  already computed or recoverable from the manifest.
- **Mode A — direct debug** (`/magic-go <N>`): parse N from args (default 25).

## Autonomy (LOCKED, plan §11 O2)

**Supervised-resumable for v1.** Claude drives the loop in the live `/aff`
session; Ray can watch/interrupt; a crash resumes from the manifest. Fully
headless (`claude -p` per judgment step, no session open) is a SEPARATE future
build item (plan v2 V13), NOT a drop-in — do not claim otherwise.

**Graduated ladder (plan v2 V6):** prove at N=2, then 5, then 10, then 25 —
inspecting OUTPUT QUALITY at each rung (not just lint/build status), watching
for body-fill drift/thinning across the batch. Do NOT jump 2 → 25.

## Preflight

1. Resolve repo per `aff.md` Step 1.
2. Run the readiness gate:
   `pwsh scripts/magic-go-readiness.ps1 -Json` → parse the ready sites.
   If zero ready, stop: "No content-ready sites. Bootstrap one first."
   For any READY-but-non-monetizing site (empty `amazonTag`), WARN Ray before
   allocating pieces to it (plan v2 V7) — those pieces earn $0.
3. **Resume check:** `Find-LatestMagicGoRunId`. If a manifest exists with
   status `in-progress` (and is not stale per `aff.md` posture rules), this is
   a RESUME, not a fresh run — jump to "Per-piece loop" at the first
   non-terminal piece (`Get-FirstNonTerminalPiece`).

## Fresh run

1. **Allocate:** `pwsh scripts/magic-go-allocate.ps1 -N <N> -Json` → the
   per-site split (cadence-deficit, per-site cap). Show Ray the split
   ("25 = MWC 12, DTP 13 — go?") and confirm in Mode B.
2. **Topic-supply check (plan v2 V7):** before committing, confirm each
   allocated site has ≥ its-allocation distinct candidate topics (run the
   scout for the site and count viable picks). If a site can't supply its
   allocation, reduce it and tell Ray.
3. **Create the manifest:** dot-source `scripts/lib/magic-go-manifest.ps1`;
   `New-MagicGoManifest -RequestedN <N> -Allocation <hashtable>`. Capture the
   runid.

## Per-piece loop

For each allocated slot (commit + push after EVERY phase — `aff.md` Step 9
durability; a crash resumes from the manifest):

1. **scout** — read `scout-topics.md` inline (Mode B, scope = the site). Pick a
   topic. **Pre-scaffold slug-collision check (plan v2 V12):** if the chosen
   slug matches an existing `.md` (any status) on the site OR another manifest
   piece, pick a different topic. NEVER overwrite. `Add-MagicGoPiece` (status
   `scouted`).
2. **research** — read `research-product.md` inline (Mode B). Fires Firecrawl +
   Canopy + last30days + /watch. Output: `docs/research/<date>-<slug>.md` with
   `target_site` + `target_slug`. **Product-availability gate (plan v2 V5):**
   the research MUST verify the product is currently sold as a single buyable
   unit — not discontinued, not multipack-only (the Moultrie case). If it
   fails, discard this slot and re-scout (do not scaffold a dead product).
   `Update-MagicGoPiece` status `researched`.
3. **scaffold** — read `scaffold-piece.md` inline (Mode B). Runs the scaffolder
   + `add-link.ps1` (Amazon-only, the site's own `amazonTag`). On resume, pass
   `-Force` so a re-run of a half-done scaffold doesn't hard-fail (plan v2 V9).
   Record `kv_status` (registered/failed) in the manifest (plan v2 V10). Status
   `scaffolded`.
4. **body-fill — RICH FRONTMATTER, fresh context (plan v2 V1/V2/V6).** THIS is
   the new judgment step. Run it in an ISOLATED sub-invocation (a fresh-context
   subagent) so quality doesn't degrade with batch position. The sub-invocation
   reads `<slug>.prompt.md` + the gold-standard exemplar
   (`sites/mywildlifecam/src/content/reviews/gardepro-e5-review.md`) and
   produces the SAME rich shape the shipped reviews use — NOT prose-only:
   - **review:** frontmatter `rubric`, `deck`, `scorecard` (weighted axes +
     note), `buyIf` (buy[]/skip[]), `flaws` ([{title,body}]), `faq`
     ([{q,a}]), `bgTheme`; PLUS the complementary prose body (Who This Is For,
     At a Glance, What It Does Well, Where It Falls Short, How It Compares,
     Verdict). Mirror GardePro exactly.
   - **buyers-guide:** multi-product `products[]`, each with `bestFor`,
     `priceFrom`, `priceUnit`, `hook`, `reason`, `facts` map, and HTML `body`
     (the unified two-tier pick-card system — see
     `sites/detailerpicks/src/content/buyers-guides/best-car-wash-soap-for-home-detailers.md`).
     **GRID-BALANCE RULE (Ray, 2026-05-29):** a guide's `products[]` count must
     render as a balanced grid — never an orphan row. **Target 6 (2 rows of 3).**
     Acceptable fallbacks: 4 (2x2) or 3 (one row). NEVER 5 (3+2 leaves a gap) or
     7 (3+3+1 orphans one). If research can only validate 5 real products,
     either find a defensible 6th or drop to 4 — do not ship a 5- or
     3-plus-1-shaped guide. Research (step 2) should target 6 validated picks so
     this never binds late.
   - **`## Bottom Line` / `bottomLine.verdict` STAYS EMPTY** (the placeholder).
     This keeps the page noindex'd and is Ray's gate.
   - **FRONTMATTER HARD REQUIREMENTS (auto-enforced by `lint-content-frontmatter.ps1`, 2026-05-30):**
     - `pillar:` MUST be set to a valid nav-pillar slug from the site's
       `site-config.json` `navigation.pillars[].slug`. Content without a matching
       `pillar:` is filtered out of its section hub → the hub renders "coming
       soon" even though the article exists. This is the bug that stranded the gog
       consoles + handhelds guides 2026-05-30. The lint blocks the commit if it is
       missing/invalid (on hub sites: gog/SA/fussybean; MWC/DTP have no hubs).
     - `description:` MUST be <=160 chars (the schema cap; over-length passes
       voice-lint but FAILS `astro build`).
   - **VOICE: no em dashes AND no semicolons** (Vonnegut rule, 2026-05-31) in any
     prose — body, verdict, supporting, facts. `lint-voice.ps1` enforces both
     (semicolons via an entity-safe check). Split into sentences or use a comma.
   - **SECTION COVERAGE:** every commercial nav pillar should end a run with >=1
     article (Ray: no "coming soon" pages). The cockpit dashboard's coverage panel
     surfaces empties; allocate a piece to any empty commercial pillar.
   - **IMAGES when firecrawl is down:** `fix-product-images.ps1` needs firecrawl
     credits. If exhausted, the body-fill/validation step should grab the real
     `og:image` (`I/<id>`) URL via a browser during /dp validation — do NOT leave
     a `P/<ASIN>` placeholder (it returns a 43-byte stub for ~half of ASINs and
     fails the image lint). For tall products (heaters, light bars, bottles) whose
     main shot is a sliver, run `scripts/pick-square-image.ps1` to pick the
     closest-to-square candidate. The guide template now hides any `$0`/missing
     price, so a missing price renders as "Check current price" not "$0".
   Run `lint-voice.ps1` on the result. Status `body-filled`.
5. **options-draft (plan v2 V15)** — read `bottom-line-helper.md` inline (Mode
   B) for this piece → 3 verdict options + supporting. Store them in the
   manifest (`bottom_line_options`, `supporting`). The queue render reads these;
   it does NOT re-invoke Claude. Status `options-drafted`.
6. **safety net** — in order: `lint-voice.ps1` (forbidden phrases + em dashes +
   semicolons), `lint-content-frontmatter.ps1` (pillar present/valid +
   description <=160), `lint-product-images.ps1`, `lint-affiliate-tags.ps1`, then
   `pnpm --filter <site> build`. (The last three + frontmatter are also in the
   pre-commit hook, so they double as the commit gate.)
   (`audit-product-images.ps1` is NOT per-piece — it runs ONCE at run end, plan
   v2 V11.) On ALL pass → status `ready`. On ANY failure → **quarantine**:
   - **lint-class** (voice/image/tag finding): leave the `.md` in place
     (noindex-safe), record `status=quarantined`, `failed_at`, verbatim
     `error`. Continue.
   - **build/schema-class** (Astro rejects the frontmatter): MOVE the `.md` OUT
     of `src/content/` to `docs/magic-go/runs/<runid>/failures/<slug>.md` so it
     can't poison every subsequent same-site build (plan v2 V4 — the cascade
     fix). Record the quarantine. Continue.
7. **commit + push** — `feat(<site>): magic-go scaffold <slug> [DRAFT]` (or
   `[quarantined — <phase>]`). `Update-MagicGoPiece` status `committed`,
   `last_commit`.

## Run end

1. `Set-MagicGoRunStatus -Status complete`.
2. `pwsh scripts/audit-product-images.ps1` ONCE across the run's sites (the
   slow Canopy sweep, V11). Apply/flag swaps; re-lint.
3. `pwsh scripts/magic-go-queue.ps1 -Open` → renders + opens
   `dist/magic-go/queue.html`.
4. Notify (plan §6): print `Queue ready: <R> drafts (<Q> quarantined).` In
   Mode B, control returns to `/aff`, whose `bottom-line-queue-pending` posture
   takes over (Ray clears verdicts), then `publish-batch-ready`.

## PRE-PUBLISH FRONT-END QA GATE (REQUIRED — runs before publish, never skipped)

**This is an ordered, required step. No piece reaches `/aff publish-batch`
(`magic-go-publish.ps1`) until it has passed this gate.** The kit makes pieces
on-brand by construction; this gate verifies that on the ACTUAL rendered page,
at real viewports, and catches the per-piece-data failures construction can't.

Sequence: it runs AFTER the queue render and AFTER Ray has written the Bottom
Line verdicts (so "Bottom Line placement / distinct hero" can be checked on the
real, index-eligible page), and BEFORE publish. Publish refuses any piece whose
`qa_status` is not `passed` — the gate is enforced in code, not just here.

For each publishable piece (exclude `quarantined` / `discarded`):

1. **Dispatch the front-end QA review.** Use the
   **`compound-engineering:ce-design-implementation-reviewer`** agent. Build the
   affected site (`pnpm --filter <site> build`, or run the dev server) and have
   the agent screenshot the rendered piece at **1440px** (desktop) and
   **true-390px** (mobile — real device width, not a scaled-down 1440 shot).
2. **Check against the `docs/STYLE_GUIDE.md` acceptance criteria** (the same set
   the kit targets, verified on the real page):
   - **Readability / scale** — body copy + headings comfortable at the ~0.92
     kit scale; nothing feels zoomed.
   - **Product images contained on white** — `object-fit: contain` in a sane
     Media box; the whole product shows, never cropped/stretched/oversized.
   - **Full-width header** — logo far-left, nav far-right, edge to edge; not
     clamped to the article shell.
   - **No mobile overflow** — nothing runs off the right edge or causes a
     horizontal scrollbar at true-390px.
   - **Balanced grid** — guide `products[]` render 2×3 / 2×2 / one row; no
     orphan row (never 5 or 3+1).
   - **Bottom Line placement** — `## Bottom Line` renders at the TOP of the
     piece (anti-recipe-page), with the verdict present.
   - **Distinct hero** — the piece's hero is its own, category-appropriate
     image; not a shared/duplicate hero reused across guides.
3. **Record the verdict in the manifest.** Dot-source the manifest lib and call
   `Update-MagicGoPiece -RunId <runid> -Slug <slug> -Set @{ qa_status = "passed"; qa_notes = "<one-line summary>" }`
   on a clean pass, or `qa_status = "failed"` with `qa_notes` listing the
   violated criteria. (`qa_status` is a parallel field like `kv_status` — it is
   NOT a value of the main `status` state machine.)
4. **A failed piece is FIXED and RE-QA'd, never published.** Fix the source
   (data: swap the hero / pick an antenna-down product image / drop to a
   balanced grid; or template if it's a kit regression), rebuild, re-dispatch
   the reviewer, and re-record. Loop until `qa_status = "passed"`. Only then is
   the piece eligible for publish.

When every publishable piece is `qa_status = "passed"`, control returns to
`/aff` → `publish-batch-ready`. `magic-go-publish.ps1` independently re-checks
both the verdict AND `qa_status == "passed"` and refuses any piece missing
either (fail-closed — `none` / `failed` / unset all block).

## What this NEVER does

- Write a `## Bottom Line` / `bottomLine.verdict` — Ray's gate, always.
- Publish — pieces stay DRAFT/noindex until Ray writes verdicts and runs
  `/aff publish-batch`.
- Run against a site that fails the readiness gate, or jump N past the
  graduated ladder rung that's been quality-checked.
- Scaffold a product that fails the availability gate (V5) or whose slug
  collides with existing content (V12).

## Build status (2026-05-28)

Spine built + tested: readiness gate + adapter (`magic-go-readiness.ps1`,
`lib/site-config.ps1`), allocator (`magic-go-allocate.ps1`), manifest
(`lib/magic-go-manifest.ps1`), queue render (`magic-go-queue.ps1`).
REMAINING before first `magic-go 2`: the fresh-context rich-frontmatter
body-fill sub-invocation (step 4) needs wiring as an actual subagent dispatch
+ the gold-standard exemplar (restructure moultrie-edge-2-review to rich
frontmatter); the `/aff` postures (plan §7) that dispatch to this playbook;
quarantine build-class move + publish-batch flow. See plan §9 build sequence.

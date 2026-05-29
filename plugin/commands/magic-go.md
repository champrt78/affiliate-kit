---
description: Internal — the Magic Go orchestrator. `/aff` reads this inline (magic-go-ready / magic-go-running postures) to run an autonomous scaffold batch across content-ready sites, then render a Bottom Line queue. Ray uses `/aff magic-go <N>`; invocable directly only for debugging. Built per docs/brainstorms/2026-05-29-magic-go-v1-plan.md (incl. the v2 CE-review revisions).
---

# /magic-go — autonomous content scaffolding to a Bottom Line queue

Runs the proven scout → research → scaffold → body-fill → lint → build chain
N times across content-ready sites, checkpointing every phase to a committed
run-manifest, quarantining failures, and rendering `dist/magic-go/queue.html`
for Ray to whip through verdicts. **The `## Bottom Line` gate stays Ray's —
this never writes a verdict.**

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
   Run `lint-voice.ps1` on the result. Status `body-filled`.
5. **options-draft (plan v2 V15)** — read `bottom-line-helper.md` inline (Mode
   B) for this piece → 3 verdict options + supporting. Store them in the
   manifest (`bottom_line_options`, `supporting`). The queue render reads these;
   it does NOT re-invoke Claude. Status `options-drafted`.
6. **safety net** — in order: `lint-voice.ps1`, `lint-product-images.ps1`,
   `lint-affiliate-tags.ps1`, then `pnpm --filter <site> build`.
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

---
title: "feat: Comparison-and-Fit Content Framework — MVP rollout for piece #1"
type: feat
status: active
date: 2026-05-16
origin: docs/brainstorms/2026-05-15-content-framework-requirements.md
---

# Comparison-and-Fit Content Framework — MVP rollout for piece #1

## Summary

Extends the existing template-fork-and-sync pattern from the 2026-05-14 content-readiness ship: harmonizes both piece types under a single `## Bottom Line` anatomy with a shared `DRAFT_MARKER`, drops `reviewSchema` JSON-LD emission to remove the silent fabricated-rating contradiction, introduces `docs/voice-doctrine.md` as the single source of truth wired into PowerShell scaffolders via sibling `<slug>.prompt.md` files, ships a `lint-voice.ps1` back-stop, and removes hands-on claims across all 5 forked About pages with the full positive-framed methodology block landing on mywildlifecam.com only. Piece #1 ships under frontmatter-only specs (no product database yet).

---

## Problem Frame

The 2026-05-14 content-readiness ship built the structural infrastructure to publish review and buyers-guide pieces. The 2026-05-15 brainstorm pivoted the content strategy to comparison-and-fit (never claim hands-on use) and locked 15 requirements with MVP-first rollout. This plan executes the minimum framework changes to ship piece #1 on `mywildlifecam.com` under the new strategy. See origin: `docs/brainstorms/2026-05-15-content-framework-requirements.md`.

---

## Requirements

- R1. Both piece types ship under a universal `## Bottom Line` anatomy with a shared `DRAFT_MARKER` literal (origin R5, R6, R7).
- R2. `## Bottom Line` is the hard DRAFT/noindex gate; `## Who This Is For` is a non-gated AI-drafted structural section (origin R6).
- R3. Voice doctrine v1 exists at `docs/voice-doctrine.md` as the single source of truth for forbidden phrases, preferred framings, and canonical direct-question responses (origin R2).
- R4. Scaffolding scripts emit a sibling `<slug>.prompt.md` artifact that combines voice doctrine + per-site reader-segment metadata + piece-type-specific guidance, ready to paste into Claude (origin R3).
- R5. A per-site config (mywildlifecam only for MVP) carries niche, primary/secondary/excluded reader segments, brand tone, and is consumed by both Astro components and the PowerShell scaffolders (supports origin R7, R12).
- R6. No piece emits `reviewSchema` JSON-LD until aggregated user-review data exists. The `data.rating ?? 5` fallback in renderers is removed; rating stays optional in Zod for future restoration (origin R1, R13 — closes JSON-LD fabrication gap surfaced in research).
- R7. The hands-on disclaimer block in `templates/buyers-guide.md.tmpl` is deleted (origin R14 revised note).
- R8. `templates/site-template/src/pages/about.astro` + `sites/mywildlifecam/src/pages/about.astro` carry a positive-framed methodology block; the 4 satellite About pages have their hands-on claims removed but receive only a stub paragraph until their cycle turns (origin R11, R14 — expanded scope per research finding).
- R9. A `scripts/lint-voice.ps1` back-stop greps a target markdown file for forbidden literals sourced from `docs/voice-doctrine.md` and exits non-zero on hit (closes the post-generation lint gap surfaced in flow analysis).
- R10. `docs/PLAYBOOK.md` carries a transitional banner at the top noting the framework supersedes it; full rewrite stays deferred to F3 / post-MVP (origin R15).
- R11. `CLAUDE.md` is updated to remove the `## My Take` reference and align the project conventions section with the new framework (supports origin R1, R2 — surfaces from research).
- R12. Piece #1 uses frontmatter-only specs (no product database yet); the MVP carve-out per origin R9 and R14 stands.
- R13. The section rename and DRAFT-gate harmonization is verified via pre-sweep and post-sweep `grep` across all 6 fork locations and both `.md.tmpl` files; zero residual occurrences of the old markers or section headings after the unit closes.

**Origin actors:** A1 (Publisher), A2 (AI drafter), A3 (Reader)
**Origin flows:** F1 (first-piece flow — fully exercised by piece #1), F2 (subsequent-piece flow — partially exercised; product-DB path deferred), F3 (MVP → full iteration — sets stage for, not executed by, this plan)
**Origin acceptance examples:** AE1 (R1, R2, R3 — AI drafter produces no first-person experience claims), AE2 (R5, R6 — placeholder Bottom Line yields DRAFT banner + noindex), AE3 (R5, R6 — filled Bottom Line indexes normally), AE4 (R8, R9 — verified specs across piece types; partially deferred since product DB is post-MVP), AE5 (R10, R11 — footer affiliate-only, About-page methodology)

---

## Scope Boundaries

- Product database schema and infrastructure — deferred to follow-up (origin R8, R15)
- Comparison-table renderer component — deferred to follow-up
- F2 product-database trigger rule — deferred to follow-up (decide when DB ships)
- Verified-date staleness windows (180/365 days) — deferred to follow-up
- Voice doctrine v1 → v2 migration policy — deferred to follow-up (first edge case sets precedent)
- Full positive-framed methodology blocks on the 4 satellite About pages — deferred to follow-up (R15 — cycle turns)
- `docs/PLAYBOOK.md` full rewrite — deferred to follow-up (transitional banner only for MVP)
- Cloudflare R2 image hosting — Phase 2 separate effort (pre-existing deferral)
- Stock-photo source library selection (origin R13) — deferred until first non-Amazon hero image needed
- `learn` content collection retrofit — out of MVP scope (no pieces planned)
- AI integration via Claude CLI or direct API call from PowerShell — deliberately chose sibling prompt file pattern
- Configurable tone scaffolding — deferred until concrete consumer exists (existing CLAUDE.md rule)
- New tests for Astro renderers — out of scope (per CLAUDE.md: `astro build` is the test)
- Bumping `@astrojs/sitemap`, `vitest`, or the `CLICKS` Analytics Engine stub — explicit non-goal; three load-bearing pins from 2026-05-14

### Deferred to Follow-Up Work

- Full About-page methodology blocks for satellite sites (`fussybean`, `detailerpicks`, `starteraquarium`, `gameovergear`) — separate PRs as each cycle turn arrives
- `docs/PLAYBOOK.md` full rewrite — separate doc-update PR after pieces 2-3 ship
- Product database schema + scaffolder integration — separate PR triggered by the chosen F2 boundary

---

## Context & Research

### Relevant Code and Patterns

- **Template-fork-and-sync pattern** (`docs/2026-05-14-affiliate-kit-content-readiness-plan.md` U1 + U5): edit template AND each site copy in same commit, grep-verify, no bootstrap re-run. This plan mirrors it for the 14-file section rename.
- **DRAFT gate** at `templates/site-template/src/pages/reviews/[...slug].astro:25-26` (literal `body.includes(DRAFT_MARKER)`); identical pattern at `buyers-guides/[...slug].astro:25-26` with a different marker literal.
- **JSON-LD emitters** at `packages/shared-utils/src/schema.ts` (`productSchema`, `reviewSchema`); consumed in renderers at `[...slug].astro:50-58` for reviews and similar for buyers-guides.
- **PowerShell scaffolders** at `scripts/new-review.ps1` and `scripts/buyers-guide.ps1` — pure `Get-Content -Raw` + `Replace(token, value)` + `Set-Content` loops with a `Next:` block at end. AI-prompt wiring extends after the substitution loop, before `Set-Content`.
- **About page** forked across 6 locations (template + 5 sites); identical content with hardcoded "first-hand experience" claims in `<h2>How we review</h2>`.
- **Content collections** at `templates/site-template/src/content/config.ts` with Zod schemas for `reviews`, `buyers-guides`, `learn`. Confirmed byte-identical to all 5 forks (per repo-research). Rating is optional today.
- **No published content** anywhere — section rename has no migration debt.

### Institutional Learnings

- "Claims of file writes in prior session logs are NARRATIVE, not evidence" (`docs/sessions/Session_2026-05-15.md` Discoveries). Verification step in each rename unit must `grep -r` for the old markers and headings after edits.
- "Edit template AND each site copy in the same commit, with a checklist" — Phase 2a settled pattern from 2026-05-14. Do NOT re-run `bootstrap` to mass-sync — it will silently revert the SITE_URL fix and any per-site About-page divergence.
- Three pinned dependencies are load-bearing and silent if violated: `@astrojs/sitemap@3.4.1`, `vitest@2.1.x`, AE binding stub. This plan touches none of them; verify via `pnpm test` in all 3 workspaces before declaring done.
- `wrangler kv` defaults to local; production writes require `--remote`. This plan doesn't touch KV; flag in case any deferred follow-up does.
- `docs/PLAYBOOK.md` is already known-stale; `docs/hub.md` line 35 acknowledges. R10 transitional banner closes the active-misguidance gap during the MVP-to-full-framework transition.

### External References

- None — this is internal architecture work; the established codebase patterns from 2026-05-14 are sufficient guidance.

---

## Key Technical Decisions

- **AI-prompt wiring mechanism: sibling `<slug>.prompt.md` file.** Scaffolders emit a second file alongside the markdown scaffold containing the AI prompt (voice doctrine + per-site config + piece-type guidance). Publisher pastes into Claude to expand AI-drafted sections. Avoids API plumbing, fits existing PowerShell-string-substitution pattern, single-artifact output (file the publisher can re-use or archive). Alternatives rejected: shell out to `claude` CLI (adds an authentication dependency that doesn't exist in the repo), direct API call from PowerShell (adds key plumbing), HTML comment block embedded in scaffold (fragile against future template parsers; ugly diff signal).

- **Voice doctrine home: `docs/voice-doctrine.md`** with H2 sections — `Forbidden phrases`, `Preferred framings`, `Direct-question responses`. Plain markdown so both PowerShell (via `Get-Content -Raw`) and humans can read it. Versioning via git. The direct-question response template (research finding #10) lives here, not in a separate file — single source of truth per origin R2.

- **Per-site config format: JSON, at `sites/<slug>/src/data/site-config.json`.** PowerShell reads via `Get-Content -Raw | ConvertFrom-Json`; Astro imports via standard JSON import (`import siteConfig from '../data/site-config.json'`). Avoids the TS-import-from-PowerShell impedance. Schema: `{ siteName, niche, primarySegments: [...], secondarySegments: [...], excludedSegments: [...], brandTone }`. MVP creates the mywildlifecam version only.

- **Buyers-guide gate harmonization: adopt `## Bottom Line` for both piece types** (universal anatomy per origin R7). Buyers-guide template's existing `## Editor's Note: Why this guide` section is renamed and moved to the top under the universal anatomy. Treats single-product and buyers-guide as variants of one shape, not as separate document types.

- **Single shared `DRAFT_MARKER` literal across both renderer families:** `"_The Bottom Line is being written._"`. Replaces today's two different literals (`"_Waiting for the human._"` and `"replace with the actual editor's note before publishing"`). One semantically-consistent placeholder reduces drift surface; the new string is distinctive enough that an AI drafter won't accidentally produce it.

- **Drop `reviewSchema` JSON-LD emission entirely (R6).** The `data.rating ?? 5` fallback at `[...slug].astro:51` silently fabricates a 5-star `Review` JSON-LD on every piece missing an explicit rating — direct contradiction of origin R1 (never claim hands-on) and R2 voice doctrine forbidden category "fabricated user quotes / blanket judgments." `productSchema` continues. Rating stays optional in the Zod schema for future restoration when aggregated user-review data is real. Alternative considered: make `rating` required, force publisher to author one — rejected because publisher-authored rating IS the hands-on claim under the new voice doctrine.

- **About-page sweep scope expansion (R8).** Origin R14 named mywildlifecam only; research surfaced that all 5 forked About pages currently claim "first-hand experience." Shipping piece #1 under the new voice doctrine while 4 satellite About pages still claim hands-on would collapse the legal-defense pillar on day one. MVP scope expands to: hands-on disclaimer removal on all 5 sites + template; full positive-framed methodology block on mywildlifecam and template only; satellites get a stub paragraph (voice-doctrine-compliant but minimal) until their cycle turn.

- **Pre-sweep + post-sweep `grep` verification** on every section-rename unit. Pre-sweep records the expected count of old markers; post-sweep confirms zero. Mirrors the U1 SITE_URL fix verification from 2026-05-14.

- **No new tests for Astro renderers** — per `CLAUDE.md`, `astro build` is the test. The plan's verification step builds all 5 sites and inspects output.

---

## Open Questions

### Resolved During Planning

- **Q: R14's "7 files" count.** Research confirmed the actual file-system reality is ~14 surfaces (template + 5 sites × 2 renderer families × 1 file each + 2 `.md.tmpl`). Plan splits the rename into per-piece-type units (U3 + U4), each touching 7 files.
- **Q: Voice doctrine document location.** Resolved to `docs/voice-doctrine.md` (plain markdown, root-level docs/).
- **Q: AI-prompt wiring mechanism.** Resolved to sibling `<slug>.prompt.md` file (see Key Technical Decisions).
- **Q: Per-site config format.** Resolved to JSON at `sites/<slug>/src/data/site-config.json`.
- **Q: `## Bottom Line` placeholder-detection mechanism (origin Outstanding Question + ce-doc-review finding #9).** Resolved: keep the existing literal-string-match pattern with a new shared marker (`"_The Bottom Line is being written._"`). Acknowledged as presence-check, not quality-check — quality enforcement is the publisher's review responsibility plus the `lint-voice.ps1` back-stop on forbidden phrases.
- **Q: Stock-photo source for category/scene hero shots (origin Outstanding Question).** Deferred — no piece-#1 dependency since piece #1 will use Amazon hotlinks for product hero (R13 existing convention).

### Deferred to Implementation

- **Exact wording of `docs/voice-doctrine.md` content** — forbidden-phrase list, preferred-framing list, direct-question response canonicals. Drafted in U1; will iterate post-MVP as edge cases surface (origin R2).
- **Exact mywildlifecam methodology block prose** — drafted in U8 from the brainstorm key decisions; not pre-specified in this plan.
- **Exact AI-prompt template body** for the sibling `<slug>.prompt.md` — composed in U6; final shape depends on what voice-doctrine content (U1) produces.
- **`lint-voice.ps1` exit-code convention and verbose-mode flag** — choose during U7 implementation.

---

## Output Structure

    docs/
      voice-doctrine.md                                 (NEW — U1)
      PLAYBOOK.md                                       (MODIFIED — U9; transitional banner)
    scripts/
      lint-voice.ps1                                    (NEW — U7)
      new-review.ps1                                    (MODIFIED — U6)
      buyers-guide.ps1                                  (MODIFIED — U6)
    sites/
      mywildlifecam/
        src/
          data/
            site-config.json                            (NEW — U5)
          pages/
            about.astro                                 (MODIFIED — U8; full methodology)
            reviews/[...slug].astro                     (MODIFIED — U3)
            buyers-guides/[...slug].astro               (MODIFIED — U4)
      detailerpicks/src/pages/about.astro               (MODIFIED — U8; stub + cleanup)
      detailerpicks/src/pages/reviews/[...slug].astro   (MODIFIED — U3)
      detailerpicks/src/pages/buyers-guides/[...slug].astro (MODIFIED — U4)
      fussybean/src/pages/about.astro                   (MODIFIED — U8; stub + cleanup)
      fussybean/src/pages/reviews/[...slug].astro       (MODIFIED — U3)
      fussybean/src/pages/buyers-guides/[...slug].astro (MODIFIED — U4)
      starteraquarium/src/pages/about.astro             (MODIFIED — U8; stub + cleanup)
      starteraquarium/src/pages/reviews/[...slug].astro (MODIFIED — U3)
      starteraquarium/src/pages/buyers-guides/[...slug].astro (MODIFIED — U4)
      gameovergear/src/pages/about.astro                (MODIFIED — U8; stub + cleanup)
      gameovergear/src/pages/reviews/[...slug].astro    (MODIFIED — U3)
      gameovergear/src/pages/buyers-guides/[...slug].astro (MODIFIED — U4)
    templates/
      review.md.tmpl                                    (MODIFIED — U3)
      buyers-guide.md.tmpl                              (MODIFIED — U4; hands-on disclaimer removed)
      site-template/
        src/
          pages/
            about.astro                                 (MODIFIED — U8; full methodology)
            reviews/[...slug].astro                     (MODIFIED — U3 + U2)
            buyers-guides/[...slug].astro               (MODIFIED — U4 + U2)
    CLAUDE.md                                           (MODIFIED — U9; My Take reference removed)

The tree shows the expected output shape. Per-unit `**Files:**` sections remain authoritative for what each unit creates or modifies.

---

## High-Level Technical Design

> *This illustrates the intended data flow and is directional guidance for review, not implementation specification.*

```
                          ┌─────────────────────────────┐
                          │  docs/voice-doctrine.md     │
                          │  (forbidden phrases,        │
                          │   preferred framings,       │
                          │   direct-question responses)│
                          └────────────┬────────────────┘
                                       │
                                       │ Get-Content -Raw
                                       ▼
┌──────────────────────────┐   ┌──────────────────────────┐
│  sites/<slug>/src/data/  │──▶│  scripts/new-review.ps1  │──▶ sites/<slug>/src/content/reviews/<slug>.md
│  site-config.json        │   │  scripts/buyers-guide.ps1│   sites/<slug>/src/content/reviews/<slug>.prompt.md
│  (segments, niche, tone) │   │  (token-sub + emit)      │
└──────────────────────────┘   └──────────────────────────┘                  │
                                                                              │
                                                                              │ paste into Claude
                                                                              ▼
                                                                    AI expands scaffold
                                                                              │
                                                                              ▼
                                                            Publisher writes ## Bottom Line
                                                                              │
                                                                              ▼
                                              scripts/lint-voice.ps1 <slug>.md    (forbidden-phrase grep; exit 1 on hit)
                                                                              │
                                                                              ▼
                                                                       astro build
                                                                              │
                                              ┌───────────────────────────────┴───────────────────────────────┐
                                              │ DRAFT_MARKER present?                                          │
                                              │   yes → <meta name="robots" content="noindex,nofollow">       │
                                              │         + <aside class="draft-banner">                         │
                                              │   no  → index normally + productSchema JSON-LD                 │
                                              │         (reviewSchema dropped per R6)                          │
                                              └───────────────────────────────────────────────────────────────┘
```

The renderer-side gate logic stays unchanged in shape; only the marker literal and the JSON-LD emission set change. The scaffolder-side adds two new reads (voice doctrine, per-site config) and one new write (sibling prompt file).

---

## Implementation Units

- U1. **Voice doctrine v1 document**

  **Goal:** Create the single-source-of-truth file for forbidden phrases, preferred framings, and direct-question response canonicals.

  **Requirements:** R3 (this plan); origin R2.

  **Dependencies:** None.

  **Files:**
  - Create: `docs/voice-doctrine.md`

  **Approach:**
  - Three H2 sections: `## Forbidden phrases`, `## Preferred framings`, `## Direct-question responses`.
  - Forbidden phrases pull from origin R2 enumerated list (first-person experience, fabricated user quotes, group-of-testers fiction, blanket judgments without spec basis, made-up review aggregates, time-spent claims) plus concrete literal examples PowerShell can grep for (e.g., "I tested", "I used", "after 6 months", "Sarah from Vermont").
  - Preferred framings: spec-driven factual claims, use-case fit, honest aggregate-of-user-reports phrasing, cited review-pattern claims, conditional comparisons.
  - Direct-question responses: 3-4 canonical replies for reader DM, manufacturer email, regulator inquiry, social-media question — each one doctrine-aligned (acknowledge research process, do not improvise a hands-on claim).
  - Frontmatter: `version: 1`, `last_updated: 2026-05-16`.

  **Patterns to follow:**
  - Markdown-as-config pattern: plain prose + structured lists, no YAML body. Mirrors `docs/PLAYBOOK.md` shape.

  **Test scenarios:**
  - Happy path: `Get-Content docs/voice-doctrine.md -Raw` succeeds and the H2 section markers are parseable by a simple regex (`^## Forbidden phrases`, etc.).
  - Edge case: a bullet under `## Forbidden phrases` that contains backticks or regex metacharacters does not break downstream consumers (U7 lint, U6 prompt builder).

  **Verification:**
  - File exists at `docs/voice-doctrine.md`.
  - All three H2 sections present.
  - At least 6 forbidden literals enumerated under `## Forbidden phrases`.
  - At least 3 direct-question response canonicals enumerated.

---

- U2. **JSON-LD truthfulness: drop `reviewSchema` emission + remove default-5 rating fallback**

  **Goal:** Stop silently emitting fabricated 5-star `Review` JSON-LD on every piece.

  **Requirements:** R6 (this plan); origin R1, R2.

  **Dependencies:** None.

  **Files:**
  - Modify: `templates/site-template/src/pages/reviews/[...slug].astro` (remove `reviewSchema` import + emission; remove `data.rating ?? 5` fallback)
  - Modify: `sites/mywildlifecam/src/pages/reviews/[...slug].astro` (same)
  - Modify: `sites/detailerpicks/src/pages/reviews/[...slug].astro` (same)
  - Modify: `sites/fussybean/src/pages/reviews/[...slug].astro` (same)
  - Modify: `sites/starteraquarium/src/pages/reviews/[...slug].astro` (same)
  - Modify: `sites/gameovergear/src/pages/reviews/[...slug].astro` (same)
  - (`packages/shared-utils/src/schema.ts` — leave intact; `reviewSchema` export stays for future restoration. Just stop calling it.)
  - (`templates/site-template/src/content/config.ts` — leave `rating` optional in the Zod schema for future restoration. Reviews can still set it; it just won't feed JSON-LD.)

  **Approach:**
  - Remove the `import { ..., reviewSchema } from "@affkit/shared-utils"` reviewSchema reference (or the local reference path) and the `reviewLd` variable + `<script type="application/ld+json">{JSON.stringify(reviewLd)}</script>` block from each renderer.
  - Confirm `productSchema` continues to emit. Do not touch buyers-guides renderers in this unit — they don't emit `reviewSchema` today.
  - This unit logically pairs with U3 (review-piece anatomy) since both touch the review renderers, but is split out because the JSON-LD change is an orthogonal correctness fix; keeping it as its own commit makes the diff reviewable on its own.

  **Patterns to follow:**
  - Template-fork-and-sync from `docs/2026-05-14-affiliate-kit-content-readiness-plan.md` U1.

  **Test scenarios:**
  - Happy path: `pnpm --filter mywildlifecam build` produces output where `grep -r "@type.*Review" sites/mywildlifecam/dist` returns zero matches; `grep -r "@type.*Product" sites/mywildlifecam/dist` returns ≥ 1 match. Covers R6.
  - Happy path: Same check across all 5 sites' dist outputs after their respective builds.
  - Integration: Existing `productSchema` JSON-LD continues to render with valid JSON body (visual inspection of one rendered piece via `astro dev`).
  - Test expectation: no new vitest cases — per CLAUDE.md, `astro build` is the test for renderers.

  **Verification:**
  - All 6 review renderer files no longer import or call `reviewSchema`.
  - `grep -rn "rating ?? 5" sites/ templates/` returns zero matches.
  - All 5 sites build clean (`pnpm -r build`).
  - Manually inspect one rendered review's `<head>` to confirm only `productSchema` JSON-LD is present.

---

- U3. **Review-piece anatomy: section rename + DRAFT marker harmonization (7 files)**

  **Goal:** Rename `## My Take` → `## Bottom Line`, move to top of anatomy, replace `DRAFT_MARKER` with the shared marker, update banner copy. Across template + 5 forked review renderers + the `.md.tmpl`.

  **Requirements:** R1, R2, R13 (this plan); origin R5, R6, R14 (revised note).

  **Dependencies:** None (U2 can land before or after; non-conflicting changes to the same files).

  **Files:**
  - Modify: `templates/review.md.tmpl` (section rename, Bottom Line at top, new placeholder line, restructure anatomy: Bottom Line → Who This Is For → spec sections)
  - Modify: `templates/site-template/src/pages/reviews/[...slug].astro` (`DRAFT_MARKER` constant + banner copy)
  - Modify: `sites/mywildlifecam/src/pages/reviews/[...slug].astro` (same)
  - Modify: `sites/detailerpicks/src/pages/reviews/[...slug].astro` (same)
  - Modify: `sites/fussybean/src/pages/reviews/[...slug].astro` (same)
  - Modify: `sites/starteraquarium/src/pages/reviews/[...slug].astro` (same)
  - Modify: `sites/gameovergear/src/pages/reviews/[...slug].astro` (same)

  **Approach:**
  - New shared `DRAFT_MARKER` literal: `"_The Bottom Line is being written._"` (used identically in U4).
  - In `review.md.tmpl`: `## Bottom Line` at top with the placeholder as the first content under it, then `## Who This Is For` (AI-drafted, not gated), then the existing supporting sections (`## TL;DR` becomes redundant — drop it; `## What I Tested` becomes `## What This Camera Does Well` or similar use-case framing — final wording in U1's voice-doctrine pass).
  - Remove the existing HTML reminder comment at the bottom of `review.md.tmpl` referring to "My Take" — replace with a one-liner referring to "Bottom Line."
  - Pre-sweep: `grep -rn "My Take" templates/ sites/ docs/ scripts/ CLAUDE.md` records the baseline count of `## My Take` and "My Take" references across all files. Post-sweep must show zero residuals in template/site source code (CLAUDE.md, PLAYBOOK.md, scripts are touched in U9 / U6).
  - Pre-sweep: `grep -rn "Waiting for the human" templates/ sites/` records baseline. Post-sweep: zero.
  - Banner copy in each renderer (`<aside class="draft-banner">`) updated from "this review's 'My Take' section is unfilled" to "this review's 'Bottom Line' section is unfilled" (exact wording chosen during implementation).

  **Patterns to follow:**
  - `docs/2026-05-14-affiliate-kit-content-readiness-plan.md` U1 + U5 (template + 5 forks edited in same commit).
  - 2026-05-14 grep-verification convention: `grep -r "old-marker" . | wc -l` before and after.

  **Test scenarios:**
  - Happy path: All 5 sites build clean after this unit lands (`pnpm -r build`).
  - Happy path: Render a scaffolded piece locally (`astro dev` on mywildlifecam) with the placeholder unchanged → DRAFT banner renders, `<meta name="robots" content="noindex, nofollow">` is in `<head>`. Covers AE2.
  - Happy path: Render the same piece after replacing the placeholder with prose → no DRAFT banner, robots meta is `"index, follow"`. Covers AE3.
  - Edge case: A piece where the publisher's Bottom Line prose accidentally contains the literal string `"_The Bottom Line is being written._"` triggers DRAFT (unlikely but documented as a known limitation per Key Technical Decisions).
  - Integration: `getStaticPaths` continues to enumerate all review entries; no piece is silently skipped.
  - Test expectation: no new vitest cases — `astro build` + dev-server visual inspection is the test.

  **Verification:**
  - `grep -rn "## My Take" templates/ sites/` returns zero matches.
  - `grep -rn "Waiting for the human" templates/ sites/` returns zero matches.
  - `grep -rn "_The Bottom Line is being written._" templates/ sites/` returns 7 matches (1 in `.md.tmpl` + 6 in renderer `DRAFT_MARKER`).
  - All 5 sites build clean.
  - Local dev preview shows DRAFT banner + `noindex` meta when placeholder is unchanged.

---

- U4. **Buyers-guide-piece anatomy: section rename + DRAFT marker harmonization + hands-on disclaimer removal (7 files)**

  **Goal:** Rename `## Editor's Note: Why this guide` → `## Bottom Line`, move to top, replace the buyers-guide `DRAFT_MARKER` with the shared marker, update banner copy. Also delete the hands-on disclaimer block from `buyers-guide.md.tmpl`. Across template + 5 forked buyers-guide renderers + the `.md.tmpl`.

  **Requirements:** R1, R2, R7, R13 (this plan); origin R5, R6, R14 (revised note).

  **Dependencies:** None.

  **Files:**
  - Modify: `templates/buyers-guide.md.tmpl` (delete intro Note line "we haven't tested this product ourselves" + Editor's Note paragraph "I haven't owned and tested __PRODUCT_NAME__ personally"; rename section header to `## Bottom Line`; move to top; restructure anatomy)
  - Modify: `templates/site-template/src/pages/buyers-guides/[...slug].astro` (`DRAFT_MARKER` constant from `"replace with the actual editor's note before publishing"` to the shared marker + banner copy)
  - Modify: `sites/mywildlifecam/src/pages/buyers-guides/[...slug].astro` (same)
  - Modify: `sites/detailerpicks/src/pages/buyers-guides/[...slug].astro` (same)
  - Modify: `sites/fussybean/src/pages/buyers-guides/[...slug].astro` (same)
  - Modify: `sites/starteraquarium/src/pages/buyers-guides/[...slug].astro` (same)
  - Modify: `sites/gameovergear/src/pages/buyers-guides/[...slug].astro` (same)

  **Approach:**
  - Same shared `DRAFT_MARKER` literal as U3: `"_The Bottom Line is being written._"`.
  - In `buyers-guide.md.tmpl`: delete the `> **Note:** This is a buyer's guide, not a review. We haven't tested this product ourselves.` block (current line 12 area); rename `## Editor's Note: Why this guide` → `## Bottom Line` and move to top; delete the "I haven't owned and tested" paragraph; restructure remaining sections under the universal anatomy.
  - Pre-sweep: `grep -rn "Editor's Note" templates/ sites/` baseline. Post-sweep: zero in the buyers-guide template + renderer paths.
  - Pre-sweep: `grep -rn "haven't tested" templates/` baseline. Post-sweep: zero in templates.
  - Pre-sweep: `grep -rn "haven't owned" templates/` baseline. Post-sweep: zero.

  **Patterns to follow:**
  - Same as U3.

  **Test scenarios:**
  - Happy path: All 5 sites build clean.
  - Happy path: Render a scaffolded buyers-guide piece with placeholder unchanged → DRAFT banner + noindex. Covers AE2 for buyers-guide piece type.
  - Happy path: Same piece with Bottom Line filled → no banner, indexed. Covers AE3 for buyers-guide piece type.
  - Edge case: A buyers-guide piece referencing 4 products renders each product's `productSchema` JSON-LD correctly (already-working behavior; this unit must not regress it).
  - Integration: `getStaticPaths` continues to enumerate all buyers-guide entries.
  - Test expectation: no new vitest cases.

  **Verification:**
  - `grep -rn "Editor's Note" templates/ sites/` returns zero matches (template + 5 sites + 2 renderers).
  - `grep -rn "haven't tested\|haven't owned" templates/buyers-guide.md.tmpl` returns zero matches.
  - `grep -rn "replace with the actual editor's note" templates/ sites/` returns zero matches.
  - All 5 sites build clean.
  - Local dev preview of a buyers-guide with placeholder unchanged shows DRAFT banner.

---

- U5. **Per-site config: schema + mywildlifecam values**

  **Goal:** Establish the typed per-site config artifact (JSON) consumed by both Astro components and PowerShell scaffolders. Create the mywildlifecam version with the reader segments locked in origin R12.

  **Requirements:** R5 (this plan); origin R7, R12.

  **Dependencies:** None.

  **Files:**
  - Create: `sites/mywildlifecam/src/data/site-config.json`

  **Approach:**
  - Schema (documented inline in U1 voice doctrine OR as a comment block in this file):
    ```
    {
      "siteName": "MyWildlifeCam",
      "domain": "mywildlifecam.com",
      "niche": "trail cameras and wildlife cameras",
      "primarySegments": ["homeowners", "property owners", "first-time buyers", "gift buyers"],
      "secondarySegments": ["backpackers"],
      "excludedSegments": ["hunters"],
      "brandTone": "snarky-but-friendly",
      "voiceDoctrineVersion": 1
    }
    ```
  - File lives at `sites/mywildlifecam/src/data/site-config.json` (under `src/` so Astro can import it cleanly via relative path or alias; under `data/` so it's clearly content-metadata, not page or component code).
  - No JSON Schema validation file in MVP; shape enforced by convention and a single import-site (the scaffolder).

  **Patterns to follow:**
  - Static-JSON-data pattern (no existing precedent in repo; this unit establishes it).

  **Test scenarios:**
  - Happy path: `pnpm --filter mywildlifecam build` succeeds with the new file present (file is not yet imported by any component; this unit is the data declaration only).
  - Happy path: `Get-Content sites/mywildlifecam/src/data/site-config.json -Raw | ConvertFrom-Json` produces an object with `.primarySegments[0]` equal to `"homeowners"`.
  - Edge case: Malformed JSON would fail PowerShell parse; covered by U6 integration when scaffolder consumes it.
  - Test expectation: no vitest case — config-data declaration, validated by U6 consumption.

  **Verification:**
  - File exists at the expected path.
  - `pwsh -Command "Get-Content sites/mywildlifecam/src/data/site-config.json -Raw | ConvertFrom-Json | ConvertTo-Json"` round-trips cleanly.
  - `pnpm --filter mywildlifecam build` succeeds.

---

- U6. **Scaffolding scripts: voice-doctrine + per-site config + sibling prompt file emission**

  **Goal:** Extend `scripts/new-review.ps1` and `scripts/buyers-guide.ps1` to read voice doctrine + per-site config and emit a sibling `<slug>.prompt.md` artifact alongside the markdown scaffold. Update existing `Next:` block copy.

  **Requirements:** R4 (this plan); origin R3.

  **Dependencies:** U1 (voice doctrine), U5 (per-site config).

  **Files:**
  - Modify: `scripts/new-review.ps1` (add voice + config reads; emit sibling prompt file; update Next: block)
  - Modify: `scripts/buyers-guide.ps1` (same)

  **Approach:**
  - After the existing token-substitution loop and before `Set-Content`, add:
    1. `$voiceDoctrine = Get-Content $repoRoot/docs/voice-doctrine.md -Raw`
    2. `$siteConfig = Get-Content "$repoRoot/sites/$Site/src/data/site-config.json" -Raw | ConvertFrom-Json`
    3. Construct `$promptBody` as a markdown string: piece-type guidance + relevant voice-doctrine excerpts (forbidden phrases bullet, preferred framings bullet) + per-site reader-segment constraints + product frontmatter context + the user's piece-specific inputs (`-ProductName`, `-Slug`, etc.).
    4. Write `$promptBody` to `$destPath.Replace('.md', '.prompt.md')`.
  - Update the `Next:` block to mention: "(1) open `<slug>.prompt.md`, paste into Claude, ask Claude to draft the body; (2) review against `docs/voice-doctrine.md`; (3) write your `## Bottom Line` section; (4) run `pwsh scripts/lint-voice.ps1 <slug>.md` before commit."
  - Graceful fallback: if `docs/voice-doctrine.md` or the per-site `site-config.json` is missing, the script writes a stub prompt with `<!-- WARNING: voice doctrine / site config missing -->` and continues. Surfaces the gap without blocking the scaffold.

  **Patterns to follow:**
  - Existing token-substitution + `Set-Content` shape in both scripts.
  - `Next:` block convention from CLAUDE.md.
  - Cross-platform PowerShell path joining via `Join-Path`.

  **Test scenarios:**
  - Happy path: `pwsh scripts/new-review.ps1 -Site mywildlifecam -Slug test-cam -ProductName "Test Cam" -Brand "TestCo" -AmazonUrl "https://amzn.to/xxx"` produces both `sites/mywildlifecam/src/content/reviews/test-cam.md` AND `sites/mywildlifecam/src/content/reviews/test-cam.prompt.md`.
  - Happy path: The prompt file contains substrings from `docs/voice-doctrine.md` (e.g., "Forbidden phrases" heading or one of the canonical forbidden literals) AND substrings from the site config (e.g., "homeowners" reader segment).
  - Happy path: Same for `scripts/buyers-guide.ps1`.
  - Edge case: Run scaffolder with `-Site nonexistent` → existing validation rejects (no regression).
  - Edge case: Voice doctrine file missing → scaffolder writes scaffold + a stub prompt file containing the `<!-- WARNING ... -->` line, exits successfully (does NOT block).
  - Edge case: `site-config.json` missing → same fallback behavior (scaffold + stub prompt + warning).
  - Integration: After scaffold + prompt-file emission, opening the prompt file in any text editor shows valid markdown.
  - Test expectation: no new vitest cases (PowerShell scripts have no test harness in this repo); validation is manual + via the dry-run scaffold check.

  **Verification:**
  - Both scripts produce a sibling `.prompt.md` file alongside the `.md` scaffold for at least one happy-path invocation per script.
  - Prompt-file body contains both voice-doctrine and site-config content.
  - `Next:` block output mentions the prompt file and `lint-voice.ps1`.
  - Scripts exit 0 even when voice doctrine / config files are missing (stub-fallback path).

---

- U7. **Voice-lint back-stop script: `scripts/lint-voice.ps1`**

  **Goal:** Provide a forbidden-phrase grep against a target markdown file using literals sourced from `docs/voice-doctrine.md`. Publisher runs after AI expansion, before commit.

  **Requirements:** R9 (this plan); supports origin R1, R2.

  **Dependencies:** U1 (voice doctrine — script must be able to parse the forbidden-phrase list out of it).

  **Files:**
  - Create: `scripts/lint-voice.ps1`

  **Approach:**
  - Parameters: `-Path <markdown file>` (required), `-Verbose` (optional flag — print matched contexts).
  - Read `docs/voice-doctrine.md -Raw`; extract the `## Forbidden phrases` H2 section content; parse out concrete literal phrases (lines starting with `-` under that section that have a literal string in backticks or quotes).
  - For each literal, case-insensitive grep against the target file. Collect hits.
  - If any hits, print findings (file:line + matched literal) and exit 1. If zero hits, print "Voice doctrine: clean" and exit 0.
  - `Next:` block on success: "Voice doctrine clean. Proceed to `astro build` + preview, then commit." On failure: "N findings — edit the piece to remove forbidden phrases, then re-run."
  - Script tolerates a missing voice doctrine by exiting 2 with a clear error message (distinguished from exit 1 "violations found").

  **Patterns to follow:**
  - Existing PowerShell scaffolder shape (parameter validation block, `Next:` block at end).
  - `Select-String` for the file-content grep (PowerShell-native, no external grep dependency).

  **Test scenarios:**
  - Happy path: A markdown file containing none of the forbidden literals → exit 0, output `"Voice doctrine: clean"`.
  - Failure path: A markdown file containing the literal `"I tested this camera for six weeks"` → exit 1, output identifies the line.
  - Failure path: A markdown file with multiple violations → exit 1, all findings listed.
  - Edge case: An empty markdown file → exit 0 (no violations).
  - Edge case: A markdown file containing the literal `"I tested"` inside a fenced code block (escaped or quoted as example) — current behavior matches it as a violation; publisher's responsibility to fence such examples in a `## Examples for documentation` section that the lint can opt-skip via a special marker. MVP does not implement the skip marker; documented as a known limitation. Future-deferred.
  - Edge case: `-Path` points to a nonexistent file → exit 2 with clear error.
  - Edge case: `docs/voice-doctrine.md` missing → exit 2 with clear error referencing U1.

  **Verification:**
  - Script exists at `scripts/lint-voice.ps1`.
  - Manual run against a synthetic markdown file with known violations identifies them correctly.
  - Manual run against a clean file returns exit 0.

---

- U8. **About-page sweep: hands-on disclaimer removal across 5 sites + full methodology block on mywildlifecam + template**

  **Goal:** Eliminate the "We test products where we can" / "first-hand experience" / "Our 'My Take' section reflects real use" claims from all 6 forked About pages. Add the full positive-framed methodology block to mywildlifecam + template; add a minimal voice-doctrine-compliant stub paragraph to the 4 satellite About pages.

  **Requirements:** R8 (this plan); origin R11, R14 (expanded per research).

  **Dependencies:** None (independent of rename units).

  **Files:**
  - Modify: `templates/site-template/src/pages/about.astro` (full positive-framed methodology block)
  - Modify: `sites/mywildlifecam/src/pages/about.astro` (full positive-framed methodology block, niche-aware)
  - Modify: `sites/detailerpicks/src/pages/about.astro` (stub paragraph; remove hands-on claims)
  - Modify: `sites/fussybean/src/pages/about.astro` (same)
  - Modify: `sites/starteraquarium/src/pages/about.astro` (same)
  - Modify: `sites/gameovergear/src/pages/about.astro` (same)

  **Approach:**
  - Full block on mywildlifecam + template:
    - `<h2>How we research</h2>` (renamed from "How we review")
    - Positive prose: "Every recommendation here is grounded in published specs, aggregated user-review patterns from verified buyers, and category-specific feature-axis analysis. We synthesize what owners report, what manufacturers publish, and what spec sheets confirm into use-case-fit recommendations."
    - Bullet list reframed: spec verification, user-review aggregation, use-case fit framing, methodology transparency.
    - The existing `<h2>How we make money</h2>` affiliate disclosure stays unchanged.
  - Stub on 4 satellites: a single paragraph "Our recommendations are based on published specs and aggregated user reviews. Full methodology coming as this site's content rolls out." Plus the affiliate disclosure (unchanged). No hands-on claims anywhere. No "we test" or "first-hand" language.
  - Pre-sweep: `grep -rn "first-hand\|We test products\|My Take" sites/*/src/pages/about.astro templates/site-template/src/pages/about.astro` baseline. Post-sweep: zero across all 6.

  **Patterns to follow:**
  - Template-fork-and-sync (edit template + each site in same commit).
  - Existing Astro page structure in `about.astro` (MainLayout wrapper, h1 + sections).

  **Test scenarios:**
  - Happy path: All 5 sites build clean after the unit.
  - Happy path: Rendered `mywildlifecam.com/about` shows the new methodology block; no hands-on claims present (manual visual via `astro dev`).
  - Happy path: Rendered `detailerpicks.com/about` shows the stub paragraph; affiliate disclosure intact; no hands-on claims (covers AE5 for satellite About page).
  - Integration: Sitemap (`sitemap-index.xml`) continues to include `/about` for each site (no path change in this unit; should be unaffected).
  - Test expectation: no new vitest cases — `astro build` + preview is the test.

  **Verification:**
  - `grep -rn "first-hand\|We test products\|My Take" sites/*/src/pages/about.astro templates/site-template/src/pages/about.astro` returns zero matches.
  - All 5 sites build clean.
  - Local preview of one satellite + mywildlifecam About page passes visual review (publisher-eyeball check).

---

- U9. **CLAUDE.md + PLAYBOOK.md transitional updates**

  **Goal:** Stop CLAUDE.md from documenting the old "## My Take" rule. Add a transitional banner to PLAYBOOK.md noting the framework supersedes it; full rewrite deferred.

  **Requirements:** R10, R11 (this plan); origin R15.

  **Dependencies:** None.

  **Files:**
  - Modify: `CLAUDE.md` (replace the "AI scaffolds the draft. Human fills in `## My Take`" line under "Content rules" with the new rule: "AI scaffolds the draft. Human fills in `## Bottom Line` (located at the top of every piece). Never publish with `## Bottom Line` empty.")
  - Modify: `CLAUDE.md` (update the "Products the human doesn't own → frame as buyer's guide, not review" line to align with the new strategy: "Both piece types are research-based; neither claims hands-on use. Voice doctrine at `docs/voice-doctrine.md`.")
  - Modify: `docs/PLAYBOOK.md` (insert at top, under the H1: a blockquote banner — `> **Status:** This playbook describes the pre-2026-05-15 model. The Comparison-and-Fit framework supersedes it. See \`docs/brainstorms/2026-05-15-content-framework-requirements.md\` and \`docs/voice-doctrine.md\` for the new model. Full playbook rewrite is queued.`)

  **Approach:**
  - Minimal touches; no rewrite. The transitional banner is one blockquote at the top of PLAYBOOK.md.
  - In `scripts/new-review.ps1` + `scripts/buyers-guide.ps1`, also update any inline references to `## My Take` or "Waiting for the human" in code comments or the `Next:` block — this is part of U6 already if not caught there; explicitly verified here.

  **Patterns to follow:**
  - Markdown blockquote convention for status notices (mirrors `docs/hub.md` style notes).

  **Test scenarios:**
  - Happy path: `grep -n "My Take" CLAUDE.md` returns zero matches.
  - Happy path: `head -10 docs/PLAYBOOK.md` shows the blockquote banner.
  - Happy path: `grep -rn "My Take\|Waiting for the human" scripts/` returns zero matches (verifies U6 carry-through).
  - Test expectation: none — documentation update, validated by visual inspection.

  **Verification:**
  - `grep -rn "## My Take\|My Take" CLAUDE.md docs/PLAYBOOK.md scripts/` returns zero matches.
  - PLAYBOOK.md opens with the transitional banner blockquote.

---

## System-Wide Impact

- **Interaction graph:** Scaffolders (PowerShell) gain two new file reads (`docs/voice-doctrine.md`, `sites/<slug>/src/data/site-config.json`) and one new file write (`<slug>.prompt.md`). Renderers (Astro) drop one JSON-LD emission (`reviewSchema`) and harmonize the `DRAFT_MARKER` literal. No new entry points, no new middleware, no new background jobs.
- **Error propagation:** Scaffolder fallback path (missing voice doctrine or site config) writes a `<!-- WARNING -->` stub rather than failing — surfaces the gap to the publisher without blocking the scaffold. Lint script returns three distinct exit codes (0 clean, 1 violations, 2 setup error) so the publisher can distinguish "fix the piece" from "fix the environment."
- **State lifecycle risks:** Section rename across 14 files is the highest-risk change. Mitigated by per-piece-type unit split (U3 + U4), pre-sweep + post-sweep grep verification, and `astro build` across all 5 sites as the final gate. No persistent-state risk (no DB, no cache to invalidate).
- **API surface parity:** No public API. The `reviewSchema` import in `packages/shared-utils` remains exported for future restoration; only call-sites stop invoking it.
- **Integration coverage:** F1 (first-piece flow) is fully exercised by piece #1 after this plan lands. F2 partially (piece #2 path validates 60-75 min cycle but without the product-DB step). F3 sets the stage but does not execute.
- **Unchanged invariants:** Link-cloaker Worker (KV envelope, URL contract, redirect behavior), JSON-LD `productSchema` emission, sitemap generation, SITE_URL substitution at bootstrap, the three pinned dependencies (`@astrojs/sitemap@3.4.1`, `vitest@2.1.x`, AE binding stub), Astro 4.16 content-collections v1 API.

---

## Risks & Dependencies

| Risk | Mitigation |
|------|------------|
| Section rename misses one of the 14 files; DRAFT gate inconsistent across piece types or sites | Per-piece-type unit split (U3 + U4) with pre-sweep + post-sweep grep verification; `astro build` across all 5 sites as final gate |
| Publisher fills `## Bottom Line` with one banal sentence; gate clears but voice-doctrine pillar silently degrades | Documented limitation in Key Technical Decisions; `lint-voice.ps1` back-stop (U7) catches forbidden-phrase violations independently of gate-clearance |
| AI drafter produces a forbidden phrase that escapes the prompt-construction constraint | U7 lint runs post-generation as the publisher's pre-commit check |
| One of the 4 satellite About-page stub paragraphs reads as filler-content and underperforms in trust signals | Acceptable for MVP; full methodology blocks land per R15 cycle turns |
| Voice doctrine v1 has gaps that surface during piece #1 drafting | v1 is explicitly a hypothesis-to-test; doctrine evolution policy deferred to follow-up (when first edge case surfaces, document the response, update doctrine) |
| AI prompt becomes too long when voice doctrine + site config + product context all concatenate | Iterate on prompt template body in U6; trim non-load-bearing voice-doctrine prose into per-piece-type relevant excerpts only |
| `sites/<slug>/src/data/site-config.json` import path conflicts with existing Astro alias config | None today; if surface during U5, add explicit relative-path import in any consumer rather than reconfigure aliases |
| Hot-shot Cloudflare Pages deploy fails on one site due to a per-site fork divergence | Run `pnpm -r build` locally before push; deploys are independent per site, so one failure doesn't block others |

---

## Documentation / Operational Notes

- After this plan lands, the affiliate-kit can produce piece #1 via: `pwsh scripts/new-review.ps1 -Site mywildlifecam ...` → publisher pastes `<slug>.prompt.md` into Claude → AI expands scaffold → publisher writes `## Bottom Line` → `pwsh scripts/lint-voice.ps1 <slug>.md` → `pnpm --filter mywildlifecam build` → local preview → commit + push → Cloudflare Pages deploys.
- `docs/voice-doctrine.md` is the live document. Treat it as evergreen; iterate as edge cases surface.
- The product-DB schema and trigger logic are explicitly deferred to a follow-up plan, written when piece #2 hits the database-decision boundary.
- PLAYBOOK.md full rewrite is queued behind 2-3 published pieces' worth of in-practice learning.

---

## Sources & References

- **Origin requirements:** [docs/brainstorms/2026-05-15-content-framework-requirements.md](../brainstorms/2026-05-15-content-framework-requirements.md)
- **Prior plan (template-fork pattern + JSON-LD wiring):** [docs/2026-05-14-affiliate-kit-content-readiness-plan.md](../2026-05-14-affiliate-kit-content-readiness-plan.md)
- **ce-doc-review findings (26 items, 3 quick-fixed):** [docs/sessions/Session_2026-05-15.md](../sessions/Session_2026-05-15.md)
- **Project conventions:** [CLAUDE.md](../../CLAUDE.md)
- **Current per-review playbook (transitional, to be rewritten):** [docs/PLAYBOOK.md](../PLAYBOOK.md)

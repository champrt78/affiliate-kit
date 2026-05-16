---
date: 2026-05-15
topic: content-framework
---

# Comparison-and-Fit Content Framework

## Summary

A reusable content framework for the affiliate-sites monorepo that ships comparison-and-fit affiliate pieces without claims of hands-on product use. Two piece types share a universal anatomy with per-niche tuning; voice doctrine enforced at AI-generation time; verified specs sourced from a shared per-site product database. MVP-first: minimum framework changes to ship piece #1, full system grown across pieces 2-5.

---

## Problem Frame

The affiliate-sites monorepo shipped its content-production capability on 2026-05-14 — review and buyer's-guide renderers, scaffolding scripts, sitemap, SEO basics, link-cloaker Worker. All five sites are HTTP 200 and structurally ready to publish.

Zero pieces have been published. The existing content rules (in `CLAUDE.md` and `docs/PLAYBOOK.md`) assume the publisher owns or has used the products being reviewed — `## My Take` is the hard DRAFT/noindex gate, and the playbook explicitly directs the publisher to "own it → review, don't own it → buyer's-guide."

The publisher does not own and does not plan to buy the products covered. The six site niches (wildlife cameras, car detailing, BBQ, aquarium gear, gaming accessories, dog products) were chosen for affiliate-revenue potential, not personal interest. The goal is passive income produced primarily by AI tooling with human review, not hobby-driven first-person reviews.

The existing toolchain cannot support this without a strategic content pivot. The piece structure implies hands-on, the section names imply hands-on, the playbook implies hands-on. Shipping under the current framework either forces dishonest first-person claims (legal/reputational risk, conflicts with the publisher's stated principles) or leaves pieces auto-noindexed in the DRAFT state forever.

---

## Actors

- A1. **Publisher**: Picks products to cover, verifies specs into the product database, writes the `## Bottom Line` synthesis on every piece, reviews AI drafts for voice-doctrine compliance, ships pieces. Time budget: 4-6 hours/week.
- A2. **AI drafter**: Generates piece drafts from product database + voice doctrine + piece type. Writes every section except `## Bottom Line`. Never produces forbidden phrases (enforced at prompt construction).
- A3. **Reader**: Lands on a piece from a search query (e.g., "best trail cam under $200", "Spypoint Flex-M review"). Wants the answer fast, low tolerance for SEO padding. Clicks affiliate links when the recommendation fits their use case.

---

## Key Flows

- F1. **First-piece-on-a-site flow**
  - **Trigger:** Publisher decides to publish content on a site for the first time under the new framework
  - **Actors:** A1 (Publisher), A2 (AI drafter)
  - **Steps:**
    1. Publisher picks a product or product category
    2. Publisher creates/updates the site's product database entry for that product (verified specs + source URLs + verified-date)
    3. Publisher runs the appropriate scaffolding script (single-product or buying-guide); script generates a piece scaffold including AI-drafted sections except `## Bottom Line`
    4. Publisher reviews the draft for voice-doctrine compliance and accuracy
    5. Publisher writes the `## Bottom Line` section in their own voice
    6. Publisher previews the piece locally, verifies JSON-LD renders cleanly
    7. Publisher commits and pushes; Cloudflare Pages deploys
  - **Outcome:** Piece is live, indexed (Bottom Line is filled so DRAFT gate clears), with a working cloaked affiliate link
  - **Covered by:** R1, R2, R3, R6, R8, R10, R11

- F2. **Subsequent-piece flow on the same site**
  - **Trigger:** Publisher writes a second or third piece covering a product already in the database
  - **Actors:** A1 (Publisher), A2 (AI drafter)
  - **Steps:**
    1. Publisher picks the product; product database entry already exists (verified)
    2. Publisher runs the scaffolding script; AI pulls verified specs from the database directly
    3. Publisher reviews AI draft, writes `## Bottom Line`, ships
  - **Outcome:** Piece live in roughly 60-75 min of publisher time; specs consistent with prior pieces about the same product
  - **Covered by:** R3, R6, R8, R10

- F3. **MVP → full-framework iteration flow**
  - **Trigger:** Publisher has shipped pieces 1-2 on mywildlifecam under the MVP framework and is ready to grow the system
  - **Actors:** A1 (Publisher)
  - **Steps:**
    1. Build per-site product database infrastructure when a second or third piece on the same product surfaces the need
    2. Rewrite existing playbook to match new strategy
    3. Add About-page methodology blocks to other sites as their cycle turns arrive
    4. Apply framework to satellite sites during their per-playbook cycle turns
  - **Outcome:** Full framework in place across all six sites by roughly three months of cycle activity
  - **Covered by:** R14, R15

---

## Requirements

**Strategic positioning and voice**

- R1. Every piece uses the comparison-and-fit content model: confident, spec-driven, use-case-framed recommendations that never claim hands-on product use.
- R2. A voice doctrine document is the single source of truth for forbidden phrases (first-person experience, fabricated user quotes, group-of-testers fiction, blanket judgments without spec basis, made-up review aggregates, time-spent claims) and preferred framings (spec-driven factual claims, use-case fit framing, honest aggregate of user reports, cited review-pattern claims, conditional comparisons, voice-neutral synthesis).
- R3. Scaffolding scripts construct the AI prompt by reading from the voice doctrine document so AI drafts never produce forbidden phrases at generation time. Voice doctrine evolves as edge cases surface in real pieces.

**Piece anatomy**

- R4. Two piece types exist: single-product (review-style with comparison embedded) and buying-guide (multi-product, use-case matchmaker).
- R5. Both piece types follow an answer-first anatomy: hero, 1-2 sentence lead, `## Bottom Line` at the top, followed by supporting sections (`## Who This Is For`, spec sections, comparison sections, user-reports section). No SEO-padding intros.
- R6. `## Bottom Line` is the hard DRAFT/noindex gate — the page will not index until the placeholder is replaced with the publisher's own prose. `## Who This Is For` is a structural AI-drafted section, not gated.
- R7. The anatomy is universal across all six sites; per-niche tuning happens at the feature-axes layer (which specs matter for this category) and reader-segment layer (who the site is written for).

**Spec verification**

- R8. Spec data lives in a per-site product database — verified once per product with source URLs and a verified-date. Pieces reference product entries by key; renderers pull specs from the database. Single source of truth across multiple pieces about the same product.
- R9. Adding a product to the database is a discrete pre-piece step; a publishable piece cannot reference a product that has no verified database entry — **except piece #1 per R14**, which uses frontmatter-only specs as the MVP carve-out before the database exists.

**Site-level disclosure**

- R10. The per-piece footer carries the affiliate disclosure only ("We may earn commissions from links on this page.") — no methodology statement.
- R11. Each site's About page carries a methodology section that documents the research process in positive framing (what we DO: specs, aggregated user reviews, use-case fit) without explicitly disclaiming hands-on testing.

**Content rules per site**

- R12. mywildlifecam targets homeowners, property owners, and first-time/gift buyers as primary readers; backpackers as secondary; explicitly NOT hunters. Other sites get their own primary-reader profiles when their cycle turns arrive.
- R13. No AI-generated product images. Product hero shots use Amazon listing image hotlinks (refreshed quarterly); category/scene hero shots use stock photos from free commercial sources.

**Rollout sequencing**

- R14. MVP-first execution: the minimum framework changes ship before piece #1 (section rename, anatomy revision, voice doctrine v1, mywildlifecam About-page methodology block, voice doctrine wired into AI prompts). Piece #1 uses frontmatter-only specs (no product database yet).
  - **Section-rename sync requirement (7 files):** The `## My Take` → `## Bottom Line` rename is not a one-file change. The DRAFT gate is a literal string match in the renderer (`DRAFT_MARKER = "_Waiting for the human._"`), so the MVP unit must update all of: (a) the placeholder string in `templates/review.md.tmpl` + `templates/buyers-guide.md.tmpl`, (b) the `DRAFT_MARKER` constant in `templates/site-template/src/pages/reviews/[...slug].astro` + `buyers-guides/[...slug].astro`, (c) the same renderers forked across all 5 sites under `sites/{mywildlifecam,fussybean,detailerpicks,starteraquarium,gameovergear}/`. Missing any one leaves the gate inconsistent.
  - **Hands-on disclaimer removal:** MVP scope also includes deleting the existing "we haven't tested this product ourselves" lines from `templates/buyers-guide.md.tmpl` (intro Note + Editor's Note section). These contradict R11's positive-framed methodology approach and the broader voice doctrine.
- R15. Full framework grows across pieces 2-5 on mywildlifecam: build per-site product database when a product appears in multiple pieces, rewrite existing playbook to match the new strategy, add About-page methodology to remaining sites as their cycle turns arrive.

---

## Acceptance Examples

- AE1. **Covers R1, R2, R3.** Given the voice doctrine forbids first-person experience claims, when the AI drafter generates a single-product review, the draft contains no phrases claiming the publisher tested, used, owned, or experienced the product over time.
- AE2. **Covers R5, R6.** Given a publisher runs the single-product scaffolding script with the placeholder still in `## Bottom Line`, when the piece is built and deployed, the page renders with a DRAFT banner and a `noindex` meta tag.
- AE3. **Covers R5, R6.** Given a publisher fills `## Bottom Line` with real prose and `## Who This Is For` retains its AI-drafted text, when the piece is built and deployed, the page renders without a DRAFT banner and is indexed normally.
- AE4. **Covers R8, R9.** Given a product database entry exists for a covered product with verified specs (sources, verified-date, feature-axis values), when a buying-guide piece references that product, the rendered piece displays the verified specs consistently with any single-product piece about the same product.
- AE5. **Covers R10, R11.** Given a published piece on any site, when a reader scrolls to the page footer, they see the affiliate disclosure but no methodology statement; when they navigate to the About page, they find the positive-framed methodology section.

---

## Success Criteria

- **Human outcome — publisher:** The publisher can scaffold, fill `## Bottom Line`, and ship a piece in roughly 60-75 min once the framework is built. The voice doctrine and DRAFT gate together prevent shipping content that either claims hands-on experience or escapes review.
- **Human outcome — reader:** A reader who landed on a piece from a "best X" or "X review" search sees the recommendation within 30 seconds of arriving, no SEO-padding intro, and can either leave with the answer or stay for the supporting case. The anti-recipe-page principle is visible in every piece.
- **Legal/risk outcome:** The combination of voice doctrine (no hands-on claims), About-page positive-framed methodology (documents what is done), and per-piece affiliate disclosure (FTC-aligned) keeps the publisher legally defensible against accusations of misleading content while sustaining an informed authoritative voice.
- **Downstream-agent handoff quality:** `ce-plan` can produce a unit-by-unit implementation plan from this document without inventing piece anatomy, voice rules, section names, gating mechanisms, disclosure structure, or rollout sequencing.

---

## Scope Boundaries

- AI-generated product images (banned per existing CLAUDE.md rule)
- Any claim of hands-on product testing or personal use
- Hunter-targeted content on mywildlifecam
- A third piece type (head-to-head A vs B) — possible future addition if data justifies
- Per-piece methodology disclosure in the footer (kept on About page only)
- Scraping or automated spec extraction
- Frontmatter `reviewed: true` flag as the DRAFT gate
- PA-API integration for product images (gated on 3 Amazon Associates sales)
- Cloudflare R2 image hosting (Phase 2, separate effort)
- Six per-niche frameworks (one universal framework with tuning chosen instead)
- Manufacturer media-kit outreach (optional, not required)
- Explicit "we don't physically test" methodology language (rejected; positive framing chosen)
- Renaming existing scaffolding script filenames or `/reviews/<slug>` URL pattern
- Backpacker-targeted dedicated content on mywildlifecam (treated as side-dish, not primary)
- Applying the framework to all six sites simultaneously
- Full framework build before piece #1 (MVP-first execution chosen)

---

## Key Decisions

- **Universal framework + niche tuning, not per-niche frameworks:** Reduces maintenance to one anatomy, one voice doctrine, one verification workflow; tuning lives at the feature-axes and reader-segment layers.
- **Two piece types, not three or four:** Single-product and buying-guide cover the bulk of affiliate-converting query types; head-to-head can be added later if data justifies the carrying cost.
- **`## Bottom Line` at the top of the anatomy:** Reader gets the answer in 30 seconds; supporting sections below for those who want depth. Anti-recipe-page is now a design principle.
- **`## Bottom Line` is the hard DRAFT gate, not a frontmatter flag:** Visible placeholder is a stronger forcing function than an invisible flag.
- **Shared per-site product database:** Verify specs once per product, reference from many pieces. Single source of truth across pieces about the same product.
- **Positive-framed methodology on About page only, not in per-piece footer:** Documents what the publisher DOES (research process) without explicitly disclaiming hands-on. Voice doctrine handles the never-claim-hands-on side; methodology handles the documentation-of-process side; together they make the "dance around it" strategy legally defensible at this scale.
- **MVP-first rollout, not full-framework-first:** Minimum changes to ship piece #1; full framework grows in flight across pieces 2-5. Avoids the perfection-paralysis failure mode.
- **mywildlifecam first; satellites in their cycle turns:** Hero site gets the real effort per existing playbook; satellites inherit framework when their cycle arrives.
- **Apply for Amazon Associates AFTER 2-3 pieces are published, not before:** Manages the 180-day-3-sales clock by ensuring the site has conversion content from approval day one.

---

## Dependencies / Assumptions

- Existing toolchain (review + buyer's-guide renderers, scaffolding scripts, link-cloaker Worker, sitemap, SEO basics) is functional and remains the foundation.
- Existing playbook cadence (90-day cycles, 5 pieces per hero cycle, satellites cycling at half-pace) remains the framework for refresh and content velocity; this document changes WHAT is in each piece, not WHEN they ship.
- Amazon listing image hotlinks remain technically viable in the near term; PA-API access is treated as Phase 2.
- The voice doctrine list (forbidden phrases, preferred framings) is treated as v1 and will evolve as edge cases surface in real pieces.
- Reader value-add is primarily anti-recipe-page experience plus aggregation, use-case framing, and verified-spec accuracy — inferred from the publisher's anti-recipe-page conviction; not validated by reader research yet.

---

## Outstanding Questions

### Deferred to Planning

- [Affects R14][Technical] Exact minimum-change set for piece #1 — does the section rename force a one-time migration of any existing template fixtures, or are there no shipped pieces to migrate? Answered by codebase inspection during ce-plan.
- [Affects R8][Needs research] Exact schema for the per-site product database (field names, types, source URL list shape) — chosen during ce-plan with the renderer code in view.
- [Affects R3][Technical] Exact mechanism for scaffolding scripts to read the voice doctrine document and inject the forbidden/preferred lists into the AI prompt — implementation choice belongs in ce-plan.
- [Affects R13][Needs research] Stock-photo source for category/scene hero shots — chosen during ce-plan based on license terms and library size.

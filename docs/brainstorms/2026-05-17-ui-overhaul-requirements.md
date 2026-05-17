---
date: 2026-05-17
topic: ui-overhaul-mywildlifecam
---

# UI Overhaul — mywildlifecam.com Visual Identity

## Summary

Nature-publication visual identity for mywildlifecam.com, elevated to the "refined outdoors" register (Land Rover, not Jeep / F-150). Sophisticated serif/sans pairing, restrained earthy palette anchored on deep forest green + warm cream + one accent in the brass/sage family, cinematic photography used purposefully, generous whitespace, subtle forest texture as accent rather than full background. Hero-first scope: mywildlifecam ships polished this round; the 4 satellites stay bare until their cycle turns and theme their own variant on the shared design system.

---

## Problem Frame

The infrastructure work to ship the affiliate-sites project is done — auto-deploy, content framework, voice doctrine, real Amazon links, hero images, link-cloaker. 3 pieces are live on mywildlifecam.com.

But the live site looks "5% done" (Ray's words) — white text on black, no real visual identity, broken proportions, the buying-guide page renders only 2 of 3 picks visibly (viewport/layout bug), text wrapping where it shouldn't. Visitors landing from a "best trail camera" search query immediately read the site as "generic AI affiliate slop" rather than as a publication worth trusting with a purchase decision.

The visual layer is the gap between "content shipped" and "actual conversion." Conversion is the entire point of the affiliate-revenue strategy. Without a visual identity that earns trust, the high-quality voice-doctrine-compliant copy underneath is wasted.

This brainstorm establishes the visual direction. `ce-frontend-design` (or equivalent) consumes the output and implements.

---

## Actors

- A1. **Reader / visitor.** Lands from organic search ("best trail cameras for backyard," "spypoint flex-m review," etc.). High intent to buy. Low patience for SEO-padding intros or generic affiliate aesthetics. Wants a trustworthy recommendation fast.
- A2. **Publisher (Ray).** Ships content under the locked voice doctrine; needs visual scaffolding so each new piece gets the polished treatment automatically.
- A3. **AI drafter.** Continues producing body content per voice doctrine. Not affected by visual changes directly.

---

## Key Flows

- F1. **Desktop reader → piece → cloaked CTA → Amazon.**
  - **Trigger:** Reader arrives at a piece URL from search.
  - **Steps:**
    1. Sticky header visible immediately
    2. Hero image + lead headline + lead paragraph above the fold
    3. Bottom Line section near the top (anti-recipe-page principle per the 2026-05-15 framework)
    4. Reader scrolls through Who This Is For + At a Glance + body sections
    5. Cloaked CTA visible at piece header AND footer; sticky header may include a "See on Amazon" button after scroll
    6. Click CTA → /go/<slug> → Worker → Amazon
  - **Outcome:** Reader leaves to Amazon with intent to buy.

- F2. **Desktop reader → home → piece.**
  - **Trigger:** Reader lands on the apex URL.
  - **Steps:**
    1. Home page hero (latest piece highlighted) + "Latest reviews" grid + "Buying guides" section
    2. Reader clicks into a piece
  - **Outcome:** Continues into F1.

- F3. **Mobile reader experience.**
  - Same as F1 / F2 but with mobile-first reflow: sticky header collapses to logo-only or hamburger at small widths; comparison tables reflow to stacked product cards; CTAs sized for thumb-touch; hero images aspect-ratio-adjusted for portrait viewports.

- F4. **Publisher scaffolds new piece → polished visual treatment auto-applied.**
  - New piece scaffolded via existing `scripts/new-review.ps1` or `scripts/buyers-guide.ps1`
  - Ray writes Bottom Line + AI body
  - On build / deploy, the piece inherits the shared design system — typography, palette, layout, sticky header, footer, affiliate disclosure — without per-piece design work
  - **Outcome:** consistent visual identity across all current and future mywildlifecam pieces.

---

## Requirements

**Strategic positioning**

- R1. Visual identity is "elevated nature publication" — Outside / Sierra / Garden & Gun adjacent. Refined outdoors register, NOT rugged / working-class / Jeep-Wrangler aesthetic. The reader's mental image: "Land Rover Range Rover at a cabin," not "F-150 at a job site."
- R2. Anti-AI-slop principles apply to the visual layer. No em dashes in styling cues. No generic Tailwind-rainbow gradients. No overused icon sets. No AI-generated decorative SVGs. Intentional, specific typography choices — not "Inter for everything." Curated photography, not stock cliché.

**Typography**

- R3. Headlines use a modern-classical serif (Domaine Display, GT Sectra Fine, Tiempos Headline, or equivalent). Body uses a crisp workhorse sans (Söhne, Inter, GT America, or equivalent). Specific fonts chosen during `ce-frontend-design` based on web-font availability, license terms, and final aesthetic test.
- R4. Type scale is editorial: generous leading, considered tracking, clear hierarchy between H1 / H2 / H3 / body / caption. Drop caps or pull quotes are allowed but not required.

**Color palette**

- R5. Anchored on deep forest green + warm cream. ONE accent color in the brass / sage / warm metallic register. Specifically avoids ochre / terracotta / orange (reads "Southwestern / Jeep / cheap-stock-outdoors").
- R6. Dark mode is in-scope as a secondary consideration but the light theme is the canonical look. Dark mode inverts to a deep charcoal background + cream text + same accent.

**Imagery**

- R7. Hero photography uses curated nature stock (Unsplash+, Pexels, Pixabay nature collections). Not Amazon manufacturer photos for hero/section imagery. The "foresty thing" is photographic atmosphere, used purposefully — one strong image per piece, not decorative sprinkles.
- R8. Product photos for individual cameras come from manufacturer CDNs (per existing R13 pattern) — Spypoint product page, Trailcampro review photos, Vikeri's listing. Treated with care: soft shadows, considered crops, breathing room around the product. NOT flat product photos slapped on a background.
- R9. AI-generated images remain banned per existing project rules.

**Layout — per piece type**

- R10. Home page: hero photo + lead pull text, "Latest reviews" grid (3-6 piece thumbnails), "Buying guides" featured section, methodology link to /about/. NOT the current bare "Latest reviews" + "Coming soon" placeholders.
- R11. Buying guide piece: hero, lead paragraph, Bottom Line at top (per voice doctrine), Who This Is For, redesigned product comparison (cards, not pure markdown table — see R12), per-product detail sections, end-of-piece summary + CTA.
- R12. Single-product review: hero with prominent product image, lead, Bottom Line at top, At a Glance spec block as a designed sidebar (not a plain table), What It Does Well / Where It Falls Short / How It Compares as editorial sections, Verdict, FAQ.

**Comparison table redesign**

- R13. The current markdown comparison table in buying-guide pieces is replaced by per-product cards. Each card contains: product image, brand, primary spec callout, "Best fit" descriptor, cloaked CTA. The buyers-guides Zod schema is extended to support `image:` per product entry. Renderer reads per-product fields and renders cards.
- R14. Each per-product card has its own cloaked CTA — `/go/<slug>-<product>` or equivalent. The buyers-guides Zod schema is extended to support per-product `cloakedSlug:` (or the existing single CTA pattern is replaced entirely; both options resolved during planning).

**Conversion mechanics**

- R15. Primary CTA pattern: cloaked "See it on Amazon" button styled in the brass/sage accent. Visible in piece header (above the fold) AND piece footer (end of read). On long pieces, sticky header MAY include a context-aware CTA after the reader scrolls past the hero.
- R16. CTAs never claim discounts, fake urgency, or scarcity. Comparison-and-fit voice doctrine carries forward into visual copy.
- R17. Affiliate disclosure: prominent in site footer; one-line inline disclosure at the top of every piece ("This guide contains affiliate links. We may earn a commission from purchases."). Per-piece disclosure is one line and visually subdued; site-footer disclosure is more complete.

**Navigation**

- R18. Sticky header on scroll. Contains: logo / wordmark (left), nav links (right). Optional: a small "See on Amazon" context CTA after scroll past hero on a piece page.
- R19. Mobile: header collapses to logo + hamburger at small widths. Touch targets minimum 44pt.

**Theming architecture**

- R20. Design system uses CSS variables (extends the existing pattern in `packages/shared-styles` / `BaseLayout.astro`) for color, font, texture, accent. mywildlifecam's actual values are set in this round. The 4 satellite sites override their values via `sites/<slug>/src/data/site-config.json` or equivalent when their cycle turns. Per-site backgrounds: forest for mywildlifecam, coffee texture for fussybean, etc. — all themed in later.

**Bug fixes (folded into this round)**

- R21. Fix the broken proportions on the current site (visible: text wrapping where it shouldn't, hierarchy collapsed, components misaligned).
- R22. Fix the "only 2 cams showing" buying-guide rendering bug — viewport / overflow / table-layout issue.
- R23. Fix text-wrapping issues on the live site.

**Voice doctrine continuity**

- R24. This round is visual-only. Voice doctrine carries forward unchanged. No copy changes other than incidental adjustments tied to layout (e.g., section headers tightening for visual hierarchy, never to change meaning).

---

## Acceptance Examples

- AE1. **Covers R1, R3, R4, R5.** Given a desktop reader visits mywildlifecam.com, when the home page renders, they see a refined nature-publication aesthetic: modern-classical serif headline, forest-green + cream palette, generous whitespace, curated hero photography. The site reads as a publication, not as a generic AI affiliate page.
- AE2. **Covers R18, R19.** Given a reader scrolls down a piece, when they scroll past the hero, the header remains sticky and remains readable. On mobile, the sticky header collapses to a logo + hamburger.
- AE3. **Covers R11, R13, R14.** Given a reader on the buying guide "Best Trail Cameras for Backyard Wildlife," when the page renders, they see 3 product cards (Spypoint Flex-M, Stealth Cam DS4K Ultimate, Vikeri Trail Camera) — each with product image, key specs, "Best fit" descriptor, individual cloaked CTA — not a single markdown table.
- AE4. **Covers R12.** Given a reader on a single-product review, when the page renders, they see a designed At-a-Glance spec sidebar treated like a magazine sidebar (not a plain markdown table), and the body reads as an editorial article rather than a wall of bullets.
- AE5. **Covers R15, R17.** Given a reader on any piece, when they scroll, the primary "See it on Amazon" CTA is visible at the top and bottom. An inline affiliate disclosure is present at the top of the piece body. The footer has the full disclosure.
- AE6. **Covers R2.** Given a designer / developer reviews the rendered site, no em dashes appear in any chrome / nav / decorative text; no generic Tailwind-style rainbow gradients; no AI-generated decorative SVGs; typography choices feel intentional rather than default.
- AE7. **Covers R21, R22, R23.** Given a desktop or mobile reader on the buying-guide page, all 3 picks render correctly (not 2); text wraps appropriately at all viewport widths; proportions are visually consistent across sections.

---

## Success Criteria

- **Reader outcome.** A trail-cam buyer arriving from a "best trail cameras for backyard wildlife" search query reads the page within 5 seconds as "a publication worth trusting" rather than "a generic AI affiliate site." Bounce rate from organic search measurably lower than the pre-overhaul baseline.
- **Publisher outcome.** Ray scaffolds future pieces (`scripts/new-review.ps1` / `scripts/buyers-guide.ps1`) and they inherit the polished design automatically — no per-piece visual work. The system stays maintainable without breaking voice doctrine or content framework.
- **Conversion outcome.** Cloaked CTA click-through rate measurably higher than the pre-overhaul baseline. (No specific target number this round; "noticeably better than zero-design" is the bar.)
- **Legal / brand outcome.** Voice doctrine compliance unchanged. Affiliate disclosure prominence increased (top-of-piece inline + footer full disclosure). No fake-urgency or fake-discount visual cues.
- **Architectural outcome.** The 4 satellite sites can be themed in a future cycle turn by overriding CSS variables / per-site config, without requiring per-satellite layout work.

---

## Scope Boundaries

- The 4 satellite sites' design — they keep bare aesthetic until their cycle turns. Design system shaped to support themed satellites later via CSS variables + per-site config overrides.
- Custom illustration assets. Land Rover register doesn't require illustrations; curated photography carries the visual weight. Future iteration if needed.
- Animation / motion design. Static this round. Subtle motion (button hover, page transitions) is a follow-up.
- Search functionality on the site. Future work.
- Newsletter signup / lead capture forms. Future work.
- Owned product photography. Manufacturer CDN hotlinks per R8 / existing R13 pattern stay until PA-API approved.
- AI-generated images. Permanently out — banned per existing project rules.
- Tone / copy changes. Voice doctrine is locked; this round is visual-only.
- Performance optimization. Lighthouse audits + Core Web Vitals work belong in a separate pass after the visual identity lands.
- Accessibility audit. WCAG-compliance pass is a separate work item; this round designs WITH accessibility in mind (contrast, touch targets, semantic markup) but doesn't formalize the audit.
- SEO meta-data refinement. Current `BaseLayout.astro` already handles basics; deeper SEO work is a separate task.

---

## Key Decisions

- **Direction = elevated Nature Publication, not Modern Editorial or Boutique Zine.** Maps cleanest to Ray's "sleek + magazine-y + subtle foresty" brief plus the "Land Rover not Jeep" refinement signal.
- **Palette excludes ochre / terracotta / orange.** Those read Southwestern / rugged / cheap-stock-outdoors — wrong register for Land Rover refinement.
- **Hero-first scope.** mywildlifecam this round only. The 4 satellites stay bare until their cycle turns. Matches the MVP-first pattern locked in the 2026-05-15 content framework.
- **Photography source = curated nature stock + manufacturer product photos.** No owned photography this round. No AI-generated images.
- **Theming via CSS variables.** Existing pattern in `packages/shared-styles` / `BaseLayout.astro` extends naturally. Satellites override per-site config when they migrate.
- **Buyers-guides schema extension.** Per-product `image:` and per-product CTA support is in-scope. Resolved at the renderer level during `ce-plan`.
- **Voice doctrine carries forward unchanged.** Visual round, not content round.
- **Bug fixes embedded.** Proportions, "only 2 cams showing," text-wrapping — fixed in this pass rather than separate work items.

---

## Dependencies / Assumptions

- Existing infrastructure (auto-deploy via GitHub Actions, link-cloaker Worker, voice doctrine, content framework, sticky-marker DRAFT gate, About-page methodology blocks) remains functional and provides the foundation.
- Web fonts via a hosted service (Google Fonts free-tier, Fontshare, or self-hosted via the `templates/site-template/public/` directory). Specific service chosen during `ce-frontend-design`.
- Curated nature stock photography is sourced from Unsplash+ / Pexels / Pixabay; license compatibility verified per-image.
- Manufacturer product photo hotlinks remain accessible (no CORS / hotlink-protection surprises). Hotlinks are refreshed quarterly per the existing R13 cadence.
- Astro 4.x rendering + Cloudflare Pages static-serve stays the deploy pattern. No SSR / hybrid rendering changes in this round.
- Voice doctrine (`docs/voice-doctrine.md`) and content framework (`docs/brainstorms/2026-05-15-content-framework-requirements.md`) are the canonical content rules; visual changes do not modify them.

---

## Outstanding Questions

### Deferred to Planning

- [Affects R3] **Specific typography pairing** (Domaine + Söhne vs Tiempos + Inter vs GT Sectra + GT America vs other) — chosen during `ce-frontend-design` based on web-font availability, license cost, and visual test.
- [Affects R5, R6] **Exact hex values for the palette** — anchored on "deep forest green + warm cream + brass/sage accent" but the specific hex codes chosen during `ce-frontend-design` after testing on actual photography.
- [Affects R7] **Specific hero photography per piece type and per-page** — sourced and selected during implementation; criteria locked here (curated nature stock, license-compatible, evocative not generic).
- [Affects R13, R14] **Exact schema extension shape for per-product image + per-product cloaked CTA** — Zod schema changes happen at `ce-plan` time based on renderer code structure.
- [Affects R15] **Sticky-header context CTA behavior** — whether the sticky header injects a "See on Amazon" CTA after scroll-past-hero, and what triggers the injection. Resolved during frontend design + user testing.
- [Affects R18] **Hamburger menu vs always-visible nav on mobile** — resolved based on nav-item count and visual test during frontend design.
- [Affects R20] **Specific CSS-variable structure and naming convention for the theming layer** — resolved during planning with the renderer code in view.
- [Affects R22] **Root cause of the "only 2 cams showing" bug** — diagnosed during the bug-fix pass; whether it's a CSS overflow, a markdown rendering quirk, or a Zod-strip issue gets identified at fix time.

### Resolved during brainstorm

- Direction (Elevated Nature Publication, not Modern Editorial or Boutique Zine).
- Refinement register (Land Rover, not Jeep / F-150).
- Scope (mywildlifecam only this round; satellites later).
- Photography source policy (curated nature stock + manufacturer product hotlinks; no owned, no AI-generated).
- Theming approach (CSS variables, satellites override later).
- Voice doctrine continuity (visual-only round; no copy changes).
- Bug fixes folded in (not deferred to follow-up).

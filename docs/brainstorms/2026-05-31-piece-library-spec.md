---
title: Standardized Piece Library — spec + approval tracker
date: 2026-05-31
status: mockups-built-awaiting-ray-review (01 approved; 02-12 mocked in docs/playgrounds/library/, gallery 00-index.html)
owner: Ray + Claude (live design session)
---

# Standardized Piece Library

## The directive (Ray, 2026-05-31)
Too much per-site drift. Standardize the pieces across all 5 sites: **every site renders the
exact same components/pages — only the SKIN (color, font, gutter image) + CONTENT differ.**
Keep all content. Same tech stack (Astro + `@affkit/shared-ui`). After the library is designed
and approved piece-by-piece, **each site gets "nuked and rebuilt"** from the shared pieces
(delete bespoke per-site page code → thin wrappers around shared components; skin + content
preserved). Reviews already work this way (proof the model holds).

## NON-NEGOTIABLE: proportions are locked (Ray, 2026-05-31)
Proportions were a HUGE factor in every approval. When the mockups become real Astro
components, the proportions (heights, image caps, spacing rhythm, column ratios, the
quick-picks row layout especially) must match the approved mockups EXACTLY — not
"close." Don't let the rebuild drift the proportions. Quick-picks row proportions
explicitly called out as locked.

## REBUILD FOUNDATION (autonomous build 2026-05-31, advisor-vetted)

Goal (Ray): rebuild ALL 5 sites + Magic Go on the locked 12-component library. Skin + content only differ. On a BRANCH (live sites untouched). Any decision Ray must make → a single HTML decisions sheet + open relevant pages.

### Token map (mockup flat tokens → real codebase tokens in packages/shared-styles/src/tokens.css)
- `--paper` → `--color-paper` · `--paper-muted` → `--color-paper-muted` · `--ink` → `--color-paper-ink`
- `--forest` → `--color-forest` · `--brass` → `--color-brass` · `--brass-soft` → `--color-brass-soft`
- `--muted` → `--color-muted` · `--border` → `--color-border`
- `--accent` → `--color-brass` (real system: `--color-accent` aliases `--color-brass`; DTP site.css collapses forest=brass)
- `--accent-ink` → `--color-accent-fg` (= `--color-paper` per skin → light text on light skins' brass, dark text on gog's cyan — already correct per skin)
- `--serif` → `--font-serif` · `--sans` → `--font-sans`
- Per-skin values ALREADY match: each site.css sets `--color-brass`/`--color-forest`/etc to the exact values the mockups used (I pulled the mockup skins FROM site.css). So porting = swap token names; skins resolve automatically.

### New tokens to ADD to shared-styles (harmonized primitives from cohesion pass)
- `--radius-card: 14px` (cards) · inner image boxes use existing `--radius-lg` (10px) · `--radius-button: 8px`
- `--shadow-card: 0 2px 10px rgba(0,0,0,.06)` · `--shadow-button: 0 2px 9px rgba(0,0,0,.18)` (+ hover)
- Section padding = existing `--space-8` (32px) · card padding = existing `--space-5` (20px) / `--space-6` (24px tall)
- Button text: 14px / 700.

### Content-model data inventory (buying-guide frontmatter ALREADY has most of it)
Frontmatter: `title, description, rubric, deck, bottomLine{verdict,supporting}, products[]{name,brand,affiliateUrl,image,bestFor,priceFrom,priceUnit,hook,reason,facts{},body}, faq[]`.
- Bottom-Line buy card → `products[0].image` ✓ `.priceFrom` ✓ `.affiliateUrl` ✓
- Section-header facts panel → picks = `products.length` ✓ · price range = min/max `priceFrom` ✓ · "best for" = guide-level (derive or `products[0].bestFor`)
- Deep card → persona = `bestFor` ✓ · key-points = `facts{}` ✓ · award label = **GAP**
- **FORK 1 (decisions sheet):** Bottom Line wants Buy-if / Skip-if / Heads-up split; current `bottomLine.verdict` is one sentence. Options: (a) graceful — render verdict as-is; (b) add `buyIf`/`skipIf`/`headsUp` fields → schema + Magic Go + content migration.
- **FORK 2 (decisions sheet):** deep-card / at-a-glance award label (BEST OVERALL/VALUE/BUDGET). Options: (a) derive from product rank (1st=Overall, cheapest=Value, etc.); (b) add `award` field per product → schema + Magic Go + content.

### Sequence (depth-first, pilot = DTP)
freeze mockups (harmonize + #4 applied + verified) → add real tokens → port shared components (token-mapped) → GuideArticle extraction → DTP wired 100% + screenshot-verified vs mockups → roll to 4 → Magic Go last. STOP + write decisions sheet if a content migration fork is large.

### FROZEN-SPEC deltas to implement in the REAL components (not re-mocked, by design)
- **#4 deep-card award = full-width top banner** (Ray chose banner). Mockup 06 still shows the old rounded PILL — do NOT trust 06's award; the real deep-card component renders the banner matching at-a-glance (05) / `award-compare.html` (RIGHT side = the approved banner). Banner metrics = at-a-glance: accent bar across full card top, 11.5px/700/.14em, white text (gog dark #07101a).
- **08 comparison table CTA** got fattened by the button-harmonization (full 14px/13×20 in a table row). In the real ComparisonTable, keep it button-styled but more compact in-cell (≈13px / 8×14) so rows don't bloat.
- **09 FAQ** eyebrow is now left-aligned with the leading rule while "Common questions" heading stays centered — asymmetry. In the real FAQ component, align them (left-align the heading to match the eyebrow, or center both).
- Harmonization otherwise applied across 01-12 (radius 14 cards / 10 img-box, button 8px+shadow, one card shadow, fb --accent #b06f2c, gog --brass-soft restored, spacing→32/20). Mockups are the frozen visual spec; real components must MATCH them (proportions = acceptance test).

## Working method
One component at a time. Claude mocks it up (standalone HTML, all 5 skins side by side) →
Ray bangs on it until he likes it → it goes in the library → next. Mockups live in
`docs/playgrounds/library/`. Local preview: `python -m http.server 8799` from repo root.

## Gold-standard references (Ray-approved "this is great")
- **FussyBean home page** — the bar for homepages.
- **DTP `/quick-picks/`** — the bar for the quick-picks page (numbered horizontal rows).
- **DTP `/buyers-guides/`** — great listing (BUT repeated images = bug to fix).
- **DTP `/buyers-guides/best-interior-cleaner-for-home-detailers/`** — the bar for the guide-detail
  page (BUT its Bottom Line is still left-justified = bug to fix). This is the extraction source.

## What's already shared (CE repo-inventory, 2026-05-31) — leave alone
Review detail (`ReviewArticle`, thin wrappers), all index/listing pages (`ReviewCard`/`BuyersGuideCard`),
chrome (`SiteShell`→`BaseLayout`, `AffiliateDisclosure`), `BottomLine`, `Media`, `CTA`.

## Where the drift lives (the work)
- **Guide detail** = biggest win: 5× ~800-906 line bespoke files, identical markup, divergent CSS +
  small markup drifts (BottomLine-vs-header order inverted on the 4 cold sites, FAQ schema, byline copy).
  → extract `GuideHeader`, `QuickPickGrid` (at-a-glance), `DeepPickCard` (full detail), `EditorialBody`,
  `GuideFooter`; collapse 5 wrappers to thin shells.
- **Homepages = two families**: DTP/MWC use shared Hero+cards; FB/GOG/SA are fully bespoke (hand-rolled
  hero + pillar tiles). Must reconcile to one skeleton + extract `FeaturedGuideBlock`.
- **Orphan components**: `ProductCard.astro` + `ComparisonTable.astro` exported but UNUSED — adopt for
  deep card / spec table, or retire.
- **Page-set gaps**: `quick-picks` only on DTP; `topics/[pillar]` only on FB/GOG/SA; no `404` anywhere.

## Known bugs to fix IN the shared components (propagate to all 5)
- Bottom Line left-justified → center.
- Oversized images: homepage "Start here" featured block + guide hero NOT capped (separate from card cap).
  Featured pick should use multi-image magazine layout, not one giant cover-cropped image.
- Sentence-style bullet lists (`- A **heater** (...)`) render as broken oversized boxes — make list
  rendering robust.
- Gutters → site-themed background images (MWC already has forest; roll to all).

## Component list + approval status
| # | Component | Status | Notes |
|---|---|---|---|
| 1 | Header / nav bar | ✅ APPROVED 2026-05-31 | = shared SiteShell header. Mock: `01-navbar.html`. Align SiteShell at build pass. |
| 2 | Footer | ⬜ | = shared SiteShell footer. |
| 3 | Hero (home) | ⬜ | shared `Hero` exists; FB/GOG/SA hand-roll their own — reconcile. |
| 4 | Bottom Line verdict block | ⬜ | COMPONENT (not a page), top of review + guide. Fix left-justify. |
| 5 | At-a-glance pick card | ⬜ | "QuickPickGrid" tier 1. |
| 6 | Deep / full product card | ⬜ | tier 2; maybe adopt orphan ProductCard. |
| 7 | Listing card (guide + review) | ⬜ | BuyersGuideCard/ReviewCard exist; fix image caps + lone-card. |
| 8 | Comparison table | ⬜ | orphan ComparisonTable exists. |
| 9 | FAQ block | ⬜ | currently only schema; no rendered component — NEW. |
| 10 | CTA / "See on Amazon" button | ⬜ | shared `CTA` exists. |
| 11 | Quick-picks row | ⬜ | from DTP quick-picks gold standard. |
| 12 | Section header + byline/trust | ⬜ | GuideHeader + byline. |

## Best-practice additions to consider (CE best-practices, 2026-05-31)
Comparison "A vs B" page; author/contributor page; inline disclosure near CTA (distinct from footer);
price + "last-checked" freshness; Schema injectors (Product/Review/FAQ/Breadcrumb); TOC/anchor nav;
pros/cons block; rating. Glossary + newsletter = nice-to-have.

## Section pun renames (Ray picks, per site) — first guide section
MWC: (pending) · DTP: **The Once-Over** ✅ · FussyBean: (pending) · GameOverGear: (pending) · StarterAquarium: (pending)
Options on file — MWC: Field Scan/First Light/Quick Tracks · FB: First Sip/Quick Pour/Crema Cut ·
GOG: First Level/Warp Zone/Press Start · SA: Quick Dip/Shallow End/Test the Water.

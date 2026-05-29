# Style Guide / Bible — Affiliate Sites

**The single source of truth for recurring visual, layout, UX, and content rules across all 5 sites.** The whole point: stop re-fixing the same little things over and over. When a fix gets made once, it becomes a RULE here, and from then on it's enforced (by lint, by template, or by checklist) instead of relitigated.

> **How this works (Ray + Claude workflow):**
> 1. Ray does a pass on a site, lists issues (with screenshots — drop them in `docs/style-evidence/` or paste in chat).
> 2. Each issue Claude turns into a durable RULE below: the rule, the WHY, the FIX, and WHERE it's enforced.
> 3. Claude applies the fix everywhere it currently occurs, and enforces it on all future work.
> 4. Where a rule can be a lint/automated check, Claude wires it (so it's caught at commit, not by Ray's eyeballs).
>
> A rule that lives only in Claude's head doesn't count. It lives HERE.

---

## 📥 Intake — from Ray's latest pass (triage me)

> Paste raw issues / screenshot references here. Claude moves each into a numbered rule below, fixes current occurrences, and notes the commit.

**Pass 1 — 2026-05-29 (Ray, on the freshly-published Magic Go pieces). Status: TRIAGING → root-cause fix pending.**

- [ ] **I1. Hero image on review pages is TOO BIG and CROPPED.** Product images (square, on white) render as oversized cover-cropped heroes. Seen on: MWC Browning review (Image #7), MWC Bushnell review (Image #8). Root: hero container blows up + crops the product shot instead of containing it at a sane height.
- [ ] **I2. Hero image on GUIDE pages is too big + cropped.** MWC cellular guide (Image #6) — no `images.hero`, so it falls back to a product image rendered huge/cropped at the top.
- [ ] **I3. Review content card is not CENTERED on the page.** MWC Browning review (Image #7) — content column pushed left, forest gutter only on the right. Should be centered with symmetric gutters.
- [ ] **I4. DTP buyers-guides INDEX has no content padding/border — heading flush to the left edge.** "Buyer's guides" heading + intro sit right on the page edge (Image #9), looks unfinished. Needs the page-shell padding/gutter the other pages have.
- [ ] **I4b. (related) DTP guide-index cards reuse the SAME hero image** (same car-wash splash on multiple cards, Image #9) — distinct or category-appropriate thumbnails would read better. Lower priority than the padding.

- [ ] **I5. DTP Reviews INDEX heading flush to left border too** (Image #10) — same padding/gutter gap as I4, on the reviews index.
- [ ] **I6. 🚨 VOICE VIOLATION live on DTP Reviews index:** intro reads "Hands-on product reviews. What works, what doesn't, and what we'd buy with our own money." Both "hands-on" and "buy with our own money" violate the doctrine. Root: hardcoded in the index `.astro` page, which the voice lint does NOT scan. FIX the copy AND extend the lint to cover `.astro` pages. Check MWC indexes for the same.
- [ ] **I7. Card thumbnails crop product images to "half the product"** (Image #10) — `object-fit:cover` on tall product images. Card thumbs should contain, not cover-crop.

- [ ] **I8. Detail/"deep" card media box renders tall product images at wildly wrong scale** (Image #21 grid card + Image #22 deep card, Spypoint Flex-S Dark). The deep-card image box is too tall/portrait, so a tall-antenna product shows as a giant thin antenna line with a tiny camera body. The image needs to be RESIZED to a sane scale. SYSTEM FIX: a single shared **Media** component with a fixed, sensible box (square or 4:3) + `object-fit:contain` + centered, used identically for grid cards, deep/detail cards, AND review hero — so ANY product image (tall, wide, antenna-up) shows fully at a comfortable scale, never stretched or dominating. Pairs with R1.5 (prefer antenna-down source images). This is the #1 image acceptance criterion for the kit.

Root-cause buckets: (A) hero + card image containment [I1, I2, I7, **I8 — one shared Media component, sane fixed aspect, contain, used everywhere**], (B) content-shell centering [I3], (C) page-shell padding/gutter on index pages [I4, I5], (D) voice violations hardcoded in `.astro` index pages + lint blind spot [I6]. Fix the roots in the shared templates, not per-page.

- [ ] **I9. HEADER must span the full page width** (Image #23, MWC cellular guide; also flagged on fussybean + "that should spread the whole page"). The header content is crammed/left-clustered instead of using the full width. SYSTEM FIX: the shared Header component is a full-width band with logo pinned to the far left and nav to the far right, edge to edge (its own comfortable padding, NOT clamped to the narrow article shell). RECURRING across 3 sites — this is a hard requirement, not a one-off.

- [ ] **I10. Duplicate hero shots across guides** (Image #24) — CONFIRMED on 3 DTP guides: ceramic + drying-towels share the identical car-wash splash, and a third repeats. Every guide needs a distinct, category-appropriate hero. SYSTEM: hero image is per-piece data; the kit must not fall back to a shared default, and scaffolding should assign/require a distinct scene per guide. (was I4b — now confirmed across 3, promoted.)
- [ ] **I11. Article/detail content "smashed into the left," big empty right** (Image #25, DTP interior guide) — the article column is left-aligned in a wide page instead of centered/using the width comfortably. Same bucket as I3 (centering). The content column should be centered in the shell with balanced gutters.
- [ ] **I12. Content "feels zoomed in, too hard to read — scale back / zoom out"** (Images #26-27, DTP interior bottom-line + body). CONFIRMED on multiple pages now. Reinforces R1.6: the global UI scale is too large; the kit sets a calmer base scale (~0.9-0.92 of current live) once, so body copy + headings + blocks read comfortably. This is a hard, recurring requirement.

Root-cause bucket (E): **shared full-width Header component** [I9] — logo far-left, nav far-right, spans the page; do not constrain to the article content shell.
Root-cause bucket (F): **distinct per-piece hero imagery** [I10] — no shared default hero; each guide/review gets its own.
Root-cause bucket (G): **calmer global scale** [I12, R1.6] — set base type/spacing ~0.9-0.92 of current in the kit; everything inherits.

**Reference look to build the kit TO: the live DTP ceramic guide** (`detailerpicks.com/buyers-guides/best-ceramic-coating-for-home-detailers`) — Ray: "essentially what is right here" (bg, content width, gutters, bg image), scaled to ~0.9–0.95.

---

## Enforcement legend

- 🔒 **Lint** — caught automatically at commit (pre-commit hook). Can't regress silently.
- 🧩 **Template** — baked into shared component/layout, so it's right by construction.
- 👁️ **Checklist** — manual rule Claude follows; not yet automated (candidate for a lint).

---

## 1. Images

- **R1.1 🔒 Every `<img>` has explicit `width` + `height` attributes.** WHY: without them the browser reserves 0 height during parse and the image pops in late, causing layout shift (CLS). This bit DTP 2026-05-20 (CLS 0.458). FIX: add the aspect-ratio-hint dimensions (CSS still controls real display). Defaults in project `CLAUDE.md` → "Web vitals." ENFORCED: `Select-String` check in CLAUDE.md; candidate to add to pre-commit.
- **R1.2 🔒 Product images must be real, 200-OK, image/*, ≥2KB, aspect 0.35–2.5.** WHY: catches wordmark banners, slivers, 404s, and tiny thumbnails. ENFORCED: `scripts/lint-product-images.ps1` (pre-commit). Fetches via curl (Amazon 400s the .NET client and mangles `+` in image IDs).
- **R1.3 👁️ Product images must be the AUTHORITATIVE main image for that exact ASIN.** WHY: Amazon pages are saturated with cross-sell carousel images; picking by document-order or file-size grabs the WRONG product's photo (a Browning page served Moultrie + Tactacam images, 2026-05-29). FIX: `scripts/fix-product-images.ps1` extracts `colorImages.initial[0].hiRes` (the real #landingImage) per ASIN. For ASINs whose /dp is bot-blocked, pull from the brand CDN and visually confirm.
- **R1.4 👁️ AI-generated product images are banned.** AI for scene/context only. Product hero shots come from Amazon PA-API or the brand media kit. (From project `CLAUDE.md`.)
- **R1.5 👁️ Prefer well-proportioned product shots; reject awkward-aspect ones.** Trail cameras flagged 2026-05-29: the main image often has the cellular antenna sticking straight up, making the product tall-and-narrow so it renders tiny inside a contained box with dead space. FIX: for these, the image picker should choose a gallery variant with the antenna folded down, or a front/alternative angle that fills the box better. General rule: when a product has a clearly squarer/better-framed alternate in its gallery, prefer it over the default main image.
- **R1.6 🧩 UI scale is ~0.75 of the original draft — comfortable, not zoomed.** Ray 2026-05-29: everything felt too big/zoomed across all sites. The component kit sets the base type scale + spacing once at this calmer scale (base font ~15px, hero h1 capped ~38px, smaller card media boxes). Lock it in the kit so every site inherits it.

## 2. Cards & grids

- **R2.1 👁️ Buying-guide product grids must be balanced — target 6 (2×3); fallback 4 (2×2) or 3; NEVER 5 or 3+1.** WHY: an orphan row (one lonely card) looks broken. Ray flagged 2026-05-29. ENFORCED: `plugin/commands/magic-go.md` step 4 + research targets 6 validated picks. Candidate for a lint.

## 3. Typography
- _(rules land here from Ray's pass — e.g. heading scale, line-length caps, prose rhythm)_

## 4. Layout & spacing
- _(rules land here — e.g. content-shell max-width, gutter behavior, header alignment, mobile padding)_
- **Known recurring offender to watch:** header/date content "mooshed into the left" instead of spanning the page (Ray flagged a fussybean page 2026-05-29). Add the specific rule once the fix is pinned down.

## 5. Links & CTAs

- **R5.1 🧩 The primary "See on Amazon" CTA uses a cloaked `/go/<slug>` link backed by a KV entry.** WHY: cloaking enables click tracking + future multi-network routing. GOTCHA: the page template auto-renders `/go/<slug>` from the page slug, so EVERY new piece needs a KV entry (`pwsh scripts/add-link.ps1 -Site <s> -Slug <slug> -Url <amazon-url-no-tag> -Tag <site-tag> -Merchant amazon`) or the money button 404s. Bit the 2026-05-29 batch run (9 pieces shipped with unregistered `/go/` CTAs; fixed same day).
- **R5.2 🔒 Every `amazon.com` link carries the site's own `?tag=`.** ENFORCED: `scripts/lint-affiliate-tags.ps1` (pre-commit).
- **R5.3 👁️ Affiliate links open in a new tab with `rel="sponsored noopener" target="_blank"`.**

## 6. Color & per-site theming

- **R6.1 🧩 Each site has a locked visual identity; shared components inherit it via a per-site `site.css` token override (no shared-code edits per site).** Identities:
  - **mywildlifecam** — elevated nature publication (forest + cream + brass, Fraunces + Inter Tight).
  - **detailerpicks** — Chrome & Suds (cream + steel-blue, Instrument Serif).
  - **fussybean** — "looks like coffeeshops smell" (espresso/cream/caramel, Fraunces + Inter, warm).
  - **gameovergear** — retro Nintendo/Atari/arcade (pixel display type, CRT scanlines, neon arcade palette). Homepage mockup APPROVED by Ray 2026-05-29 (`docs/playgrounds/gameovergear-mockups/home.html`).
  - **starteraquarium** — fun + bright aquatic, but NOT childish (Poppins not Baloo, icon chips not big emoji, aquarium-glass palette not candy). v2 mockup at `docs/playgrounds/starteraquarium-mockups/home.html`.

## 7. Content & voice

- **R7.1 🔒 Never claim hands-on use** ("we tested", "we own", "hands-on review" are banned). Spec-driven + reviewer-attributed + use-case-framed. ENFORCED: `scripts/lint-voice.ps1` + full doctrine in `docs/voice-doctrine.md`.
- **R7.2 🔒 No em dashes in content body.** WHY: screams AI. Use commas/periods/"and". ENFORCED: `lint-voice.ps1`.
- **R7.3 👁️ No defensive audience exclusions** ("this isn't for hunters"). Write for the actual audience; let exclusion be implicit.
- **R7.4 🧩 `## Bottom Line` is human-written and gated.** Empty `bottomLine.verdict` → page emits `noindex,nofollow`. Never publish with it empty.

---

_Related canonical docs: project `CLAUDE.md` (web-vitals + pre-commit safeguards), `docs/voice-doctrine.md` (forbidden phrases), `docs/SYSTEM.md` (architecture). This file is the human-facing visual/UX bible those don't fully cover._

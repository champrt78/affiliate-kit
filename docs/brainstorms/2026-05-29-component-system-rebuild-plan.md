---
title: Component-System Rebuild — build once, skin per site, QA before live
date: 2026-05-29
status: proposed (awaiting Ray go-ahead)
origin: Ray's 2026-05-29 style pass (docs/STYLE_GUIDE.md intake I1-I12)
---

# Component-System Rebuild

## RECALIBRATED 2026-05-29 (Ray): tweak pass, not a ground-up rebuild
"We are actually pretty close with what we have, just a few last things need tweaked." So this is a TARGETED fix pass on the EXISTING shared components (`packages/shared-ui` already exists), not a from-scratch rebuild. Get the few remaining rules right in the shared layer so they propagate and stop recurring.

**Priority order (Ray, explicit):**
1. **READABILITY — #1.** People must be able to read easily, get interested, and click. Hard to read = they leave. Comfortable body size, good line length, contrast, calmer scale (~0.9-0.92, the "zoom out" feedback).
2. **Image fit — scale to FIT, never crop.** `object-fit: contain`: the whole image scales down to fit its box; we never crop the image to fill the box. Show the entire product, sized to fit.
3. Header full-width, content centering, distinct heroes, antenna-down product images (the rest below).

## Why
The 5 sites carry divergent copies of page templates + CSS, so the same visual bug exists in N places and gets fixed N times, retroactively, after going live. Ray's call: build it like React — a small set of correct shared components, then per site just swap palette + fonts + text + images + links. And a front-end QA pass must run BEFORE anything goes live, not after.

## Reference look (the target)
The live **DTP ceramic guide** (`detailerpicks.com/buyers-guides/best-ceramic-coating-for-home-detailers`) — Ray: "essentially what is right here." Background, content width, gutters, bg image. Scaled to ~0.9-0.92. The kit is built to reproduce this, then re-skinned.

## Acceptance criteria (from the style pass — the build is "done" when all pass on every site)
- **Media**: one shared component, fixed sane box (square or 4:3), `object-fit:contain`, centered. Any product image (tall antenna, wide, square) shows fully at a comfortable scale, never zoomed/cropped/stretched. [I1,I2,I7,I8]
- **Header**: full-width band, logo far-left, nav far-right, edge to edge; NOT clamped to the article shell. [I9]
- **Shell/centering**: content column centered, symmetric gutters, on article AND index pages; index headings get padding (not flush to edge). [I3,I4,I5,I11]
- **Scale**: global base type + spacing set ~0.9-0.92 of current live; body copy reads comfortably, nothing feels zoomed. [I12,R1.6]
- **Hero imagery**: per-piece, distinct; no shared default hero across guides. [I10]
- **Product image quality**: prefer antenna-down / well-framed gallery variants. [R1.5]
- **Voice**: zero forbidden phrases in templates or content; lint scans `.astro` + content. [I6 — done]
- **Grid balance**: 6 picks = 2x3; never 5 or orphan rows. [#57 rule]
- **Web vitals**: every img has width/height attrs. [R1.1]

## Architecture
- **`packages/shared-ui`** owns the WHOLE page now: `BaseLayout`, `SiteHeader`, `SiteFooter`, `PageShell`, `Hero`, `Media`, `PickCard`, `PickGrid`, `DeepCard`, `BottomLine`, `Scorecard`. Built once to the criteria above.
- **Per site = two things only:** (1) a tokens file (palette + fonts + gutter/bg image) — the existing `site-tokens.css` / `site.css` pattern; (2) content (markdown + `site-config.json`: text, images, links). Nothing else diverges.
- **Scale + spacing** live as tokens in the kit base, so the ~0.92 scale is one source of truth.

## Build order
1. **Kit**: build/normalize the shared components to the criteria, matched to the DTP-ceramic reference at ~0.92. Storybook-style verify via the canonical mockup (already approved structure).
2. **Migrate DTP** (the reference) onto the kit → screenshot-verify all page types at 1440 + 390.
3. **Migrate MWC + fussybean** → re-verify. (Also swap MWC trail-cam images to antenna-down per R1.5.)
4. **Build the 2 cold sites** (gameovergear retro, starteraquarium fun-v2) on the kit from day one — they never get divergent copies.
5. **Re-wire Magic Go**: content pipeline (research/validate) stays; rendering targets the kit; a new piece is correct by construction.
6. **Pre-publish front-end QA gate**: a front-end agent screenshots each new piece at real viewports and checks the acceptance criteria BEFORE the noindex flips. Fails the publish if a criterion is violated. This is the "pass before live" Ray asked for.

## Enforcement (so it can't regress)
- Acceptance criteria live in `docs/STYLE_GUIDE.md` (the bible).
- Lints catch what's lintable (images, tags, voice incl. `.astro`, img dims).
- The QA-gate agent catches the visual ones (scale, centering, header width, image framing) pre-publish.

## Risk / notes
- Migrating live sites onto the kit is the delicate step — do DTP first, verify hard, then roll. Keep each site's old templates until its migration verifies green.
- This re-wires Magic Go (Ray approved: "if we need to kinda start over and re-wire the magic go button a little that is fine").
- Existing 9 published pieces stay live; they re-render through the kit on migration (content unchanged).

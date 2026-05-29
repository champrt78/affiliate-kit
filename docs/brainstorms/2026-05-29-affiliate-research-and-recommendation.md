---
title: What makes a successful affiliate site — research + build recommendation
date: 2026-05-29
status: report for Ray (decision pending)
sources: affilorama.com/website-layouts, squarespace affiliate-website-examples, openEHR affiliate template, GitHub affiliate/blogger-template/jekyll topics, plus affiliate-SEO domain knowledge
---

# Research: what makes a successful affiliate site, and what we should build

## 1. What the research says (synthesized)

**A. Readability + scannability is foundational.** Generous white space measurably lifts readability (~20%) and perceived trust. Short paragraphs, bold callouts, clear subheads, comfortable type. → This validates Ray's "readability is #1." Our current pages fail this where they feel "zoomed in / hard to read."

**B. Speed + mobile decide whether people stay.** 53% abandon a page that takes >3s; ~53% of traffic is mobile; Google indexes mobile-first. → Our Astro static stack is already excellent here. This is a reason NOT to switch to a JS-heavy stack.

**C. Trust / E-E-A-T wins the click.** Real photos (not stock), a real About/author story, pros AND cons (admitting negatives boosts credibility), credentials, a transparent methodology. → We already have About + how-we-evaluate + the comparison-and-fit doctrine + buyIf/flaws (pros/cons). Strong. Keep + surface more.

**D. The proven REVIEW/GUIDE layout:**
- A verdict/summary box at the TOP (so skimmers get the answer fast). → This is literally our `## Bottom Line` gate. We already do the single highest-leverage thing right.
- A comparison/spec table ("at a glance"). → We have it; should make it the scannable centerpiece.
- "Best for X" segmented picks, not feature-count ranking. → Our two-tier pick cards + `bestFor`. Already aligned.
- Pros/cons per product. → buyIf/flaws.
- One clear primary CTA, high-contrast, placed AFTER credibility; multiple affiliate links through a review is fine; sticky CTA acceptable on reviews. → We have the `/go/` CTA; could add a sticky buy-bar on long reviews.
- Schema markup (Review/Product/FAQ) for rich snippets. → CONFIRMED we already emit JSON-LD (shared `packages/shared-utils/src/schema.ts` with tests, wired into the review + guide templates). Strength, keep it.
- High-quality, distinct, real product images, contained not cropped. → Exactly Ray's image rule.
- Conventional layout (logo→home, standard nav), KISS, minimal sidebar/distraction, full-width header. → Matches Ray's header + simplicity asks.

**E. Homepage = pillar/category hubs + featured guides.** Organize by category, feature popular/seasonal guides. → We already have pillar IA + `/topics/<pillar>/` hubs.

## 2. What the GitHub templates tell us (stack decision)

- The `topics/affiliate`, `topics/blogger-template`, `topics/jekyll-blog` pages are lists of mostly hobby/static templates. The openEHR one is a single-page community template (not product-review shaped). The MERN example is a client-rendered React app.
- **Takeaway: none of them beat our current stack for THIS job.** MERN (client-rendered React) is actively WORSE for an affiliate site — slower first paint, weaker SEO out of the box, more infra. Jekyll is fine but Astro is strictly better (islands, faster, better DX). Our Astro + Cloudflare static setup is already the stack a "successful affiliate site" research would point you to: fast, cheap, SEO-friendly, mobile-first.
- **So: keep Astro. Do NOT switch frameworks.** The React analogy Ray wants is achievable WITHIN Astro via shared components (`packages/shared-ui`) — that IS componentized like React.

## 3. The honest diagnosis

Our **content model and stack are right** (the research validates Bottom-Line-at-top, comparison-and-fit, bestFor, pros/cons, E-E-A-T, Astro static). What's wrong is the **presentation layer**: divergent per-site templates, images cropped/zoomed, scale too big/hard to read, header not full-width, repeated heroes. These are exactly the things a clean shared component layer fixes once.

## 4. Recommendation

**Rebuild the COMPONENT LAYER (not the stack), to the proven patterns, readability-first.** Same Astro + Cloudflare, same content/Magic-Go pipeline. Promote the whole page into `packages/shared-ui` as a tuned kit:

- **Readability baked in:** ~0.9-0.92 base scale, comfortable body size (~17-18px reading size on article prose), ~65-75 char line length, strong heading hierarchy, generous white space.
- **Media component:** contain (whole image fits, never cropped), sane fixed box, centered.
- **Review/guide layout to the proven pattern:** verdict box top (Bottom Line), at-a-glance comparison table, bestFor pick cards, pros/cons, one high-contrast CTA + optional sticky buy-bar, distinct real hero, Review/Product/FAQ schema.
- **Full-width header, centered shell, per-site tokens only.**
- **Pre-publish front-end QA gate** in Magic Go.

This is a real rebuild of the presentation layer — which Ray is open to — but on the stack the research says is correct, reusing everything that already works.

## 5. Decision for Ray
- **Option 1 (recommended): Component-layer rebuild on Astro.** Clean shared kit tuned to the research + your requirements; migrate DTP→MWC→fussybean→cold sites; rewire Magic Go to render into it + QA gate. Keeps speed/SEO, fixes all the flagged issues at the root.
- **Option 2: Minimal tweak pass.** Just patch the few things in the existing shared components (image contain, scale, header). Faster, but the per-site divergence stays, so drift can recur.
- **Not recommended: stack switch** (MERN/Jekyll/new template). Worse for affiliate SEO/speed; throws away working content + pipeline.

My recommendation: **Option 1**, scoped tightly to the acceptance criteria already in `docs/STYLE_GUIDE.md`.

---
title: Revenue Plan — money-sites-first (comparisons + EEAT + linking)
date: 2026-06-01
status: AWAITING RAY SIGN-OFF
scope: MyWildlifeCam (hero) + DetailerPicks. Satellites = content cadence only.
origin: 5-site readability pass + 2026 affiliate-revenue research (this session)
---

# Revenue Plan — what actually drives sales, money-sites-first

## The thesis (from 2026 research, not 2019 dogma)
Goal is **$$**. The research ranked the revenue levers for a small 2026 affiliate site:
1. **Buyer-intent content** (comparisons + "best X") — drives ranking AND conversion at once
2. Content depth with genuine first-hand/analysis signals
3. Topical coverage breadth (pays off in 6–12 mo)
4. **Site structure / internal linking** — real, but lever #4, NOT the money switch
5. On-page conversion (verdict + table above the fold)
6. EEAT signals — mostly *defensive* (prevents the ranking loss that hit 71% of affiliate sites in the Dec 2025 helpful-content update)

**Honest framing:** structure is hygiene; the money levers are **comparison content + on-page conversion + content depth.** This plan leads with those and treats IA as concurrent polish, not a gate. Revenue is months out regardless (3–6 mo to traffic, 5–8 mo to first ~$1k via SEO) — these are the right bets, not a switch.

## Scope (Ray locked 2026-06-01)
- **NOW — MWC + DTP** (the revenue sites): comparison content type + EEAT signals + internal-linking polish.
- **Satellites (FB / SA / gog):** buyer-intent content cadence via Magic Go. **Their IA restructure is deferred** — research says restructuring thin content is premature; publish first, structure once there's content.
- **Not in scope:** abandoning the voice doctrine (see Workstream B for the EEAT-safe resolution); satellite silos now.

---

## Workstream A — Head-to-head "X vs Y" comparison content type  ★ lead revenue lever
Converts **2–5× informational**; AI Overviews hit comparison queries far less than how-tos; highest buyer intent. MWC has zero today.

- **New `comparisons` content collection** + schema: `productA`, `productB` (optionally C), shared `specMatrix`, `verdict` (who-wins + who-should-buy-each), `dealBreakers`, `faq`, affiliate links per product.
- **`ComparisonArticle` shared component** reusing the kit (`ComparisonTable`, `BottomLine` buy/skip pattern, `Media`, `FaqList`). Structure that converts (per research):
  - Comparison **table within the first ~300px** (not gated below the fold)
  - **Verdict / recommendation block** right at top — answer before the scroll
  - Sections: specs · use-case fit · price/value · deal-breakers · "Who should buy A / Who should buy B"
  - Affiliate links in **both** the table AND the verdict; honest limitation callout on the winner
  - Build **both URL directions** (`/a-vs-b/`, `/b-vs-a/`) with canonical → one
- **First targets (highest ROI):** MWC trail-cam head-to-heads (e.g. Browning vs Stealth Cam, Spypoint vs Moultrie cellular); DTP 2–3 (e.g. ceramic spray vs wax, foam cannon vs foam gun).
- **Magic Go:** add `comparison` as a 3rd emittable piece type (scaffolder + body-fill), so the engine produces them on cadence.

## Workstream B — EEAT signals (defensive vs the HCU; cheap, do now)
Dec 2025 update rewarded methodology + first-hand signals; punished spec-recitation. Our voice doctrine ("no hands-on claims") is the flagged tension — **resolution the surviving sites use, and which fits our doctrine: disclose the method clearly and make it prominent.** No doctrine change.

- **Prominent "How We Evaluate" box** ON each guide/review/comparison (not just the standalone page): "specs analyzed · N owner reports synthesized · independent teardowns reviewed — we don't take payment from brands." This *is* the voice-doctrine methodology disclosure, surfaced where Google + readers see it.
- **Author byline + a real author/About credential line** per site (legit experience framing, no fake testing claims).
- **"Last updated" date** visible on every piece (verify present + accurate).
- **Honest limitation callout** prominent on every review/comparison (we have "Where it falls short" / flaws — make sure it's not buried).
- **Original-analysis signal**: "we synthesized 47 verified-buyer reports across 3 models" (+156% AIO citation chance) — a framing we can do truthfully under the doctrine.

## Workstream C — Internal linking / IA polish (MWC + DTP only)
Both money sites are currently **flat** (Home/Guides/Reviews/About, zero pillar hubs) while the satellites are siloed — backwards. Concurrent with content, NOT a gate.

- Give MWC + DTP **pillar/topic hubs** (the satellites' topic-hub component already exists — wire pillars into their `site-config.json` + reuse the hub).
- **Contextual** internal links pillar ↔ cluster ↔ piece (NOT forced exact-match anchors — the research says over-optimized internal linking is now a negative signal).
- Comparison pages link out to the single-product reviews + the relevant buying guide (and vice-versa).

## Workstream D — AI-Overview citation hygiene (cheap, high-leverage)
AIOs are on 48% of queries; cited content skews to: schema (2.1×), FAQ (1.9×), original data (+156%), 2,000+ words (3×).
- Verify Review/Product schema on reviews+guides and FAQPage on all (mostly present — audit).
- Add the original-data line (Workstream B) to qualify for citation.
- **Audit + upgrade-or-remove thin spec-recitation content** — it ranks briefly, gets zero-clicked, and signals low quality post-HCU.

## Satellites — content cadence (no IA work now)
Run **Magic Go** to publish buyer-intent pieces (best-X + the new comparisons) on the satellites' slower clock. Revisit their IA only once each has a content base. (This is the existing Magic Go roadmap — this plan just confirms content-before-structure for the cold sites.)

---

## Sequence
1. **A1** — build the `comparisons` collection + `ComparisonArticle` component (reuses kit) → ship 1 MWC comparison as the proof piece, Ray reviews the format.
2. **B** — EEAT box + byline + dates wired into the shared guide/review/comparison components (one pass, all money-site pages benefit).
3. **A2** — 2–3 more MWC comparisons + 2 DTP; wire Magic Go to emit `comparison`.
4. **C** — MWC + DTP pillar hubs + contextual internal links.
5. **D** — schema/FAQ/thin-content audit.
6. Satellites: Magic Go cadence (parallel, ongoing).

## What success looks like (honest leading indicators — not overnight)
- Comparison pages indexed + ranking for "X vs Y" long-tail (weeks to months)
- EEAT signals live before the next core update (defensive)
- Then: impressions → clicks → first comparison-driven commissions (months). We track in the cockpit.

## Open questions for Ray
1. **Author identity for bylines** — a persona name per site (e.g. "the MyWildlifeCam field desk") or your real name/initials? EEAT wants a credible author; your call on identity.
2. **First comparison matchups** — want to pick the MWC trail-cam pairings, or have scout/research propose the highest-search-volume "X vs Y" pairs?
3. **Comparison verdict** — does it stay your gate (you write the winner call), like the Bottom Line? (Recommend yes — same DRAFT/noindex gate.)

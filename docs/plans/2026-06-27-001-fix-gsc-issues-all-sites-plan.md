---
title: "fix: Resolve GSC indexing gap + product snippet schema errors across 5 sites"
date: 2026-06-27
status: active
type: fix
---

# fix: Resolve GSC indexing gap + product snippet schema errors across 5 sites

## Summary

Three parallel tracks: (1) fix the product snippet schema bug in shared code so all Product JSON-LD passes Google validation, (2) submit sitemaps and request manual indexing for key pages via GSC browser automation, (3) run IndexNow to push live URLs to Bing/Yandex. The noindex gap is primarily a Google crawl-timing issue — sitemaps are correct — but manual indexing requests and IndexNow re-submission are the levers we control.

---

## Problem Frame

GSC audit (2026-06-27) revealed:
- **7 INVALID product snippets** on detailerpicks.com (0 valid) — caused by a schema bug, not content
- **Indexing gap** across all 5 sites: ~15 pages indexed total vs. 38+ live pages (June 2 publish)
- **Sitemaps likely not submitted** to GSC (unverified — submit step may have been skipped)
- **DTP registered as URL prefix** (`https://detailerpicks.com/`) vs. domain property like the other 4

---

## Root Cause Analysis

**Schema bug:** `productSchema()` in `packages/shared-utils/src/schema.ts` only adds an `offers` block when `price !== undefined`. No content files define `price` (affiliate model — prices change). No `aggregateRating` is added either. Result: every Product JSON-LD has `name` + `brand` + `sku` + `image` + `description` but zero of the required `offers | review | aggregateRating` fields Google demands for a valid product snippet.

**Indexing gap:** The `prune-sitemap-noindex.mjs` post-build script correctly strips noindex pages from sitemaps. The built `dist/sitemap-0.xml` files are clean. The gap is that: (a) sitemaps may not be submitted to GSC, (b) IndexNow was set up but may not have been re-run after the June 2 verdict flip, and (c) Google crawls new sites slowly regardless.

---

## Requirements

- R1: All Product JSON-LD on review pages must pass Google Rich Results validation (have `aggregateRating` at minimum)
- R2: Sitemaps submitted to GSC for all 5 sites
- R3: Key pages on all 5 sites have indexing requested via GSC URL Inspection
- R4: IndexNow submission fired for all 5 sites post-fix
- R5: GSC unread notifications reviewed for any actionable issues
- R6: DTP added as domain property in GSC (low priority)

---

## Key Technical Decisions

**Add `aggregateRating` not `price`:** Content files don't track price (affiliate model — Amazon prices fluctuate). Adding a price field would require maintenance every few months. `aggregateRating` from the existing `rating` field (present on every review) is the correct fix — it satisfies Google's requirement without introducing stale data.

**`aggregateRating.ratingCount: 1`:** Schema.org requires `ratingCount` alongside `ratingValue`. Since these are editorial scores (not user ratings), we use `1` as the count representing the single editorial rating. This is honest and passes validation.

**Sitemaps via GSC browser automation:** The sitemap URL pattern is `https://<domain>/sitemap-index.xml` for all sites (Astro generates `sitemap-index.xml` + `sitemap-0.xml`). Submit the index file.

---

## Implementation Units

### U1. Fix `productSchema()` to include `aggregateRating`

**Goal:** Add `aggregateRating` to the Product JSON-LD output so Google can validate the schema.

**Requirements:** R1

**Dependencies:** none

**Files:**
- `packages/shared-utils/src/schema.ts` — add `rating` to `ProductSchemaInput`, add `aggregateRating` block to output
- `packages/shared-ui/src/components/ReviewArticle.astro` — pass `rating: data.rating` to `productSchema()`

**Approach:**
- Extend `ProductSchemaInput` with optional `rating?: number`
- In `productSchema()`, when `input.rating !== undefined`, add:
  ```
  aggregateRating: {
    "@type": "AggregateRating",
    ratingValue: input.rating.toFixed(1),
    bestRating: "5",
    worstRating: "1",
    ratingCount: 1
  }
  ```
- In `ReviewArticle.astro`, add `rating: data.rating` to the `productSchema({...})` call
- Check `GuideArticle.astro` to see if it also calls `productSchema` — if so, apply the same fix

**Test scenarios:**
- `productSchema({ ..., rating: 4.5 })` → output includes `aggregateRating.ratingValue: "4.5"`
- `productSchema({ ..., rating: undefined })` → output has no `aggregateRating` key (no crash)
- `productSchema({ ..., price: 29.99, currency: "USD", offerUrl: "...", rating: 4.5 })` → output has BOTH `offers` AND `aggregateRating`
- Generated HTML on a review page contains valid JSON-LD with `@type: "Product"` + `aggregateRating`

**Verification:** Run Google's Rich Results Test against a DTP review URL after deploy. Should show 0 errors.

---

### U2. Build all 5 sites and run IndexNow submission

**Goal:** Rebuild all sites (picks up the schema fix) and push live URLs to Bing/Yandex via IndexNow.

**Requirements:** R4

**Dependencies:** U1 (build after schema fix)

**Files:**
- No code changes — this is a build + script execution step
- `scripts/indexnow-submit.mjs` — already exists, run after build

**Approach:**
- Run `pnpm build` (or per-site builds) to regenerate dist with fixed schema
- Run `node scripts/indexnow-submit.mjs` from repo root — submits all 5 sites
- Check output for HTTP 200/202 per site; 403 = key file not reachable

**Test expectation:** none — this is a script execution step, not a code unit

**Verification:** Script outputs `HTTP 200 OK` or `HTTP 202 OK` for all 5 sites

---

### U3. Submit sitemaps to GSC for all 5 sites

**Goal:** Ensure sitemaps are registered in GSC so Google discovers all live pages.

**Requirements:** R2

**Dependencies:** U2 (sitemaps should reflect rebuilt/clean state)

**Files:** No code changes — browser automation against GSC

**Approach:** For each site in GSC (mywildlifecam, detailerpicks, fussybean, gameovergear, starteraquarium):
- Navigate to Indexing → Sitemaps
- Submit `sitemap-index.xml` if not already present
- Verify status shows "Success"

**Sitemap URLs to submit:**
- `https://mywildlifecam.com/sitemap-index.xml`
- `https://detailerpicks.com/sitemap-index.xml`
- `https://fussybean.com/sitemap-index.xml`
- `https://gameovergear.games/sitemap-index.xml`
- `https://starteraquarium.com/sitemap-index.xml`

**Test expectation:** none — console operation

**Verification:** Each site's Sitemaps section shows the sitemap with "Success" status and a discovered URL count matching the live page count

---

### U4. Request manual indexing for priority pages via GSC URL Inspection

**Goal:** Accelerate indexing of the most important pages by requesting Google crawl them now.

**Requirements:** R3

**Dependencies:** U3

**Files:** No code changes — browser automation against GSC

**Approach:** For each site, use GSC URL Inspection → "Request indexing" on the homepage + 2-3 top content pages. Priority order:
- mywildlifecam.com homepage + top review (hero site)
- detailerpicks.com homepage + top review
- Other 3 sites: homepage only (satellites, lower priority)

**Test expectation:** none — console operation

**Verification:** GSC shows "Indexing requested" status; pages appear in Google search within 1-7 days

---

### U5. Read and resolve GSC notifications across all 5 sites

**Goal:** Clear unread notifications (2-7 per site) and identify any actionable issues not caught in the overview.

**Requirements:** R5

**Dependencies:** none — independent

**Files:** No code changes — browser automation

**Approach:** Open the bell icon in GSC for each property, read notifications, note any actionable items (manual actions, security issues, new issues). Most are likely informational (new property added, verification confirmed) but some may flag specific pages.

**Test expectation:** none — review step

**Verification:** All notifications read; any actionable ones logged in session notes

---

### U6. Add detailerpicks.com as a domain property in GSC

**Goal:** Get full coverage for DTP (all protocols/subdomains) alongside the existing URL prefix property.

**Requirements:** R6

**Dependencies:** none — independent of other units

**Files:** No code changes — GSC console

**Approach:**
- In GSC, click "+ Add property" → Domain → enter `detailerpicks.com`
- Follow DNS TXT record verification (same flow as other 4 sites)
- Note: this requires adding a DNS TXT record in Cloudflare dashboard (`raychampion78@gmail.com` account)

**Test expectation:** none — console operation

**Verification:** DTP appears twice in the property list — once as domain, once as URL prefix. Domain property begins accumulating data.

---

## Scope Boundaries

**In scope:**
- Schema fix across all sites (shared component, 1 code change)
- Sitemap submission for all 5 sites
- IndexNow re-push for all 5 sites
- Manual indexing requests for priority pages
- GSC notifications review

**Deferred to Follow-Up Work:**
- Buying guide product schema (if `GuideArticle.astro` doesn't call `productSchema`, no fix needed — check in U1)
- Google-side rich result validation testing after deploy (verify step, not code)
- Core Web Vitals — no data yet; not actionable until traffic grows
- Cloudflare Crawler Hints toggle (alternative to IndexNow; revisit if IndexNow shows 403s)

**Out of scope:**
- Content creation / adding more pages to index
- Any changes to the noindex gating logic (it works correctly)
- Price tracking / affiliate price feeds

---

## Risks & Dependencies

- **IndexNow 403**: If the key file isn't reachable at `https://<domain>/5d0d95fb745523afd64fcf3d113d2c95.txt`, the submit will fail. Key files are in `public/` so they deploy with the site — should be fine, but verify for each site.
- **GSC DNS verification for DTP domain property (U6)**: Requires touching Cloudflare DNS. Low risk but needs confirmation before executing.
- **Google crawl timing**: Even after manual indexing requests, Google may take days to index. This is normal — not a failure of the fix.

---

## Sequencing

```
U1 (schema fix) → U2 (build + IndexNow) → U3 (submit sitemaps) → U4 (request indexing)
U5 (notifications) — parallel, any time
U6 (DTP domain property) — low priority, after U3
```

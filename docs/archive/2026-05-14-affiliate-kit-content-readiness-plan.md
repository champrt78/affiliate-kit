---
title: "feat: affiliate-kit content-production readiness (unblock review #1)"
type: feat
status: active
date: 2026-05-14
origin: in-conversation 4-agent CE evaluation (no formal requirements doc — agent reports in 2026-05-14 session)
---

# feat: affiliate-kit content-production readiness (unblock review #1)

## Overview

Phase 1 of the affiliate-kit shipped infrastructure perfectly — 5 sites live on Cloudflare Pages, link-cloaker Worker deployed and smoke-tested, bootstrap CLI that successfully bootstrapped all 5 sites end-to-end. Phase 1 shipped exactly **zero content-production capability**: no review-route renderer in the site template, no review markdown templates, no `/aff-new-review` command, no KV-management scripts, no playbook documenting the quarterly cycle. The four CE evaluation agents independently converged on the same root finding — every site is currently building with `https://example.com` as its canonical URL (silent SEO killer), and there is no Astro page that consumes the `reviews` content collection schema.

This plan adds the tooling, templates, docs, and infrastructure fixes needed to:

1. **Unblock review #1** on the hero site (`sites/mywildlifecam/`)
2. **Remove friction** from the per-review production loop so the quarterly cycle is repeatable
3. **Harden the Worker** on two cheap-now-expensive-later issues while KV is empty
4. **Make the docs honest** about what the plugin actually does

Scope is deliberately narrow: this plan does NOT replace the `__TOKEN__` template-substitution system with a data-driven `site.config.ts`, does NOT build the PA-API image helper (gated by Amazon Associates 3-sales approval), and does NOT add hero/satellite tier modeling to the bootstrap CLI. Those are deferred.

---

## Problem Frame

Ray wants to write affiliate reviews. The infrastructure exists; the content-production path does not. Specifically, when Ray sits down to write review #1 on `mywildlifecam.com`:

- He has no review markdown template to copy from
- Even if he writes the MDX by hand, there is no `src/pages/reviews/[slug].astro` to render it — `astro build` succeeds, but no review URL exists
- The `reviewSchema()` / `productSchema()` / `faqSchema()` helpers in `packages/shared-utils/src/schema.ts` are tested and working but imported by zero files
- He has to remember `wrangler kv key put --remote --namespace-id=...` to add the cloaked-link entry (got bit by missing `--remote` on Phase 1)
- His own `COMMANDS.md` cheatsheet lists 5 slash commands that don't exist
- The `tone: polite|snarky|spicy` config field and `--spicy` flag are typed and documented but consumed by zero lines of code
- Every page Google currently crawls has `<link rel="canonical" href="https://example.com/...">` baked in
- The Worker accepts `mywildlifecam.com/go/fussybean/breville-bambino` and happily redirects to fussybean's affiliate URL — cross-tenant link leak

The biggest risk to this project is not code defects — it is "Ray never starts writing reviews because the friction is too high at the moment of inspiration."

---

## Requirements Trace

- R1. Ray can write a review markdown file from a template, run a single script, and have a live published `<apex>/reviews/<slug>` URL with correct schema markup and a working cloaked affiliate-link button
- R2. The 5 already-deployed sites stop serving `https://example.com` as their canonical URL
- R3. The `<apex>/sitemap-index.xml` URL advertised in robots.txt actually resolves to a generated sitemap
- R4. Adding, listing, or removing an affiliate link is one script invocation, not a memorized wrangler command with a `--remote` gotcha
- R5. The playbook for one review, and for the 90-day cycle that contains it, exists as a single readable document
- R6. The plugin's documented surface area matches what the plugin actually does — no advertised commands that don't exist
- R7. The Worker cannot serve a cross-tenant link (`<site-A>/go/<site-B>/<slug>` must not 302 to site-B's URL)
- R8. KV values can carry status metadata (`active` / `retired` / `replaced_by`) so the future refresh-sweep can flip a flag instead of deleting entries

---

## Scope Boundaries

- This plan does NOT replace `__TOKEN__` template substitution with a data-driven `site.config.ts`. The substitution works; the cost-of-change for renames is medium and renames are rare.
- This plan does NOT build the Amazon PA-API integration. PA-API access requires 3 qualifying affiliate sales in 180 days — chicken-and-egg gated. Stub helper interface can land later when access is approved.
- This plan does NOT model hero/satellite tier asymmetry in the bootstrap CLI. The differential is encoded in the playbook prose, not in tooling.
- This plan does NOT add the `/aff-cycle`, `/aff-refresh`, `/aff-status`, `/aff-next` slash commands. Those are correctly Phase 2/3 work. This plan removes them from the docs as advertised capability and replaces them with a stub `/aff-help` that derives the real list from `plugin/commands/`.
- This plan does NOT touch the `affkit_clicks` Analytics Engine reading path. A documented SQL-query bundle is honorable-mention-deferred — the Worker writes the data correctly today; querying it can wait until review #5 or so when there's actually data.
- This plan does NOT enable Cloudflare R2. R2 enablement is a dashboard click, not a code change; deferring to when the first product image needs hosting.
- This plan does NOT enroll Ray in Amazon Associates. That is Ray's action, not implementation.

### Deferred to Follow-Up Work

- **`docs/AFFILIATE_PROGRAMS.md`** — checklist of affiliate programs (Amazon Associates, niche-specific) with status, tracking tag, approval date. Worth writing but trivially small; can land alongside review #1 prep when Ray submits the Associates application.
- **Edge-cache the 302 + STATUS kill-switch in the Worker** — real and valuable, but no traffic yet means no observable cost. Wait until review #1 generates first clicks.
- **Worker `/healthz` route + Analytics Engine query bundle (`workers/link-cloaker/queries.md`)** — observability polish; defer until there's data worth querying.

---

## Context & Research

### Relevant Code and Patterns

- `templates/site-template/src/content/config.ts` — defines `reviews`, `buyers-guides`, `learn` Zod schemas. Renderer must match these field shapes exactly.
- `packages/shared-utils/src/schema.ts` — `productSchema()`, `reviewSchema()`, `faqSchema()` JSON-LD builders. Tested. Currently orphaned.
- `packages/shared-utils/src/cloaked-link.ts` — `cloakedLink({site, slug})` helper. Note: post-Worker-URL-fix, the `site` parameter is dropped.
- `packages/shared-ui/src/components/` — `BaseLayout`, `Hero`, `CTA`, `ComparisonTable`, `AffiliateDisclosure`. `CTA` already takes `rel` and `target` props — wire from the review renderer.
- `workers/link-cloaker/src/index.ts` — 44-line Worker. KV-backed redirect, writes one Analytics Engine data point per hit. Tests at `workers/link-cloaker/test/cloaker.test.ts` use `@cloudflare/vitest-pool-workers` with a real KV binding.
- `tools/bootstrap/src/copy-template.ts` — substitutes `__SITE_NAME__`, `__TAGLINE__`, etc. into copied template files. Currently substitutes nothing in `astro.config.mjs` because the file uses `process.env.SITE_URL ?? "https://example.com"` rather than a placeholder.
- `tools/bootstrap/src/wrangler.ts` — shells out to wrangler. Pattern for KV scripts to follow.
- `scripts/install-plugin.ps1` — pattern for plugin installer. Idempotent re-runs preserve config.json.

### Institutional Learnings

- **`wrangler kv` defaults to local state, not production.** Phase 1 session log Wrap (commit `4eca7db`) captured this. Every `kv key put/delete` must use `--remote` to hit production. Scripts MUST bake this in.
- **Windows symlink copies fail in template clones.** Phase 1 patched `copy-template.ts` to filter `node_modules/`, `.astro`, `dist`. New scripts that copy templates should follow the same pattern.
- **`gh` active account flips between sessions.** Today's session log notes the `rchampion_arrow` vs `champrt78` switch. Worth a `gh auth status` check before any push-from-script — but out of scope for THIS plan (the new scripts target wrangler/KV, not gh).
- **Naming-craft bar applies to user-facing strings.** Per memory: cadence/syllables/tongue-feel/earworm matter for taglines, slugs, and any string a customer sees. Affects PLAYBOOK.md tone but not implementation.

### External References

- Astro sitemap integration: https://docs.astro.build/en/guides/integrations-guide/sitemap/
- Astro content collections + routing: https://docs.astro.build/en/guides/content-collections/
- Cloudflare Workers `URL` API + Host header access: standard fetch API, no version-specific gotchas

---

## Key Technical Decisions

- **Decision: Drop the `<site>` segment from cloaked URLs; derive site from Host header.** The Worker route is already per-apex (`<apex>/go/*`). Trusting the URL path for `<site>` is cross-tenant unsafe and adds redundant URL noise. While KV is empty, the migration cost is zero. Worker maintains a small `apexToSite` constant (5 entries).
- **Decision: Structured KV values, not raw URL strings.** KV value shape becomes `{ url, tag, merchant, status, updated, replaced_by? }`. Worker reconstructs the final redirect at request time by applying `?tag=<tag>` (where applicable). Enables future refresh-sweep status flips and Amazon tag rotation without re-importing every KV entry. JSON parse with safe fallback to plain-string-as-`url` for any legacy values (currently none in production).
- **Decision: Delete `tone` config + `--spicy` flag.** Documented but unwired. Two options: wire it through or delete it. Wiring requires building per-tone string tables across all command output, adds carrying cost, has no clear customer need beyond personal preference. Deletion is one type narrowing + one doc line removal. Pick deletion. Can be re-added when there's a concrete consumer.
- **Decision: Site-template renderer is the source of truth; back-propagate to 5 sites by rsync-style copy.** The 5 sites are byte-for-byte template copies today (per architecture agent). Adding a new file under `templates/site-template/src/pages/reviews/[...slug].astro` and propagating via `cp -r templates/site-template/src/pages/reviews sites/<slug>/src/pages/` to each site is the simplest, lowest-risk path. Bootstrap CLI does not need to change.
- **Decision: SITE_URL substitution at bootstrap time, not runtime.** Replace `process.env.SITE_URL ?? "https://example.com"` in `astro.config.mjs` with a literal `__SITE_URL__` placeholder, substituted by `copy-template.ts` at bootstrap. Eliminates the runtime-env dependency. Already-bootstrapped sites need a one-time fix: replace the broken line in each `sites/<slug>/astro.config.mjs` with the literal URL.
- **Decision: `scripts/new-review.ps1` is a thin PowerShell wrapper, not a TypeScript CLI.** The interaction is cp + sed-style frontmatter fill + one `wrangler kv key put --remote` shell-out. PowerShell is already required for the install script; adding a TypeScript dependency here adds complexity without value. Keep TypeScript for the bootstrap CLI where the surface area is large.
- **Decision: `/aff-help` is a slash command that reads `plugin/commands/` at invocation time and prints the actual command list.** Auto-derived prevents doc/code drift, which is exactly the class of bug Phase 1 hit four times (apex, KV permission, scoped policies, `--remote`).
- **Decision: `docs/PLAYBOOK.md` describes the per-review workflow and the 90-day cycle in one document, no separate refresh-sweep doc.** One file Ray can read in 5 minutes when starting a cycle is more useful than three files he won't remember where to find.

---

## Open Questions

### Resolved During Planning

- **Wire or delete the `tone` config?** → Delete. Re-add when a concrete consumer exists. Lower carrying cost.
- **Worker URL collision fix: clean break or backward-compat?** → Clean break. KV is empty in production; no external traffic depends on `/go/<site>/<slug>` shape; the existing `cloakedLink()` helper changes once and recompiles cleanly via TypeScript strict mode.
- **Site config refactor (`__TOKEN__` → typed `site.config.ts`)?** → Defer. Brand renames are rare; current substitution works; cost-of-change is medium.
- **Hero/satellite tier modeling in tooling?** → Defer. Encoded in PLAYBOOK.md prose, not tooling. Revisit if the playbook diverges enough between tiers to justify code-level branching.
- **`/aff-cycle` and other Phase 2 commands?** → Not in this plan. Document as `(NOT YET)` in COMMANDS.md.

### Deferred to Implementation

- **Exact frontmatter field set for the review template.** The Zod schema in `src/content/config.ts` is the authoritative shape; the template just needs to match. Implementer should diff template against schema as the final step.
- **Per-site `SITE_URL` lookup table in `tools/bootstrap/src/index.ts`** vs deriving from `<slug>` + a TLD config. The 5 known sites have varying TLDs (`.com`, `.games`); a lookup table is more explicit but requires editing in two places (bootstrap CLI + known-sites map). Decide at implementation time based on what's already in `index.ts`.
- **PowerShell vs cross-platform shell for `new-review.ps1` and `add-link.ps1`.** Ray is on Windows; bootstrap CLI is already PowerShell-flavored. If a sibling Bash port is ever needed, mirror the structure. Defer until needed.

---

## Implementation Units

- [ ] U1. **Substitute `SITE_URL` into `astro.config.mjs` at bootstrap time**

**Goal:** Eliminate the `https://example.com` canonical-URL silent SEO regression on all 5 sites and bake the correct site URL into the build output at bootstrap time.

**Requirements:** R2

**Dependencies:** None

**Files:**
- Modify: `templates/site-template/astro.config.mjs` (replace `process.env.SITE_URL ?? "https://example.com"` with `__SITE_URL__` literal placeholder)
- Modify: `tools/bootstrap/src/copy-template.ts` (substitute `__SITE_URL__` along with the existing `__SITE_NAME__`, `__TAGLINE__`, etc.)
- Modify: `tools/bootstrap/src/index.ts` (pass the resolved `siteUrl` to `copyTemplate`)
- Modify: `sites/mywildlifecam/astro.config.mjs`, `sites/fussybean/astro.config.mjs`, `sites/detailerpicks/astro.config.mjs`, `sites/starteraquarium/astro.config.mjs`, `sites/gameovergear/astro.config.mjs` (one-time hand-fix: replace the broken line with the literal URL — `https://mywildlifecam.com`, etc.)
- Test: `tools/bootstrap/src/copy-template.test.ts` (add a case asserting `__SITE_URL__` substitution)

**Approach:**
- The substitution mechanism already exists in `copy-template.ts`; adding `__SITE_URL__` is one entry in the substitutions map plus one parameter through `copyTemplate`.
- For the 5 already-bootstrapped sites, hand-fix is simpler than re-running the bootstrap. The line in `astro.config.mjs` is identical across all 5; a 5-file targeted edit.
- The known-sites table in `tools/bootstrap/src/index.ts` already has the apex domain — derive `siteUrl` as `https://${apex}`.

**Patterns to follow:**
- Existing `__TOKEN__` substitution in `tools/bootstrap/src/copy-template.ts`

**Test scenarios:**
- Happy path: bootstrap CLI invoked with `--slug=mywildlifecam` produces `sites/mywildlifecam/astro.config.mjs` with `site: "https://mywildlifecam.com"` literal in the source
- Edge case: a slug whose known-sites entry uses a non-`.com` TLD (`gameovergear.games`) substitutes correctly
- Edge case: re-running bootstrap on an existing site does NOT regress the already-correct `site:` value
- Verification of 5 hand-fixed sites: each `astro.config.mjs` has its correct domain as a literal string, no `process.env.SITE_URL` lookup remains

**Verification:**
- `pnpm --filter @affkit/mywildlifecam build` produces `dist/sitemap-index.xml` (after U4) with `<loc>https://mywildlifecam.com/...</loc>`, not `<loc>https://example.com/...</loc>`
- `grep -r "example.com" sites/` returns zero hits (other than disclosure-text mentions if any)

---

- [ ] U2. **Add `@astrojs/sitemap` integration to the template**

**Goal:** Make the `<apex>/sitemap-index.xml` advertised in `robots.txt` actually resolve to a generated sitemap.

**Requirements:** R3

**Dependencies:** U1 (sitemap entries need correct `site:` URL)

**Files:**
- Modify: `templates/site-template/astro.config.mjs` (register `sitemap()` integration)
- Modify: `templates/site-template/package.json` (add `@astrojs/sitemap` dependency)
- Modify: `templates/site-template/src/components/BaseLayout.astro` or wherever the `<head>` lives (add `<link rel="sitemap" type="application/xml" href="/sitemap-index.xml" />`)
- Same modifications back-propagated to all 5 `sites/<slug>/` directories
- Modify: `pnpm-lock.yaml` (regenerated by `pnpm install`)

**Approach:**
- Single-line integration registration in `astro.config.mjs`. Filter rule for the Worker-handled `/go/*` paths — exclude them from the sitemap (`filter: (page) => !page.startsWith("/go/")`).
- Back-propagation: `cp templates/site-template/astro.config.mjs sites/<slug>/astro.config.mjs` is too destructive (overwrites U1's per-site substitutions). Instead, edit each site's `astro.config.mjs` by hand — same one-line addition.
- `pnpm install` at the workspace root picks up the new dependency for all sites because of workspace hoisting.

**Patterns to follow:**
- `astro.config.mjs` integration registration pattern (standard Astro convention)

**Test scenarios:**
- Happy path: `pnpm --filter @affkit/mywildlifecam build` produces `dist/sitemap-index.xml` and `dist/sitemap-0.xml`
- Happy path: `dist/sitemap-0.xml` includes URLs for `/about`, `/contact`, `/disclosure`, `/privacy` and the index
- Edge case (post-U6): when at least one review exists in `src/content/reviews/`, the sitemap includes `/reviews/<slug>`
- Edge case: the Worker-routed `/go/*` paths do NOT appear in the sitemap
- Verification: `BaseLayout.astro` rendered output contains `<link rel="sitemap" ...>` in the `<head>`

**Verification:**
- After build, `curl https://mywildlifecam.com/sitemap-index.xml` (post-deploy) returns 200 with valid sitemap XML
- Built sitemap origin is `https://mywildlifecam.com`, not `https://example.com` (confirms U1 + U2 work together)

---

- [ ] U3. **Add SEO basics to `BaseLayout.astro`**

**Goal:** Wire the missing SEO/meta primitives into the shared layout so review pages (U5) inherit them.

**Requirements:** R1 (indirect — review pages need these meta tags to be useful for SEO)

**Dependencies:** None (parallel-safe with U1, U2)

**Files:**
- Modify: `packages/shared-ui/src/components/BaseLayout.astro` (add `<meta name="robots">`, `<meta name="theme-color">`, `og:image` fallback, Twitter card meta tags, canonical URL using `Astro.site` and `Astro.url`)

**Approach:**
- All additions go in the `<head>` block. Use props with sensible defaults:
  - `robotsContent` default `"index, follow"` — review pages override to nothing-extra; disclosure/privacy pages can override to `"noindex"` if Ray wants
  - `themeColor` default from `tokens.css` — derive from `--color-brand` or hardcode `#000000` as a fallback
  - `ogImage` default to a per-site brand image at `/og-default.png` (file presence not required by the layout)
  - Twitter card: `summary_large_image`
  - Canonical: `<link rel="canonical" href={Astro.url.href}>` when not explicitly overridden
- Don't break the existing prop interface — all additions are optional with defaults.

**Patterns to follow:**
- Standard Astro `<head>` prop forwarding via `Astro.props`

**Test scenarios:**
- Happy path: rendering `BaseLayout` with no extra props produces a `<head>` with all the new meta tags using defaults
- Happy path: passing `robotsContent="noindex, nofollow"` overrides the default
- Edge case: canonical URL respects `Astro.site` from U1 — produces `https://mywildlifecam.com/about` not `https://example.com/about`

**Verification:**
- Manual: `pnpm --filter @affkit/mywildlifecam build && grep -A 20 "<head>" dist/index.html` shows all meta tags present

---

- [ ] U4. **Commit `templates/review.md.tmpl` and `templates/buyers-guide.md.tmpl`**

**Goal:** Provide the markdown scaffolding so reviews can be drafted from a template, not from blank.

**Requirements:** R1

**Dependencies:** None (parallel-safe)

**Files:**
- Create: `templates/review.md.tmpl`
- Create: `templates/buyers-guide.md.tmpl`

**Approach:**
- Templates use placeholder tokens like `__PRODUCT_NAME__`, `__PRODUCT_BRAND__`, `__PRODUCT_SKU__`, `__SLUG__`, `__PUB_DATE__`, `__TAGLINE__` that `scripts/new-review.ps1` (U6) substitutes.
- Frontmatter shape must match `templates/site-template/src/content/config.ts` Zod schema exactly. The Zod schema is authoritative; templates are slaves to it.
- Body structure for `review.md.tmpl`: `## TL;DR` (one paragraph) → `## My Take` (with a `> _Waiting for the human._` placeholder that the U5 renderer flags as DRAFT) → `## What I Tested` → `## What Works` / `## What Doesn't` → `## How It Compares` → `## Who It's For` / `## Who Should Skip` → `## Verdict` → `## FAQ`.
- Body structure for `buyers-guide.md.tmpl`: same shell but `## My Take` is replaced with `## Editor's Note: Why this guide` (no human-experience claim, since Ray hasn't used the product).
- Both templates include a footer comment `<!-- HUMAN: fill in My Take before publishing. The build will block if this placeholder remains. -->`

**Patterns to follow:**
- Reference the design spec at `docs/2026-05-12-affiliate-kit-design.md` for the intended section list (it described `review.md.tmpl` in detail)

**Test scenarios:**
- Test expectation: none — these are static template files, exercised by U6's substitution and U5's renderer at build time

**Verification:**
- Files exist
- Manual review: frontmatter matches Zod schema
- Used by U6 (`new-review.ps1`) and U5 (renderer flags DRAFT) — verification happens at integration

---

- [ ] U5. **Build review + buyer's-guide route renderers in the site template**

**Goal:** Render the `reviews` and `buyers-guides` content collections as live pages with JSON-LD, cloaked-link buttons, and a DRAFT guard for empty `## My Take`.

**Requirements:** R1

**Dependencies:** U3 (BaseLayout SEO tags)

**Files:**
- Create: `templates/site-template/src/pages/reviews/[...slug].astro` (single review page)
- Create: `templates/site-template/src/pages/reviews/index.astro` (listing page — "Latest reviews")
- Create: `templates/site-template/src/pages/buyers-guides/[...slug].astro` (single buyer's guide)
- Create: `templates/site-template/src/pages/buyers-guides/index.astro` (listing)
- Modify: `templates/site-template/src/pages/index.astro` (replace "No reviews published yet" with a `<RecentReviews limit={6} />` component or inline collection query)
- Create: `packages/shared-ui/src/components/ReviewCard.astro` (used by listing + homepage)
- Back-propagate the new template pages to all 5 `sites/<slug>/src/pages/` directories (one `cp -r` per site)

**Approach:**
- `[...slug].astro` consumes the content collection: `const entries = await getCollection("reviews"); return entries.map(e => ({ params: { slug: e.slug }, props: e }))`
- Wire `reviewSchema()` and `productSchema()` from `packages/shared-utils/src/schema.ts` into the page as `<script type="application/ld+json" set:html={JSON.stringify(reviewSchema(props.data))}>`
- Wire the cloaked-link CTA via `packages/shared-ui/src/components/CTA.astro` with `href={cloakedLink({ slug: entry.slug })}` (post-U9, `cloakedLink` no longer takes `site`)
- DRAFT guard: if the rendered body contains the placeholder `_Waiting for the human._` from U4's template, render a visible banner at the top of the page and add `<meta name="robots" content="noindex, nofollow">` via the U3 prop. Optional: throw a build-time error in production builds (gated by `import.meta.env.PROD`).
- Listing pages sort by `pubDate` descending. Use `Astro.glob` is deprecated; use `getCollection`.

**Patterns to follow:**
- Standard Astro content collection routing: https://docs.astro.build/en/guides/content-collections/#generating-routes-from-content
- Existing component composition patterns in `packages/shared-ui/`

**Test scenarios:**
- Happy path: a review markdown file under `src/content/reviews/test-product.md` produces a live `/reviews/test-product` URL after `astro build`
- Happy path: the rendered page includes valid JSON-LD with `@type: "Review"` and `@type: "Product"`
- Happy path: the listing page lists all reviews sorted by `pubDate` desc
- Edge case: a review with the `_Waiting for the human._` placeholder shows the DRAFT banner and emits `<meta name="robots" content="noindex, nofollow">`
- Edge case: a buyer's-guide entry under `src/content/buyers-guides/` renders at `/buyers-guides/<slug>` (separate route)
- Edge case: index page with zero reviews renders gracefully ("No reviews yet — check back soon")
- Integration: the `cloakedLink({slug})` output is exactly `/go/<slug>` (validates U9 contract)

**Verification:**
- `pnpm --filter @affkit/mywildlifecam build` succeeds with at least one review markdown file in place
- The rendered review page validates against Google's Rich Results Test for Review structured data (manual check, post-deploy)
- DRAFT banner renders when the placeholder is present

---

- [ ] U6. **Write `scripts/new-review.ps1`**

**Goal:** One-command scaffolding for a new review: copy template, fill frontmatter, write the KV entry, print next-step hint.

**Requirements:** R1, R4

**Dependencies:** U4 (templates), U9 (Worker URL contract), U10 (`scripts/add-link.ps1` which `new-review.ps1` delegates to for the KV write)

**Files:**
- Create: `scripts/new-review.ps1`
- Create: `scripts/buyers-guide.ps1` (sister script for guide mode)

**Approach:**
- CLI shape: `pwsh scripts/new-review.ps1 -Site mywildlifecam -Slug spypoint-flex-m -ProductName "Spypoint Flex-M" -Brand "Spypoint" -Sku "FLEX-M" -AmazonUrl "https://amazon.com/dp/B0..."`
- Resolves `sites/<site>/src/content/reviews/<slug>.md` and refuses if it exists (no `--force` initially)
- Copies `templates/review.md.tmpl`, substitutes `__SLUG__`, `__PRODUCT_NAME__`, `__BRAND__`, `__SKU__`, `__PUB_DATE__` (today, ISO), `__TAGLINE__` (from the site config or a sensible default)
- Calls `scripts/add-link.ps1 -Site $Site -Slug $Slug -Url $AmazonUrl` to wire the cloaked link
- Prints a `Next:` hint pointing at the new file path and reminding Ray to fill in `## My Take`
- Errors out cleanly if `wrangler` is not on PATH, or if `git` working tree is dirty (optional safety)

**Patterns to follow:**
- `scripts/install-plugin.ps1` PowerShell style (param validation, `$ErrorActionPreference = "Stop"`, Write-Host for user output)
- `tools/bootstrap/src/index.ts` for the "Next:" block convention

**Test scenarios:**
- Happy path: running with all params produces the expected markdown file with substitutions applied
- Happy path: the script invokes `add-link.ps1` with the right args (mocked or via integration)
- Error path: target file already exists → script exits 1 with clear message
- Error path: `wrangler` not on PATH → script warns but completes the markdown write (so Ray isn't blocked on local tooling)
- Error path: a required param is missing → PowerShell-native param-binding error

**Verification:**
- Running the script in a fresh checkout produces a file that `pnpm --filter @affkit/<site> build` consumes without error
- The KV entry exists at `<site>:<slug>` (or post-U9, just `<slug>`) when checked via `wrangler kv key get`

---

- [ ] U7. **Write `scripts/add-link.ps1`, `list-links.ps1`, `remove-link.ps1`**

**Goal:** Wrap the wrangler KV commands so Ray never has to remember `--remote` or the namespace ID.

**Requirements:** R4

**Dependencies:** None

**Files:**
- Create: `scripts/add-link.ps1`
- Create: `scripts/list-links.ps1`
- Create: `scripts/remove-link.ps1`
- Modify: `workers/link-cloaker/wrangler.toml` (no change expected — read namespace ID from this file)

**Approach:**
- All three scripts read the production KV namespace ID from `workers/link-cloaker/wrangler.toml` (parse the `[[kv_namespaces]]` `id =` field). Single source of truth.
- `add-link.ps1 -Site <s> -Slug <s> -Url <u> [-Tag <t>] [-Merchant <m>]`:
  - Constructs the JSON envelope per U11's KV schema: `{ url, tag, merchant: "amazon", status: "active", updated: <today-iso> }`
  - Shells out: `wrangler kv key put --remote --binding=AFFILIATE_LINKS "<slug>" "<json>"` (post-U9, key is just slug; pre-U9, key is `<site>:<slug>`)
- `list-links.ps1 [-Site <s>]`:
  - `wrangler kv key list --remote --binding=AFFILIATE_LINKS` and filter to the site if given
- `remove-link.ps1 -Slug <s>`:
  - `wrangler kv key delete --remote --binding=AFFILIATE_LINKS "<slug>"` after a confirmation prompt
- All three: PowerShell-native `-Confirm` support for destructive ops

**Patterns to follow:**
- `scripts/install-plugin.ps1` PowerShell style
- `tools/bootstrap/src/wrangler.ts` for the wrangler shell-out pattern

**Test scenarios:**
- Happy path: `add-link.ps1` writes a structured JSON value at the expected key
- Happy path: `list-links.ps1` returns keys, filtered by site if requested
- Happy path: `remove-link.ps1` deletes after confirmation
- Edge case: `add-link.ps1` with no `-Tag` arg uses a sensible default (read from a config or warn that none is set)
- Error path: wrangler not on PATH → clear error
- Error path: KV write fails (network, permissions) → script exits non-zero with wrangler's error surfaced

**Verification:**
- Round-trip: `add-link.ps1` then `list-links.ps1` shows the new key; `remove-link.ps1` then `list-links.ps1` shows it gone
- Manual: hitting `<apex>/go/<slug>` post-add returns the expected 302

---

- [ ] U8. **Write `docs/PLAYBOOK.md` — the review cycle + refresh sweep**

**Goal:** Document the per-review workflow, the 90-day cycle, the refresh sweep, and the hero-vs-satellite differential in one readable file.

**Requirements:** R5

**Dependencies:** U6, U7 (so the playbook can cite real script names)

**Files:**
- Create: `docs/PLAYBOOK.md`

**Approach:**
- Structure:
  - `## Per-review workflow` — numbered steps: pick product → classify (own it? → review; don't own it? → buyer's guide) → run `new-review.ps1` → fill `## My Take` → check schema preview (Rich Results Test URL) → commit → push → deploy → verify
  - `## The quarterly cycle (90 days)` — what 5 reviews looks like for one site; cadence (one per ~18 days); time-of-quarter calendar shape (Week 1: plan + cycle product list; Week 2-9: write 5 reviews; Week 10-12: refresh sweep)
  - `## Refresh sweep checklist` — bullet list: (1) `list-links.ps1` to enumerate, (2) test each link for HTTP 200, (3) check for dead products, (4) bump `lastUpdated` on the markdown, (5) replace stale price mentions, (6) `submitToIndexNow()` ping
  - `## Hero vs satellite` — one paragraph: hero gets a full cycle every quarter; satellites get one cycle every TWO quarters until the hero proves the model works
  - `## What this playbook does NOT cover` — Amazon Associates enrollment (Ray's task), PA-API (deferred), image hosting (R2 — deferred)
- Tone: brief, scannable, second-person. No "we" prose — Ray reads this when starting a cycle.

**Patterns to follow:**
- `docs/BASEMENT_SETUP.md` if it exists (the "Barney-style hand-held" pattern Ray prefers, per recent session feedback)

**Test scenarios:**
- Test expectation: none — this is documentation

**Verification:**
- A reader (Ray, or future-Claude, or a teammate) can read this file in under 5 minutes and start a cycle with no further questions
- Cross-references to `scripts/new-review.ps1`, `scripts/add-link.ps1`, etc. all resolve to real files

---

- [ ] U9. **Drop `<site>` segment from Worker URL; derive site from Host header**

**Goal:** Eliminate the cross-tenant link-leak bug and simplify the URL shape.

**Requirements:** R7

**Dependencies:** None for the Worker itself; U6 and U7 (KV-writing scripts) need to land in the same release so the KV-key shape is consistent

**Files:**
- Modify: `workers/link-cloaker/src/index.ts` (parse `/go/<slug>` not `/go/<site>/<slug>`; map `request.headers.get("host")` or `url.hostname` to a canonical site slug via a const map)
- Modify: `packages/shared-utils/src/cloaked-link.ts` (drop `site` param; emit `/go/<slug>`)
- Modify: `workers/link-cloaker/test/cloaker.test.ts` (update existing tests to the new URL shape; add test for Host-header-based site mapping; add test for unknown-host falling through to a safe 404)
- Modify: `packages/shared-utils/test/cloaked-link.test.ts` (update test fixtures)
- Modify: any caller of `cloakedLink({site, slug})` — likely only U5's review renderer; TypeScript strict mode will surface the rest at compile time

**Approach:**
- Small `apexToSite` const inside the Worker: `{ "mywildlifecam.com": "mywildlifecam", "fussybean.com": "fussybean", ... }`. If the Host is unknown, return 404.
- `cloakedLink({ slug })` returns `/go/${slug}`. No host needed at link-build time because the page is already served from the right host — relative URL works.
- Update `workers/link-cloaker/wrangler.toml` if needed (route attachment is still `<apex>/go/*`, no change).
- KV key shape becomes `<slug>` alone (no `<site>:` prefix) per the new contract. Worker constructs the lookup key from `${site-from-host}:${slug}` if Ray ever wants to share slugs across sites, but the default is no prefix.
  - **Decision sub-point:** keep `<site>:<slug>` as the KV key internally (Worker derives it from Host + URL) — preserves namespacing if a future Phase 3 lets satellites share product slugs. URL stays clean (`/go/<slug>`); storage stays namespaced.

**Patterns to follow:**
- Existing Worker structure — single-file, minimal, no framework

**Test scenarios:**
- Happy path: `https://mywildlifecam.com/go/spypoint-flex-m` looks up KV key `mywildlifecam:spypoint-flex-m` and 302s
- Happy path: Analytics Engine `writeDataPoint` continues to receive the site dimension correctly
- Edge case: `https://mywildlifecam.com/go/<unknown-slug>` returns 404 with friendly text (existing behavior)
- Edge case: `https://example.com/go/anything` (unknown apex) returns 404 with no KV read
- Edge case: `https://mywildlifecam.com/go/` (empty slug) returns 400 (existing behavior)
- Integration: a real KV entry written by U7's `add-link.ps1` is retrievable via `<apex>/go/<slug>`
- Removed: the old `mywildlifecam.com/go/fussybean/breville-bambino` cross-tenant test case — that URL shape no longer parses

**Verification:**
- Cross-tenant link-leak test (`<site-A>/go/<site-B>/<slug>`) no longer 302s; returns 404 (slug parse fails since the URL has extra path segments)
- All existing test cases pass on the new contract
- `cloakedLink` callers compile cleanly

---

- [ ] U10. **Structured KV values (JSON envelope)**

**Goal:** Replace raw URL strings in KV with a structured `{ url, tag, merchant, status, updated, replaced_by? }` envelope. Future-proofs refresh sweep, Amazon tag rotation, and product retirement.

**Requirements:** R8

**Dependencies:** U9 (lands in the same Worker release)

**Files:**
- Modify: `workers/link-cloaker/src/index.ts` (JSON-parse the KV value with safe fallback to plain-string-as-`url`; handle `status: "retired"` → 410 Gone; handle `replaced_by` → 301 redirect to the new slug)
- Create: `packages/shared-utils/src/kv-link.ts` (export `KVLinkValue` TypeScript type + `parseKVValue(raw: string): KVLinkValue` helper with safe-parse fallback)
- Modify: `scripts/add-link.ps1` (write JSON envelope, not raw URL)
- Modify: `workers/link-cloaker/test/cloaker.test.ts` (add tests for: structured value happy path, retired status → 410, replaced_by → 301 chain, legacy plain-URL string still works via fallback)
- Modify: `packages/shared-utils/test/cloaked-link.test.ts` (if cloaked-link.ts is touched at all in U10 — likely not)

**Approach:**
- `KVLinkValue = { url: string, tag?: string, merchant?: "amazon" | "other", status: "active" | "retired", updated: string, replaced_by?: string }`
- `parseKVValue`: try `JSON.parse`; if it succeeds AND has a `url` field, return as `KVLinkValue`. If it fails OR is a string, return `{ url: raw, status: "active", updated: "unknown" }`. This makes the migration zero-effort — old entries (none in prod today) still work.
- Worker: if `status === "retired"`, return 410 Gone with optional `Retry-After: 0` to signal "this is permanent." If `replaced_by` is set on an active entry, return 301 to `/go/${replaced_by}` (browser re-issues the request → cleaner analytics).
- Amazon tag application: if `merchant === "amazon"` and `tag` is set, build the final URL as `${url}${url.includes("?") ? "&" : "?"}tag=${tag}`. Otherwise emit `url` as-is.

**Patterns to follow:**
- `packages/shared-utils/src/cloaked-link.ts` for the helper-module pattern
- Existing Worker structure — keep it 50 lines, not 200

**Test scenarios:**
- Happy path: KV value `{"url":"https://amazon.com/dp/B0X","tag":"affkit-20","merchant":"amazon","status":"active","updated":"2026-05-15"}` produces 302 to `https://amazon.com/dp/B0X?tag=affkit-20`
- Happy path: `status: "active"` non-Amazon merchant emits the URL as-is
- Edge case: legacy plain-URL string `"https://amazon.com/dp/B0X"` produces 302 to the URL as-is (no tag applied — fallback path has no tag)
- Edge case: `status: "retired"` returns 410 Gone with body "This product is no longer available."
- Edge case: `replaced_by: "newer-slug"` on an active entry returns 301 to `/go/newer-slug`
- Edge case: malformed JSON (e.g. `"{not really json"`) falls back to treating the raw string as a URL
- Integration: `scripts/add-link.ps1` writes a value that the Worker correctly parses end-to-end

**Verification:**
- Unit tests pass for all 6 scenarios above
- Manual: write a `retired` entry, hit the URL, confirm 410
- The Worker source stays under ~80 LOC after the change (was 44 — budget for ~35 LOC of envelope handling)

---

- [ ] U11. **Honest `COMMANDS.md` + auto-derived `/aff-help` slash command + delete `tone` config**

**Goal:** Stop the plugin docs from lying about commands that don't exist. Make `/aff-help` derive its output from real filenames. Delete the unwired `tone` config + `--spicy` flag.

**Requirements:** R6

**Dependencies:** None (parallel-safe)

**Files:**
- Modify: `COMMANDS.md` — mark all non-existent commands as `(NOT YET — Phase 2)`. Sort so existing commands are top-of-file, planned commands are footnoted in a `## Roadmap` section.
- Modify: `plugin/README.md` — same treatment as COMMANDS.md
- Modify: `CLAUDE.md` — remove the `--spicy` flag mention from the "Tone of generated output" section, or replace with "Tone is currently fixed at snarky-but-friendly. Configurable in a future release."
- Create: `plugin/commands/aff-help.md` — new slash command that, when invoked, lists the contents of `plugin/commands/` (resolved relative to the plugin install path) and prints one-line descriptions parsed from each command file's frontmatter
- Modify: `tools/bootstrap/src/config.ts` — remove the `tone` field from `PluginConfig` (or change the type to never-instantiated for forward-compat)
- Modify: `tools/bootstrap/src/config.test.ts` — drop `tone` test cases
- Modify: `~/.claude/plugins/affiliate-kit/config.json` schema example file if one exists — drop `tone`

**Approach:**
- `aff-help.md` is a markdown-with-frontmatter file. The body instructs Claude to read `plugin/commands/*.md`, parse each frontmatter for `description:`, and render a table. Inline instruction since slash commands are themselves Claude prompts.
- Sort `COMMANDS.md`: existing commands first (`/aff-bootstrap`, `/aff-help`, plus the new ones from this plan: `/aff-new-review` if it gets a slash-command wrapper, otherwise just the script), then `## Roadmap (Phase 2/3)` section listing future commands with `(NOT YET)` tags
- Decision check: does `/aff-new-review` get a slash-command wrapper in this plan, or just the PowerShell script (U6)? Plan position: script only — slash command can come later when the workflow stabilizes. Document the script in COMMANDS.md instead.
- `tone` deletion: simple type narrowing in `PluginConfig`. Re-add when there's a real consumer.

**Patterns to follow:**
- Existing `plugin/commands/aff-bootstrap.md` frontmatter for the new aff-help.md command file
- Any other Claude Code plugin command file you can find in `~/.claude/plugins/`

**Test scenarios:**
- Happy path: `/aff-help` invoked from Claude Code prints a list with `/aff-bootstrap` (the only real command pre-plan) + any new commands added by this plan
- Edge case: a malformed command file (missing frontmatter `description:`) shows the filename without a description, doesn't crash
- Edge case: `config.test.ts` no longer references `tone`; the file compiles
- Verification: `grep -r "tone" tools/bootstrap/src/` returns no hits in active code (test file might have a comment trail; that's fine)
- Verification: `grep -ri "spicy" CLAUDE.md README.md plugin/` returns no hits

**Verification:**
- Reading `COMMANDS.md` cold, the list of commands matches `ls plugin/commands/`
- `pnpm test` passes after the `tone` deletion
- `/aff-help` invocation from Claude Code prints the correct list

---

## System-Wide Impact

- **Interaction graph:** The Worker is the choke point for click attribution; U9 (URL contract change) ripples through `cloakedLink()` in `packages/shared-utils/`, every consumer of `cloakedLink()` (U5's review renderer), and `scripts/add-link.ps1`. TypeScript strict mode will catch broken callers at compile time.
- **Error propagation:** U10 introduces `status: "retired"` → 410 Gone. SEO crawlers and external link-checkers will see 410 vs the previous 404. This is intentional and better for crawl-budget signals.
- **State lifecycle risks:** The 5 already-bootstrapped sites diverge from the template in U1 (hand-fix of `astro.config.mjs`) and U2 (sitemap integration). Future re-runs of the bootstrap will not overwrite these per-site edits — the bootstrap only creates new directories. If Ray re-bootstraps an existing site (`--force` flag, currently not implemented), U1 + U2 changes will need to be re-applied.
- **API surface parity:** All 5 sites get the same renderer (U5), the same sitemap (U2), the same SEO basics (U3), the same `SITE_URL` baking (U1). No per-site divergence introduced by this plan.
- **Integration coverage:** U6's `new-review.ps1` calls U7's `add-link.ps1` which calls wrangler which writes to KV which the Worker reads. The end-to-end happy path crosses 4 surfaces; manual verification of "write a real review and verify it renders + the cloaked link 302s" is the only test that proves it.
- **Unchanged invariants:** Astro build pipeline, Cloudflare Pages deploy pipeline, Worker route attachment, the bootstrap CLI's CF Pages/DNS/Worker-route flows are all untouched. The Worker's binding shape (KV + Analytics Engine) is unchanged. The `affkit_clicks` analytics dataset schema is unchanged (blob ordinals preserved).

---

## Risks & Dependencies

| Risk | Mitigation |
|------|------------|
| The 5 hand-fixed sites drift from the template in subtle ways after U1/U2 | Document the 2 hand-fixed lines in each `astro.config.mjs` in a comment so a future template-sync exercise can rediscover them. Better: future Phase work to introduce a `pnpm sync-template <slug>` operation. |
| U10's safe-fallback JSON parse masks real malformed KV writes | The fallback only kicks in for non-JSON values, which the new `add-link.ps1` will never produce. Manual hand-writes via raw `wrangler kv key put` would still trigger the fallback, but Ray's path goes through the script. Acceptable. |
| U9's Worker URL change breaks any external referrer that's already minted `/go/<site>/<slug>` links | Today, no external referrers exist (KV is empty, no review pages are live). The window for a clean break is exactly today. If anyone has shared a `/go/...` link in a Slack DM or similar, it 404s after the change — acceptable cost for closing the cross-tenant leak. |
| The 5 site `astro.config.mjs` hand-fixes are silently re-broken on the next `cp templates/site-template/astro.config.mjs sites/<slug>/` someone might run | The plan never instructs anyone to do that copy. The template substitution (U1) makes the bootstrap path produce the correct file. Watch for ad-hoc copies in future PRs. |
| Future Phase 2 work that adds `/aff-cycle` / `/aff-refresh` could collide with the playbook prose's "Week 10-12: refresh sweep" cadence | Playbook prose describes the workflow; tooling commands automate parts of it. Future commands should match the playbook prose, not the other way around. Worth a callout in PLAYBOOK.md: "When tooling lands, prefer the command over manual steps." |
| `BaseLayout.astro` changes (U3) affect all pages on all sites — about, contact, disclosure, privacy | All additions are backward-compatible (new optional props with defaults). Per-page overrides remain possible. Risk is low. |

---

## Documentation / Operational Notes

- `PROJECT_STATE.md` will get a new entry when this plan's work lands: "2026-05-XX — Content-production readiness shipped: review/buyer's-guide renderers live, scripts for new-review + add-link/list-links/remove-link, playbook documented, Worker URL collision fixed, structured KV envelope. Ready for review #1 on mywildlifecam."
- The `docs/2026-05-12-affiliate-kit-plan-phase-1.md` plan file remains the canonical Phase 1 record. This plan does not modify it.
- After this plan lands, the next big artifact for Ray to write is the `docs/AFFILIATE_PROGRAMS.md` checklist (deferred to follow-up) and the Amazon Associates application (Ray's task, no code involved).

---

## Sources & References

- 4-agent CE evaluation reports in conversation history (2026-05-14 session):
  - Tools/plugin audit
  - Architecture + template audit
  - Cloudflare Worker audit
  - Execution readiness audit
- `CLAUDE.md` at repo root — the affiliate-kit conventions
- `docs/2026-05-12-affiliate-kit-design.md` — the original Phase 1 spec
- `docs/2026-05-12-affiliate-kit-plan-phase-1.md` — Phase 1 plan (for context only; not modified)
- `docs/sessions/Session_2026-05-12.md` and `Session_2026-05-14.md` — the Phase 1 retro and this session's earlier work

# Cold-Site Bootstrap Tool + FussyBean Execution — Implementation Plan

**Date:** 2026-05-29
**Author:** Ray (via Claude, home PC session)
**Status:** Plan for review — NO code written, NO site files touched. Reviewed before any build.
**Parent docs:**
- `docs/brainstorms/2026-05-28-magic-go-vision.md` — the north star (Items 3 pillar-IA + 4 minimalist-homepage are the foundations this tool generates).
- `docs/brainstorms/2026-05-29-magic-go-v1-plan.md` — the orchestrator plan. **This doc IS the "separate framework-rebuild + bootstrap track" that magic-go v1 §11 explicitly parks the SEO findings into.** It does not contradict magic-go v1; it implements the stricter superset gate that magic-go's R1–R5 is the minimal floor of.

---

## Why this doc exists

We have five Astro satellites. Two are content-ready (MWC, DTP). The rest — fussybean, starteraquarium, gameovergear — are cold: page shells + an old content schema + (for fussybean) no `site-config.json` and zero content. Lifting a cold site to content-readiness by hand is a long, error-prone, copy-MWC-and-find-replace slog that has never been done cleanly, and the one naive shortcut (copy `templates/site-template/`) **ships a voice-doctrine violation** into every satellite (see §0).

A just-completed SEO best-practices research pass surfaced seven structural gaps (config-shape divergence, two pillar types, missing pillar routes, schema gaps, missing E-E-A-T scaffolding, crawl hygiene, topical-focus discipline). This doc turns that brief into:

1. **A reusable bootstrap tool** — script + playbook hybrid — that lifts any cold satellite to the SEO-strong readiness bar in one supervised pass.
2. **The fussybean-specific execution** — the concrete file-by-file diff, with placeholders marked for the niche judgment Ray must supply.

The payoff is direct: **once fussybean passes the readiness gate, magic-go's per-site gate (R1–R5) auto-includes it** in the next `/aff magic-go <N>` run. This track makes the satellites SEO-strong so the volume magic-go produces is worth indexing.

---

## 0. The voice-doctrine violation we must fix first (load-bearing)

`templates/site-template/src/pages/index.astro` ships two banned claims:

- Line 18: `description="__SITE_NAME__ — honest, hands-on reviews and buyer's guides for __NICHE__."` — **"hands-on reviews"** is a direct hands-on claim, banned by `docs/voice-doctrine.md`.
- Line 44: `<p class="muted">Comparative roundups of products we've researched but don't own.</p>` — "but don't own" is defensible, but the surrounding framing leans on the recipe-page anti-pattern; more importantly the *live fussybean copy* (`sites/fussybean/src/pages/index.astro:18`) has inherited the identical `honest, hands-on reviews` string AND a niche-mismatched tagline ("Coffee gear, ranked by someone who can taste the difference" — implies tasting, i.e. hands-on).

**Both the template AND the already-spawned fussybean copy carry the violation.** The bootstrap tool must (a) fix the source template so future bootstraps are clean, and (b) overwrite the per-site homepage with a voice-clean, comparison-and-fit version. The lint back-stop (`scripts/lint-voice.ps1`) greps the forbidden phrases in `voice-doctrine.md` (which lists `I tested` / `we tested` / `I own` / etc., per the doc's own note at line 15 that the lint reads the file at runtime). **"hands-on reviews" as a phrase is NOT currently in that forbidden list**, so the lint does not catch this string today. That's a gap: add `hands-on review` / `hands-on testing` to `voice-doctrine.md` so the lint catches this class, then fix the template. (Filed as build step 0.)

---

## 1. Canonical schema decision: adopt DTP's nested shape

### The divergence (the #1 blocker)

| | MWC (`sites/mywildlifecam/src/data/site-config.json`) | DTP (`sites/detailerpicks/src/data/site-config.json`) |
|---|---|---|
| identity | flat: `siteName`, `domain` | nested: `site.{slug,name,tagline,apex}` |
| niche | `niche` = string | `niche.{vertical,subcategory}` |
| segments | top-level `primarySegments` / `secondarySegments` / `excludedSegments` (string[]) | `readerSegments.{primary,secondary,excluded}` (string[]) |
| voice | `brandTone` (string) | `voice.{register,tone,core_anxiety,framings[]}` |
| feature axes | `featureAxes` = string[] | `featureAxes.default` = `[{name,weight,description}]` |
| pillars | (absent) | `categoryPillars` = string[] |
| brands | (absent) | `brandsCovered` = string[] |

### Decision: **nested (DTP-style) is canonical.** The bootstrap tool generates the nested shape, always.

Rationale: nested already carries `categoryPillars`, weighted `featureAxes`, structured `voice`, and `brandsCovered` — exactly the richer fields the SEO brief needs (weighted-axes rubric for the methodology page, pillars for the hub-and-spoke IA, brands for topical focus). MWC's flat shape is a strict subset.

### How this reconciles with magic-go v1 (NOT a contradiction)

magic-go v1 §11 **LOCKED O1 = "write a `Get-SiteConfigField` two-shape adapter; do NOT migrate MWC mid-build."** That stands. The two statements live at different layers:

- **`Get-SiteConfigField` adapter (magic-go's resolution):** the *bridge*. It lets magic-go's readiness gate + scaffold-context extractor read BOTH flat (MWC) and nested (DTP) shapes today, so the orchestrator isn't blocked.
- **"Nested is canonical" (this doc's resolution):** the *long-term target*. Every NEW site the bootstrap tool produces is born nested. fussybean is greenfield, so **it needs neither the adapter accommodation nor a migration — it is canonical from line one.**
- **MWC migration** (flat → nested) is the only remaining flat config. It is a **flagged open decision (§Open decisions D1)**, explicitly NOT a step in the fussybean build sequence. Migrating MWC is a risky rewrite of a shipped hero site that magic-go is mid-build against via the adapter; coupling fussybean to it would be drift.

Net: the adapter keeps the old world running; the bootstrap tool makes the new world canonical; MWC is the one legacy node, migrated on Ray's call, not on fussybean's critical path.

---

## 2. Two pillar types + the hub-and-spoke backbone

`categoryPillars` (commercial product categories) is only half the IA. Pure-commercial pillars miss the legitimate, non-hands-on E-E-A-T play: informational topical-authority content (cost guides, how-tos, comparisons, research explainers) that carries NO product and never claims use. The bootstrap tool models BOTH via a `navigation.pillars[]` superset.

### Proposed `navigation.pillars[]` shape (exact)

```jsonc
"navigation": {
  "pillars": [
    {
      "slug": "espresso-machines",        // URL segment + spoke FK value
      "label": "Espresso Machines",        // nav + hub H1
      "type": "commercial",                // commercial | informational
      "categoryPillar": "espresso-machines", // FK → an entry in categoryPillars[]; commercial only
      "blurb": "Pump, lever, and super-automatic machines for the home bar.",
      "hubKicker": "Buying guides"          // small label above the hub list
    },
    {
      "slug": "brewing-costs",
      "label": "What It Costs",
      "type": "informational",              // NO categoryPillar FK; pure topical authority
      "categoryPillar": null,
      "blurb": "Cost-to-brew breakdowns, upgrade-path math, and total-cost-of-ownership guides.",
      "hubKicker": "Guides & research"
    }
  ]
}
```

- `type: "commercial"` → `categoryPillar` is an FK to a `categoryPillars[]` entry; the hub lists buying-guides + reviews whose `pillar` field matches.
- `type: "informational"` → `categoryPillar: null`; the hub lists informational pieces only (cost guides, how-tos). This is the E-E-A-T authority play, products-free, never hands-on.

### Spokes must declare their pillar

Add a `pillar` field to BOTH content collections (the linking backbone is currently missing everywhere):

```ts
// in reviews + buyersGuides schema:
pillar: z.string().optional(),   // FK → navigation.pillars[].slug
```

Optional (not required) so existing MWC/DTP content without it still builds. New bootstrapped content sets it. magic-go's scaffolder will populate it once Item-3 pillar IA is live (magic-go v1 deliberately does NOT slot into pillars yet — see §6).

---

## 3. Routing: keep `/reviews/` + `/buyers-guides/`, ADD pillar hubs

The repo has `/reviews/[...slug]` + `/buyers-guides/[...slug]` (spokes) and `/reviews/` + `/buyers-guides/` (flat list pages). There is **no pillar-hub route anywhere** (confirmed: no `/guides/[pillar]` or equivalent exists). The bootstrap tool generates one.

### URL-taxonomy decision (recommended)

**Keep the existing spoke URLs unchanged** (`/reviews/<slug>`, `/buyers-guides/<slug>`) — minimizes churn on MWC/DTP, no redirects. **Add pillar hubs at `/topics/<pillar>/`.**

Why `/topics/` and NOT `/guides/[pillar]`: `/guides/` reads ambiguous sitting next to the existing `/buyers-guides/` route — a reader (and a crawler) can't tell a "guide hub" from a "buyers-guide spoke." `/topics/<pillar>/` is unambiguous, reads as a category/section index, and works equally for commercial pillars (lists buying-guides + reviews) and informational pillars (lists how-tos + cost guides). Homepage nav points at `/topics/<pillar>/`.

Route file the tool generates: `sites/<slug>/src/pages/topics/[pillar].astro` — `getStaticPaths` from `navigation.pillars[]`; each page lists spokes where `entry.data.pillar === pillar.slug`, grouped by collection. (Flagged as open decision D2 in case Ray prefers a different segment word.)

---

## 4. Schema (JSON-LD) emission

| Schema | Where | Action |
|---|---|---|
| `Organization` + `WebSite` | site-wide, in `BaseLayout.astro` head | **ADD** — absent today. Driven by per-site identity (name, apex, logo). `WebSite` enables sitelinks-searchbox eligibility later. |
| `Product` + `Offer` (no rating) | spokes, via `productSchema()` | **KEEP** — already emitted on both routes; no rating, doctrine-safe. |
| `Article` + `author` | spokes | **ADD** — `Article` with a named author entity (§5) + `datePublished`/`dateModified` from `pubDate`/`lastUpdated`. |
| `BreadcrumbList` | spokes + hubs | **ADD** — Home → Topic/Pillar → Piece. Needs the pillar FK (§2) to build the middle crumb. |
| `Review` / `AggregateRating` | — | **NEVER EMIT.** `packages/shared-utils/src/schema.ts` `reviewSchema()` asserts a 1–5 hands-on rating — a direct contradiction of the comparison-and-fit doctrine and a legal footgun. **Verified state (grepped 2026-05-29):** `reviewSchema()` is currently emitted by ZERO site/component files — `ReviewArticle.astro` imports only `productSchema` (line 18), and its emission was deliberately dropped on 2026-05-16 (U2, commit `24943f1`, `docs/sessions/Session_2026-05-16.md`). The ONLY remaining importer is `packages/shared-utils/test/schema.test.ts`. So deleting `reviewSchema()` does NOT touch any site build — the only follow-on edit is removing/trimming its test block. **Recommend: delete `reviewSchema()` + its test** (it's a dormant footgun; resurrect from git if a first-party-review site ever exists). Alternative: hard-gate behind an `allowFirstPartyReview: true` site-config flag that fussybean and all current sites leave false. (Open decision D-minor.) |

The bootstrap tool wires `Organization`/`WebSite` into `BaseLayout` (shared, all sites benefit) and `Article`/`BreadcrumbList` into the shared spoke components.

---

## 5. E-E-A-T scaffolding the tool generates

Modeled on MWC's existing `how-we-evaluate.astro` + `about.astro` (the gold-standard, voice-clean precedent). For each cold site the tool generates:

1. **`/how-we-evaluate/`** — renders the weighted `featureAxes` rubric (e.g. "Build Quality 25%, Temperature Stability 20%, ...") from `site-config.json` so the methodology is data-driven and matches the scorecard weights. Includes the "what we don't claim" hands-on disclaimer (verbatim register from MWC's page).
2. **`/about/`** — research-methodology framing in positive voice (published specs + aggregated verified-buyer reviews + use-case fit), per the voice-doctrine direct-question responses.
3. **Named author entity** — a single editorial persona per site (e.g. "The FussyBean editorial team" — matches MWC's byline pattern) wired into the `Article` author schema (§4) and the spoke byline. (Open decision D5: a real named human vs. an "editorial team" entity.)
4. **Network-generic affiliate disclosure** — `/disclosure/` + footer use `AffiliateDisclosure.astro` with NO network named (so multi-network routing, magic-go Item 2, can swap behind it later). The tool confirms no Amazon-specific copy leaks in.

---

## 6. The reusable bootstrap tool — design

### Script-vs-playbook split (the decision)

**Hybrid, mirroring magic-go v1's supervised-resumable model exactly:**

- **Deterministic file generation = `scripts/bootstrap-site.ps1`.** Given a completed `site-config.json` (the niche judgment already captured), it deterministically: writes the upgraded `config.ts`, copies + parameterizes the page templates and MainLayout, generates the pillar-hub route, the E-E-A-T pages, the voice-clean homepage, the per-site `robots.txt`, and verifies `astro.config.mjs`. Idempotent, unit-testable, no Claude-in-the-loop.
- **Niche-judgment Q&A = a `/aff`-internal playbook `plugin/commands/bootstrap-site.md`.** It asks the operator the question set (below), turns answers into the canonical nested `site-config.json`, then calls `scripts/bootstrap-site.ps1`, then runs the lint+build gates. The judgment (what are the right pillars? what feature axes and weights? which brands?) is model + Ray work; the file mechanics are the script.

This is the same seam magic-go drew: *deterministic spine in PowerShell, judgment in the playbook Claude reads inline.* No new top-level slash command — `bootstrap-site.md` is an internal mechanic (`description:` starts with `Internal —`), surfaced by `/aff` when a site has a config-but-no-content or no-config posture.

### The question set the playbook asks (one consolidated block, not ping-pong)

1. **Niche** — vertical + subcategory (the one tight topical focus; off-niche drift dilutes authority).
2. **Reader segments** — primary / secondary / excluded.
3. **Feature axes + weights** — the 4–6 evaluation axes with integer weights summing to 100 + a one-line description each (feeds the scorecard + `/how-we-evaluate/` rubric).
4. **Commercial pillars** — the product categories (`categoryPillars[]`).
5. **Informational pillars** — cost-guide / how-to / comparison / research clusters (the products-free authority play). Includes any novelty/gift sub-pillar.
6. **Brands** — the brand universe (`brandsCovered[]`) — also a topical-focus guardrail.
7. **Voice / tone** — register + tone + core reader anxiety + 2–4 framings.
8. **Identity** — fonts + palette direction (proposed by the playbook, confirmed by Ray) + tagline.

### What the script generates / copies (the readiness payload)

| Artifact | Source | Parameterized by |
|---|---|---|
| `src/data/site-config.json` | (written by playbook from Q&A) | all answers |
| `src/content/config.ts` | upgraded MWC schema + `pillar` field | — |
| `src/pages/reviews/[...slug].astro` | MWC's (uses `ReviewArticle` + `bottomLine` DRAFT gate) | site name |
| `src/pages/buyers-guides/[...slug].astro` | MWC's (quick-scout + deep-card + `BottomLine`) | site name, kicker |
| `src/pages/topics/[pillar].astro` | NEW (§3) | `navigation.pillars[]` |
| `src/pages/reviews/index.astro` + `buyers-guides/index.astro` | MWC's list pages | site name |
| `src/layouts/MainLayout.astro` | **parameterized** MWC layout (§7) | brand, nav, bgTheme set, palette |
| `src/pages/index.astro` | NEW voice-clean homepage (§0) | site name, pillars, tagline |
| `/about/`, `/how-we-evaluate/`, `/disclosure/`, `/privacy/`, `/contact/` | MWC pattern | identity, rubric, author |
| `public/robots.txt` | disallow `/go/` | — |
| `astro.config.mjs` | verify `site:` + sitemap `/go/` filter | apex |

---

## 7. Per-site MainLayout: parameterized-and-copied, NOT forced-shared

`CLAUDE.md` says sites diverge after spawn. The shared seam already exists: `BaseLayout.astro` (in `packages/shared-ui`) takes `siteName`, `fontsHref`, `ogImage`, `robotsContent` as props — that's where per-site identity flows in. **MainLayout stays per-site.** MWC's MainLayout hardcodes brand SVG, forest palette, Pexels gutter photos, the `bgTheme` map — all MWC-specific. fussybean already has its own minimal MainLayout.

The bootstrap tool writes a **parameterized MainLayout per site** from a template that takes: brand name/mark, nav items (derived from `navigation.pillars[]`), palette tokens, and the bgTheme background set (or `solid` for sites that don't want photo gutters). It does NOT collapse MWC + fussybean into one shared MainLayout. It passes per-site fonts to `BaseLayout` via `fontsHref` (default is MWC's Fraunces+Inter; fussybean overrides — §8).

---

## 8. FussyBean execution plan (file-by-file)

**fussybean IS the tool's first invocation — this is dogfooding, not a parallel manual build.** Build steps 4–10 (§10) are exactly: run `plugin/commands/bootstrap-site.md` (the Q&A captures the §8.1 config) → `scripts/bootstrap-site.ps1` generates the files described below → verify. The file-by-file detail here is the *expected output* of that first run, written out so we can confirm the tool produces it. If the tool can't lift fussybean cleanly, the "reusable" claim is unvalidated; fussybean is the validation.

Niche (from Ray): **home coffee gear** — the hardware (espresso machines, grinders, gooseneck kettles, scales). NOT beans/content ("not yet anyway"). Plus a novelty/gift sub-pillar (fun non-essential coffee accessories, e.g. a coffee-cup-shaped pod holder) modeled as ONE informational pillar so it doesn't dilute authority. Apex confirmed `fussybean.com` (`astro.config.mjs:5` `site: "https://fussybean.com"`, sitemap `/go/` filter already present — crawl hygiene R6 partially satisfied already).

### 8.1 CREATE `sites/fussybean/src/data/site-config.json` (canonical nested; placeholders marked)

```jsonc
{
  "site": {
    "slug": "fussybean",
    "name": "FussyBean",
    "tagline": "Home coffee gear, by use case.",   // <!-- RAY: confirm tagline -->
    "apex": "fussybean.com"
  },
  "affiliate": { "amazonTag": "" },                  // empty until Associates tag exists (lint skips empty)
  "niche": {
    "vertical": "home-coffee-gear",
    "subcategory": "espresso + manual brewing hardware"
  },
  "voice": {
    "register": "enthusiast-pro",                    // <!-- RAY: confirm register -->
    "tone": "precise about specs, warm about the ritual, never snobbish",
    "core_anxiety": "spending $$$ on gear that won't actually improve the cup",
    "framings": [
      "Upgrade-path: what to buy first, what to skip until later",
      "Cross-brand honest comparison (Breville vs Gaggia vs De'Longhi vs Baratza)",
      "Hardware not beans: we rank the machine, not the roast",
      "Total-cost-of-ownership, not just sticker price"
    ]                                                // <!-- RAY: confirm framings -->
  },
  "readerSegments": {
    "primary": ["first-espresso-machine-buyer","upgrading-from-pods","manual-brew-enthusiast","gift-buyer"],
    "secondary": ["small-office-buyer"],
    "excluded": ["commercial-cafe-operators (different price tier, different machines)"]
  },                                                 // <!-- RAY: confirm segments -->
  "featureAxes": {
    "default": [
      { "name": "Build Quality",        "weight": 25, "description": "materials, boiler type, longevity" },
      { "name": "Temperature Stability","weight": 20, "description": "PID, thermal recovery, shot consistency" },
      { "name": "Value",                "weight": 20, "description": "performance per dollar, TCO" },
      { "name": "Ease of Use",          "weight": 20, "description": "learning curve, cleaning, daily friction" },
      { "name": "Footprint",            "weight": 15, "description": "counter space, water tank, noise" }
    ]                                                // <!-- RAY: confirm axes + weights (must sum to 100) -->
  },
  "categoryPillars": [
    "espresso-machines",
    "grinders",
    "gooseneck-kettles",
    "scales",
    "manual-brewers"
  ],                                                 // <!-- RAY: confirm commercial pillar list -->
  "navigation": {
    "pillars": [
      { "slug": "espresso-machines", "label": "Espresso Machines", "type": "commercial",    "categoryPillar": "espresso-machines", "blurb": "Pump, lever, and super-auto machines for the home bar.", "hubKicker": "Buying guides" },
      { "slug": "grinders",          "label": "Grinders",          "type": "commercial",    "categoryPillar": "grinders",          "blurb": "Burr grinders that actually matter more than the machine.", "hubKicker": "Buying guides" },
      { "slug": "manual-brewing",    "label": "Manual Brewing",    "type": "commercial",    "categoryPillar": "manual-brewers",    "blurb": "Kettles, scales, pour-over, and press gear.", "hubKicker": "Buying guides" },
      { "slug": "coffee-costs",      "label": "What It Costs",     "type": "informational", "categoryPillar": null,                "blurb": "Cost-to-brew math, upgrade paths, and total-cost guides.", "hubKicker": "Guides & research" },
      { "slug": "fun-stuff",         "label": "Fun Stuff",         "type": "informational", "categoryPillar": null,                "blurb": "Novelty and gift gear for the coffee-obsessed.", "hubKicker": "Gifts & novelty" }
    ]
  },                                                 // <!-- RAY: confirm informational-pillar COUNT (D4) -->
  "brandsCovered": [
    "Breville","Gaggia","De'Longhi","Rancilio","Baratza","Fellow","Hario","Acaia","Timemore"
  ],                                                 // <!-- RAY: confirm brand list -->
  "doctrineNotes": "Comparison-and-fit framework. Hardware only, not beans (not yet). Never claim hands-on use; cite manufacturer specs, verified-buyer reviews, and independent testing (James Hoffmann, Whole Latte Love teardowns) as third-party evidence. No em dashes. No defensive audience exclusions."
}
```

### 8.2 UPGRADE `sites/fussybean/src/content/config.ts`

Current fussybean schema is the OLD one (no `bottomLine`/`scorecard`/`buyIf`/`flaws`/`faq`). Replace with the MWC schema (the good one), PLUS the new `pillar` field on both collections (§2). This is what satisfies magic-go **R3** (collections define both `reviews` + `buyers-guides` with `bottomLine`).

### 8.3 REPLACE page routes (satisfies magic-go R4 + R5)

- `sites/fussybean/src/pages/reviews/[...slug].astro` — currently the OLD inline pattern with DRAFT detection via `body.includes(DRAFT_MARKER)`. Replace with MWC's version: imports `ReviewArticle`, and **keys the DRAFT/noindex gate off `data.bottomLine.verdict`** (not the body-string marker). **This switch is precisely what satisfies magic-go R5** (gate keys off `bottomLine`, grep-able `noindex` + `bottomLine` co-occurrence).
- `sites/fussybean/src/pages/buyers-guides/[...slug].astro` — replace with MWC's quick-scout + deep-card + `BottomLine` version (also `bottomLine`-gated).
- `sites/fussybean/src/pages/reviews/index.astro` + `buyers-guides/index.astro` — replace with MWC's list pages (parameterized copy).

### 8.4 ADD `sites/fussybean/src/pages/topics/[pillar].astro` (§3) — the pillar hubs.

### 8.5 PARAMETERIZE `sites/fussybean/src/layouts/MainLayout.astro` (§7)

Current fussybean MainLayout is a bare header/footer with no pillar nav, no bgTheme, MWC-default fonts. Rewrite from the parameterized template: brand "FussyBean", nav from `navigation.pillars[]` (Home + each pillar label + About), a coffee-appropriate palette, pass coffee fonts to `BaseLayout` via `fontsHref`.

### 8.6 IDENTITY (propose; mark for Ray's approval)

- **Palette (proposed):** warm espresso-brown + cream + a brass/copper accent (coffee-equipment register; distinct from MWC forest, distinct from DTP). `<!-- RAY: approve palette (D3) -->`
- **Fonts (proposed):** a warm humanist serif for display (e.g. **Fraunces** reused, OR **Newsreader** for a softer editorial feel) + **Inter** for UI. `<!-- RAY: approve fonts (D3) -->`
- bgTheme: start `solid` (no photo gutters) — coffee scene photos are an iteration after launch.

### 8.7 E-E-A-T pages (§5)

Rewrite the existing `about.astro`, `disclosure.astro`, `privacy.astro`, `contact.astro` to the MWC register (currently bare shells), and ADD `how-we-evaluate.astro` rendering the fussybean `featureAxes` rubric. Author entity: "The FussyBean editorial team" `<!-- RAY: confirm author identity (D5) -->`.

### 8.8 HOMEPAGE (§0)

Overwrite `sites/fussybean/src/pages/index.astro`: remove `honest, hands-on reviews`, remove the tasting-implying tagline, render a minimalist pillar-index homepage (magic-go vision Item 4) — one hero, pillar cards from `navigation.pillars[]`, latest reviews grid. Voice-clean description.

### 8.9 CONFIRM crawl hygiene (mostly already done)

`astro.config.mjs` already has `site: "https://fussybean.com"` + sitemap `/go/` filter (good — not hardcoded to mywildlifecam). `public/robots.txt` exists — verify it disallows `/go/`. DRAFT/noindex armed on both routes via 8.3.

---

## 9. The definitive readiness checklist (the SEO-strong bar)

This is the **superset** of magic-go v1's R1–R5 minimal gate. magic-go runs against R1–R5; this track adds R6–R12 so the content magic-go produces is SEO-strong. Mapping shown so the two docs visibly agree.

| # | Check | magic-go R# | fussybean status after §8 |
|---|---|---|---|
| R1 | `site-config.json` present + parseable (canonical nested) | R1 | ✅ 8.1 |
| R2 | Config has niche / segments / weighted axes resolvable | R2 | ✅ 8.1 |
| R3 | `config.ts` defines `reviews`+`buyers-guides` with `bottomLine` | R3 | ✅ 8.2 |
| R4 | Both spoke routes present | R4 | ✅ 8.3 |
| R5 | DRAFT/noindex gate keys off `bottomLine.verdict` | R5 | ✅ 8.3 (the body-marker → bottomLine switch) |
| R6 | Crawl hygiene: per-site `site:`, sitemap `/go/` filter, `robots.txt` disallow `/go/` | — | ✅ 8.9 (mostly pre-existing) |
| R7 | `navigation.pillars[]` present (commercial + informational); spokes carry `pillar` field | — | ✅ 8.1 + 8.2 |
| R8 | Pillar-hub route `/topics/[pillar]` present | — | ✅ 8.4 |
| R9 | Per-site identity: parameterized MainLayout, fonts via `fontsHref`, palette | — | ✅ 8.5 / 8.6 |
| R10 | Voice-clean homepage + template (no hands-on claims) | — | ✅ 8.8 + §0 |
| R11 | E-E-A-T: `/how-we-evaluate/` rubric, `/about/`, named author, generic disclosure | — | ✅ 8.7 |
| R12 | Schema: `Organization`+`WebSite` site-wide, `Product`+`Offer`, `Article`+`BreadcrumbList` on spokes, NO `Review`/`AggregateRating` | — | ✅ §4 |
| GATE | `lint-voice` + `lint-product-images` + `lint-affiliate-tags` clean, `pnpm --filter fussybean build` green | — | verified each step (§11) |

---

## 10. Ordered build sequence

Each step independently committable + verifiable. Do NOT start a step before the prior is green. **No step touches MWC** (its migration is D1, off this path).

0. **Voice-doctrine + template fix (§0).** Add `hands-on review` / `hands-on testing` to `voice-doctrine.md` forbidden phrases; fix `templates/site-template/src/pages/index.astro`. *Verify:* `lint-voice.ps1` now trips on the old string.
1. **Schema additions (shared, all sites benefit).** `Organization`+`WebSite` into `BaseLayout`; `Article`+`BreadcrumbList` into shared spoke components; add `pillar` to MWC schema (optional, non-breaking); delete `reviewSchema()` + trim its test block (known-safe — zero site callers, §4). *Verify:* `pnpm --filter mywildlifecam build` still green (regression guard) AND `pnpm --filter @affkit/shared-utils test` green after the test trim.
2. **`scripts/bootstrap-site.ps1`** (deterministic generator, §6). *Verify:* dry-run prints the file manifest it would write.
3. **`plugin/commands/bootstrap-site.md`** (Q&A playbook). *Verify:* prose review only.
4. **fussybean: write `site-config.json`** (8.1). *Verify:* `ConvertFrom-Json` parses; axes sum to 100.
5. **fussybean: `config.ts` upgrade** (8.2). *Verify:* `astro check` clean.
6. **fussybean: spoke routes + index pages** (8.3). *Verify:* build green with zero content (empty-state renders).
7. **fussybean: pillar-hub route** (8.4). *Verify:* `/topics/<pillar>/` pages emit for each pillar.
8. **fussybean: MainLayout + identity** (8.5/8.6). *Verify:* build green; fonts load.
9. **fussybean: E-E-A-T pages** (8.7). *Verify:* `/how-we-evaluate/` renders the rubric from config.
10. **fussybean: homepage** (8.8). *Verify:* `lint-voice.ps1` clean on `index.astro`; no `hands-on`.
11. **Full gate:** all three lints clean + `pnpm --filter fussybean build` green. *Verify:* run `scripts/magic-go-readiness.ps1 -Site fussybean` → **ready** (proves R1–R5, magic-go auto-includes it).
12. **Docs:** session log + PROJECT_STATE milestone ("fussybean passes readiness gate — first satellite SEO-strong").

---

## 11. Per-step verification (build + 3 lints green)

Every fussybean step that writes content-adjacent files ends with the same triple-check, mirroring the pre-commit hook so nothing is a surprise at commit time:

```
pnpm --filter fussybean build                                   # Astro is the test
pwsh scripts/lint-voice.ps1 -Path sites/fussybean/src/...       # voice doctrine
pwsh scripts/lint-product-images.ps1                            # (once content exists)
pwsh scripts/lint-affiliate-tags.ps1                            # tag match (skips empty tag)
```

Until fussybean has real content (post-bootstrap, via magic-go), the image + tag lints are no-ops (no `image:`/`tag=` to check) — but build + voice run from step 6 onward. The final readiness proof (step 11) is `scripts/magic-go-readiness.ps1 -Site fussybean` returning `ready: true`.

---

## 12. How this interacts with Magic Go

- **Auto-inclusion:** magic-go v1 §2.2 iterates `sites/*` and runs only against sites passing R1–R5. fussybean fails R4 today (old routes, body-marker gate). After build steps 4–6 it passes R1–R5 → **the next `/aff magic-go <N>` auto-allocates slots to fussybean** with zero magic-go code change. The bootstrap track is the on-ramp; magic-go is the engine.
- **No double-work on config shape:** fussybean is born canonical (nested). magic-go's `Get-SiteConfigField` adapter already reads nested (it must, for DTP). So fussybean "just works" through the adapter the day it's born — the adapter was built for DTP's nested shape, fussybean shares it.
- **`categoryPillars` interplay (the key nuance):** magic-go v1 §2.2 **deliberately does NOT gate on `categoryPillars`** (requiring it would reject flat-config MWC). This bootstrap track ADDS `categoryPillars` + `navigation.pillars` to fussybean anyway, because pillar IA (Item 3) is part of the SEO-strong bar. That's fine and non-conflicting: magic-go's gate is a floor, not a ceiling — having pillars never *fails* the gate, and magic-go's scaffolder simply won't populate the `pillar` field on spokes until Item 3 ships (at which point bootstrapped sites are already pillar-ready). So fussybean is forward-compatible with Item 3 before Item 3 exists.
- **Sequencing recommendation:** land this bootstrap track (fussybean SEO-strong) BEFORE the big `magic-go 25` run, exactly as magic-go v1 §11's scope note asks ("SHOULD land before the big magic-go 25 run so the volume is SEO-strong"). The magic-go-2 PROOF can still run against MWC+DTP first; fussybean joins the portfolio for the scaled run.

---

## 13. Open decisions for Ray

**Top 3 (lead with these):**

- **D1 — MWC canonical-config migration.** This doc makes nested canonical. MWC is the one remaining flat config. Migrate MWC flat→nested now, or keep the `Get-SiteConfigField` adapter as the permanent bridge? *Recommend:* keep the adapter for now (magic-go is mid-build against it; migrating a shipped hero site mid-flight is risk for no fussybean benefit). Schedule the migration as its own track after magic-go v1 ships. **Off the fussybean critical path either way.**
- **D2 — URL taxonomy.** Keep `/reviews/` + `/buyers-guides/` and ADD pillar hubs at **`/topics/<pillar>/`**? *Recommend:* yes — zero churn on existing URLs, and `/topics/` avoids the `/guides/` vs `/buyers-guides/` ambiguity. Alternative segment words: `/shop/`, `/best/`, `/category/`.
- **D3 — fussybean identity/palette.** Approve the proposed espresso-brown + cream + brass palette and the Newsreader/Fraunces + Inter font pairing? Or steer a different direction before the tool bakes it in.

**Lower-stakes (defaulted unless Ray objects):**

- **D4 — how many informational pillars to seed.** Proposed 2 (`coffee-costs` + `fun-stuff`/novelty). More authority clusters = more E-E-A-T surface but more empty hubs at launch. *Recommend:* start with these 2; add as content arrives.
- **D5 — named-author identity.** "The FussyBean editorial team" (matches MWC) vs. a real named human persona. *Recommend:* editorial-team entity for now; a named human is a stronger E-E-A-T signal later if Ray wants to attach his name.
- **D-minor — `reviewSchema()` disposition.** Delete outright + trim its test (recommended; verified zero site callers, §4) vs. hard-gate behind `allowFirstPartyReview` flag. *Recommend:* delete; resurrect from git if ever needed. (Note: the MWC `reviews` schema keeps its optional `rating: 1–5` field, which fussybean inherits in 8.2 — it stays for possible internal/editorial use but is NEVER emitted as `Review`/`AggregateRating` JSON-LD. The field is harmless data; the emission was the footgun, and it's already gone.)

---

## Recommended first build step

**Build step 0 — fix the voice-doctrine violation at the source: add `hands-on review` / `hands-on testing` to `docs/voice-doctrine.md`'s forbidden-phrase list, then strip the banned claims from `templates/site-template/src/pages/index.astro`.** Reasons:

- It's the one defect that **actively ships a doctrine violation into every future bootstrap** — the naive copy-the-template path bakes "hands-on reviews" into each new satellite. Fixing the template is the highest-leverage, lowest-risk first move: it closes the hole before the tool that would propagate it exists.
- It surfaces a real lint gap (the current forbidden list doesn't catch the `hands-on review` phrasing), so closing it strengthens the pre-commit back-stop for the whole portfolio, not just fussybean.
- It's deterministic, touches no site config, no schema, no MWC — fully isolated, instantly verifiable (re-run `lint-voice.ps1` and watch it trip on the old string), and unblocks every subsequent step with zero coupling risk.

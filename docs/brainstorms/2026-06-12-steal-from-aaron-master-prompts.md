# Steal-from-Aaron — Review of the 5 "Master Prompt" Docs

**Date:** 2026-06-12
**Author:** Ray (via Claude)
**Source:** 5 of Aaron's playbook docs (he's Ray's brother — shared both ways):
1. `MASTER-NICHE-BUILD-PROMPT-v6-ULTIMATE` — the one-shot site builder
2. `Universal-Site-Completion-Audit-v4.2` — post-build QA checklist
3. `Universal-Platform-Setup-Template-v3` — CF/Google/Prerender/email wiring
4. `STANDALONE-OFFPAGE-SEO-PROMPT-v5` — backlinks / submission
5. `MONETIZATION-STRATEGY-v5-ULTIMATE` — revenue tiering

**Governance note (read first):** the Magic Go backlog is **locked and sequenced** in `2026-05-28-magic-go-vision.md` + `2026-05-29-magic-go-v1-plan.md`. Per those docs' own rule, new ideas do **not** get inserted into the sequence — they go to `/aff-idea`. This doc is **review notes, not a new plan.** It sorts Aaron's material into: (A) confirms what's already locked, (B) already shipped / we're at parity, (C) **3 genuinely-new, architecture-agnostic items → flagged for `/aff-idea`**, (D) explicit do-not-steal.

---

## The one-sentence reframe

Aaron's kit is a **volume + autonomy + verification** machine. Its single load-bearing rule (Rule 4: *"No human checkpoints — never ask 'should I continue?'"*) is the **direct antithesis of Ray's Bottom Line gate**, which is the entire moat against slop. So "steal from Aaron" here does **not** mean adopt his no-gate volume engine. It means **harden our quality gate** by borrowing his *verification discipline* and a couple of concrete *data-integrity checks*. We keep the gate; we steal the rigor around it.

---

## (A) Confirms the locked backlog — no action, just validation

| Aaron's doc | Our locked item it confirms |
|---|---|
| Topic pages + "Browse by Topic" pills + TOPICS dropdown (Build Features #8–10) | **Pillar-cluster IA** (vision Item 3) |
| NO_LCP skeleton + single-hero homepage | **Minimalist homepage** (vision Item 4) |
| The 7 self-driving loops + batch production | **Magic Go autonomous scaffolding** (vision Item 5) — we steal the *loop structure*, NOT the no-gate philosophy |
| "How We Make Money" page + un-named footer disclosure | **Generic affiliate disclosure** (vision Item 2) |
| `MONTHLY-REVENUE.md` + mission-control dashboard | **Revenue dashboard** (vision Item 6) |

Nothing here reorders the sequence. It's external corroboration that the locked plan is pointed the right way.

---

## (B) Already shipped / at-parity — don't re-do

- **IndexNow → Bing + Yandex.** His offpage doc submits to Bing Webmaster + IndexNow + Yandex. We already ping both Bing and Yandex via `pnpm indexnow:submit` (commit `e5dbdc7`, ~163 URLs HTTP 202), Bing Webmaster account active, GSC submitted. Parity-or-better.
- **Multi-network commission routing.** His 5 prompt docs *hardcode* a single Amazon tag (`jra047-20`). Our locked Item 1 (multi-network routing) is ahead **of these prompt docs** — note: his *dashboard* (separate tooling) does auto-swap networks, so we're ahead of the prompts, not ahead of Aaron.
- **Schema / OG / sitemap / trailing-slash / security headers.** All already in our Astro build + Cloudflare layer.
- **Product-liveness safety net.** v1-plan line 424 already plans a discontinued/multipack-only/delisted ASIN guard.

---

## (C) Genuinely new — architecture-agnostic — → file via `/aff-idea`

These are **not** inserted into the Magic Go sequence. They're cheap hardening of the gate, logged here so they aren't lost.

### C1. Post-deploy **visual-regression screenshot pass** (the headline steal — but right-sized)
Aaron's loudest rule across all 5 docs: *"HTTP 200 means NOTHING. curl means NOTHING. The browser screenshot is the ONLY valid proof."* That **absolutism is calibrated to a fragile React SPA** — blank-React-page, JS-chunk-404, relative-paths-breaking-on-nested-routes, cached-HTML-instead-of-image. **Most of those failure classes don't exist on our pre-rendered static Astro,** and the incidents we *have* hit (CLS 0.458; Canopy image rotation) are already covered by the `<img>` width/height grep in `CLAUDE.md` + `lint-product-images.ps1` + `audit-product-images.ps1`.

So the steal is **additive, not "the only proof":** a thin post-deploy Playwright pass (MCP already available, noted in vision line 110) that screenshots a money page per site and flags the narrow class our greps **can't** see —
- a marketing **composite** image (passes aspect lint at 0.5) rendering as a tall sliver inside our 1:1 card containers,
- a CSS/mobile regression that overlaps a CTA with an image.

Scope it as a visual smoke check on Tier-A pages, not a gate. Don't import Aaron's urgency — our static stack already prevents the failures that made it his #1 rule.

### C2. **ASIN-to-name alignment check**
Distinct from the planned liveness guard. Aaron's check: the product the ASIN *resolves to on Amazon* must match the product *name on our page*. A wrong-but-live ASIN silently sends a buyer to a competitor's product and we'd never know from a 200. Add to the same research/safety-net step as the liveness check (v1-plan ~line 424): on scaffold, fetch the ASIN's title (Canopy/PA-API) and fuzzy-match it against the piece's product name; flag mismatches to the failures queue.

### C3. **Amazon search-link fallback for un-verified ASINs**
Aaron's Category 30.7 strategy table: for DTC/niche brands not reliably on Amazon, link to a **tagged search** (`/s?k=Product+Name&tag=...`) instead of a guessed `/dp/{ASIN}` that 404s or shows the wrong product. A never-404 degradation path. Pairs cleanly with multi-network routing (Item 1): if no verified ASIN *and* no other network has the product, fall back to tagged search rather than a dead direct link.

---

## (D) Explicit do-not-steal (with reasons, so it stops recurring)

- **Rule 4 — "no human checkpoints, never ask."** The antithesis of the Bottom Line gate. This is the whole point of our architecture; adopting it would trade away the moat. Hard no.
- **Prerender.io for crawler SEO.** A React-SPA crutch. Astro emits full static HTML at build time — crawlers already get the rendered page. Wiring Prerender would be pure waste and added attack surface.
- **Niche scoring matrix / domain availability API.** 6 sites, not scouting #7. Dead weight until that changes (already on the vision's not-now list).
- **500–1000 page volume play.** His shipped site is ~10 articles; claim unverified. Quality gate > page count.
- **Hardcoded single Amazon tag.** We're going multi-network.

**Reference-only (file as memory if it ever bites):** his Platform-Setup doc documents a real deploy gotcha — Wrangler **v3.20** + token perm **User → Memberships → Read** (NOT Account → Account → Read); `wrangler@latest`/`4.x` needs Node 22 and `3.50+` adds a `/memberships` auth check. We deploy via GitHub Actions matrix today; this is the fix-it note if that ever throws a `/memberships` auth error.

---

## Follow-up: the Google Analytics panel, SEO, keywords, monetization

Ray asked specifically about these four. Grounded in our actual state (we run **Cloudflare Web Analytics — cookieless, edge-injected**; no GA4, no custom events, no consent banner, no OAuth dashboard; `/ops` is static pipeline-state only):

### Google Analytics panel / dashboard
Aaron's stack: **GA4 + Consent Mode v2**, custom events (`affiliate_click`, `newsletter_signup`, `compare_select`) with a conversion goal on `affiliate_click`, plus an **in-site OAuth dashboard** at `/dashboard` (scopes `analytics.readonly` + `webmasters.readonly`) and a portfolio mission-control panel.
- **The dashboard itself = already your locked Item 6** (revenue + cost roll-up). And your planned *local-HTML* version beats his in-site OAuth panel for a solo operator — no public OAuth surface, no per-site login. **Don't build his `/dashboard`.**
- **DON'T adopt GA4 + Consent Mode v2.** It exists in his stack *only because GA4 sets cookies* — which forces the cookie-consent banner. You're cookieless today. Bolting on GA4 would drag a consent banner onto clean sites = a UX/perf regression for a metric you mostly already have.
- **The one real gap worth closing: affiliate-click tracking.** You currently can't see which products/links convert. But the right place is the **link-cloaker Worker** (it already sits in every click path), not GA4 — log click-by-product/by-network at the edge, stay cookieless, no banner. This is **already implied** by locked Item 1 ("track click-through-by-network in Cloudflare Analytics"). So: not new, just confirms Item 1 is the click-analytics vehicle.

### SEO
- **On-page: parity or ahead.** Most of his SEO rules (BrowserRouter, Prerender, absolute asset paths, no-`#` URLs) are **SPA-tax** your static Astro skips. Schema / OG / sitemap-trailing-slash / canonical — you already emit. 3+ internal links/article = revenue-plan Workstream C, in flight.
- **Off-page is your genuinely thin spot** — and you said as much in *today's* session log ("a few real external backlinks"). His `STANDALONE-OFFPAGE-SEO-PROMPT` is a concrete manual playbook: HARO, guest posts, broken-link building, resource-page links, a data study, Reddit/Quora. **Steal the tactics as a checklist, not a feature** (it's outreach labor, not code). This is the highest-value SEO steal in the whole bundle.

### Keywords
- `/scout-topics` + `/research-product` already cover discovery. His Keyword Exhaustion engine (autocomplete → PAA → Related → cluster → saturate) is more *exhaustive*, but the saturation/coverage-% stop condition leans toward the **volume play you explicitly rejected.** Skip the saturation engine.
- **One cheap add:** pipe People-Also-Ask questions into the FAQ section your pieces already have (better AIO-citation surface, truthful under doctrine). Low-priority `/aff-idea`.

### Monetization
- Your `2026-06-01-revenue-plan.md` **already locked scope** to comparison content + EEAT + internal linking + AIO hygiene — *deliberately excluding* email lists and display ads. So most of Aaron's tier ladder (Ezoic ads, newsletter monetization, sponsored, courses, membership, private label) is **not-now by your own decision**, not an oversight.
- His sound principle if ads ever happen: **display ads ONLY on low-value pages, NEVER on money pages.** File for later.
- The highest-leverage monetization move is **protecting revenue you already earn** — multi-network routing + verified links + search-link fallback. That's locked Item 1 + steals C2/C3 above. Nothing new here.

---

## Bottom line for Ray

Three small things worth doing (C1/C2/C3), all of which **strengthen the gate** rather than dilute it — route them through `/aff-idea` so they queue without disturbing the locked Magic Go sequence. Everything else is either already done, already planned, or actively wrong for our static architecture. The most useful sentence in the whole review: **his machine has no quality gate, and that's exactly the part we don't want.**

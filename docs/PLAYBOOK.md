# Affiliate Kit Playbook

> The single-page reference for writing reviews and running quarterly cycles. Read this at the start of every cycle. 5 minutes, then go.

---

## Quick orientation

This kit runs five Astro sites on Cloudflare Pages with a shared link-cloaker Worker. One **hero** site (`mywildlifecam.com`) gets the real effort; four **satellites** (`fussybean.com`, `detailerpicks.com`, `starteraquarium.com`, `gameovergear.games`) get the same playbook on a slower clock. The non-negotiable content rule: **AI scaffolds the draft, you fill in `## My Take`**. Pages that still have the `_Waiting for the human._` placeholder render a DRAFT banner and get `noindex` — they cannot ship by accident.

---

## Before review #1 (one-time prerequisites)

Do these once, in order, before you scaffold your first review on a site.

1. **Enroll in Amazon Associates under the hero apex.** Sign up at `affiliate-program.amazon.com` using `mywildlifecam.com` as the listed property. Why: every Amazon link in the kit applies a `?tag=...` at the Worker. Without the Associates tag, clicks pay nothing. How: apply → wait for approval email → copy your tracking ID (e.g. `mywildlifecam-20`).
2. **Eyeball niche programs.** For trail cams: Spypoint, Moultrie, Bushnell direct affiliate programs sometimes pay more than Amazon. Note tracking tags as you get them. Not built yet: `docs/AFFILIATE_PROGRAMS.md` is queued — for now keep a Notes file.
3. **Pick the 5-product roster for cycle 1.** Five products you can actually order, photograph, and use. If you don't own a product and won't, that's a buyer's-guide slot, not a review slot.
4. **Confirm local clone is in good state.** From the repo root: `pnpm install`, then `pnpm test` in `packages/shared-utils`, `tools/bootstrap`, and `workers/link-cloaker`. All green. If they're not, fix that first — don't paper over.
5. **Confirm `wrangler` is logged in.** Run `wrangler whoami`. If it doesn't print your account, `wrangler login`. The KV scripts will fail without it.

---

## Per-review workflow (~1-2 hours, once warmed up)

Steps for ONE review on ONE site. Repeat per product.

### 1. Pick a specific product

**What:** A real product with a real SKU. Not a category, not "a trail cam under $200."
**Done when:** You can name the brand, model, and (ideally) the Amazon ASIN.

### 2. Decide: review or buyer's-guide?

**What:** If you own it and have used it → **review**. If you don't own it → **buyer's-guide**. The content rule is load-bearing — buyer's-guides cannot claim personal experience.
**Done when:** You know which script you're about to run (`new-review.ps1` vs `buyers-guide.ps1`).

### 3. Get the Amazon URL with your tracking tag

**What:** The product page on Amazon. The Worker re-applies your tag at request time, so paste the plain product URL (e.g. `https://www.amazon.com/dp/B0XXXXXXXX`) — no `?tag=` needed in what you save. If you're using a non-Amazon affiliate program, paste the program's tagged URL directly; the Worker passes it through as-is when `merchant != "amazon"`.
**Done when:** URL is in your clipboard.

### 4. Run the scaffolding script

**What:** This copies the template, fills frontmatter, writes the KV entry. One command.

For a review:

```powershell
pwsh scripts/new-review.ps1 `
  -Site mywildlifecam `
  -Slug spypoint-flex-m `
  -ProductName "Spypoint Flex-M" `
  -Brand "Spypoint" `
  -Sku "FLEX-M" `
  -AmazonUrl "https://www.amazon.com/dp/B0XXXXXXXX" `
  -Tag "mywildlifecam-20"
```

For a buyer's guide:

```powershell
pwsh scripts/buyers-guide.ps1 `
  -Site mywildlifecam `
  -Slug best-trail-cam-under-200 `
  -ProductName "Spypoint Flex-M" `
  -Brand "Spypoint" `
  -AmazonUrl "https://www.amazon.com/dp/B0XXXXXXXX"
```

**Gotcha:** `-Slug` becomes the URL segment AND the KV key suffix. Lowercase, hyphens, no spaces. Once it's live and indexed, renaming is painful.
**Done when:** The script prints `[ok] Wrote ...` and `[ok] Wrote <site>:<slug> to KV`.

### 5. Fill in `## My Take` (or `## Editor's Note` for guides)

**What:** Open the new file at `sites/<site>/src/content/reviews/<slug>.md` (or `buyers-guides/<slug>.md`). Find `## My Take` and replace `> _Waiting for the human._` with your actual experience — what you tested, what worked, what didn't, who it's for.
**Gotcha:** Leave that placeholder in and the page ships with DRAFT banner + `noindex`. By design — but don't rely on it as a process, just fill it in.
**Done when:** The placeholder string is gone and your prose is in.

### 6. Add product images

**What:** Set `images.hero` (and any additional images) in the frontmatter.
**Not built yet:** Cloudflare R2 + PA-API helper. For now: paste Amazon product image URLs directly into frontmatter (right-click the hero image on the product page → Copy image address). It's not ideal — Amazon image URLs can rotate — but it works until R2 lands in Phase 2.
**Done when:** Frontmatter has a hero image URL that loads in a browser.

### 7. Preview locally

```powershell
pnpm --filter @affkit/mywildlifecam dev
```

Open `http://localhost:4321/reviews/<slug>` (or `/buyers-guides/<slug>`). Check the hero, the CTA button, the rendered prose.
**Done when:** Page renders, no DRAFT banner (because you filled in My Take), CTA button shows.

### 8. Spot-check JSON-LD

**What:** The page emits `Review` + `Product` structured data. Validate it.
**How:** Open `https://search.google.com/test/rich-results` in a browser, paste your local URL (or wait until deploy and paste the live URL). Look for `Review` and `Product` items with no errors.
**Done when:** Rich Results Test shows green for both schema types.

### 9. Commit and push

```powershell
git add sites/<site>/src/content/reviews/<slug>.md
git commit -m "feat(<site>): add <slug> review"
git push
```

Cloudflare Pages auto-deploys on push to `main`. ~60-90 seconds to live.
**Done when:** Pages dashboard shows the new deployment as "Success."

### 10. Smoke-test the cloaked link

```powershell
curl -I https://mywildlifecam.com/go/spypoint-flex-m
```

Expected: `HTTP/2 302` with a `Location:` header pointing at Amazon. Or click the CTA on the live page and watch the browser bar — it should bounce through `/go/<slug>` and land on Amazon with your `?tag=` applied.
**Done when:** 302 returned, tag visible in the redirect URL.

---

## The 90-day cycle (per site)

5 reviews + refresh sweep, once per quarter. Roughly:

| Weeks | What you're doing | What NOT to do |
|-------|-------------------|----------------|
| 1-2   | Plan + roster. Commit to 5 products. Confirm affiliate programs. Order anything you don't have. | Don't start writing yet — half-baked rosters waste reviews. |
| 3-9   | Write 5 reviews/guides. One every ~10 days. Mix review (own it) and buyer's-guide (don't) as the roster dictates. | Don't batch all 5 in week 9 — quality cratering is real. |
| 10-11 | Refresh sweep on this site's older content. See checklist below. | Don't refresh content from sites you're not currently cycling. |
| 12    | Buffer. Catch up on whatever slipped. Pick the next quarter's roster. | Don't start cycle N+1 inside this week — the buffer is the buffer. |

If a week slips, slip the buffer first, then the refresh sweep, then a review. Never sacrifice My Take quality to hit a date.

---

## Refresh sweep checklist

Run during weeks 10-11 on the site currently in-cycle. The point: catch dead products, stale prices, and broken affiliate links before Google does.

- **Enumerate live links.** `pwsh scripts/list-links.ps1 -Site mywildlifecam`. Note the count.
- **Test each cloaked link.** For each key, `curl -I https://<apex>/go/<slug>` should return 302. Anything returning 404 means the KV entry is gone but the markdown file still links to it — fix the KV or remove the link from the post.
- **Flag retired products.** Click through to the merchant. If the product is "currently unavailable" with no restock, mark it retired. Not built yet: the structured KV envelope supports `status: "retired"` → 410 and `replaced_by` → 301 chains, but there's no script wrapper for flipping them — for now, re-run `scripts/add-link.ps1` with the same key (overwrites). Worker handles the rest.
- **Successor product?** If you have one, set `replaced_by: "<new-slug>"` on the retired entry. Visitors get a 301 to the new review.
- **Bump `lastUpdated` in frontmatter** on any review where you changed body copy.
- **Search-and-replace stale phrases.** Grep the site's `src/content/reviews/` for "as of 2026", "released last year", any year reference, any price reference. Replace or remove. Stale dates erode trust faster than anything else.
- **Ping IndexNow.** Not built yet: there's no `/aff-refresh` slash command and no CLI wrapper. The `submitToIndexNow()` helper exists in `packages/shared-utils/` but isn't wired to a script. For now: manually POST to `https://www.bing.com/indexnow` with your changed URLs, or skip — Google will re-crawl on its own clock.

---

## Hero vs satellite cadence

The hero (`mywildlifecam.com`) gets a full 90-day cycle every quarter — 5 reviews, refresh sweep, the works. The four satellites (`fussybean.com`, `detailerpicks.com`, `starteraquarium.com`, `gameovergear.games`) each get **one cycle every TWO quarters** until the hero proves the model with organic traffic and affiliate revenue. Do not try to write 5 reviews on 5 sites every quarter — that's 25 reviews per quarter, you will burn out, the hero will starve for attention, and none of the sites will get the focus they need. When the hero shows traction (real affiliate dollars, sustained organic traffic), promote one satellite to hero-tier cadence and demote the hero to maintenance. Re-evaluate every two quarters.

---

## What this playbook does NOT cover

- **Amazon Associates application and niche-program enrollment.** Your action, not code. The pattern from `docs/launch-playbook.html` (apply, wait, log the tracking tag) is the same.
- **PA-API integration for product hero images.** PA-API access is gated on 3 qualifying sales within 180 days of Associates approval. Chicken-and-egg. For now, paste Amazon image URLs into frontmatter manually.
- **Cloudflare R2 image hosting.** Not enabled. Phase 2. For now, hotlink Amazon URLs and accept they may rotate.
- **The `/aff-cycle`, `/aff-refresh`, `/aff-status`, `/aff-next` slash commands.** Phase 2/3. For now the workflow above is manual; `/aff-help` (auto-derived from `plugin/commands/`) lists the real commands that exist.
- **Season-finale or special-product handling.** No special path. Treat seasonal products like any other product — write the review when you have it in hand, retire it via the refresh sweep when it's gone.
- **Cross-site product reuse.** KV keys are namespaced as `<site>:<slug>` so the same slug on two sites is two separate entries. Don't share a review file across sites — copy and rewrite.

---

## When you get stuck

- **Original design intent:** `docs/2026-05-12-affiliate-kit-design.md`. Read when something feels arbitrary — it's probably not.
- **What the team did recently:** `docs/sessions/Session_YYYY-MM-DD.md`. The session logs are the running narrative.
- **Repo conventions and content rules:** `CLAUDE.md` at the repo root. Strategy + content rules + style.
- **This plan:** `docs/2026-05-14-affiliate-kit-content-readiness-plan.md`. Every decision in this playbook ties back to a unit in that plan.
- **Basement setup (one-time per machine):** `docs/BASEMENT_SETUP.md`. Re-read if you're starting fresh on a new PC.

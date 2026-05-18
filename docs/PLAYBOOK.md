# Affiliate Kit Playbook

**The Ray-facing operating guide.** What commands exist, how to use them, the workflow for shipping a piece, and how often to do what.

**For the engineering / architecture picture, see `docs/SYSTEM.md`.** This doc is the user manual; SYSTEM.md is the wiring diagram.

**Last refreshed:** 2026-05-18

---

## The Kit at a glance

You have 5 affiliate sites on Cloudflare Pages. One hero (`mywildlifecam.com`) gets real attention; four satellites (`detailerpicks`, `fussybean`, `starteraquarium`, `gameovergear`) get the same playbook on a slower clock. Content framework is **comparison-and-fit**: never claim hands-on use, drive value through spec verification + reader-segment fit + reviewer attribution. Voice doctrine at `docs/voice-doctrine.md` is the single source of truth for forbidden phrases.

The hard rule that makes this work, not slop: **the Bottom Line is human, written by you, never AI.** The scaffolder leaves `## Bottom Line` empty; an empty Bottom Line auto-flips the page to `noindex` so a draft can't leak. You write it. That's the moat.

---

## The 4 slash commands

All installed via `pnpm install-plugin`. All version-controlled in `plugin/commands/`.

### `/capture <idea>`

**When:** A sidetrack idea hits mid-conversation. "Oh we should also add X." "Try Y next time." "Remember to look at Z."
**What it does:** Files the idea into `~/documents/github/second-brain/ideas/` with a timestamp, the project tag, and status `inbox`. Brad's hook auto-commits to second-brain. Returns one line — does NOT start working on the idea.
**Why it exists:** So you don't have to choose between "lose the idea" and "break the current thread." File it, keep going.
**Example:** `/capture a dashboard that tells me what to do next for each site`

### `/research-product <topic>`

**When:** You want to write about a product or category and need source-attributed data before scaffolding.
**What it does:** Parallel-fires four research jobs:
- **Firecrawl search** → product spec pages
- **`/last30days`** → Reddit threads + comments, owner-report patterns
- **`/watch`** → top YouTube reviewer's transcript (verbatim quote-ready)
- **Canopy API** → ASIN verification + current pricing

Synthesizes findings into `docs/research/<date>-<slug>.md` with verified specs, community signal, reviewer transcript highlights, and a recommendation on piece type (single-product review vs buying guide).

**Why it exists:** This is the 30-60 min per piece you used to spend manually researching. Now it runs while you do other stuff. Quality of synthesis > speed.
**Example:** `/research-product Browning Strike Force Elite HP5`

### `/scaffold-piece <args>`

**When:** Research is done (or skipped — your call), you know the product, the slug, the Amazon URL. Ready to create the file.
**What it does:** Wraps `scripts/new-review.ps1` (or `scripts/buyers-guide.ps1`) + `scripts/add-link.ps1` (cloaker KV) + `scripts/lint-voice.ps1` + `pnpm --filter <site> build` in one command. STOPS at the DRAFT gate — won't commit or push because the Bottom Line is empty.
**Why it exists:** The 5-step shell ritual collapses to one line, and the build verifies before you touch anything.
**Example:** `/scaffold-piece site=mywildlifecam type=review slug=moultrie-edge-2-pro product="Moultrie Edge 2 Pro" brand=Moultrie amazon_url="https://amazon.com/.../dp/XXX?tag=mywildlifecam-20"`

### `/bottom-line-helper <slug>`

**When:** You scaffolded a piece, the body is drafted, and you're sitting at the empty `## Bottom Line` slot trying to write the verdict.
**What it does:** Reads the piece's frontmatter (scorecard, buyIf, flaws data) and 2-3 prior shipped Bottom Lines on the same site for voice anchor. Drafts 3 verdict options (Option A = Buy/Skip, B = doctrine angle, C = specific picks) + a supporting paragraph. Outputs to chat. **Never writes to the file.** You pick one, edit it in your voice, paste it in.
**Why it exists:** The hard part of the Bottom Line isn't writing 20 words — it's picking the framing. This shortcuts that.
**Example:** `/bottom-line-helper best-pressure-washer-for-home-detailers`

---

## The piece workflow (end-to-end)

From "I want to write about X" to "live on the site." Roughly 60-90 min of your time per piece, of which ~20 min is the Bottom Line.

```
1. PICK            You decide the product or category
2. RESEARCH        /research-product <topic>           ← runs in background, 5-10 min
3. REVIEW NOTES    Read docs/research/<date>-<slug>.md  ← decide review vs guide, sanity-check framing
4. SCAFFOLD        /scaffold-piece <args>               ← scaffolder + cloaker + lint + build
5. DRAFT BODY      AI fills the body from research      ← I do this from the research notes
6. BOTTOM LINE     /bottom-line-helper <slug>           ← 3 options drafted
7. YOU WRITE       You write the actual Bottom Line     ← the human moat, never automate
8. LINT            pwsh scripts/lint-voice.ps1 <path>   ← back-stop for forbidden phrases
9. COMMIT + PUSH   git add + commit + push to main      ← GH Actions deploys all 5 sites
10. VERIFY         Hit the live URL, click the CTA      ← 302 → Amazon with your tag
```

### Step-by-step in PowerShell

**Pick + research:**
```
/research-product best pressure washer for home detailers
```

**Scaffold (after reading research):**
```
/scaffold-piece site=detailerpicks type=buyers-guide slug=best-pressure-washer-for-home-detailers product="MTM Hydro PF22" brand="MTM Hydro" amazon_url="https://www.amazon.com/dp/XXXXX?tag=mywildlifecam-20" description="Cross-brand pressure washer guide for home detailers."
```

**Draft body** — happens in-conversation; I write from the research notes.

**Bottom Line:**
```
/bottom-line-helper best-pressure-washer-for-home-detailers
```

You pick a draft, edit in your voice, paste into the piece's `bottomLine.verdict` frontmatter field.

**Lint + commit + push:**
```powershell
pwsh scripts/lint-voice.ps1 sites/detailerpicks/src/content/buyers-guides/best-pressure-washer-for-home-detailers.md
git add sites/detailerpicks/src/content/buyers-guides/best-pressure-washer-for-home-detailers.md
git commit -m "feat(detailerpicks): pressure washer buying guide live with Bottom Line"
git push
```

GH Actions matrix runs ~3 min, all 5 sites redeploy in parallel. Verify at `https://detailerpicks.com/buyers-guides/best-pressure-washer-for-home-detailers/`.

### Step-by-step in PowerShell — single-product review

Same shape, swap `type=review` and the script picks `scripts/new-review.ps1` instead of `buyers-guide.ps1`. Single-product pieces use the same Bottom Line discipline.

---

## Cadence — how often to do what

### Per site

| Activity | Hero (mywildlifecam) | Satellites (detailerpicks, fussybean, starteraquarium, gameovergear) |
|---|---|---|
| New piece | Roughly 1 per week | Roughly 1 per 2-3 weeks |
| Quarterly cycle (5 new + refresh sweep) | Every 90 days | Every 180 days |
| Refresh sweep (price/spec/link health) | Weeks 10-11 of each cycle | Once per cycle |
| Visualping check (product page drift) | Auto, weekly per job | Same |

### Portfolio-wide

| Check | Cadence | Where |
|---|---|---|
| `affiliate_link_health` nightly run | Nightly (AIOS) | Manual trigger today; cron-scheduled when AIOS dashboard is ready |
| Google Search Console crawl + ranking check | Weekly skim | search.google.com/search-console |
| Bing Webmaster check | Monthly | bing.com/webmasters |
| Amazon Associates dashboard (clicks, sales) | Weekly skim | affiliate-program.amazon.com |
| Awin / AvantLink / brand-direct programs | Check approvals, then monthly | Per platform |
| Visualping watchlist | Auto-alerts (5 jobs) | visualping.io |
| Second Brain `ideas/` inbox triage | Weekly | `~/documents/github/second-brain/ideas/` |

### What "ranking check" actually looks like

GSC → Performance report → filter by site → look for:
- Any query bringing >5 impressions/day with click-through-rate below 2% → Bottom Line probably weak or title needs work
- Any page at position 8-15 → on the edge of page 2; small content improvements push it to page 1
- Any new query you didn't expect to rank for → opportunity for a tighter follow-up piece

---

## The DRAFT gate (why it works)

Every piece's `## Bottom Line` starts empty. The Astro renderer detects an empty Bottom Line and:
1. Emits `<meta name="robots" content="noindex, nofollow">` on the page
2. Renders a visible DRAFT banner at the top

So a piece can sit in the repo, deployed, with `noindex` until you finish the Bottom Line. The moment you fill it in and push, the page goes live (no separate "publish" step needed).

**This is the moat against being AI slop.** Google's March 2026 update hit affiliate sites with zero hands-on signal at 71% negative impact. We don't claim hands-on (legally + ethically correct since you don't own these products), but the Bottom Line being human-written, in your voice, with editorial judgment, is what makes the piece worth ranking. Without it, you're indistinguishable from autogenerated comparison spam.

**Never automate the Bottom Line.** `/bottom-line-helper` drafts options. You write the real one. That's the line.

---

## Second Brain triage workflow

`/capture` files ideas into `~/documents/github/second-brain/ideas/<date>-<slug>.md` with project tag + status `inbox`. Weekly, walk the inbox and triage:

```powershell
# List recent captures
ls ~/documents/github/second-brain/ideas/ | tail -20
```

For each idea:

- **Actionable + affiliate-sites scope** → add to `docs/TODO.md` Now/Next/Later in the affiliate-sites repo, then delete or move to `~/documents/github/second-brain/done/`
- **Actionable + other project** → move to that project's TODO or relevant file
- **Speculative, not now** → leave in `ideas/`; if it's still relevant in 30 days, promote
- **Not actionable** → delete

The point of `/capture` is to never break the active thread. The point of triage is to make sure ideas don't rot in the inbox.

---

## When to write what kind of piece

| Signal | What to write |
|---|---|
| Single product with strong opinions + spec story | **Review** (single-product, 1500-2500 words) |
| Category where 3-5 products map to distinct reader segments | **Buying guide** (5-7 picks with use-case framing) |
| Same product from a different angle (e.g. "for cellular vs SD-card") | **Cross-link from existing review** — don't write a separate piece unless the angle truly differs |
| Niche term with search volume but no commercial intent | **Skip** — non-affiliate content is a different game |
| Brand-new product without owner reports | **Wait 30-60 days** for community signal, then `/research-product` and decide |

---

## Health checks before publishing

Before you push a piece to `main`, run through this checklist:

- [ ] Bottom Line is yours, not the helper's draft verbatim
- [ ] `pwsh scripts/lint-voice.ps1 <path>` returns 0 findings
- [ ] `pnpm --filter <site> build` succeeds
- [ ] Frontmatter `images.hero` URL loads in a browser
- [ ] Frontmatter `affiliateUrl` points at the canonical product page (not a Smile or bundle URL by accident — Canopy can verify the ASIN if you're not sure)
- [ ] Voice scan in your head: no em dashes, no "I tested," no "this isn't for X," no first-person possessives
- [ ] Scorecard adds to 100% weight
- [ ] FAQ uses second-person ("How do you...")

After push:

- [ ] GH Actions matrix run succeeded
- [ ] Live URL renders without DRAFT banner
- [ ] Cloaked link `/go/<slug>` returns 302 to Amazon with `?tag=mywildlifecam-20`

---

## Fresh-machine setup

Full architecture + dependencies are in `docs/SYSTEM.md`. Short version for a fresh laptop:

```powershell
git clone https://github.com/champrt78/affiliate-kit.git affiliate-sites
cd affiliate-sites
pnpm install
pnpm install-plugin     # installs the 4 slash commands + prints account/key checklist
# fill in ~/.claude/plugins/affiliate-kit/config.json with Cloudflare token
# fill in ~/.config/last30days/.env with Canopy, Firecrawl, ScrapeCreators, Groq keys
# clone second-brain repo so /capture has somewhere to write
```

`pnpm install-plugin` prints the full external-account checklist (GSC, Bing, Amazon Associates, Awin, AvantLink, Visualping).

---

## When you get stuck

| Need | Go here |
|---|---|
| How does X connect to Y? | `docs/SYSTEM.md` (the architecture doc) |
| What's open right now? | `docs/TODO.md` (the canonical work list) |
| Voice / forbidden phrases | `docs/voice-doctrine.md` |
| What did we ship recently? | `docs/PROJECT_STATE.md` (milestones) |
| What happened yesterday/last week? | `docs/sessions/Session_*.md` |
| Content framework decisions | `docs/brainstorms/2026-05-15-content-framework-requirements.md` |
| Historical (pre-pivot) plans | `docs/archive/` |
| Past research per product | `docs/research/<date>-<slug>.md` |
| Design exploration history | `docs/playgrounds/` |

---

## What this playbook does NOT cover

- **Amazon Associates application + niche-program enrollment.** Your action, not code. Approval clocks are in the program TOS.
- **Cloudflare R2 image hosting.** Not enabled. Currently hotlinking Amazon CDN + manufacturer CDN URLs. R2 is a future enhancement when image rot becomes painful.
- **Click-tracking analytics queries.** Worker writes click events to Cloudflare Analytics Engine; query bundle is deferred until there's enough traffic to learn from.
- **The deferred `/aff-cycle`, `/aff-refresh`, `/aff-status`, `/aff-next` commands** from the original 2026-05-12 design. Replaced by `docs/TODO.md` for what's-next and Visualping for refresh-sweep automation. Archived design at `docs/archive/2026-05-12-affiliate-kit-design.md`.
- **Cross-site product reuse.** KV keys are `<site>:<slug>` — same slug on two sites = two separate entries. Don't share content files across sites; write per-site.

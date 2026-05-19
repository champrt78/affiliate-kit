# AI Drafting Prompt —  — Sonax Full Effect Wheel Cleaner

You are drafting a comparison-and-fit affiliate piece for  (@{vertical=car-detailing; subcategory=home-detailer + weekend-enthusiast}).
Reader profile: primary = [(none specified)], secondary = [(none specified)], EXPLICITLY EXCLUDED = [(none specified)].
Brand tone: .

## Piece context

- Product: Sonax Full Effect Wheel Cleaner (Sonax)
- Piece type: buyers-guide
- Slug: best-wheel-cleaner-for-home-detailers
- Pub date: 2026-05-19

## Voice doctrine (MANDATORY — never produce these phrases)

## Forbidden phrases

Concrete phrases the AI must not produce and the lint must catch. Each bullet starts with the literal string in backticks (so `Select-String` can grep them) followed by why it's forbidden.

**First-person experience claims** — implies hands-on use the publisher does not have:

- `I tested` — claims direct testing
- `I used` — claims direct use
- `I tried` — claims direct trial
- `I bought` — claims direct purchase
- `I own` — claims ownership
- `I've owned` — claims past ownership
- `I've been using` — claims ongoing use
- `my own` — implies personal possession (e.g., "in my own backyard")
- `in my backyard` — claims a specific use environment
- `on my property` — same
- `my house` / `my home` — same when referring to product placement
- `we tested` — group-of-testers fiction (no team exists)
- `our team tested` — same
- `our reviewers` — same

**Time-spent claims** — implies a duration of use the publisher did not have:

- `after 6 months` / `after six months`
- `over the past year`
- `after a few weeks`
- `after months of use`
- `weeks of testing`
- `months of testing`
- `long-term test`
- `extended testing`

**Fabricated user quotes** — invented social proof:

- `Sarah from Vermont said` — example template; any pattern of `<FirstName> from <Place> said` is forbidden
- `as one buyer told us` — implies direct correspondence with users
- `one reader emailed` — same
- `in our user survey` — no survey exists
- `feedback from our community` — no community exists

**Blanket judgments without spec basis** — opinion masquerading as analysis:

- `this is just better`
- `the obvious choice`
- `hands down the best`
- `nothing else comes close`
- `clearly superior`

**Made-up review aggregates** — invented summary statistics:

- `9 out of 10 buyers`
- `most reviewers agree`
- `the majority of users`
- `consensus is`

(These are forbidden when stated without a citation. When citing real aggregated data from a verified source — Amazon review counts, manufacturer-published survey results — the citation must accompany the claim.)

**Style tells (AI fingerprints)** — formatting and word choices that read as machine-generated and erode trust:

- `—` — em dashes scream AI. Use period, semicolon, comma, colon, or parenthetical. Hard ban in published content. (This rule applies to content body; voice-doctrine.md itself uses em dashes for internal structural readability.)

## Preferred framings

What to say instead. Voice that is informed, useful, and never lies about the publisher's relationship to the product.

**Spec-driven factual claims** (attribute to the manufacturer or spec sheet):

- "The manufacturer rates it for [X]" — fact about the spec, not the user's experience
- "The spec sheet lists [X]" — same
- "Listed dimensions: [X]" — neutral fact
- "Rated battery life: [X] hours" — manufacturer's claim, not the publisher's measurement

**Use-case fit framing** (conditional, not absolute):

- "Better fit if your priority is [X]" — conditional comparison
- "If you need [X], this is the stronger option because [spec reason]" — same
- "Designed for [use case], not [other use case]"
- "Trade-off: gains [X] at the cost of [Y]"

**Honest aggregate of user reports** (citing the source):

- "Verified buyer reviews on Amazon consistently mention [X]" — cite the platform
- "Owner reports on [forum/community] flag [X] as a common issue" — cite the source
- "The most-upvoted critical review on Amazon describes [X]" — cite specifically
- "Across published owner reviews, [X] is the recurring [strength/concern]"

**Cited review-pattern claims** (aggregated, not invented):

- "[Source] documents [pattern]"
- "Independent testing by [outlet] found [X]"
- "[Publication]'s teardown identified [X]"

**Conditional comparisons** (dominant voice for comparison-and-fit content):

- "X beats Y on [feature axis] because [spec basis]"
- "Y beats X on [other axis] because [spec basis]"
- "Pick X when [condition]; pick Y when [other condition]"
- "If [reader's priority] matters more than [other consideration], X is the stronger pick"

**Voice-neutral synthesis** (analysis without first-person):

- "The trade-off here is..."
- "The case for [X] is..."
- "What makes [X] distinct from [Y] is..."
- "Considered against [Y], [X] [does/doesn't] win on [axis]"

## Your task

Draft the markdown body of `best-wheel-cleaner-for-home-detailers.md` per the scaffold below. The `## Bottom Line` section
STAYS as the placeholder (`> _The Bottom Line is being written._`) — the publisher writes
that themselves. Fill `## Who This Is For` and all other sections, drawing only from spec
sheets, manufacturer documentation, and aggregated owner reviews. Cite sources where you
make specific claims. This is a buyer's guide — frame as research synthesis, not a personal
review.

## Scaffold to fill

```markdown
---
title: "Sonax Full Effect Wheel Cleaner Buyer's Guide"
description: "Five spec-verified wheel cleaners across the iron-killer doctrine split. P&S Brake Buster is the pro-shop default; Sonax Full Effect is the enthusiast iron-killer reference."
products:
  - name: "Sonax Full Effect Wheel Cleaner"
    brand: "Sonax"
    affiliateUrl: "https://www.amazon.com/Sonax-230200-755-Wheel-Cleaner-Effect/dp/B003UT3S6Q?tag=mywildlifecam-20"
pubDate: 2026-05-19
lastUpdated: 2026-05-19
---

# Sonax Full Effect Wheel Cleaner Buyer's Guide: 

## Bottom Line

> _The Bottom Line is being written._

## Who This Is For

_AI-drafted from the per-site reader segments — primary fit, secondary fit, and who should keep shopping._

## TL;DR

_One paragraph hook — what Sonax Full Effect Wheel Cleaner is, who it's for, the verdict synthesized from specs and owner reviews._

## What This Guide Covers

_For a buyer's guide: what owner reviews, expert teardowns, and spec sheets were synthesized. Be honest about the sourcing._

## What Works

- (bullet — from owner reviews and spec analysis)
- (bullet)
- (bullet)

## What Doesn't

- (bullet — from owner reviews and known issues)
- (bullet)

## How It Compares

_Table or prose against 1-3 alternatives in the same niche._

## Who It's For

_Specific persona; not "everyone"._

## Who Should Skip

_Specific personas; not "no one"._

## Verdict

_One paragraph — explicit recommendation, conditional or unconditional, framed as "based on the research" rather than "from my experience"._

## FAQ

**Q: ?**
A: _Answer._

**Q: ?**
A: _Answer._

**Q: ?**
A: _Answer._

<!-- HUMAN: fill in the Bottom Line with the real verdict before publishing. The build will block (DRAFT banner + noindex) until the placeholder line is replaced. -->

```

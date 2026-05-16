# AI Drafting Prompt — MyWildlifeCam — Spypoint Flex-M

You are drafting a comparison-and-fit affiliate piece for MyWildlifeCam (trail cameras and wildlife cameras).
Reader profile: primary = [homeowners, property owners, first-time buyers, gift buyers], secondary = [backpackers], EXPLICITLY EXCLUDED = [hunters].
Brand tone: snarky-but-friendly.

## Piece context

- Product: Spypoint Flex-M (Spypoint)
- SKU: 
- Piece type: review
- Slug: spypoint-flex-m-review
- Pub date: 2026-05-16

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

Draft the markdown body of `spypoint-flex-m-review.md` per the scaffold below. The `## Bottom Line` section
STAYS as the placeholder (`> _The Bottom Line is being written._`) — the publisher writes
that themselves. Fill `## Who This Is For` and all other sections, drawing only from spec
sheets, manufacturer documentation, and aggregated owner reviews. Cite sources where you
make specific claims.

## Scaffold to fill

```markdown
---
title: "Spypoint Flex-M Review"
description: ""
product:
  name: "Spypoint Flex-M"
  brand: "Spypoint"
  sku: ""
  currency: "USD"
  affiliate:
    amazon: "https://amzn.to/example-spypoint-flex-m"
rating: # TODO: 1-5, e.g. 4.5
classification: "review"
pubDate: 2026-05-16
lastUpdated: 2026-05-16
images:
  hero: ""
  context: ""
  comparison: ""
---

# Spypoint Flex-M Review: 

## Bottom Line

> _The Bottom Line is being written._

(This section is REQUIRED for publication. The build flags this page as DRAFT and noindex until this placeholder is replaced with the publisher's own prose. AI scaffolding never fills this section — answer-first synthesis goes here. Anti-recipe-page principle: this is what the reader sees first.)

## Who This Is For

_AI fills this. Primary use case + reader segment fit per `sites/<slug>/src/data/site-config.json`. Conditional framing: "if your priority is X, this is the strong pick because [spec reason]." Do not list "everyone." Do not claim hands-on use._

## At a Glance

_Hero spec block + use-case fit summary. Spec-driven, never first-person. Cite manufacturer specs verbatim and link the source._

## What It Does Well

- (spec-driven bullet — feature axis + why it matters for the primary reader segment)
- (bullet)
- (bullet)

## Where It Falls Short

_Honest aggregate of recurring concerns from verified-buyer reviews. Cite the source (e.g., "the most-upvoted critical Amazon review describes X"). No first-person claims._

- (bullet)
- (bullet)

## How It Compares

_Table or prose against 1-3 alternatives in the same niche. Conditional comparisons: "X beats Y on [axis] because [spec basis]; Y beats X on [other axis] because [spec basis]." Pick X when [condition]; pick Y when [other condition]._

## Who Should Skip

_Specific reader segments + reasons. Reference excluded segments from the per-site config (e.g., for mywildlifecam: hunter use cases)._

## Verdict

_Conditional recommendation. "If you need [X], this is the stronger option because [spec reason]." Not a personal endorsement. Synthesizes the comparison; never claims testing._

## FAQ

**Q: ?**
A: _Answer — spec-grounded or owner-review-cited._

**Q: ?**
A: _Answer._

**Q: ?**
A: _Answer._

<!-- HUMAN: fill in the Bottom Line section before publishing. The build will block (DRAFT banner + noindex) if the placeholder remains. -->

```

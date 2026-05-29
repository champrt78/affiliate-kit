---
version: 1
last_updated: 2026-05-16
status: active
---

# Voice Doctrine — v1

The single source of truth for what affiliate-sites content can and cannot say about products. The doctrine has three jobs:

1. **Tell AI drafters what NOT to produce** at generation time (scaffolders inject forbidden-phrase lists into AI prompts).
2. **Tell `scripts/lint-voice.ps1` what to grep for** as a back-stop after AI drafting.
3. **Tell the publisher what to say** when readers, manufacturers, or regulators ask direct questions about whether content is hands-on.

The doctrine is evergreen. Edit it freely as edge cases surface. The lint script reads this file at runtime, so changes here propagate automatically to the back-stop.

---

## Forbidden phrases

Concrete phrases the AI must not produce and the lint must catch. Each bullet starts with the literal string in backticks (so `Select-String` can grep them) followed by why it's forbidden.

**First-person experience claims** — implies hands-on use the publisher does not have:

- `I tested` — claims direct testing
- `I used` — claims direct use
- `I tried` — claims direct trial
- `I bought` — claims direct purchase
- `I own` — claims ownership
- `I've owned` — claims past ownership
- `we own` — plural of `I own`; same hands-on claim (caught 2026-05-24 in MWC homepage manifesto: *"When we own a camera, we say so plainly..."*)
- `we've owned` — plural of `I've owned`
- `hands-on review` — claims a first-person review (e.g. "honest, hands-on reviews"); the comparison-and-fit framework never claims hands-on. Caught 2026-05-28 in the site template + fussybean homepage, which would have infected every bootstrapped satellite. Note: denials phrased as "we don't claim hands-on testing" use different wording and are fine — this literal only catches the claim form.
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

---

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

---

## Direct-question responses

When a reader, manufacturer, regulator, or social-media commenter asks directly whether content is hands-on, silence reads as concealment and an improvised "yes" collapses the legal defense. These canonical replies are doctrine-aligned: they acknowledge the research process without claiming or denying personal use in a way that contradicts the published content.

**For reader DMs or comments asking "did you actually test this?":**

> "Our recommendations are research-based — we synthesize published specs, manufacturer documentation, and aggregated owner reviews into use-case-fit picks. We don't claim personal hands-on testing in the content; you can read our research methodology on the About page."

**For manufacturer or brand outreach asking about review methodology:**

> "We produce comparison-and-fit content based on published specifications, third-party teardowns, and aggregated verified-buyer reviews. We don't represent ourselves as hands-on testers and we're explicit about that on every site's About page. If your team has spec sheets, technical documentation, or aggregated customer-feedback data you'd like us to consider for future pieces, we'll factor it in with appropriate citation."

**For regulator, FTC, or compliance inquiry:**

> "Our content is comparison-and-fit affiliate content, not first-person product reviews. We don't claim personal hands-on testing or first-hand experience with the products covered. Each site's About page documents our research methodology in positive framing: published specs, aggregated user reviews from verified buyers, and use-case fit analysis. Per-piece footers carry the required affiliate disclosure. We can provide source citations for any specific claim on request."

**For social-media commenters asking "do you even own this?":**

> "Nope, didn't claim to. The piece is comparison research — spec sheets, owner reviews on Amazon, third-party teardowns, use-case fit. If you want a hands-on review, look for a reviewer who claims one."

---

## Evolution policy

When an edge case surfaces in a real piece — a phrase the AI produced that should have been forbidden, or a framing pattern that worked better than the doctrine anticipated — update this file directly. No formal versioning gate; git history is the audit trail. The `version:` frontmatter bumps when forbidden-phrase categories change shape, not on every line edit.

If the same edge case appears 3+ times across pieces, that's a signal the doctrine has a gap large enough to deserve attention. Surface it in a session log entry and a brainstorm if scope warrants.

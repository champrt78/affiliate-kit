---
description: Internal — Bottom Line drafter that `/aff` reads inline when posture is `draft-needs-bottom-line`. Drafts 3 verdict options + supporting paragraph per piece (read-only — Ray picks one and writes the final). Ray uses `/aff` as the entry point — invocable directly only for debugging.
---

You are being invoked to draft 3 candidate Bottom Line options for a DRAFT-gated piece. Two entry modes:

**Mode A — Direct slash invocation** (`/bottom-line-helper <piece-file-path>`): Ray typed the command directly. Resolve the target per Step 1A.

**Mode B — Read inline by `/aff`**: `/aff` has already resolved the piece path during its Step 6.B flow. Skip Step 1A entirely — the path is already in conversation context. Jump straight to Step 2.

## What you'll do

1. **(Mode A only)** **Resolve the target file.** Ray may give you:
   - A full path: `sites/detailerpicks/src/content/buyers-guides/best-pressure-washer-for-home-detailers.md`
   - A slug: `best-pressure-washer-for-home-detailers` (search both sites' content/ for it)
   - Just the topic: "the latest detailerpicks piece" → list recent DRAFT-gated pieces and pick the most recent

   **(Mode B)** Skip this step — `/aff` already passed the resolved file path.

2. **Read the file's frontmatter** and extract:
   - `title`, `deck`, `rubric`
   - `product.name` + `product.brand` (for review pieces)
   - `products[].name` + `products[].brand` (for buying-guide pieces)
   - `scorecard.axes` (name + score + weight per axis)
   - `buyIf.buy` + `buyIf.skip` (the existing reader-segment fit framing)
   - `flaws` if present (honest cons disclosed in piece body)

3. **Read 2-3 prior shipped Bottom Lines on the same site** to anchor on Ray's voice:
   - For mywildlifecam: check `spypoint-flex-m-review.md`, `stealth-cam-ds4k-ultimate-review.md`, `tactacam-reveal-x-3-review.md`
   - For detailerpicks: check `best-car-wash-soap-for-home-detailers.md`, `best-foam-cannon-for-home-detailers.md`

4. **Draft 3 distinct verdict options** in Ray's voice:
   - **Option A — "Buy if / Skip if" 2-clause** (his most common pattern): `"Buy it if <one positive condition>. Skip it if <one disqualifying condition>."`
   - **Option B — "doctrine angle" or "honest disagreement"**: surfaces an editorial framing that creates a hook (e.g., "Pick by which school you trust...")
   - **Option C — "matter-of-fact / specific picks"**: names actual products in the verdict and what they're for (works best on buying guides)

   Constraints on all 3:
   - **Single sentence ideally**, two sentences max
   - **Voice doctrine:** no em dashes, no hands-on claims ("I tested"), no defensive exclusions ("this isn't for X"), no first-person possessives
   - **Tonal goal:** snarky-but-friendly, decisive, no hedging
   - **Match the tonality of the prior shipped Bottom Lines on the same site**

5. **Draft a supporting paragraph** (2-3 sentences) that backs the verdict with the strongest specific facts from the piece. Should NOT repeat the verdict — should add concrete supporting detail. Same voice constraints.

6. **Present the output to Ray in a tight format:**

```
## Bottom Line drafts for <piece title>

**Option A:** "<verdict>"

**Option B:** "<verdict>"

**Option C:** "<verdict>"

**Suggested supporting paragraph:**
> "<supporting paragraph>"

Pick one (A/B/C/your own), edit, write fresh — tell me when saved and I'll commit + push.
```

7. **DO NOT write to the file.** Ray writes the actual Bottom Line in his voice — this skill ONLY drafts candidates for him to choose from. The whole point is to preserve the human-Bottom-Line discipline.

## Constraints

- Use Read tool to inspect frontmatter.
- Use Grep tool to find prior shipped pieces if needed.
- Use the Bash tool only if you need to ls a directory to find the file.
- Do NOT use Edit or Write — output goes in chat, not into a file.
- If the file doesn't have a scorecard or buyIf (incomplete frontmatter), draft based on what's there + the piece body content. Note in your response what was missing.
- If Ray says "do all 3 pieces at once" — handle multiple files, output one block per file in the same chat response.

## Example

```
/bottom-line-helper best-pressure-washer-for-home-detailers
```

Should produce 3 verdict options + supporting paragraph in chat, ready for Ray to pick and paste into the piece's `bottomLine.verdict` and `bottomLine.supporting` frontmatter fields.

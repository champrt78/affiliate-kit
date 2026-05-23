---
description: Internal — scaffolder that `/aff` reads inline after research-ready-to-scaffold posture or scout-then-scaffold flow completes. Wraps PowerShell scaffolders (new-review.ps1 / buyers-guide.ps1) + KV cloaker registration + voice lint + astro build. Ray uses `/aff` as the entry point — invocable directly only for debugging.
---

You are being invoked to scaffold a new content piece. Two entry modes:

**Mode A — Direct slash invocation** (`/scaffold-piece <args>`): Ray typed the command directly with CLI-style args. Parse them per Step 1A.

**Mode B — Read inline by `/aff`**: `/aff` has already collected site/type/slug/product/brand/amazon_url/description conversationally during its Step 6.C flow. Skip Step 1A entirely — those values are already in conversation context. Jump straight to Step 2 (scaffolder execution).

## What you'll do

1. **(Mode A only)** **Parse Ray's input** to extract:
   - `site` — one of: `mywildlifecam`, `detailerpicks`, `fussybean`, `starteraquarium`, `gameovergear`
   - `type` — `review` (single product) or `buyers-guide` (multi-product comparison)
   - `slug` — URL slug for the piece (kebab-case)
   - `product` — primary product name
   - `brand` — primary product brand
   - `amazon_url` — Amazon affiliate URL (with `?tag=mywildlifecam-20` appended if applicable)
   - `description` — short piece description

   If any are missing, ask ONE consolidated question listing what's needed. Don't ping-pong one-by-one.

   **(Mode B)** Skip this step — `/aff` already collected and passed all values.

2. **Run the appropriate scaffolder** from `C:\Users\Ray\documents\github\affiliate-sites\scripts\`:
   - For review: `pwsh scripts/new-review.ps1 -Site <site> -Slug <slug> -ProductName <product> -Brand <brand> -AmazonUrl <url> -Description <desc>`
   - For buying guide: `pwsh scripts/buyers-guide.ps1 -Site <site> -Slug <slug> -ProductName <product> -Brand <brand> -AmazonUrl <url> -Description <desc>`

3. **Register the cloaker KV entry** with the same data:
   - `pwsh scripts/add-link.ps1 -Site <site> -Slug <slug> -Url <amazon_url_without_tag> -Tag mywildlifecam-20 -Merchant amazon`
   - If the URL is non-Amazon, use `-Merchant other` and omit `-Tag`.

4. **Verify the build is clean:**
   - `cd C:/Users/Ray/documents/github/affiliate-sites && pwsh scripts/lint-voice.ps1 -Path sites/<site>/src/content/<reviews|buyers-guides>/<slug>.md`
   - `pnpm --filter <site> build`

5. **Report status concisely:**
   - File scaffolded at `<path>`
   - Cloaker KV registered (status: 302 verified or "not verified" if curl fails)
   - Lint clean / N findings
   - Build clean / failed (with first error)
   - Next step: "Ray writes Bottom Line at line N, then commit + push for live deploy"

6. **DO NOT commit or push.** The piece is DRAFT-gated until Ray writes the Bottom Line. Let him drive the publish moment.

## Constraints

- All file paths are Windows-style with forward slashes (`C:/Users/Ray/...`).
- PowerShell scripts via `pwsh` (NOT `powershell`).
- Use the Bash tool for all shell calls.
- If any step fails, STOP and report — don't auto-retry or try to fix in-place. Ray decides.

## Example invocation

```
/scaffold-piece site=mywildlifecam type=review slug=moultrie-edge-2-pro-review product="Moultrie Edge 2 Pro" brand=Moultrie amazon_url="https://www.amazon.com/.../dp/XXXXXX?tag=mywildlifecam-20" description="Spec-based review of the Moultrie Edge 2 Pro cellular trail camera."
```

If Ray gives you a less-structured input like "scaffold a Moultrie Edge 2 Pro review on mywildlifecam," parse what you can and ask ONE follow-up for the missing fields.

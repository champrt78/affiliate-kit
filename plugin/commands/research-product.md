---
description: Multi-source research pipeline for a single product or category. Parallel-fires Firecrawl search, Canopy ASIN lookup, ScrapeCreators last30days, and /watch on the top credible YouTube review. Synthesizes findings into a structured research note at affiliate-sites/docs/research/<date>-<slug>.md. Use when Ray says "research X" or "let's research the next product."
---

You are being invoked because Ray wants research data on a product or category before scaffolding/drafting content. The user's input follows `/research-product <topic>`.

## What you'll do

1. **Parse the topic** from Ray's input. Examples:
   - `Tactacam Reveal Ultra` — single product, trail-cam niche
   - `best foam cannon for home detailers` — category, detailing niche
   - `Bushnell CelluCORE 20` — single product, trail-cam niche

2. **Generate a kebab-case slug** for the output file (max 6 words).

3. **Fire parallel research jobs in background** (use Bash with `run_in_background: true`):

   **Job A — Firecrawl search for product spec pages** (use the Firecrawl plugin):
   ```bash
   export FIRECRAWL_API_KEY="$(grep '^FIRECRAWL_API_KEY=' /c/Users/Ray/.config/last30days/.env | cut -d= -f2-)"
   firecrawl search "<topic> specifications price 2026" --limit 6 -o .firecrawl/<slug>-spec-search.json
   ```

   **Job B — `/last30days` for community discussion** (use the user's `last30days` skill):
   ```bash
   export PATH="/c/Users/Ray/AppData/Local/Microsoft/WinGet/Packages/yt-dlp.yt-dlp_Microsoft.Winget.Source_8wekyb3d8bbwe:$PATH"
   PYTHONUTF8=1 python "C:\Users\Ray\.claude\skills\last30days\scripts\last30days.py" "<topic> owner reviews 2026" --emit=compact --no-native-web --save-dir="$HOME/Documents/Last30Days"
   ```

   **Job C — `/watch` on the top credible YouTube review** (after a quick WebSearch for "topic owner review 2026 site:youtube.com"):
   ```bash
   python "C:\Users\Ray\.claude\skills\watch\scripts\watch.py" "<top youtube url>" --max-frames 30
   ```

4. **While they run, do a WebSearch** for `<topic> Amazon site:amazon.com` to find the canonical ASIN.

5. **When Job A returns**, extract the most credible spec-page URL and scrape it with `firecrawl scrape <url> --only-main-content -o .firecrawl/<slug>-spec-page.md`. Then verify pricing via Canopy:
   ```bash
   CK=$(grep '^CANOPY_API_KEY=' /c/Users/Ray/.config/last30days/.env | cut -d= -f2-)
   curl -s -H "API-KEY: $CK" "https://graphql.canopyapi.co/" -X POST -H "Content-Type: application/json" \
     -d '{"query":"{ amazonProduct(input: {asin: \"<ASIN>\", domain: US}) { title brand price { display } } }"}'
   ```

6. **When all 3 background jobs complete, synthesize into a research note** at `C:/Users/Ray/documents/github/affiliate-sites/docs/research/<YYYY-MM-DD>-<slug>.md`:

```markdown
---
type: research
topic: <topic>
created: <ISO date>
sources_consulted:
  - firecrawl_search
  - last30days
  - watch
  - canopy_api
---

# Research: <Topic>

## Verified specs (manufacturer / retailer pages)

<spec table from Firecrawl scrape with source URLs>

## Community signal (Reddit + last30days)

<key threads + comment patterns from last30days output>

## Reviewer transcript highlights (/watch)

<top 5-10 verbatim quotes from the /watch transcript with timestamps>

## Buying guide / single-product piece synthesis

<3-5 sentence framework recommendation for what kind of piece this should be>

## Open questions / what we still need

<what's missing that would block drafting>

## Source URLs

<all URLs consulted, link-attributed>
```

7. **Report concisely:** Research note saved to `<path>`. Key finding: <one line headline>. Recommended piece type: review / buying-guide / skip.

## Constraints

- Use the Bash tool for all shell calls.
- Run jobs in parallel via `run_in_background: true` to keep total time under 5-10 minutes.
- DO NOT scaffold the piece — that's the `/scaffold-piece` command's job. Research only.
- DO NOT commit the research note — Ray can choose when to commit.
- Voice doctrine applies if you quote anything for use in eventual piece content: no em dashes, no hands-on claims, no defensive exclusions, attribute every quote to the source.
- If a job fails (rate limit, 404, etc.), continue with what you got and note the failure in the research note's "Open questions" section.

## Example

```
/research-product Browning Strike Force Elite HP5
```

Should produce:
- 3-4 parallel background jobs
- ~5-8 minutes total wall-clock
- One research note at `docs/research/2026-05-18-browning-strike-force-elite-hp5.md`
- Concise return summary

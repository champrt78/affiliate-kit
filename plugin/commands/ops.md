---
description: Internal — operations dashboard generator. Folded into `/aff`'s state survey (Step 2) and `where-are-we` flow. Still useful standalone for regenerating the HTML ops board at docs/ops.html. Ray uses `/aff` for the conversational version — this file is invocable directly only for the static dashboard render.
---

You are being invoked because Ray wants the operations dashboard regenerated and opened.

## What to do

1. **Run the generator** from the affiliate-sites repo root:
   ```bash
   cd /c/Users/Ray/documents/github/affiliate-sites && pwsh scripts/ops.ps1 -Open
   ```

   The `-Open` flag opens the generated HTML in Ray's default browser. The script:
   - Reads all site content (`sites/<slug>/src/content/{reviews,buyers-guides}/*.md`)
   - Detects DRAFT state per piece (empty `verdict` or body placeholder)
   - Reads `docs/TODO.md` Now section
   - Reads `docs/research/*.md` for available research notes
   - Reads recent `git log` for cadence + commit signal
   - Computes per-site next-action with priority ranking
   - Outputs `docs/ops.html` (single self-contained file, dark mode)

2. **Confirm in chat** with the key numbers from the script's stdout:
   ```
   Dashboard refreshed: N live · N drafts · N commits in last 14d
   Opened in browser. Top action: <whatever the script's top recommendation is>
   ```

3. **DO NOT** start working on whatever the dashboard recommends. The whole point is Ray sees it, decides. Just regenerate, open, confirm.

## Constraints

- Use Bash tool to invoke the PowerShell script
- The script is idempotent — safe to re-run any time
- If the script errors (rare — would only happen if a content file has malformed frontmatter), surface the error verbatim
- Do not edit the dashboard HTML directly; always regenerate via the script

## Example invocation

```
/ops
```

Re-fires the script, opens the page. ~1 second.

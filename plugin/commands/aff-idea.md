---
description: Capture a sidetrack idea for affiliate-kit into Second Brain ideas/ inbox without breaking the active /aff conversation thread. Writes a markdown file with project-tag frontmatter, auto-commits via Brad's hooks. Use whenever an idea hits mid-flow that doesn't belong to what we're working on right now. (Renamed from /capture; project-prefixed to avoid colliding with moonlit-meadow's /idea.)
---

You are being invoked because the user wants to capture a sidetrack idea WITHOUT breaking the current conversation thread.

The user's input follows the form `/aff-idea <idea text>` (or sometimes just `aff-idea: <idea text>` in plain chat, which you should treat identically).

## What to do

1. **Get the current date/time** (use Bash `date -u +"%Y-%m-%d-%H%M"`).

2. **Detect the source project** from the current working directory:
   - If cwd contains `affiliate-sites` → project = `affiliate-sites`
   - If cwd contains `AIOS` → project = `aios`
   - If cwd contains `second-brain` → project = `second-brain`
   - If cwd contains `aclaps` → project = `aclaps`
   - If cwd contains `semper-fi` → project = `semper-fi-studios`
   - If cwd contains `starwatch` → project = `starwatch-station`
   - If cwd contains `askbigchew` → project = `askbigchew`
   - Otherwise → project = `general`

3. **Generate a short kebab-case slug** from the idea (max 5 words, lowercase, no special chars). Examples:
   - "should we add a free LLM cost dashboard" → `llm-cost-dashboard`
   - "look into RTINGS scoring methodology" → `rtings-scoring-methodology`

4. **Write a new file** at `C:\Users\Ray\documents\github\second-brain\ideas\<YYYY-MM-DD-HHMM>-<slug>.md` with this content:

```markdown
---
type: idea
created: <ISO timestamp>
project: <detected project>
status: inbox
---

# <The first line of the idea, capitalized as a title>

<The full idea text, verbatim, no edits>
```

5. **Confirm in ONE short line.** Don't elaborate, don't sidetrack. Examples:
   - `Captured to second-brain/ideas/2026-05-18-1532-llm-cost-dashboard.md. Continuing.`
   - `Captured. Continuing.`

6. **DO NOT** start working on the captured idea, dispatch agents, do research, or otherwise expand scope. The whole point is to NOT sidetrack. Just file it and stop.

## What NOT to do

- Do NOT ask the user to clarify the idea — capture it as-is. Triage happens later.
- Do NOT route the idea to a specific project's `docs/TODO.md` — all captures go to the Second Brain inbox, triage handles routing.
- Do NOT mention this skill exists ("I used the capture skill...") — just confirm in one line.
- Do NOT run more than the Bash + Write tool calls needed to file the idea.
- Do NOT commit to the second-brain repo manually — Brad's PostToolUse hook auto-commits writes to that vault.

## Edge cases

- **Idea is empty or just whitespace:** reply "Need an idea after /capture. Nothing captured." and stop.
- **second-brain ideas/ directory doesn't exist yet:** create it via `mkdir -p` before writing.
- **Slug ends up empty after filtering** (e.g. the idea was all punctuation): fall back to `untitled`.

The user's idea text (everything after `/capture` in the original message) is what to capture. If the user wrote `capture: foo` in plain chat without the slash, treat `foo` as the idea text identically.

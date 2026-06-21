---
name: wrap
description: End-of-session safety net. Reads the existing docs/sessions/Session_YYYY-MM-DD.md, identifies gaps between inline writes and conversation context, then appends only what's missing plus end-of-session synthesis. Invoke before closing the laptop.
---

# Wrap Session

## What this does

Append an end-of-session entry to `docs/sessions/Session_YYYY-MM-DD.md` so the next session can pick up exactly where this one left off.

**This skill is a safety net, not the primary writer.** The agent should have been updating the session file proactively throughout the session. By the time `wrap` is called, most of the day's work should already be captured inline. Your job here is to:

1. Read what's already in the session file.
2. Identify gaps between the inline record and the conversation context.
3. Fill ONLY the gaps — minimize redundant re-summaries.
4. Add end-of-session synthesis (status, next steps, blockers).

## Process

### 1. Gather git activity

Run in parallel:

```bash
git log --since="$(date +%Y-%m-%d) 00:00:00" --format='%h %s'
git status --short
git diff --stat HEAD
git ls-files --others --exclude-standard
```

### 2. Review the conversation

Re-read the session's conversation context for:

- What the user asked for and what you did
- Decisions made and the reasoning behind them
- Gotchas / discoveries / edge cases / bugs diagnosed
- Files changed and why
- Ticket numbers referenced
- Status — what's done, in-progress, next, blocked

### 3. Find or create today's session file

Path: `docs/sessions/Session_YYYY-MM-DD.md` in the project root.

- Create `docs/sessions/` directory if missing.
- If the file exists, read its FULL current contents before writing anything.
- If the file is missing, create it with the standard header structure.
- When appending, use a horizontal rule (`---`) and a timestamped sub-header like `## Wrap — HH:MM`. Never overwrite.

### 4. Identify the gaps

Compare the conversation context against the existing file. Look for:

- Gotchas, decisions, or discoveries not yet captured.
- End-of-session synthesis: overall status, next steps, blockers, staged vs committed vs pushed.
- Corrections where an inline entry got something wrong.

Do NOT rewrite items already captured inline.

### 5. Write the entry

If nothing significant is missing, append a short acknowledgment:

```markdown
---
## Wrap — HH:MM
Caught up — today's work is already captured inline. No additional notes beyond the existing entries.
```

Otherwise, append only the missing sections:

```markdown
# Session — YYYY-MM-DD

## What We Did
- Brief description (`commit-sha` if committed)

## Decisions
- Why approach X was chosen over Y

## Discoveries / Gotchas
- Non-obvious things uncovered

## Files Changed
- path/to/file — what changed and why

## Status at End of Session
- What's done
- What's in progress
- What's next / blockers
- Branch state
```

Rules:
- Tag ticket numbers.
- Link commits with short hashes.
- Be specific — file paths, function names, line numbers when relevant.
- Capture the WHY, not just the WHAT.
- Omit empty sections rather than leaving placeholders.

### 6. Update PROJECT_STATE.md if a win happened

Check `docs/PROJECT_STATE.md`:

- Create it if missing.
- If a milestone, shipped feature, or significant accomplishment happened today, append:
  ```
  - **YYYY-MM-DD** — Brief description of what was accomplished
  ```
- Only add real wins. Routine bug fixes / minor tweaks / in-progress work do NOT go here.
- If nothing milestone-worthy happened, skip this step silently.

### 7. Verify the write

Re-read the last ~50 lines of the session file to confirm the entry appended cleanly and formatting is correct. Fix anything wrong immediately.

### 8. Report

Short confirmation:

```
Wrapped session:
  ✓ docs/sessions/Session_YYYY-MM-DD.md (appended N lines)
  ✓ docs/PROJECT_STATE.md (added milestone: "...")   # or unchanged
```

## Rules

- **NEVER overwrite** — always append.
- **Verify the write** by re-reading.
- **Zero user input needed** — use conversation context + git.
- **PROJECT_STATE.md is for milestones only**.
- **Dedupe against existing content.**

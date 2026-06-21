---
name: brief
description: Session-start or mid-session catch-up. Reads the last 5 session logs, PROJECT_STATE.md, and recent git activity to produce a structured briefing in chat. Use when rejoining a project after a gap or when you need a "remind me where we are" during a session. Inverse of wrap — reads context rather than writing it. Zero arguments, zero file writes.
---

# Brief Session

## What this does

Produce an in-chat catch-up briefing that tells the user:

1. **Where they are** — current phase / focus.
2. **What's open** — bugs, TODOs, asks that need attention.
3. **What to pick up next** — one concrete, actionable recommendation.

`brief` is the inverse of `wrap`. Where `wrap` writes context to the session log at end-of-day, `brief` reads context at session start or on demand. It writes nothing.

This skill does NOT replace the mandatory auto-briefing at session start defined in `.kimi-code/AGENTS.md`.

## When to use this

- User types `/brief` or invokes the `brief` skill.
- Never auto-invoke. This is user-initiated only.

## Inputs

Fire these reads in parallel:

| Source | How to read it | Purpose |
|---|---|---|
| Project state | Read `docs/PROJECT_STATE.md` (full file, if it exists) | Milestone spine |
| Session logs | Read up to 5 most recent `docs/sessions/Session_*.md` by filename date | Recent narrative |
| Git recent | `git log --since="30 days ago" --format='%h %ad %s' --date=short` | Ground truth |
| Git state | `git status --short` plus `git diff --stat HEAD` | Current uncommitted work |
| Project conventions | Read root `CLAUDE.md` if present | Project rules |

## Process

### 1. Fire all reads in parallel

Issue all reads in a single message. Wait for all results.

### 2. Compute "days since last session"

From the newest `Session_*.md` filename, extract the date and subtract from today's date.

- 0-6 days → no gap messaging
- 7+ days → headline leads with `You've been away N days.`
- 30+ days → add `Consider re-reading CLAUDE.md for project conventions.`

### 3. Cross-check completion vs intent

For each session log, scan `Status at End of Session` and `What's next`. For every next-step item, check `git log` since that session's date. If it appears already committed, do NOT include it in `Open threads`.

### 4. Surface open items

Scan session files and `docs/TODO.md` for phrases like `TODO:`, `still open`, `not started`, `needs investigation`, `open question`. Deduplicate.

Classify each:
- **BUG** — broken / regressed
- **TODO** — known work not started
- **ASK** — question/request from stakeholder
- **NOTE** — freeform items

### 5. Render the briefing

```markdown
# Affiliate Kit — Brief

> **<Narrative headline — 2 to 3 sentences.>** State where they are, when they were last here, and what's most important right now.

═══════════════════════════════════════════════════════════

## Where we left off

| | |
|---|---|
| **Last session** | `YYYY-MM-DD` (N day(s) ago) |
| **Branch** | `<branch>` — N uncommitted, N unpushed |
| **Last commit** | `<hash>` — <subject> |

**Recent commits**

| Hash | Date | Summary |
|---|---|---|
| `<hash>` | MM-DD | <subject> |

═══════════════════════════════════════════════════════════

## Open threads

| Type | Item | Source |
|---|---|---|
| **BUG** | <description> | `<source>` |
| **TODO** | <description> | `<source>` |

═══════════════════════════════════════════════════════════

## Suggested next

> <One concrete suggestion with rationale.>
```

Formatting rules:
- NEVER use emoji icons.
- Use `═══════════════════════════════════════════════════════════` as section separators.
- Wrap commit hashes, file paths, branch names in backticks.
- Omit empty sections.
- Keep lines short and whitespace generous.

## Rules

- **READ-ONLY** — never write any file.
- **ZERO USER PROMPTS** — do not ask questions.
- **NO EMOJI**.
- **PARALLEL READS**.
- **OMIT EMPTY SECTIONS**.
- **ONE RECOMMENDATION** in `Suggested next`.

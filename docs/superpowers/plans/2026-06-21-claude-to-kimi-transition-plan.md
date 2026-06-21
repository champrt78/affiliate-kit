# Affiliate Kit — Port Dotfiles Session/State Management to Kimi

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Bring the session-resumption mechanics from Ray's dotfiles (`champrt78/dotfiles`) into Kimi Code so every project auto-maintains session logs and project-state wins. This includes project-level skills/instructions in the Affiliate Kit repo plus a **global** `SessionEnd` hook in `~/.kimi-code/config.toml` that runs for every Kimi session.

**Architecture:** Mirror the Claude Code pattern (`claude/CLAUDE.md` + `claude/skills/wrap/` + `claude/skills/brief/` + `claude/memory-templates/session-rules.md` + `settings.json` hooks) with a Kimi-native equivalent:
- Global hook in `~/.kimi-code/config.toml` + `~/.kimi-code/hooks/session-end.sh` — fires on every session end, appends a git-activity floor to `docs/sessions/Session_YYYY-MM-DD.md` when the project has a `docs/sessions/` directory.
- `.kimi-code/AGENTS.md` — project-level rule that mandates proactive session logging and auto-brief on every new Kimi session.
- `.kimi-code/skills/wrap/SKILL.md` — end-of-session safety net that appends richer context to `docs/sessions/Session_YYYY-MM-DD.md`.
- `.kimi-code/skills/brief/SKILL.md` — on-demand catch-up that reads sessions + `docs/PROJECT_STATE.md` + recent git and renders a briefing in chat.

Existing `docs/sessions/` and `docs/PROJECT_STATE.md` stay in the same place so Claude and Kimi share the same paper trail.

**Tech Stack:** Kimi Code project rules (`AGENTS.md`), Kimi skills (`SKILL.md`), Kimi hooks (`config.toml`), Bash, Markdown, git.

---

## Task 0: Install global `SessionEnd` hook in `~/.kimi-code/config.toml`

**Files:**
- Create: `~/.kimi-code/hooks/session-end.sh`
- Modify: `~/.kimi-code/config.toml`

- [ ] **Step 1: Create the hooks directory**

Run: `mkdir -p ~/.kimi-code/hooks`

- [ ] **Step 2: Write the global session-end script**

```bash
cat > ~/.kimi-code/hooks/session-end.sh <<'EOF'
#!/usr/bin/env bash
set -euo pipefail

# Global Kimi SessionEnd hook.
# Appends a git-activity floor to docs/sessions/Session_YYYY-MM-DD.md
# for any project that has a docs/sessions/ directory.

REPO_ROOT="$(pwd)"
SESSIONS_DIR="$REPO_ROOT/docs/sessions"

if [[ ! -d "$SESSIONS_DIR" ]]; then
  # Not a project with session files; exit silently.
  exit 0
fi

TODAY="$(date +%Y-%m-%d)"
NOW="$(date +%H:%M)"
SESSION_FILE="$SESSIONS_DIR/Session_$TODAY.md"

GIT_LOG="$(git log --since=\"$TODAY 00:00:00\" --format='%h %s' 2>/dev/null || true)"
GIT_STATUS="$(git status --short 2>/dev/null || true)"
BRANCH="$(git branch --show-current 2>/dev/null || true)"

mkdir -p "$SESSIONS_DIR"

if [[ ! -f "$SESSION_FILE" ]]; then
  cat > "$SESSION_FILE" <<HDR
# Session — $TODAY

HDR
fi

{
  echo ""
  echo "---"
  echo "## Wrap — $NOW (auto)"
  echo ""
  if [[ -n "$BRANCH" ]]; then
    echo "Branch: \`$BRANCH\`"
  fi
  if [[ -n "$GIT_LOG" ]]; then
    echo ""
    echo "Commits today:"
    echo "$GIT_LOG" | sed 's/^/- /'
  fi
  if [[ -n "$GIT_STATUS" ]]; then
    echo ""
    echo "Uncommitted changes:"
    echo "\`\`\`"
    echo "$GIT_STATUS"
    echo "\`\`\`"
  fi
  echo ""
} >> "$SESSION_FILE"

exit 0
EOF
chmod +x ~/.kimi-code/hooks/session-end.sh
```

- [ ] **Step 3: Backup current Kimi config**

Run:

```bash
cp ~/.kimi-code/config.toml "~/.kimi-code/config.toml.$(date +%Y%m%d-%H%M%S).bak"
```

- [ ] **Step 4: Add the SessionEnd hook to config.toml**

Copy and edit the candidate:

```bash
cp ~/.kimi-code/config.toml ~/.kimi-code/config-new.toml
```

Append to `~/.kimi-code/config-new.toml`:

```toml
[[hooks]]
event = "SessionEnd"
command = "bash ~/.kimi-code/hooks/session-end.sh"
timeout = 10
```

- [ ] **Step 5: Validate the candidate**

Run: `kimi doctor config ~/.kimi-code/config-new.toml`
Expected: exit code 0.

- [ ] **Step 6: Apply the config**

Run:

```bash
mv ~/.kimi-code/config-new.toml ~/.kimi-code/config.toml
```

- [ ] **Step 7: Tell the user to reload**

Run `/reload` in the Kimi TUI (or start a new session) for the hook to take effect.

---

## Task 1: Create `.kimi-code/AGENTS.md` with session-resumption rules

**Files:**
- Create: `.kimi-code/AGENTS.md`

- [ ] **Step 1: Write AGENTS.md**

```markdown
# Affiliate Kit — Kimi Agent Conventions

This file teaches Kimi how to operate the Affiliate Kit monorepo and how to keep sessions resumable. Read it before responding to the user.

## Entry point

The Kimi orchestrator playbook lives at `docs/superpowers/orchestrator.md`. When the operator says anything that sounds like bootstrap, content, or status intent, follow that playbook verbatim.

## Session documentation (non-negotiable)

Same rules as `CLAUDE.md`:
- Update `docs/sessions/Session_YYYY-MM-DD.md` proactively after every meaningful action (commit, decision, discovery, bug found, build fixed).
- Update `docs/PROJECT_STATE.md` only for milestone-level wins.
- Tag ticket numbers when they exist.
- Link git commits with short hashes.

## On every new session start (mandatory — before responding)

1. Check that `docs/sessions/` and `docs/PROJECT_STATE.md` exist; create them if missing.
2. Read the 2-3 most recent `docs/sessions/Session_YYYY-MM-DD.md` files.
3. Read `docs/PROJECT_STATE.md`.
4. Read the project `CLAUDE.md`.
5. Proactively tell the user: "Last time we worked on X, left off at Y."
6. Then respond to the user's message.

## Tool conventions

- Use the Bash tool for all shell commands.
- Use repo-relative paths.
- Do not call PowerShell scripts directly; use the kit CLIs (`pnpm kit:bootstrap`, `pnpm kit:scaffold`).
- After file mutations, run the relevant `pnpm --filter <site> build` and commit.

## Skills

- `wrap` — end-of-session safety net. Run before closing the laptop.
- `brief` — session-start or mid-session catch-up. Run whenever you need to rehydrate context.

## When in doubt

- Architecture → `docs/SYSTEM.md`
- Current state → `docs/TODO.md`
- Voice rules → `docs/voice-doctrine.md`
- Kimi orchestration → `docs/superpowers/orchestrator.md`
```

- [ ] **Step 2: Verify the file**

Run: `cat .kimi-code/AGENTS.md`
Expected: the markdown above prints without errors.

- [ ] **Step 3: Commit**

```bash
git add .kimi-code/AGENTS.md
git commit -m "docs(kimi): add AGENTS.md with session-resumption rules"
```

---

## Task 2: Create the `/wrap` Kimi skill

**Files:**
- Create: `.kimi-code/skills/wrap/SKILL.md`

- [ ] **Step 1: Create the skills directory**

Run: `mkdir -p .kimi-code/skills/wrap`

- [ ] **Step 2: Write SKILL.md**

```markdown
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
```

- [ ] **Step 3: Verify the skill file**

Run: `cat .kimi-code/skills/wrap/SKILL.md`
Expected: the markdown above prints without errors.

- [ ] **Step 4: Commit**

```bash
git add .kimi-code/skills/wrap/SKILL.md
git commit -m "feat(kimi): add wrap skill for end-of-session safety net"
```

---

## Task 3: Create the `/brief` Kimi skill

**Files:**
- Create: `.kimi-code/skills/brief/SKILL.md`

- [ ] **Step 1: Create the skills directory**

Run: `mkdir -p .kimi-code/skills/brief`

- [ ] **Step 2: Write SKILL.md**

```markdown
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
```

- [ ] **Step 3: Verify the skill file**

Run: `cat .kimi-code/skills/brief/SKILL.md`
Expected: the markdown above prints without errors.

- [ ] **Step 4: Commit**

```bash
git add .kimi-code/skills/brief/SKILL.md
git commit -m "feat(kimi): add brief skill for session-start catch-up"
```

---

## Task 4: Ensure session/state files exist and are consistent

**Files:**
- Modify: `CLAUDE.md`
- Create or verify: `docs/sessions/Session_2026-06-21.md`, `docs/PROJECT_STATE.md`

- [ ] **Step 1: Add a note to CLAUDE.md that Kimi shares the same session/state files**

Read `CLAUDE.md`, find the `## Session Documentation` section, and append a short note:

```markdown
## Kimi compatibility

Kimi Code reads `.kimi-code/AGENTS.md` and uses the same `docs/sessions/` + `docs/PROJECT_STATE.md` files. Session logs and project-state wins are shared across Claude and Kimi sessions.
```

- [ ] **Step 2: Verify today's session file exists**

Run: `ls docs/sessions/Session_2026-06-21.md`
Expected: file exists (if not, create with the standard `# Session — 2026-06-21` header).

- [ ] **Step 3: Verify PROJECT_STATE.md exists**

Run: `ls docs/PROJECT_STATE.md`
Expected: file exists.

- [ ] **Step 4: Commit CLAUDE.md update**

```bash
git add CLAUDE.md
git commit -m "docs: note shared session/state files with Kimi"
```

---

## Task 5: Smoke-test the skills

**Files:**
- None (read-only / append-only tests)

- [ ] **Step 1: Verify skills are discoverable**

Run: `ls .kimi-code/skills/`
Expected: `brief` and `wrap` directories exist.

- [ ] **Step 2: Test `brief` skill (read-only)**

Invoke the `brief` skill. Expected output: a structured briefing with no file writes.

Verify no writes occurred:

```bash
git status --short
```

Expected: empty output (or only pre-existing changes).

- [ ] **Step 3: Test `wrap` skill (append-only)**

Invoke the `wrap` skill. Expected output: confirmation that it appended to `docs/sessions/Session_2026-06-21.md`.

Verify the append:

```bash
tail -30 docs/sessions/Session_2026-06-21.md
```

Expected: a `## Wrap — HH:MM` section at the end.

- [ ] **Step 4: Commit test artifacts**

If the wrap produced meaningful session updates, commit them:

```bash
git add docs/sessions/Session_2026-06-21.md
git commit -m "docs(session): wrap today's Kimi transition work"
```

---

## Task 6: Merge kimi-kit branch to main

**Files:**
- Git branches

- [ ] **Step 1: Ensure working tree clean**

Run: `git status --short`
Expected: empty output.

- [ ] **Step 2: Run tests and typecheck**

Run:

```bash
pnpm typecheck
pnpm test
```

Expected: typecheck passes. Note any pre-existing test failures but do not block merge unless introduced on this branch.

- [ ] **Step 3: Merge**

```bash
git fetch origin
git checkout main
git pull origin main
git merge --no-ff kimi-kit -m "feat(kimi): port dotfiles session/state management to Kimi

- Add .kimi-code/AGENTS.md with session-resumption rules
- Add wrap skill for end-of-session safety net
- Add brief skill for session-start catch-up
- Note shared session/state files in CLAUDE.md"
git push origin main
```

- [ ] **Step 4: Delete branch**

```bash
git branch -d kimi-kit
git push origin --delete kimi-kit
```

---

## Self-review

1. **Spec coverage:** The spec is "port dotfiles session/state management to Kimi." Task 1 covers auto-brief rules; Task 2 covers `/wrap`; Task 3 covers `/brief`; Task 4 ensures file consistency; Task 5 tests; Task 6 lands the branch.
2. **Placeholder scan:** No TBD/TODO; every step has exact commands and expected output.
3. **Type consistency:** File paths (`docs/sessions/Session_YYYY-MM-DD.md`, `docs/PROJECT_STATE.md`) are consistent throughout.

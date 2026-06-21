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

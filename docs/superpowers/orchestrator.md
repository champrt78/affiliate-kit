# Kimi Orchestrator — Affiliate Kit

This is the single plain-language entry point for the Affiliate Kit.

## Supported intents

1. **Bootstrap a new site:** "Spin up a site called <slug> about <niche>"
2. **Scaffold content:** "Write a <review|buyer's guide> for <product> on <site>"
3. **Check status:** "Where are we?"

## Routing

- Bootstrap intent → run `pnpm kit:bootstrap create <slug>` with collected flags.
- Content intent → run `pnpm kit:scaffold <review|guide> --site <site> ...`.
- Status intent → survey `sites/*/src/content/`, `docs/TODO.md`, and recent git log, then report.

## Conventions

- Use repo-relative paths.
- Use the Bash tool for all shell commands.
- Do not use PowerShell scripts directly; always go through the kit CLIs.
- After every mutation, run the relevant lint/build command and commit.

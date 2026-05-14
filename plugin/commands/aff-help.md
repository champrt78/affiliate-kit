---
description: Print an auto-derived cheatsheet of every affiliate-kit slash command installed on this machine. Usage: /aff-help
---

# /aff-help

Print a tidy cheatsheet of every affiliate-kit command currently installed in this Claude Code instance. The list is derived at runtime from the plugin's `commands/` directory, so it never drifts from reality — adding a new command file automatically shows up here.

## How to run this

**Step 1: Locate the installed plugin directory.**

The plugin is installed at `~/.claude/plugins/affiliate-kit/commands/`. On Windows that expands to `C:/Users/<user>/.claude/plugins/affiliate-kit/commands/`. Use the home directory of the current user. If the directory does not exist, tell the user the plugin isn't installed and point them at `pnpm install-plugin` from the monorepo root (and `docs/BASEMENT_SETUP.md` for first-time setup), then stop.

**Step 2: List every `.md` file in that directory.**

Use the Glob tool with pattern `*.md` against the commands directory. Each file is one slash command. The command name is the filename without the `.md` extension, prefixed with `/` (so `aff-bootstrap.md` becomes `/aff-bootstrap`).

**Step 3: Parse the YAML frontmatter of each file.**

Each command file starts with a YAML frontmatter block delimited by `---` lines. Read the first ~10 lines of each file and extract the `description:` field. That's the one-line description for the command. If a file has no frontmatter or no `description:` field, use `(no description)` as a placeholder and note it as something to fix.

**Step 4: Print the cheatsheet.**

Print a markdown table sorted alphabetically by command name:

```
| Command | Description |
|---|---|
| `/aff-bootstrap` | <description from frontmatter> |
| `/aff-help` | <description from frontmatter> |
```

Keep descriptions to one line each. If a description has a `Usage:` clause, you can trim it from the printed cell or keep it — author's call, but stay consistent.

**Step 5: Print a `Next:` block.**

Suggest the most useful next command. If `sites/` in the monorepo (path from `~/.claude/plugins/affiliate-kit/config.json` → `monorepo_path`) is empty or doesn't exist, suggest `/aff-bootstrap <slug>`. Otherwise, mention that Phase 2 commands aren't built yet and point at `COMMANDS.md` for the roadmap.

Example:

```
Next: No sites scaffolded yet. Run `/aff-bootstrap mywildlifecam` to spin up the hero site.
```

## Why this is auto-derived

Hard-coding the command list in a static doc means it drifts every time someone adds, renames, or removes a command. By reading `commands/*.md` at runtime, `/aff-help` is always honest — if a command shows up here, it exists; if it doesn't, it isn't installed. Keep it that way: do not maintain a hard-coded fallback list inside this file.

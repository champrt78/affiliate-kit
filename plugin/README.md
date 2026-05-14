# affiliate-kit plugin

Source for the Claude Code plugin. To install:

```powershell
pnpm install-plugin
```

This copies `plugin/` to `~/.claude/plugins/affiliate-kit/`.

## First-time setup

After installing, create `~/.claude/plugins/affiliate-kit/config.json` (gitignored, never committed) with:

```json
{
  "monorepo_path": "C:/Users/<you>/source/repos/affiliate-sites",
  "tokens": {
    "cloudflare_api": "<your CF API token>",
    "cloudflare_account_id": "<your CF account id>"
  }
}
```

See `docs/BASEMENT_SETUP.md` in the monorepo root for the full first-time setup walkthrough.

## Available commands (Phase 1)

Only these commands exist as files in `plugin/commands/` today:

- `/aff-bootstrap <slug>` — scaffold a new affiliate site and deploy it to Cloudflare Pages.
- `/aff-help` — auto-derived cheatsheet that lists every installed plugin command by reading the `commands/` directory at runtime.

## Roadmap (NOT YET — Phase 2)

Designed but not implemented. See `COMMANDS.md` and the design doc for the spec.

- `/aff-next` — the smart router (NOT YET — Phase 2)
- `/aff-status [site]` — portfolio state (NOT YET — Phase 2)
- `/aff-cycle <site>` — quarterly cycle orchestrator (NOT YET — Phase 2)
- `/aff-new-review <site> <product>` — review writer (NOT YET — Phase 2)
- `/aff-refresh <site> [page]` — content refresher (NOT YET — Phase 2)

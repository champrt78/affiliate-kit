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
  "tone": "snarky",
  "tokens": {
    "cloudflare_api": "<your CF API token>",
    "cloudflare_account_id": "<your CF account id>"
  }
}
```

See `docs/BASEMENT_SETUP.md` in the monorepo root for the full first-time setup walkthrough.

## Commands

Only `/aff-bootstrap` is implemented in Phase 1. Phase 2 adds:

- `/aff-next` ⭐ — the smart router
- `/aff-status [site]` — portfolio state
- `/aff-help` — cheatsheet
- `/aff-cycle <site>` — quarterly cycle orchestrator
- `/aff-new-review <site> <product>` — review writer
- `/aff-refresh <site> [page]` — content refresher

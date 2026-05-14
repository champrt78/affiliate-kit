# Affiliate Kit — Command Cheatsheet

> Same content as `/aff-help`, but always available in this repo.

## Available commands (work today)

| Command | Purpose |
|---|---|
| `/aff-bootstrap <slug>` | Create a new site from scratch (scaffold + Cloudflare deploy). |
| `/aff-help` | Auto-derived cheatsheet of every installed plugin command. |

These are the only two commands that exist as files in `plugin/commands/`. Everything below is planned, not built.

## Examples

```
/aff-bootstrap mywildlifecam   # scaffold + deploy the hero site
/aff-help                      # remind me what's installed
```

## Roadmap (Phase 2/3)

The commands below are designed but NOT YET implemented. Treat this list as the spec for future work, not as a menu of things you can run today.

| Command | Purpose | Status |
|---|---|---|
| `/aff-next` | "What should I do?" smart router across the portfolio. | (NOT YET — Phase 2) |
| `/aff-status [site]` | Show portfolio (or one site) state, sorted by urgency. | (NOT YET — Phase 2) |
| `/aff-cycle <site>` | Run the full quarterly cycle (5 new + refresh sweep). | (NOT YET — Phase 2) |
| `/aff-new-review <site> <product-or-keyword>` | Write one new review. | (NOT YET — Phase 2) |
| `/aff-refresh <site> [page]` | Refresh existing reviews. | (NOT YET — Phase 2) |

## Phase status

- **Phase 1 (toolkit + `/aff-bootstrap` + `/aff-help`):** code complete; Cloudflare provisioning + first site bootstrap deferred to basement PC. See `docs/BASEMENT_SETUP.md`.
- **Phase 2 (content commands, status engine, cycle orchestrator):** not started — only `/aff-bootstrap` and `/aff-help` exist today.

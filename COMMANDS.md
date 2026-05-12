# Affiliate Kit — Command Cheatsheet

> Same content as `/aff-help`, but always available in this repo.

## Everyday — most likely what you want

| Command | Purpose |
|---|---|
| `/aff-next` ⭐ | "What should I do?" The smart router. Start here. |
| `/aff-status [site]` | Show portfolio (or one site) state, sorted by urgency. |

## Per-site work

| Command | Purpose |
|---|---|
| `/aff-cycle <site>` | Run the full quarterly cycle (5 new + refresh sweep). |
| `/aff-new-review <site> <product-or-keyword>` | Write one new review. |
| `/aff-refresh <site> [page]` | Refresh existing reviews. |

## One-time

| Command | Purpose |
|---|---|
| `/aff-bootstrap <slug>` | Create a new site from scratch. |

## Examples

```
/aff-next                                  # most common
/aff-cycle mywildlifecam                   # quarterly push for the hero
/aff-new-review fussybean breville-bambino # one-off review
/aff-refresh detailerpicks                 # check all detailer pages
/aff-status --spicy                        # for motivation days
/aff-next --auto                           # surprise me
```

## Phase status

- **Phase 1 (toolkit + `/aff-bootstrap`):** code complete; Cloudflare provisioning + first site bootstrap deferred to basement PC. See `docs/BASEMENT_SETUP.md`.
- **Phase 2 (content commands, status engine, cycle orchestrator):** not started — only `/aff-bootstrap` exists today.

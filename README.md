# affiliate-kit

A Claude Code plugin and Astro monorepo for operating 5 affiliate sites with minimal active overhead.

## Status

**Phase 1 complete (toolkit built).** Site bootstrapping (Cloudflare provisioning + first real site) is deferred to the basement PC — see [`docs/BASEMENT_SETUP.md`](docs/BASEMENT_SETUP.md).

## Docs

- [Design spec](docs/2026-05-12-affiliate-kit-design.md)
- [Phase 1 plan](docs/2026-05-12-affiliate-kit-plan-phase-1.md)
- [Basement setup checklist](docs/BASEMENT_SETUP.md)

## Local layout

This repo lives at `~/source/repos/affiliate-sites/` on every machine. The plugin source under `plugin/` is copied to `~/.claude/plugins/affiliate-kit/` by `scripts/install-plugin.ps1`.

## The 5 sites

| Slug | Niche | Tier |
|---|---|---|
| `mywildlifecam` | Trail cameras / wildlife cams | Hero |
| `detailerpicks` | Car detailing | Satellite |
| `fussybean` | Coffee / espresso | Satellite |
| `starteraquarium` | Beginner aquariums | Satellite |
| `gameovergear` | Retro gaming gear | Satellite (passion) |

## Stack

Astro static → Cloudflare Pages → Workers (link cloaking) + R2 (images) + Web Analytics. Domains on Porkbun, nameservers pointed at Cloudflare.

## Quick commands (after install)

See [`COMMANDS.md`](COMMANDS.md).

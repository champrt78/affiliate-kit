# affiliate-kit

A Claude Code plugin and Astro monorepo for operating 6 affiliate sites with minimal active overhead.

## Status

**Phase 1 complete (toolkit built).** Site bootstrapping (Cloudflare provisioning + first real site) is deferred to the basement PC — see [`docs/BASEMENT_SETUP.md`](docs/BASEMENT_SETUP.md).

## Docs

- [Design spec](docs/2026-05-12-affiliate-kit-design.md)
- [Phase 1 plan](docs/2026-05-12-affiliate-kit-plan-phase-1.md)
- [Basement setup checklist](docs/BASEMENT_SETUP.md)

## Local layout

This repo lives at `~/source/repos/affiliate-sites/` on every machine. The plugin source under `plugin/` is copied to `~/.claude/plugins/affiliate-kit/` by `scripts/install-plugin.ps1`.

## The 6 sites

| Slug | Niche | Tier | Stack |
|---|---|---|---|
| `mywildlifecam` | Trail cameras / wildlife cams | Hero | Astro template |
| `detailerpicks` | Car detailing | Satellite | Astro template |
| `fussybean` | Coffee / espresso | Satellite | Astro template |
| `starteraquarium` | Beginner aquariums | Satellite | Astro template |
| `gameovergear` | Retro gaming gear | Satellite (passion) | Astro template |
| `askbigchew` | English Bulldog products (Big Chew reviews) | Satellite | Next.js + MDX (own repo: `champrt78/askbigchew`) |

## Stack

Astro static → Cloudflare Pages → Workers (link cloaking) + R2 (images) + Web Analytics. Domains on Porkbun, nameservers pointed at Cloudflare.

`askbigchew` is structurally different — Next.js 15 + MDX in its own `bc/` repo, registered on Namecheap. Same Cloudflare DNS + link-cloaker Worker pattern applies. Migration walkthrough: [`docs/askbigchew-cloudflare-migration.html`](docs/askbigchew-cloudflare-migration.html).

## Quick commands (after install)

See [`COMMANDS.md`](COMMANDS.md).

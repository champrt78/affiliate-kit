# affiliate-kit

Design + (eventually) implementation of a Claude Code plugin and Astro monorepo for operating 5 affiliate sites with minimal active overhead.

## Status

**Design phase.** Spec is written and approved. Implementation plan not yet generated.

## What's here

- [`2026-05-12-affiliate-kit-design.md`](2026-05-12-affiliate-kit-design.md) — the design spec

## What's coming

- Implementation plan (next step — via the `writing-plans` Claude Code skill)
- Plugin code under `plugin/`
- Astro monorepo under `affiliate-sites/` (or as a separate repo — TBD)

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

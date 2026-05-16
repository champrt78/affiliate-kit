# Affiliate Kit — Conventions

This file teaches Claude the conventions for working inside this monorepo. Read it before making changes.

## Layout
- `packages/` — shared code (utils, UI components, styles). Published as workspace packages.
- `templates/` — source templates used by `/aff-bootstrap`. Do not edit a site directly; if you need to change something across sites, change it in `templates/site-template/` and re-run the bootstrap or manually sync.
- `sites/<slug>/` — generated per-site Astro projects. Each site is independent and can diverge from the template once spawned.
- `workers/` — Cloudflare Workers (one per Worker, currently just `link-cloaker`).
- `tools/` — internal CLIs and helpers. Used by the `/aff-bootstrap` command.
- `plugin/` — Claude Code plugin source. Installed to `~/.claude/plugins/affiliate-kit/` via `scripts/install-plugin.ps1`.
- `docs/` — spec + plans + retrospectives.

## Strategy
- One hero site (`mywildlifecam`) gets the real effort. Five satellites (`detailerpicks`, `fussybean`, `starteraquarium`, `gameovergear`, `askbigchew`) get the playbook on a slower clock. Don't suggest equal effort across all 6.
- Quarterly cycle = 5 new reviews + refresh sweep, per site, every 90 days.
- `askbigchew` lives in its own repo (`champrt78/askbigchew`, locally `bc/`) and uses Next.js + MDX instead of the Astro template. Don't try to bootstrap it via `/aff-bootstrap`; it follows a different deploy path documented in `docs/askbigchew-cloudflare-migration.html`. Once on Cloudflare DNS, it shares the same link-cloaker Worker as the others.

## Content rules
- AI scaffolds the draft. Human fills in `## My Take`. Never publish with My Take empty.
- Products the human doesn't own → frame as buyer's guide, not review.
- AI-generated product images are banned. AI for scene/context only. Product hero shots come from Amazon PA-API or the brand's affiliate media kit.

## Style
- TypeScript strict mode. No `any` without a `// reason:` comment.
- Test the hard parts (Worker logic, helpers, schema generators). Don't unit-test Astro templates — `astro build` is the test.
- Conventional commits: `feat:`, `fix:`, `refactor:`, `docs:`, `chore:`, `test:`.
- Frequent commits; one logical change per commit.

## Tone of generated output
- Tone is currently fixed at snarky-but-friendly. Configurable tone is deferred until a concrete consumer exists.
- Every command's output ends with a `Next:` block telling the user what to do next.

## When in doubt
- Check the spec at `docs/2026-05-12-affiliate-kit-design.md`.
- Check the active plan at `docs/2026-05-12-affiliate-kit-plan-phase-1.md`.
- Check the basement setup at `docs/BASEMENT_SETUP.md` for what's deferred.

---
description: Scaffold a new affiliate site and deploy it to Cloudflare Pages. Usage: /aff-bootstrap <slug>
---

# /aff-bootstrap

Scaffolds a new affiliate site under `sites/<slug>/`, deploys it to Cloudflare Pages, points DNS at it, and attaches the link-cloaker Worker route. By the end, the site is live on its custom domain.

## How to run this

The user invoked: `/aff-bootstrap <slug>` (plus possibly more args).

**Step 1: Validate the slug.**

The slug must be lowercase, alphanumeric, with single dashes between words. It must match one of the 5 known sites:

- `mywildlifecam` → `mywildlifecam.com` — niche: trail cameras / wildlife cams — siteName: MyWildlifeCam
- `fussybean` → `fussybean.com` — niche: coffee and espresso — siteName: FussyBean
- `detailerpicks` → `detailerpicks.com` — niche: car detailing — siteName: DetailerPicks
- `starteraquarium` → `starteraquarium.com` — niche: beginner aquariums — siteName: StarterAquarium
- `gameovergear` → `gameovergear.games` — niche: retro gaming gear — siteName: GameOverGear

If the slug doesn't match a known site, stop and ask the user to clarify (or pass a `--custom` flag and ask for niche/apex/etc.).

**Step 2: Gather the per-site values.**

If the slug matches a known site, you already know `siteName`, `apex`, and `niche`.

You still need to ask the user (or accept from flags):
- `tagline` — one-line site tagline (e.g. "Honest reviews of wildlife cameras for the backyard naturalist.")
- `contactEmail` — contact email (e.g. "hello@mywildlifecam.com")

Ask politely if any are missing.

**Step 3: Confirm.**

Show the user the gathered values in a small table and ask them to confirm before kicking off the bootstrap. The bootstrap makes real changes to Cloudflare (creates a Pages project, DNS records, Worker route, R2 bucket) — those are reversible but real.

**Step 4: Run the CLI.**

Once confirmed, run from the monorepo's `tools/bootstrap` directory:

```bash
pnpm dev <slug> \
  --site-name "<siteName>" \
  --site-url "https://<apex>" \
  --niche "<niche>" \
  --tagline "<tagline>" \
  --contact-email "<contactEmail>" \
  --apex "<apex>"
```

Stream stdout to the user as it runs (it will print progress lines).

**Step 5: Print the `Next:` block.**

The CLI prints its own `Next:` block when it finishes. Echo it through to the user without modification.

## Pre-flight checks

Before running the CLI, verify:

1. `~/.claude/plugins/affiliate-kit/config.json` exists and has `tokens.cloudflare_api` and `tokens.cloudflare_account_id`. If not, point the user at `docs/BASEMENT_SETUP.md`.
2. The apex domain is added to Cloudflare. If not, ask the user to add it via the Cloudflare dashboard first.
3. Porkbun nameservers point at Cloudflare. If propagation isn't done, the bootstrap will still succeed but the site won't be reachable until propagation completes — note this to the user.
4. The link-cloaker Worker (`affkit-link-cloaker`) is deployed. If not, ask the user to run `cd workers/link-cloaker && wrangler deploy` first.

## On failure

If the CLI exits non-zero, capture the error, present it to the user, and suggest the most likely fix:
- "zone not found" → user needs to add the domain to Cloudflare first
- "API token missing" → user needs to update `config.json`
- "already exists" on a site directory → user needs to delete or rename the existing one
- "pnpm install failed" → likely network or registry; suggest retrying

Do not attempt destructive recovery automatically. Surface the error and let the user decide.

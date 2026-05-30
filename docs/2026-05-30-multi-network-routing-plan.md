---
title: Multi-network commission routing — implementation plan
type: feat
status: plan (BLOCKED on Ray's network credentials — do not build yet)
origin: docs/TODO.md item #10
author: Claude (autonomous run 2026-05-30)
---

# Multi-network commission routing

## Why this is a plan, not code

Ray deferred the affiliate-network keys (PA-API arriving soon after 3 Amazon
orders clear; Awin / AvantLink not yet applied for). Building the routing layer
before the credentials exist would mean shipping untestable code with no live
network to validate against. This doc is the build-ready blueprint so the work
is a half-day once the keys land, not a from-scratch design.

**Do not implement until Ray pastes credentials.** TODO #41 tracks the key
hand-off; this plan is its downstream consumer.

## Today (single-network reality)

- `workers/link-cloaker/src/index.ts` reads one KV value per slug:
  `{ url, tag?, merchant: "amazon" | "other", status, updated, replaced_by? }`.
- On hit: `retired` → 410; `replaced_by` → 301; else if `merchant === "amazon"`
  and a `tag` is set, it appends `?tag=<tag>` and 302-redirects, writing one
  `CLICKS` Analytics Engine datapoint.
- `scripts/add-link.ps1` writes exactly one offer per `site:slug` KV key.
- Every product therefore points at exactly one merchant (always Amazon today).

The whole system assumes one product = one link = one network. Multi-network
routing relaxes that to one product = N candidate offers, pick the best at click
time.

## Goal

For a product carried by more than one network (e.g. a trail cam on Amazon AND
on a brand store that runs an Awin program), let the cloaker choose which
network to send the click to, by a deterministic policy, without changing any
page markup. The page keeps linking to the same clean `/go/<slug>`; the routing
decision moves entirely into KV data + the Worker.

Non-goals: real-time commission-rate scraping, per-user geo-routing, A/B split
testing. Those are later items if the basic router proves out.

## Design

### 1. KV envelope v2 (backward compatible)

Add an optional `offers` array. When present it wins; when absent the Worker
falls back to the v1 single-offer fields, so existing entries keep working
untouched (no migration required).

```jsonc
{
  // v1 fields stay as the fallback / single-offer case
  "url": "https://www.amazon.com/dp/B0XXXX",
  "tag": "mywildlifecam-20",
  "merchant": "amazon",
  "status": "active",
  "updated": "2026-05-30T...",

  // v2: when present, the router picks from here
  "offers": [
    { "network": "amazon",    "url": "https://www.amazon.com/dp/B0XXXX", "tag": "mywildlifecam-20", "priority": 10 },
    { "network": "awin",      "url": "https://brand.com/product/123",    "awinmid": "12345",          "priority": 20 },
    { "network": "avantlink", "url": "https://merchant.com/p/abc",       "avantMerchant": "5678",     "priority": 30 }
  ],
  "policy": "priority"   // "priority" (default) | "first-available"
}
```

Per-network offer fields:
- **amazon** — `url` (a `/dp/<ASIN>` or canonical), `tag` (the site's Associates tag). Link = `url + ?tag=<tag>`.
- **awin** — `url` (the destination/deep-link target), `awinmid` (merchant ID). Link = `https://www.awin1.com/cread.php?awinmid=<mid>&awinaffid=<AFFID>&ued=<urlencoded url>`.
- **avantlink** — `url` (destination), `avantMerchant` (merchant ID). Link = `https://www.avantlink.com/click.php?tt=cl&mi=<merchant>&pw=<AFFID>&url=<urlencoded url>`.

`AFFID`/`pw` are the SITE-level affiliate IDs — they are secrets, NOT stored
per-offer in KV (see §4).

### 2. Selection policy (deterministic, in the Worker)

- `policy: "priority"` (default): sort `offers` by ascending `priority`, take the
  first whose network has credentials configured for this site (see §4). This
  lets Ray rank networks by commission/reliability per product just by ordering.
- `policy: "first-available"`: take the first offer in array order with
  configured credentials. Simpler; use when priority doesn't matter.
- If no offer has configured credentials, fall back to the v1 single-offer
  fields. If those are also missing, 404 (current behavior).
- Retired/`replaced_by` handling stays at the envelope level, unchanged.

Determinism matters: the same KV value + same Worker env must always pick the
same link, so click attribution and testing are stable.

### 3. Per-network link builders (Worker)

Add a `buildLink(offer, env, site)` dispatcher with one pure function per
network, mirroring today's `applyAmazonTag`:

```ts
function buildAmazon(o, env, site) { return applyAmazonTag(o.url, o.tag); }
function buildAwin(o, env, site)   { return `https://www.awin1.com/cread.php?awinmid=${o.awinmid}&awinaffid=${env[`AWIN_AFFID_${site}`]}&ued=${encodeURIComponent(o.url)}`; }
function buildAvantlink(o, env, site){ return `https://www.avantlink.com/click.php?tt=cl&mi=${o.avantMerchant}&pw=${env[`AVANT_AFFID_${site}`]}&url=${encodeURIComponent(o.url)}`; }
```

Each builder is independently unit-testable with a fixed env, which is how the
existing `cloaker.test.ts` already tests Amazon tagging.

### 4. Credentials = Worker secrets, never KV

Per-site affiliate IDs are secrets, set with `wrangler secret put`, namespaced
by site so one Worker serves all sites without cross-leak (the Worker already
derives `site` from the Host header):

- `AWIN_AFFID_mywildlifecam`, `AWIN_AFFID_detailerpicks`, ...
- `AVANT_AFFID_mywildlifecam`, ...
- Amazon tags stay in KV per offer (they are not secret; they are already in
  page URLs).

"Credentials configured for this site" in §2 = the matching `*_AFFID_<site>`
secret is present. A network with no secret for that site is skipped, so Ray can
roll out networks site-by-site as approvals come in.

### 5. Click attribution

Extend the `CLICKS.writeDataPoint` call to record the chosen network as a blob
dimension (today it records source/slug). Then a click report can break revenue
attribution down by network, which is the signal Ray needs to tune `priority`
ordering over time.

### 6. Tooling — `add-link.ps1` v2

- Add a repeatable `-Offer` parameter or an `-OffersJson` blob so one slug can
  carry multiple offers, e.g.:
  `pwsh scripts/add-link.ps1 -Site mywildlifecam -Slug browning-x -OffersJson '[{"network":"amazon","url":"...","tag":"mywildlifecam-20","priority":10},{"network":"awin","url":"...","awinmid":"123","priority":20}]'`
- Keep the current single-offer signature working (it writes v1 fields), so
  nothing that calls add-link today breaks (Magic Go scaffolding, /aff unblock
  flow — see `plugin/commands/scaffold-piece.md` + `aff.md`).
- `list-links.ps1` gains an offers column.

### 7. Rollout (once keys exist)

1. Land the Worker v2 (offers + builders + policy + attribution) behind the
   backward-compatible fallback. Ship it. Every existing single-offer entry
   keeps working — zero behavior change until an `offers` array is written.
2. `wrangler secret put` the AFFID secrets for whichever site/network is live
   first.
3. Convert a SINGLE pilot product to a 2-offer entry (Amazon + the new network),
   verify both links resolve and attribution records the network, watch one
   real click.
4. Backfill offers on products that have a second network, ranked by `priority`.
5. Add a one-line note to `docs/SYSTEM.md` (the cloaker section) and to
   `CLAUDE.md` (the add-link convention).

## Risks & notes

- **Link format drift.** Awin/AvantLink deep-link URL formats change occasionally
  and have per-program quirks (some merchants need the `clickref`/`ref`
  parameter). Validate each network's exact format from its dashboard at build
  time, not from this doc — treat the §3 builders as the shape, not the gospel.
- **Backward compatibility is load-bearing.** The v1 fallback is what lets this
  ship before all networks are live and keeps Magic Go / `/aff` unblock flows
  working. Do not remove it.
- **Secrets, not KV, for AFFIDs.** Putting affiliate IDs in KV would expose them
  in any KV dump; they belong in Worker secrets.
- **One Worker, many sites.** The Host-derived `site` + per-site secret naming is
  what keeps detailerpicks from spending mywildlifecam's affiliate ID. Preserve
  that boundary in every builder.

## Blocked on (Ray)

- PA-API access (Amazon — arriving) — not strictly needed for routing, but it is
  the trigger that signals Ray is ready to wire networks.
- Awin publisher account + per-site `AWIN_AFFID_*` + per-program `awinmid`s.
- AvantLink affiliate account + per-site `AVANT_AFFID_*` + per-merchant ids.

When those land (TODO #41), this plan is a half-day build.

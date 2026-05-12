# Basement PC Setup — Affiliate Kit Phase 1

This is the checklist you run on the basement PC (or any fresh machine) to take the toolkit from `git clone` to `mywildlifecam.fyi is live on the internet`. Every step is annotated with what it does and why it can't be automated from the work PC.

If you hit anything weird, the source of truth for the design is `docs/2026-05-12-affiliate-kit-design.md` and the original plan is `docs/2026-05-12-affiliate-kit-plan-phase-1.md`.

---

## Part 1 — Get the code

```powershell
# Clone the repo into its long-term home
mkdir -Force $env:USERPROFILE\source\repos
cd $env:USERPROFILE\source\repos
git clone https://github.com/champrt78/affiliate-kit.git affiliate-sites
cd affiliate-sites
```

The clone target directory must be named `affiliate-sites` (not `affiliate-kit`) — the plugin and bootstrap CLI both assume that path.

---

## Part 2 — Install global tooling

You need Node 20+, pnpm, and wrangler installed globally. If they're already there, skip.

```powershell
# Node 20+ — check first
node --version            # should print v20.x or higher
# If not, install from https://nodejs.org/ (LTS) or use nvm-windows.

# pnpm
npm install -g pnpm@latest
pnpm --version            # should print 9.x

# wrangler (Cloudflare CLI)
npm install -g wrangler@latest
wrangler --version        # should print 3.x

# PowerShell 7 (for the install-plugin script). Skip if you already have pwsh.
winget install --id Microsoft.PowerShell --silent
```

---

## Part 3 — Install workspace dependencies

```powershell
cd $env:USERPROFILE\source\repos\affiliate-sites
pnpm install
```

This wires all the workspace packages together. Expect 1-3 minutes the first time.

---

## Part 4 — Run the test suite

Confirm the toolkit code actually works on this machine.

```powershell
# Test the shared utilities (cloakedLink, schema, IndexNow)
cd packages/shared-utils
pnpm test

# Test the bootstrap copy-template helper
cd ../../tools/bootstrap
pnpm test

# Test the link-cloaker Worker (requires wrangler, no CF deploy needed yet)
cd ../../workers/link-cloaker
pnpm test
```

All three should pass green. If any fail on a fresh clone, the cause is most likely a tooling version mismatch (Node, pnpm, wrangler) — not the code. Verify versions before debugging.

---

## Part 5 — Cloudflare account setup

These steps create the resources the toolkit talks to. Done once per Cloudflare account.

### 5a. Add all 5 domains to Cloudflare

For each of: `mywildlifecam.fyi`, `fussybean.com`, `detailerpicks.com`, `starteraquarium.com`, `gameovergear.games`:

1. Cloudflare dashboard → **Add Site** → enter domain → choose **Free** plan.
2. Cloudflare gives you 2 nameservers (e.g. `xxx.ns.cloudflare.com`). Note them.
3. Log into Porkbun → that domain → **Authoritative Nameservers** → replace with the 2 from Cloudflare. Propagation: 0-24 hours, usually under an hour.

You can do this in parallel for all 5 — just keep a list of which nameservers Cloudflare gave you per domain.

### 5b. Get your Cloudflare account id

Dashboard → click any of your domains → right sidebar → **Account ID**. Copy it.

### 5c. Create a Cloudflare API token

Dashboard → **My Profile** → **API Tokens** → **Create Token** → **Custom token**.

Permissions:
- `Account` → `Cloudflare Pages` → `Edit`
- `Account` → `Workers Scripts` → `Edit`
- `Account` → `Workers R2 Storage` → `Edit`
- `Account` → `Account Settings` → `Read`
- `Zone` → `DNS` → `Edit`
- `Zone` → `Workers Routes` → `Edit`

Zone Resources: **Include — All zones from an account** (so this single token works for all 5 sites).
Account Resources: **Include — All accounts**.

Save the token. Treat it like a password — anything that has this token can deploy to your CF account.

### 5d. Authenticate wrangler

```powershell
wrangler login
```

Opens a browser, you approve, done.

---

## Part 6 — Install the Claude Code plugin

```powershell
cd $env:USERPROFILE\source\repos\affiliate-sites
pnpm install-plugin
```

This runs `scripts/install-plugin.ps1` which copies `plugin/` to `~/.claude/plugins/affiliate-kit/`.

---

## Part 7 — Create the plugin config file

Create `~/.claude/plugins/affiliate-kit/config.json` with this content (replace the two `<...>` values):

```json
{
  "monorepo_path": "C:/Users/<your-username>/source/repos/affiliate-sites",
  "tone": "snarky",
  "tokens": {
    "cloudflare_api": "<paste the API token from step 5c>",
    "cloudflare_account_id": "<paste the account id from step 5b>"
  }
}
```

This file is gitignored. Never commit it. Use forward slashes in `monorepo_path` (Windows accepts them and they don't need escaping in JSON).

---

## Part 8 — Deploy the link-cloaker Worker (one-time)

The Worker handles affiliate-link redirects across all 5 sites. Deploy it once before bootstrapping any site.

```powershell
cd $env:USERPROFILE\source\repos\affiliate-sites\workers\link-cloaker

# Create the KV namespace
wrangler kv namespace create AFFILIATE_LINKS
```

Wrangler will print something like:

```
[[kv_namespaces]]
binding = "AFFILIATE_LINKS"
id = "abc123def456..."
```

**Edit `wrangler.toml`** and replace the `REPLACE_WITH_KV_NAMESPACE_ID` value with that id.

Then:

```powershell
wrangler deploy
```

Expected output ends with `Deployed affkit-link-cloaker`.

Commit the updated `wrangler.toml`:

```powershell
cd $env:USERPROFILE\source\repos\affiliate-sites
git add workers/link-cloaker/wrangler.toml
git commit -m "chore(link-cloaker): record production KV namespace id"
git push
```

---

## Part 9 — Bootstrap mywildlifecam.fyi (the proof)

Open Claude Code in the monorepo directory:

```powershell
cd $env:USERPROFILE\source\repos\affiliate-sites
claude
```

In the Claude session, type:

```
/aff-bootstrap mywildlifecam
```

Claude will:
1. Recognize `mywildlifecam` from the known-sites list (siteName: MyWildlifeCam, apex: mywildlifecam.fyi, niche: trail cameras).
2. Ask you for `tagline` and `contactEmail`.
3. Show a confirmation table.
4. Run the CLI which copies the template, builds the site, creates the Pages project, deploys, attaches the domain, creates DNS, attaches the Worker route.

Suggested values:
- **tagline**: "Honest reviews of trail cameras for the backyard naturalist."
- **contactEmail**: `hello@mywildlifecam.fyi`

Expected runtime: 1-3 minutes.

---

## Part 10 — Verify the site is live

```powershell
curl -I https://mywildlifecam.fyi
```

Expected: `HTTP/2 200` with `server: cloudflare`.

If you get NXDOMAIN, DNS propagation isn't done. Wait 5-15 minutes and retry.

Visit `https://mywildlifecam.fyi` in a browser. You should see the MyWildlifeCam homepage with the tagline you set.

### Smoke-test the link cloaker

Add a temporary KV entry:

```powershell
# Get your namespace id from wrangler.toml in workers/link-cloaker/
$kvId = "<your AFFILIATE_LINKS id>"

wrangler kv key put --namespace-id=$kvId "mywildlifecam:test-product" "https://example.com/test"
```

Visit `https://mywildlifecam.fyi/go/mywildlifecam/test-product` — should 302 to `https://example.com/test`.

Visit `https://mywildlifecam.fyi/go/mywildlifecam/does-not-exist` — should return 404.

Delete the test entry:

```powershell
wrangler kv key delete --namespace-id=$kvId "mywildlifecam:test-product"
```

---

## Part 11 — Commit the generated site

```powershell
cd $env:USERPROFILE\source\repos\affiliate-sites
git add sites/mywildlifecam
git commit -m "feat: bootstrap mywildlifecam.fyi"
git push
```

---

## You're done with Phase 1.

You should now have:

- 5 domains added to Cloudflare with nameservers pointed correctly
- The link-cloaker Worker deployed and routed at `mywildlifecam.fyi/go/*`
- `mywildlifecam.fyi` live on Cloudflare Pages with all 5 standard pages (home, about, disclosure, privacy, contact)
- The Claude Code plugin installed, with `/aff-bootstrap` working

**What you do NOT have yet** (Phase 2):
- Any reviews or buyer's guides — sites are structurally complete but content-empty
- The status engine, refresh scanners, or cycle orchestrator
- `/aff-next`, `/aff-status`, `/aff-help`, `/aff-cycle`, `/aff-new-review`, `/aff-refresh`

When you're ready to start writing reviews, that's Phase 2 — a new design + plan, picking up from here.

---

## Troubleshooting

**"zone not found" during bootstrap**
The apex domain isn't on Cloudflare yet. Go back to step 5a.

**"API token missing" or "Unauthorized"**
Config.json isn't where the CLI expects it, or the token is wrong. Check:
- Path: `~/.claude/plugins/affiliate-kit/config.json`
- Permissions: token has all 6 permissions from step 5c

**"sites/mywildlifecam already exists"**
You ran bootstrap before. Either delete `sites/mywildlifecam/` and retry, or pick a different slug.

**Worker tests fail with "wrangler not found"**
Wrangler isn't installed globally. `npm install -g wrangler`.

**Site loads but `/go/<slug>/<x>` doesn't redirect**
The Worker route isn't attached. Manually check in Cloudflare dashboard → your domain → Workers Routes. There should be a route `mywildlifecam.fyi/go/*` → `affkit-link-cloaker`. If missing, the API call during bootstrap failed silently — re-run bootstrap or attach manually.

**DNS still shows old Porkbun records after 24h**
Make sure you replaced the nameservers AT Porkbun (Authoritative Nameservers section), not the DNS records themselves. Porkbun won't relinquish authority until nameservers point elsewhere.

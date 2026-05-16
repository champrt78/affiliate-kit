# Cloudflare Pages → GitHub Auto-Deploy Setup

**Last updated:** 2026-05-16
**Status:** Walkthrough for Ray to connect each of 5 affiliate-sites CF Pages projects to the GitHub repo so pushes to `main` auto-deploy.

---

## Why this exists

The 2026-05-12 bootstrap created the 5 CF Pages projects via direct `wrangler pages deploy` upload. **None of them are connected to GitHub.** Every push to `origin/main` lands on GitHub but does NOT trigger a CF Pages rebuild. The live sites stay frozen at the last manual `wrangler pages deploy`. This is a silent failure mode: pieces "ship to git" but stay invisible on the live site.

This walkthrough fixes that. After completion, future `git push origin main` triggers automatic CF Pages builds + deploys for each of the 5 sites.

`scripts/deploy.ps1` (shipped 2026-05-16) remains useful for manual hotfixes or "force redeploy without committing." After this walkthrough lands, you'll rarely need it.

---

## Before you start

You'll need:
1. Cloudflare account access (you have it — `raychampion78@gmail.com`).
2. GitHub access to `champrt78/affiliate-kit`.
3. ~30-60 min uninterrupted (5 sites x roughly 5-10 min each, sequential).
4. Browser open to `https://dash.cloudflare.com/`.

---

## The exact build configuration (paste this into each project)

For each of the 5 CF Pages projects, when you reach the "Build settings" screen, paste these values:

| Field | Value (replace `<site>` with the actual slug) |
|---|---|
| **Framework preset** | None (or "Astro" if offered — but we're using a custom command, so None is safer) |
| **Build command** | `pnpm install && pnpm --filter <site> build` |
| **Build output directory** | `sites/<site>/dist` |
| **Root directory** | (leave empty — defaults to repo root, which is what we want) |
| **Production branch** | `main` |

Environment variables to add (under "Environment variables" / "Production"):

| Variable | Value | Why |
|---|---|---|
| `NODE_VERSION` | `20` | CF Pages defaults to an older Node; pin to 20 to match our `engines` |
| `NPM_FLAGS` | `--version` | Skips CF's default npm install (we use pnpm) |

That's it. CF auto-detects pnpm via the root `package.json`'s `packageManager: pnpm@9.0.0` field.

---

## The 5 sites + their build commands

| Site (slug) | Project name in CF | Build command to paste |
|---|---|---|
| `mywildlifecam` | `affkit-mywildlifecam` | `pnpm install && pnpm --filter mywildlifecam build` |
| `detailerpicks` | `affkit-detailerpicks` | `pnpm install && pnpm --filter detailerpicks build` |
| `fussybean` | `affkit-fussybean` | `pnpm install && pnpm --filter fussybean build` |
| `starteraquarium` | `affkit-starteraquarium` | `pnpm install && pnpm --filter starteraquarium build` |
| `gameovergear` | `affkit-gameovergear` | `pnpm install && pnpm --filter gameovergear build` |

Output directory for each: `sites/<slug>/dist`.

---

## Step-by-step (do mywildlifecam first as the test)

### 1. Open the project in the CF dashboard

1. Go to `https://dash.cloudflare.com/`
2. Pick the right account (the one tied to `raychampion78@gmail.com`)
3. Left sidebar: **Workers & Pages** → **Pages** tab
4. Click into **`affkit-mywildlifecam`**

### 2. Connect the project to GitHub

The current project was created via direct upload, so the Git tab will show "Not connected." There are two paths depending on what CF's UI offers:

**Option 2a (easiest if available):** Look for a button like "Connect to Git" / "Link a Git repo" in the project's **Settings** → **Build & deployments** → **Source** section. If it's there, click it and follow the GitHub OAuth flow.

**Option 2b (fallback if 2a is missing):** Some older CF projects can't be retrofitted with Git after direct-upload creation. If you don't see a "Connect to Git" option:

1. Note the apex domain attached to the existing project (`mywildlifecam.com`)
2. Create a NEW Pages project via dashboard "Create application" → "Pages" → "Connect to Git"
3. Authenticate GitHub, pick `champrt78/affiliate-kit`
4. During setup, use the build config from the table above
5. After the new project deploys successfully, detach `mywildlifecam.com` from the old project and re-attach to the new one
6. Delete the old `affkit-mywildlifecam` project (or rename it to `affkit-mywildlifecam-old` and leave for a week as backup)

Try 2a first. If the UI doesn't offer Git connection on the existing project, fall back to 2b.

### 3. GitHub OAuth handshake

CF will redirect to GitHub asking for permission to read the `champrt78/affiliate-kit` repo. Grant it. You may need to install the Cloudflare Pages GitHub App if it's not already installed on your account.

Scope: just the `champrt78/affiliate-kit` repo, not all repos. Less surface area, easier to audit later.

### 4. Build configuration

When CF asks for build settings, paste from the table above. For mywildlifecam:

- Framework preset: **None**
- Build command: **`pnpm install && pnpm --filter mywildlifecam build`**
- Build output directory: **`sites/mywildlifecam/dist`**
- Root directory: (empty)
- Production branch: **`main`**

Add environment variables:
- `NODE_VERSION` = `20`
- `NPM_FLAGS` = `--version`

### 5. Save and trigger first build

Click "Save and Deploy." CF will:
1. Clone `champrt78/affiliate-kit` at the `main` branch
2. Run `pnpm install` (CF detects pnpm via `packageManager` field)
3. Run the build command
4. Upload the output from `sites/mywildlifecam/dist`
5. Deploy to `mywildlifecam.com`

Watch the build log in the CF dashboard. Expected duration: 2-4 minutes total.

### 6. Verify the auto-deploy works

After the first auto-deploy succeeds:

```pwsh
# Make a trivial change to force a deploy
cd C:\Users\Ray\documents\github\affiliate-sites
# Edit something cosmetic, e.g., add a space to README.md
git add README.md
git commit -m "test: trigger CF auto-deploy"
git push origin main
```

Watch the CF Pages dashboard. You should see a new "Production" deployment kick off within 30 seconds of the push, building from the `main` branch's HEAD commit. If it does, mywildlifecam is wired correctly.

### 7. Repeat for the other 4 sites

Once mywildlifecam works, do the same for the other 4 sites (`detailerpicks`, `fussybean`, `starteraquarium`, `gameovergear`). The flow is identical; just swap the slug in the build command and output directory.

---

## What success looks like

After all 5 sites are connected, `wrangler pages project list` should show `Git Provider: GitHub` on all 5. From that point forward:

- Push a piece to `origin/main` → all 5 sites auto-build (only the affected site changes meaningfully, but CF rebuilds them all on any main push — that's fine, builds are cheap)
- Build status visible in the CF Pages dashboard for each site
- No more manual `wrangler pages deploy` needed
- `scripts/deploy.ps1` remains useful for: manual hotfixes, forcing a redeploy without a commit, testing dist output before committing

---

## Troubleshooting

**Build fails with "pnpm: command not found":**
- Add `corepack enable` to the start of the build command: `corepack enable && pnpm install && pnpm --filter <site> build`

**Build fails with "ENOENT lockfile":**
- Verify `pnpm-lock.yaml` is committed at repo root. Run `git ls-files pnpm-lock.yaml` to confirm.

**Build succeeds but the wrong site deploys:**
- Output directory is wrong. Should be `sites/<slug>/dist`, not `dist` or `<slug>/dist`.

**`@astrojs/sitemap` crash:**
- Should not happen — we pinned `@astrojs/sitemap@3.4.1` for Astro 4.x compat. If it does, verify the lockfile is current.

**Auto-deploy doesn't fire on push:**
- Check CF Pages dashboard → project → Settings → Builds & deployments → Production branch matches your push branch (should be `main`)
- Check the GitHub repo settings → Integrations → Cloudflare Pages → confirm it's installed and has access to the repo
- Check the CF Pages project deployment history for a "Build failed" entry that might explain why

---

## When you finish

Update `docs/sessions/Session_<TODAY>.md` with: "CF Pages GitHub auto-deploy wired up for all 5 sites." Update `docs/PROJECT_STATE.md` if you want to capture it as a milestone (it qualifies — it changes the operational shape of the project).

Mark task #7 in `docs/RAY_QUEUE.md` (if I added one for this) as done.

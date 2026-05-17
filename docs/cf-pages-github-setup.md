# Cloudflare Pages → GitHub Auto-Deploy Setup

**Last updated:** 2026-05-16 (revised after live walkthrough)
**Status:** Walkthrough for Ray to connect each of 5 affiliate-sites CF Pages projects to the GitHub repo so pushes to `main` auto-deploy.

---

## Friction points caught during the live walkthrough (2026-05-16)

First end-to-end attempt on `mywildlifecam` hit six distinct friction points before the Workers project + Pages project + token were all aligned. Documenting them so subsequent sites (and future-you) don't re-discover from scratch. Manual `pwsh scripts/deploy.ps1 -Site <slug>` remains the always-working fallback if Git auto-deploy is ever flaky.

The 6 friction points, in the order they bit:

**1. CF Pages does NOT support retrofitting Git onto direct-upload projects.** Confirmed via CF's own docs: *"If you deploy using the Git integration, you cannot switch to Direct Upload later"* (one-way restriction). The only path is the fallback: create a NEW project from Git, move the custom domain over, delete the old direct-upload project. Phase B starts by creating new projects, not by retrofitting old ones.

**2. CF's "Create application → Connect to Git" flow creates a WORKERS project by default, not a Pages project.** Even when you intend a Pages project, the unified UI puts you in a Workers configuration. The form shows fields like "Deploy command" (Workers concept) and the default is `npx wrangler deploy` (which looks for `wrangler.toml` and fails on a static Pages site). Workaround: leave it as a Workers project but change the Deploy command to use `wrangler pages deploy` explicitly — the Workers project becomes a "build orchestrator" that publishes static output to a separate Pages project on each push.

**3. The default Build command (`pnpm run build`) ran a recursive `pnpm -r build` which surfaced two pre-existing bugs in `tools/bootstrap`:** a tsconfig rootDir vs include mismatch, and NodeNext requiring explicit `.js` extensions on relative imports. Both fixed in commit `e6e6c07` (2026-05-16). If you're walking through this AFTER that commit, you should be clean. If you're walking through it BEFORE, you'll hit `tsc` errors on the bootstrap build step.

**4. The "API token" field in CF's project settings does NOT inject `CLOUDFLARE_API_TOKEN` into the deploy command's environment with sufficient permissions.** Symptom: `wrangler pages deploy` fails with `Authentication error [code: 10000]` even though the dashboard shows an API token is configured. The auto-injected token (or whatever CF does with that field) lacks Pages:Edit permission. Workaround: create an API token explicitly with `Account → Cloudflare Pages → Edit` permission, then add it to the project's **Variables and secrets** section (NOT the "API token" field) as a Secret named `CLOUDFLARE_API_TOKEN`. Also: if you generate a token from a "Workers" template, it gets every Workers-related permission (Workers Scripts, R2, KV, D1, etc.) EXCEPT Cloudflare Pages — Pages is a separate permission you have to add explicitly.

**5. `wrangler pages deploy` does NOT auto-create the target Pages project.** Symptom: `Project not found. The specified project name does not match any of your existing projects. [code: 8000007]`. You must create the empty Pages project once before the Workers build can deploy to it. Best done via local terminal: `npx wrangler pages project create <slug> --production-branch=main`. The interactive prompt during creation may not honor the `--production-branch=main` flag and may ask you to enter the branch name; just type `main` at the prompt.

**6. The Non-production branch deploy command field is NOT optional in CF's UI.** You can't leave it blank — CF requires a value. Use the same `wrangler pages deploy` command minus the `--branch=main` flag (creates preview deploys on non-main branches), or set it to `echo "skip"` if you genuinely never want non-main pushes to deploy.

**After clearing all 6 friction points, the `mywildlifecam` setup is:**
- Workers project (Git-connected): `mywildlifecam`, runs `pnpm --filter mywildlifecam build` then `npx wrangler pages deploy sites/mywildlifecam/dist --project-name=mywildlifecam --branch=main`
- Pages project (deploy target, created manually via wrangler): `mywildlifecam`
- API token: `Cloudflare Pages: Edit` permission, set as a Variables/Secrets entry named `CLOUDFLARE_API_TOKEN` (or via the "API token" field if that works — both routes exist)

**Then to actually serve the apex domain from the new project:** detach `mywildlifecam.com` from `affkit-mywildlifecam` and re-attach to the new `mywildlifecam` Pages project. This is a separate dashboard step after the new project has a successful deployment.

**For the 4 satellite sites (after mywildlifecam works):** the same 6-friction-point setup applies. Build command + deploy command + project-name flag all change to the satellite's slug. The empty Pages project for each must be pre-created via `npx wrangler pages project create <slug> --production-branch=main`. Domain migration from `affkit-<slug>` to `<slug>` follows the same pattern.

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

CF's unified UI creates these as Workers projects with Pages-style static publishing. Use these exact values per site (the Build command and Deploy command both need to be set explicitly):

| Field | Value (replace `<site>` with the actual slug) |
|---|---|
| **Build command** | `pnpm --filter <site> build` *(no `pnpm install` prefix — CF auto-installs)* |
| **Deploy command** | `npx wrangler pages deploy sites/<site>/dist --project-name=<site> --branch=main` |
| **Non-production branch deploy command** | (leave empty — we don't use preview branches) |
| **Path** | `/` |
| **Production branch** | `main` *(set during project creation)* |

Important quirks:

- **Don't use `npx wrangler deploy`** (the default CF puts in this field). That's the Workers command and fails on Pages sites with "The Wrangler application detection logic has been run in the root of a workspace instead of targeting a specific project." Use `wrangler pages deploy` explicitly.
- **The `--project-name=<site>` flag creates a separate CF Pages project** on first deploy if it doesn't already exist. That new project is where your custom domain attaches. The Workers project from "Connect to Git" stays as the build orchestrator.
- **Don't set `pnpm install &&` prefix** in the Build command. CF auto-runs `pnpm install --frozen-lockfile` before your build command (detected via `packageManager: pnpm@9.0.0` in root `package.json`).

Environment variables — CF detects pnpm via `packageManager`, Node 20 via `engines.node`, so usually no env vars are required. If you hit Node version issues during build, add `NODE_VERSION=20` as a production environment variable.

---

## The 5 sites + their per-site values

When you create each Git-connected Workers project, name it the same as the site slug (no `affkit-` prefix — the old direct-upload projects still own those names until you delete them at cleanup). Each site has its own Build + Deploy command pair:

| Site (slug) | New Workers project name | Build command | Deploy command |
|---|---|---|---|
| `mywildlifecam` | `mywildlifecam` | `pnpm --filter mywildlifecam build` | `npx wrangler pages deploy sites/mywildlifecam/dist --project-name=mywildlifecam --branch=main` |
| `detailerpicks` | `detailerpicks` | `pnpm --filter detailerpicks build` | `npx wrangler pages deploy sites/detailerpicks/dist --project-name=detailerpicks --branch=main` |
| `fussybean` | `fussybean` | `pnpm --filter fussybean build` | `npx wrangler pages deploy sites/fussybean/dist --project-name=fussybean --branch=main` |
| `starteraquarium` | `starteraquarium` | `pnpm --filter starteraquarium build` | `npx wrangler pages deploy sites/starteraquarium/dist --project-name=starteraquarium --branch=main` |
| `gameovergear` | `gameovergear` | `pnpm --filter gameovergear build` | `npx wrangler pages deploy sites/gameovergear/dist --project-name=gameovergear --branch=main` |

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

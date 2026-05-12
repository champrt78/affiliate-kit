# Affiliate Kit — Phase 1 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build the foundation of the affiliate-kit system — a working pnpm monorepo with shared packages, a reusable Astro site template, a Cloudflare Worker for affiliate-link cloaking, and a `/aff-bootstrap` command that takes a slug and produces a live site on Cloudflare Pages. End state: `mywildlifecam.fyi` is live, served from Cloudflare Pages, with the `/go/<slug>` link cloaker operational.

**Architecture:** A single GitHub repo (`champrt78/affiliate-kit`) cloned locally to `~/source/repos/affiliate-sites/`. Contains the pnpm workspace monorepo at root, plus a `plugin/` subdirectory holding the Claude Code plugin source (installed to `~/.claude/plugins/affiliate-kit/` via a script). The bootstrap command is markdown that Claude executes, with deterministic Cloudflare operations handled by Wrangler CLI commands shelled out from TypeScript helper scripts.

**Tech Stack:** pnpm 9.x workspaces, Astro 4.x, TypeScript 5.x, Vitest 1.x, Cloudflare Pages + Workers + R2 + Web Analytics, Wrangler 3.x, Porkbun (registrar) with Cloudflare nameservers.

**Out of scope for Phase 1:** `/aff-new-review`, `/aff-refresh`, `/aff-status`, `/aff-next`, `/aff-help`, `/aff-cycle`, the `Next:` footer helper, content generation, image sourcing, schema generation beyond the basic shell. Those land in Phase 2.

---

## Pre-flight: One-time prerequisites (do these before starting Task 1)

These are manual steps the human must do once before the plan can execute. The plan assumes they're complete.

- [ ] **Install pnpm globally:** `npm install -g pnpm@latest`
- [ ] **Install Wrangler globally:** `npm install -g wrangler@latest`
- [ ] **Verify Node 20+:** `node --version` should print v20 or higher
- [ ] **Create or confirm Cloudflare account** at https://cloudflare.com (free tier is fine)
- [ ] **Add `mywildlifecam.fyi` to Cloudflare:** Dashboard → Add Site → enter domain → choose Free plan → note the 2 nameservers Cloudflare assigns
- [ ] **Point Porkbun nameservers to Cloudflare:** Porkbun → mywildlifecam.fyi → Authoritative Nameservers → replace with the 2 from Cloudflare. Propagation takes 0-24 hours; the plan can start before propagation finishes.
- [ ] **Create a Cloudflare API token:**
  - Dashboard → My Profile → API Tokens → Create Token → Custom token
  - Permissions: `Account > Cloudflare Pages > Edit`, `Account > Workers Scripts > Edit`, `Account > Workers R2 Storage > Edit`, `Account > Account Settings > Read`, `Zone > DNS > Edit`, `Zone > Workers Routes > Edit`
  - Zone Resources: Include — Specific zone — `mywildlifecam.fyi` (we'll widen later)
  - Account Resources: All accounts (since you only have one)
  - Save the token securely; you'll paste it into `config.json` in Task 16
- [ ] **`wrangler login`** in a terminal — opens browser, authenticates the CLI (one-time, separate from the API token used by helper scripts)

If any prerequisite isn't done, pause the plan and complete it. Do not proceed past Task 1 without all of these.

---

## File structure overview

By the end of Phase 1, the repo will look like this:

```
~/source/repos/affiliate-sites/   (= clone of champrt78/affiliate-kit)
├── .gitignore
├── .nvmrc
├── README.md
├── COMMANDS.md
├── CLAUDE.md
├── package.json                    # root
├── pnpm-workspace.yaml
├── pnpm-lock.yaml
├── tsconfig.base.json
├── docs/
│   ├── 2026-05-12-affiliate-kit-design.md
│   └── 2026-05-12-affiliate-kit-plan-phase-1.md
├── packages/
│   ├── shared-styles/
│   │   ├── package.json
│   │   └── src/tokens.css
│   ├── shared-utils/
│   │   ├── package.json
│   │   ├── tsconfig.json
│   │   ├── vitest.config.ts
│   │   ├── src/
│   │   │   ├── index.ts
│   │   │   ├── cloaked-link.ts
│   │   │   ├── schema.ts
│   │   │   └── indexnow.ts
│   │   └── test/
│   │       ├── cloaked-link.test.ts
│   │       ├── schema.test.ts
│   │       └── indexnow.test.ts
│   └── shared-ui/
│       ├── package.json
│       ├── tsconfig.json
│       └── src/components/
│           ├── BaseLayout.astro
│           ├── AffiliateDisclosure.astro
│           ├── CTA.astro
│           ├── ComparisonTable.astro
│           └── Hero.astro
├── templates/
│   └── site-template/
│       ├── package.json
│       ├── astro.config.mjs
│       ├── tsconfig.json
│       ├── public/
│       │   ├── robots.txt
│       │   └── favicon.svg
│       └── src/
│           ├── content/config.ts
│           ├── layouts/MainLayout.astro
│           └── pages/
│               ├── index.astro
│               ├── about.astro
│               ├── disclosure.astro
│               ├── privacy.astro
│               └── contact.astro
├── workers/
│   └── link-cloaker/
│       ├── package.json
│       ├── tsconfig.json
│       ├── wrangler.toml
│       ├── vitest.config.ts
│       ├── src/index.ts
│       └── test/cloaker.test.ts
├── tools/
│   └── bootstrap/
│       ├── package.json
│       ├── tsconfig.json
│       ├── vitest.config.ts
│       ├── src/
│       │   ├── index.ts              # CLI entry
│       │   ├── config.ts             # loads ~/.claude/plugins/affiliate-kit/config.json
│       │   ├── copy-template.ts
│       │   ├── wrangler.ts           # wrapper around wrangler shell-outs
│       │   ├── cloudflare-pages.ts
│       │   ├── cloudflare-dns.ts
│       │   ├── cloudflare-r2.ts
│       │   └── cloudflare-worker-route.ts
│       └── test/
│           └── copy-template.test.ts
├── plugin/                            # plugin source (copied to ~/.claude/plugins/affiliate-kit/)
│   ├── plugin.json
│   ├── commands/
│   │   └── aff-bootstrap.md
│   └── README.md
├── scripts/
│   └── install-plugin.ps1            # copies plugin/ to ~/.claude/plugins/affiliate-kit/
└── sites/
    └── mywildlifecam/                # created by /aff-bootstrap in Task 17
        └── (full Astro site)
```

---

## Phase A — Repo restructure & monorepo skeleton

### Task 1: Move the repo to its long-term home and reorganize

The current repo is at `~/source/repos/sidequests/affiliate-kit-spec/`. The spec mandates `~/source/repos/affiliate-sites/`. Move it and reorganize so spec + plan land under `docs/`.

**Files:**
- Move: `C:\Users\rchampion\source\repos\sidequests\affiliate-kit-spec\` → `C:\Users\rchampion\source\repos\affiliate-sites\`
- Create: `docs/` directory inside the moved repo
- Move: `2026-05-12-affiliate-kit-design.md` → `docs/2026-05-12-affiliate-kit-design.md`
- Move: `2026-05-12-affiliate-kit-plan-phase-1.md` → `docs/2026-05-12-affiliate-kit-plan-phase-1.md`

- [ ] **Step 1: Confirm no uncommitted changes**

Run: `cd C:/Users/rchampion/source/repos/sidequests/affiliate-kit-spec && git status`
Expected: `nothing to commit, working tree clean`

If there are uncommitted changes, commit them first or stash. Do not proceed without a clean tree.

- [ ] **Step 2: Move the directory**

Run (PowerShell): `Move-Item "C:\Users\rchampion\source\repos\sidequests\affiliate-kit-spec" "C:\Users\rchampion\source\repos\affiliate-sites"`
Expected: no output, directory moved.

Verify: `Test-Path "C:\Users\rchampion\source\repos\affiliate-sites\.git"` returns `True`

- [ ] **Step 3: Create `docs/` and move spec + plan into it**

Run (PowerShell, from new location):
```powershell
cd C:\Users\rchampion\source\repos\affiliate-sites
New-Item -ItemType Directory -Path docs
git mv "2026-05-12-affiliate-kit-design.md" "docs/2026-05-12-affiliate-kit-design.md"
git mv "2026-05-12-affiliate-kit-plan-phase-1.md" "docs/2026-05-12-affiliate-kit-plan-phase-1.md"
```

Expected: both files moved under `docs/`.

- [ ] **Step 4: Update the README to point at the new doc location**

Replace the existing `README.md` content:

```markdown
# affiliate-kit

A Claude Code plugin and Astro monorepo for operating 5 affiliate sites with minimal active overhead.

## Status

**Phase 1 in progress.** Foundation + bootstrap command.

## Docs

- [Design spec](docs/2026-05-12-affiliate-kit-design.md)
- [Phase 1 plan](docs/2026-05-12-affiliate-kit-plan-phase-1.md)

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
```

- [ ] **Step 5: Commit and push**

Run:
```bash
git add -A
git commit -m "refactor: move repo to ~/source/repos/affiliate-sites/, organize docs/"
git push
```

Expected: push succeeds. The repo on GitHub now has `docs/` containing the spec and plan, plus an updated README.

---

### Task 2: Initialize pnpm workspace and monorepo root files

**Files:**
- Create: `package.json` (root)
- Create: `pnpm-workspace.yaml`
- Create: `.nvmrc`
- Create: `tsconfig.base.json`
- Create: `COMMANDS.md`
- Create: `CLAUDE.md`
- Modify: `.gitignore` (add monorepo entries)

- [ ] **Step 1: Write `.nvmrc`**

File: `C:\Users\rchampion\source\repos\affiliate-sites\.nvmrc`

```
20
```

- [ ] **Step 2: Write root `package.json`**

File: `C:\Users\rchampion\source\repos\affiliate-sites\package.json`

```json
{
  "name": "affiliate-sites",
  "version": "0.0.1",
  "private": true,
  "packageManager": "pnpm@9.0.0",
  "engines": {
    "node": ">=20"
  },
  "scripts": {
    "build": "pnpm -r --if-present build",
    "dev": "pnpm -r --if-present --parallel dev",
    "test": "pnpm -r --if-present test",
    "typecheck": "pnpm -r --if-present typecheck",
    "lint": "pnpm -r --if-present lint",
    "install-plugin": "pwsh ./scripts/install-plugin.ps1"
  },
  "devDependencies": {
    "typescript": "^5.4.0"
  }
}
```

- [ ] **Step 3: Write `pnpm-workspace.yaml`**

File: `C:\Users\rchampion\source\repos\affiliate-sites\pnpm-workspace.yaml`

```yaml
packages:
  - "packages/*"
  - "sites/*"
  - "templates/*"
  - "tools/*"
  - "workers/*"
```

- [ ] **Step 4: Write `tsconfig.base.json`**

File: `C:\Users\rchampion\source\repos\affiliate-sites\tsconfig.base.json`

```json
{
  "compilerOptions": {
    "target": "ES2022",
    "module": "ESNext",
    "moduleResolution": "Bundler",
    "lib": ["ES2022", "DOM"],
    "strict": true,
    "noImplicitAny": true,
    "noUnusedLocals": true,
    "noUnusedParameters": true,
    "noFallthroughCasesInSwitch": true,
    "esModuleInterop": true,
    "forceConsistentCasingInFileNames": true,
    "skipLibCheck": true,
    "resolveJsonModule": true,
    "isolatedModules": true,
    "verbatimModuleSyntax": false,
    "declaration": true,
    "sourceMap": true
  }
}
```

- [ ] **Step 5: Replace the existing `.gitignore` with the monorepo version**

File: `C:\Users\rchampion\source\repos\affiliate-sites\.gitignore`

```
# Dependencies
node_modules/
.pnpm-store/

# Build output
dist/
.astro/
build/
.output/

# Astro
.cache/

# Env / secrets
.env
.env.local
.env.*.local
config.json
*-key.json
gsc-key.json
.wrangler/

# OS / editor
.DS_Store
*.log
.vscode/
.idea/
Thumbs.db
```

- [ ] **Step 6: Write `COMMANDS.md` (the persistent cheatsheet)**

File: `C:\Users\rchampion\source\repos\affiliate-sites\COMMANDS.md`

```markdown
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

Phase 1 (foundation + `/aff-bootstrap`): in progress.
Phase 2 (content commands, status engine, cycle orchestrator): not started — only `/aff-bootstrap` works today.
```

- [ ] **Step 7: Write `CLAUDE.md` (monorepo conventions for Claude)**

File: `C:\Users\rchampion\source\repos\affiliate-sites\CLAUDE.md`

```markdown
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
- One hero site (`mywildlifecam`) gets the real effort. Four satellites (`detailerpicks`, `fussybean`, `starteraquarium`, `gameovergear`) get the playbook on a slower clock. Don't suggest equal effort across all 5.
- Quarterly cycle = 5 new reviews + refresh sweep, per site, every 90 days.

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
- Default snarky-but-friendly. `--spicy` flag for unhinged mode. Configurable in `~/.claude/plugins/affiliate-kit/config.json`.
- Every command's output ends with a `Next:` block telling the user what to do next.

## When in doubt
- Check the spec at `docs/2026-05-12-affiliate-kit-design.md`.
- Check the active plan at `docs/2026-05-12-affiliate-kit-plan-phase-1.md`.
```

- [ ] **Step 8: Run `pnpm install` to lock the workspace shape**

Run: `cd C:/Users/rchampion/source/repos/affiliate-sites && pnpm install`
Expected: "Done in Xs" — generates `pnpm-lock.yaml` and `node_modules/.pnpm/`. No workspace packages yet, so install is fast.

- [ ] **Step 9: Commit and push**

Run:
```bash
git add -A
git commit -m "feat: initialize pnpm workspace, root configs, docs"
git push
```

Expected: push succeeds.

---

## Phase B — Shared packages

### Task 3: Create `packages/shared-styles` (design tokens)

**Files:**
- Create: `packages/shared-styles/package.json`
- Create: `packages/shared-styles/src/tokens.css`

- [ ] **Step 1: Write `packages/shared-styles/package.json`**

File: `C:\Users\rchampion\source\repos\affiliate-sites\packages\shared-styles\package.json`

```json
{
  "name": "@affkit/shared-styles",
  "version": "0.0.1",
  "private": true,
  "type": "module",
  "main": "./src/tokens.css",
  "exports": {
    "./tokens.css": "./src/tokens.css"
  }
}
```

- [ ] **Step 2: Write `packages/shared-styles/src/tokens.css`**

File: `C:\Users\rchampion\source\repos\affiliate-sites\packages\shared-styles\src\tokens.css`

```css
:root {
  /* Color — neutrals */
  --color-bg: #ffffff;
  --color-fg: #1a1a1a;
  --color-muted: #6b7280;
  --color-border: #e5e7eb;
  --color-surface: #f9fafb;

  /* Color — brand (override per site) */
  --color-brand: #2563eb;
  --color-brand-fg: #ffffff;
  --color-brand-muted: #93c5fd;

  /* Color — semantic */
  --color-success: #10b981;
  --color-warning: #f59e0b;
  --color-danger: #ef4444;

  /* Typography */
  --font-sans: ui-sans-serif, system-ui, -apple-system, "Segoe UI", Roboto, sans-serif;
  --font-serif: ui-serif, Georgia, "Times New Roman", serif;
  --font-mono: ui-monospace, "Cascadia Code", "Source Code Pro", monospace;

  /* Type scale */
  --text-xs: 0.75rem;
  --text-sm: 0.875rem;
  --text-base: 1rem;
  --text-lg: 1.125rem;
  --text-xl: 1.25rem;
  --text-2xl: 1.5rem;
  --text-3xl: 1.875rem;
  --text-4xl: 2.25rem;

  /* Spacing */
  --space-1: 0.25rem;
  --space-2: 0.5rem;
  --space-3: 0.75rem;
  --space-4: 1rem;
  --space-6: 1.5rem;
  --space-8: 2rem;
  --space-12: 3rem;
  --space-16: 4rem;

  /* Layout */
  --container-max: 72rem;
  --content-max: 42rem;
  --radius-sm: 0.25rem;
  --radius-md: 0.5rem;
  --radius-lg: 0.75rem;

  /* Shadows */
  --shadow-sm: 0 1px 2px 0 rgb(0 0 0 / 0.05);
  --shadow-md: 0 4px 6px -1px rgb(0 0 0 / 0.1);
  --shadow-lg: 0 10px 15px -3px rgb(0 0 0 / 0.1);
}

@media (prefers-color-scheme: dark) {
  :root {
    --color-bg: #0a0a0a;
    --color-fg: #f5f5f5;
    --color-muted: #9ca3af;
    --color-border: #262626;
    --color-surface: #171717;
  }
}

* { box-sizing: border-box; }
html { font-family: var(--font-sans); color: var(--color-fg); background: var(--color-bg); }
body { margin: 0; line-height: 1.6; }
img, picture, video { max-width: 100%; display: block; }
```

- [ ] **Step 3: Install workspace package**

Run: `cd C:/Users/rchampion/source/repos/affiliate-sites && pnpm install`
Expected: `@affkit/shared-styles` registered in the workspace.

- [ ] **Step 4: Commit**

Run:
```bash
git add packages/shared-styles
git commit -m "feat(shared-styles): design tokens package"
```

---

### Task 4: Create `packages/shared-utils` and implement `cloaked-link` helper (TDD)

The cloaked-link helper generates `/go/<site>/<slug>` URLs that the Worker resolves to real affiliate URLs. The function is small but load-bearing — it's the entry point of every affiliate click on every page.

**Files:**
- Create: `packages/shared-utils/package.json`
- Create: `packages/shared-utils/tsconfig.json`
- Create: `packages/shared-utils/vitest.config.ts`
- Create: `packages/shared-utils/src/index.ts`
- Create: `packages/shared-utils/src/cloaked-link.ts`
- Create: `packages/shared-utils/test/cloaked-link.test.ts`

- [ ] **Step 1: Write `package.json`**

File: `C:\Users\rchampion\source\repos\affiliate-sites\packages\shared-utils\package.json`

```json
{
  "name": "@affkit/shared-utils",
  "version": "0.0.1",
  "private": true,
  "type": "module",
  "main": "./src/index.ts",
  "exports": {
    ".": "./src/index.ts",
    "./cloaked-link": "./src/cloaked-link.ts",
    "./schema": "./src/schema.ts",
    "./indexnow": "./src/indexnow.ts"
  },
  "scripts": {
    "test": "vitest run",
    "test:watch": "vitest",
    "typecheck": "tsc --noEmit"
  },
  "devDependencies": {
    "typescript": "^5.4.0",
    "vitest": "^1.6.0"
  }
}
```

- [ ] **Step 2: Write `tsconfig.json`**

File: `C:\Users\rchampion\source\repos\affiliate-sites\packages\shared-utils\tsconfig.json`

```json
{
  "extends": "../../tsconfig.base.json",
  "compilerOptions": {
    "outDir": "./dist",
    "rootDir": "./src",
    "types": ["vitest/globals"]
  },
  "include": ["src/**/*", "test/**/*"]
}
```

- [ ] **Step 3: Write `vitest.config.ts`**

File: `C:\Users\rchampion\source\repos\affiliate-sites\packages\shared-utils\vitest.config.ts`

```ts
import { defineConfig } from "vitest/config";

export default defineConfig({
  test: {
    globals: true,
    environment: "node",
    include: ["test/**/*.test.ts"],
  },
});
```

- [ ] **Step 4: Install workspace dependencies**

Run: `cd C:/Users/rchampion/source/repos/affiliate-sites && pnpm install`
Expected: vitest and typescript install under `packages/shared-utils/node_modules` (via the pnpm store).

- [ ] **Step 5: Write failing tests for `cloakedLink`**

File: `C:\Users\rchampion\source\repos\affiliate-sites\packages\shared-utils\test\cloaked-link.test.ts`

```ts
import { describe, it, expect } from "vitest";
import { cloakedLink, sanitizeSlug } from "../src/cloaked-link";

describe("sanitizeSlug", () => {
  it("lowercases and dashes spaces", () => {
    expect(sanitizeSlug("Reconyx HC600")).toBe("reconyx-hc600");
  });

  it("strips non-alphanumerics other than dash", () => {
    expect(sanitizeSlug("Breville Barista Express® (BES870)")).toBe(
      "breville-barista-express-bes870"
    );
  });

  it("collapses repeated dashes", () => {
    expect(sanitizeSlug("foo --  bar")).toBe("foo-bar");
  });

  it("trims leading and trailing dashes", () => {
    expect(sanitizeSlug("--foo--")).toBe("foo");
  });

  it("rejects empty input", () => {
    expect(() => sanitizeSlug("")).toThrow("slug cannot be empty");
    expect(() => sanitizeSlug("   ")).toThrow("slug cannot be empty");
  });
});

describe("cloakedLink", () => {
  it("builds a /go/<site>/<slug> path", () => {
    expect(cloakedLink({ site: "mywildlifecam", slug: "reconyx-hc600" })).toBe(
      "/go/mywildlifecam/reconyx-hc600"
    );
  });

  it("sanitizes the slug input", () => {
    expect(cloakedLink({ site: "mywildlifecam", slug: "Reconyx HC600" })).toBe(
      "/go/mywildlifecam/reconyx-hc600"
    );
  });

  it("accepts an optional source tag and appends it as a query param", () => {
    expect(
      cloakedLink({
        site: "fussybean",
        slug: "breville-bambino",
        source: "comparison-table",
      })
    ).toBe("/go/fussybean/breville-bambino?src=comparison-table");
  });

  it("sanitizes the source tag", () => {
    expect(
      cloakedLink({
        site: "fussybean",
        slug: "breville-bambino",
        source: "Comparison Table!",
      })
    ).toBe("/go/fussybean/breville-bambino?src=comparison-table");
  });

  it("rejects empty site", () => {
    expect(() => cloakedLink({ site: "", slug: "x" })).toThrow(
      "site cannot be empty"
    );
  });
});
```

- [ ] **Step 6: Run the tests to confirm they fail**

Run: `cd C:/Users/rchampion/source/repos/affiliate-sites/packages/shared-utils && pnpm test`
Expected: tests fail with `Cannot find module '../src/cloaked-link'` (file doesn't exist yet).

- [ ] **Step 7: Implement `cloaked-link.ts`**

File: `C:\Users\rchampion\source\repos\affiliate-sites\packages\shared-utils\src\cloaked-link.ts`

```ts
export interface CloakedLinkOptions {
  site: string;
  slug: string;
  source?: string;
}

export function sanitizeSlug(input: string): string {
  const trimmed = input.trim();
  if (trimmed.length === 0) {
    throw new Error("slug cannot be empty");
  }
  const slug = trimmed
    .toLowerCase()
    .replace(/[^a-z0-9]+/g, "-")
    .replace(/-+/g, "-")
    .replace(/^-|-$/g, "");
  if (slug.length === 0) {
    throw new Error("slug cannot be empty");
  }
  return slug;
}

export function cloakedLink(options: CloakedLinkOptions): string {
  if (options.site.trim().length === 0) {
    throw new Error("site cannot be empty");
  }
  const site = sanitizeSlug(options.site);
  const slug = sanitizeSlug(options.slug);
  const base = `/go/${site}/${slug}`;
  if (options.source) {
    const src = sanitizeSlug(options.source);
    return `${base}?src=${src}`;
  }
  return base;
}
```

- [ ] **Step 8: Write `src/index.ts` re-exporting**

File: `C:\Users\rchampion\source\repos\affiliate-sites\packages\shared-utils\src\index.ts`

```ts
export * from "./cloaked-link";
```

(`schema.ts` and `indexnow.ts` will be added in later tasks; re-exports updated then.)

- [ ] **Step 9: Run the tests to confirm they pass**

Run: `cd C:/Users/rchampion/source/repos/affiliate-sites/packages/shared-utils && pnpm test`
Expected: all 9 tests pass.

- [ ] **Step 10: Run typecheck**

Run: `pnpm typecheck`
Expected: no errors.

- [ ] **Step 11: Commit**

Run:
```bash
cd C:/Users/rchampion/source/repos/affiliate-sites
git add packages/shared-utils
git commit -m "feat(shared-utils): cloakedLink helper with slug sanitization"
```

---

### Task 5: Add `schema.ts` JSON-LD generators to shared-utils (TDD)

JSON-LD generators for Product, Review, and FAQPage. These get injected into review pages for rich snippet eligibility.

**Files:**
- Create: `packages/shared-utils/src/schema.ts`
- Create: `packages/shared-utils/test/schema.test.ts`
- Modify: `packages/shared-utils/src/index.ts`

- [ ] **Step 1: Write failing tests**

File: `C:\Users\rchampion\source\repos\affiliate-sites\packages\shared-utils\test\schema.test.ts`

```ts
import { describe, it, expect } from "vitest";
import { productSchema, reviewSchema, faqSchema } from "../src/schema";

describe("productSchema", () => {
  it("emits a Product JSON-LD object", () => {
    const result = productSchema({
      name: "Reconyx HC600",
      brand: "Reconyx",
      sku: "HC600",
      image: "https://example.com/hc600.jpg",
      description: "A trail camera",
      offerUrl: "https://example.com/buy",
      price: 549.99,
      currency: "USD",
      availability: "InStock",
    });
    expect(result["@context"]).toBe("https://schema.org");
    expect(result["@type"]).toBe("Product");
    expect(result.name).toBe("Reconyx HC600");
    expect(result.brand).toEqual({ "@type": "Brand", name: "Reconyx" });
    expect(result.sku).toBe("HC600");
    expect(result.image).toBe("https://example.com/hc600.jpg");
    expect(result.offers).toEqual({
      "@type": "Offer",
      url: "https://example.com/buy",
      priceCurrency: "USD",
      price: "549.99",
      availability: "https://schema.org/InStock",
    });
  });

  it("omits offers when no offer info given", () => {
    const result = productSchema({
      name: "X",
      brand: "Y",
      sku: "Z",
      image: "img",
      description: "d",
    });
    expect(result.offers).toBeUndefined();
  });
});

describe("reviewSchema", () => {
  it("emits a Review JSON-LD object with a 5-star scale by default", () => {
    const result = reviewSchema({
      productName: "Reconyx HC600",
      rating: 4.5,
      author: "Ray Champion",
      datePublished: "2026-05-12",
      reviewBody: "Solid trail cam, fires too easily in wind.",
    });
    expect(result["@context"]).toBe("https://schema.org");
    expect(result["@type"]).toBe("Review");
    expect(result.itemReviewed).toEqual({
      "@type": "Product",
      name: "Reconyx HC600",
    });
    expect(result.reviewRating).toEqual({
      "@type": "Rating",
      ratingValue: "4.5",
      bestRating: "5",
      worstRating: "1",
    });
    expect(result.author).toEqual({ "@type": "Person", name: "Ray Champion" });
    expect(result.datePublished).toBe("2026-05-12");
    expect(result.reviewBody).toBe("Solid trail cam, fires too easily in wind.");
  });

  it("rejects ratings outside [1, 5]", () => {
    expect(() =>
      reviewSchema({
        productName: "X",
        rating: 6,
        author: "A",
        datePublished: "2026-01-01",
        reviewBody: "",
      })
    ).toThrow("rating must be between 1 and 5");
    expect(() =>
      reviewSchema({
        productName: "X",
        rating: 0,
        author: "A",
        datePublished: "2026-01-01",
        reviewBody: "",
      })
    ).toThrow("rating must be between 1 and 5");
  });
});

describe("faqSchema", () => {
  it("emits an FAQPage with Question/Answer pairs", () => {
    const result = faqSchema([
      { q: "Is it weatherproof?", a: "Yes, IP66 rated." },
      { q: "Does it use cellular?", a: "No, SD card only." },
    ]);
    expect(result["@context"]).toBe("https://schema.org");
    expect(result["@type"]).toBe("FAQPage");
    expect(result.mainEntity).toHaveLength(2);
    expect(result.mainEntity[0]).toEqual({
      "@type": "Question",
      name: "Is it weatherproof?",
      acceptedAnswer: { "@type": "Answer", text: "Yes, IP66 rated." },
    });
  });

  it("rejects an empty FAQ list", () => {
    expect(() => faqSchema([])).toThrow("FAQ list cannot be empty");
  });
});
```

- [ ] **Step 2: Run the tests to confirm they fail**

Run: `cd C:/Users/rchampion/source/repos/affiliate-sites/packages/shared-utils && pnpm test`
Expected: tests fail because `../src/schema` doesn't exist.

- [ ] **Step 3: Implement `schema.ts`**

File: `C:\Users\rchampion\source\repos\affiliate-sites\packages\shared-utils\src\schema.ts`

```ts
export type Availability = "InStock" | "OutOfStock" | "PreOrder" | "Discontinued";

export interface ProductSchemaInput {
  name: string;
  brand: string;
  sku: string;
  image: string;
  description: string;
  offerUrl?: string;
  price?: number;
  currency?: string;
  availability?: Availability;
}

export interface ReviewSchemaInput {
  productName: string;
  rating: number;
  author: string;
  datePublished: string;
  reviewBody: string;
}

export interface FaqEntry {
  q: string;
  a: string;
}

export function productSchema(input: ProductSchemaInput): Record<string, unknown> {
  const result: Record<string, unknown> = {
    "@context": "https://schema.org",
    "@type": "Product",
    name: input.name,
    brand: { "@type": "Brand", name: input.brand },
    sku: input.sku,
    image: input.image,
    description: input.description,
  };

  if (input.offerUrl && input.price !== undefined && input.currency) {
    result.offers = {
      "@type": "Offer",
      url: input.offerUrl,
      priceCurrency: input.currency,
      price: input.price.toFixed(2),
      availability: `https://schema.org/${input.availability ?? "InStock"}`,
    };
  }

  return result;
}

export function reviewSchema(input: ReviewSchemaInput): Record<string, unknown> {
  if (input.rating < 1 || input.rating > 5) {
    throw new Error("rating must be between 1 and 5");
  }

  return {
    "@context": "https://schema.org",
    "@type": "Review",
    itemReviewed: { "@type": "Product", name: input.productName },
    reviewRating: {
      "@type": "Rating",
      ratingValue: input.rating.toString(),
      bestRating: "5",
      worstRating: "1",
    },
    author: { "@type": "Person", name: input.author },
    datePublished: input.datePublished,
    reviewBody: input.reviewBody,
  };
}

export function faqSchema(entries: FaqEntry[]): Record<string, unknown> {
  if (entries.length === 0) {
    throw new Error("FAQ list cannot be empty");
  }
  return {
    "@context": "https://schema.org",
    "@type": "FAQPage",
    mainEntity: entries.map((e) => ({
      "@type": "Question",
      name: e.q,
      acceptedAnswer: { "@type": "Answer", text: e.a },
    })),
  };
}
```

- [ ] **Step 4: Update `src/index.ts`**

File: `C:\Users\rchampion\source\repos\affiliate-sites\packages\shared-utils\src\index.ts`

```ts
export * from "./cloaked-link";
export * from "./schema";
```

- [ ] **Step 5: Run tests**

Run: `pnpm test`
Expected: all tests pass (the cloaked-link tests stay green, schema tests now pass).

- [ ] **Step 6: Commit**

Run:
```bash
git add packages/shared-utils
git commit -m "feat(shared-utils): JSON-LD schema generators for Product, Review, FAQPage"
```

---

### Task 6: Add `indexnow.ts` to shared-utils (TDD)

IndexNow client that pings search engines (Google + Bing + Yandex via the IndexNow protocol) when a URL is published or updated.

**Files:**
- Create: `packages/shared-utils/src/indexnow.ts`
- Create: `packages/shared-utils/test/indexnow.test.ts`
- Modify: `packages/shared-utils/src/index.ts`

- [ ] **Step 1: Write failing tests**

File: `C:\Users\rchampion\source\repos\affiliate-sites\packages\shared-utils\test\indexnow.test.ts`

```ts
import { describe, it, expect, vi, beforeEach } from "vitest";
import { submitToIndexNow } from "../src/indexnow";

describe("submitToIndexNow", () => {
  beforeEach(() => {
    vi.restoreAllMocks();
  });

  it("posts a single-URL payload to api.indexnow.org", async () => {
    const fetchMock = vi
      .spyOn(globalThis, "fetch")
      .mockResolvedValue(new Response(null, { status: 200 }));
    const result = await submitToIndexNow({
      host: "mywildlifecam.fyi",
      key: "abc123",
      keyLocation: "https://mywildlifecam.fyi/abc123.txt",
      urls: ["https://mywildlifecam.fyi/reviews/reconyx-hc600"],
    });
    expect(result.ok).toBe(true);
    expect(result.status).toBe(200);
    expect(fetchMock).toHaveBeenCalledOnce();
    const [url, init] = fetchMock.mock.calls[0];
    expect(url).toBe("https://api.indexnow.org/IndexNow");
    expect(init?.method).toBe("POST");
    expect(init?.headers).toMatchObject({
      "Content-Type": "application/json; charset=utf-8",
    });
    expect(JSON.parse(init?.body as string)).toEqual({
      host: "mywildlifecam.fyi",
      key: "abc123",
      keyLocation: "https://mywildlifecam.fyi/abc123.txt",
      urlList: ["https://mywildlifecam.fyi/reviews/reconyx-hc600"],
    });
  });

  it("returns ok=false when the API responds with 4xx", async () => {
    vi.spyOn(globalThis, "fetch").mockResolvedValue(
      new Response("bad request", { status: 422 })
    );
    const result = await submitToIndexNow({
      host: "mywildlifecam.fyi",
      key: "abc123",
      keyLocation: "https://mywildlifecam.fyi/abc123.txt",
      urls: ["https://mywildlifecam.fyi/x"],
    });
    expect(result.ok).toBe(false);
    expect(result.status).toBe(422);
  });

  it("rejects an empty URL list", async () => {
    await expect(
      submitToIndexNow({
        host: "mywildlifecam.fyi",
        key: "abc123",
        keyLocation: "https://mywildlifecam.fyi/abc123.txt",
        urls: [],
      })
    ).rejects.toThrow("urls cannot be empty");
  });

  it("rejects more than 10000 URLs in one call", async () => {
    const urls = Array.from(
      { length: 10001 },
      (_, i) => `https://mywildlifecam.fyi/p${i}`
    );
    await expect(
      submitToIndexNow({
        host: "mywildlifecam.fyi",
        key: "abc123",
        keyLocation: "https://mywildlifecam.fyi/abc123.txt",
        urls,
      })
    ).rejects.toThrow("urls cannot exceed 10000 entries per request");
  });
});
```

- [ ] **Step 2: Run tests to confirm they fail**

Run: `pnpm test`
Expected: tests fail because `../src/indexnow` doesn't exist.

- [ ] **Step 3: Implement `indexnow.ts`**

File: `C:\Users\rchampion\source\repos\affiliate-sites\packages\shared-utils\src\indexnow.ts`

```ts
export interface IndexNowInput {
  host: string;
  key: string;
  keyLocation: string;
  urls: string[];
}

export interface IndexNowResult {
  ok: boolean;
  status: number;
}

const INDEXNOW_ENDPOINT = "https://api.indexnow.org/IndexNow";

export async function submitToIndexNow(input: IndexNowInput): Promise<IndexNowResult> {
  if (input.urls.length === 0) {
    throw new Error("urls cannot be empty");
  }
  if (input.urls.length > 10000) {
    throw new Error("urls cannot exceed 10000 entries per request");
  }

  const response = await fetch(INDEXNOW_ENDPOINT, {
    method: "POST",
    headers: { "Content-Type": "application/json; charset=utf-8" },
    body: JSON.stringify({
      host: input.host,
      key: input.key,
      keyLocation: input.keyLocation,
      urlList: input.urls,
    }),
  });

  return { ok: response.ok, status: response.status };
}
```

- [ ] **Step 4: Update `src/index.ts`**

File: `C:\Users\rchampion\source\repos\affiliate-sites\packages\shared-utils\src\index.ts`

```ts
export * from "./cloaked-link";
export * from "./schema";
export * from "./indexnow";
```

- [ ] **Step 5: Run tests**

Run: `pnpm test`
Expected: all tests pass.

- [ ] **Step 6: Commit**

Run:
```bash
git add packages/shared-utils
git commit -m "feat(shared-utils): IndexNow submission client"
```

---

### Task 7: Create `packages/shared-ui` with base Astro components

These are the building blocks every site uses: layout, CTA button, comparison table, hero, disclosure banner.

**Files:**
- Create: `packages/shared-ui/package.json`
- Create: `packages/shared-ui/tsconfig.json`
- Create: `packages/shared-ui/src/components/BaseLayout.astro`
- Create: `packages/shared-ui/src/components/CTA.astro`
- Create: `packages/shared-ui/src/components/ComparisonTable.astro`
- Create: `packages/shared-ui/src/components/Hero.astro`
- Create: `packages/shared-ui/src/components/AffiliateDisclosure.astro`

- [ ] **Step 1: Write `package.json`**

File: `C:\Users\rchampion\source\repos\affiliate-sites\packages\shared-ui\package.json`

```json
{
  "name": "@affkit/shared-ui",
  "version": "0.0.1",
  "private": true,
  "type": "module",
  "exports": {
    "./BaseLayout.astro": "./src/components/BaseLayout.astro",
    "./CTA.astro": "./src/components/CTA.astro",
    "./ComparisonTable.astro": "./src/components/ComparisonTable.astro",
    "./Hero.astro": "./src/components/Hero.astro",
    "./AffiliateDisclosure.astro": "./src/components/AffiliateDisclosure.astro"
  },
  "dependencies": {
    "@affkit/shared-styles": "workspace:*"
  },
  "peerDependencies": {
    "astro": "^4.0.0"
  },
  "devDependencies": {
    "astro": "^4.16.0"
  }
}
```

- [ ] **Step 2: Write `tsconfig.json`**

File: `C:\Users\rchampion\source\repos\affiliate-sites\packages\shared-ui\tsconfig.json`

```json
{
  "extends": "../../tsconfig.base.json",
  "include": ["src/**/*"]
}
```

- [ ] **Step 3: Write `BaseLayout.astro`**

File: `C:\Users\rchampion\source\repos\affiliate-sites\packages\shared-ui\src\components\BaseLayout.astro`

```astro
---
import "@affkit/shared-styles/tokens.css";

interface Props {
  title: string;
  description: string;
  canonical?: string;
  siteName: string;
}

const { title, description, canonical, siteName } = Astro.props;
const fullTitle = title.includes(siteName) ? title : `${title} — ${siteName}`;
---
<!doctype html>
<html lang="en">
<head>
  <meta charset="UTF-8" />
  <meta name="viewport" content="width=device-width, initial-scale=1.0" />
  <meta name="description" content={description} />
  {canonical && <link rel="canonical" href={canonical} />}
  <title>{fullTitle}</title>
  <link rel="icon" type="image/svg+xml" href="/favicon.svg" />
  <meta property="og:title" content={fullTitle} />
  <meta property="og:description" content={description} />
  {canonical && <meta property="og:url" content={canonical} />}
  <meta property="og:type" content="website" />
</head>
<body>
  <slot />
</body>
</html>

<style>
  body {
    max-width: var(--container-max);
    margin: 0 auto;
    padding: var(--space-4);
  }
</style>
```

- [ ] **Step 4: Write `CTA.astro`**

File: `C:\Users\rchampion\source\repos\affiliate-sites\packages\shared-ui\src\components\CTA.astro`

```astro
---
interface Props {
  href: string;
  variant?: "primary" | "secondary";
  external?: boolean;
}

const { href, variant = "primary", external = true } = Astro.props;
---
<a
  href={href}
  class:list={["cta", variant]}
  rel={external ? "nofollow sponsored noopener" : undefined}
  target={external ? "_blank" : undefined}
>
  <slot />
</a>

<style>
  .cta {
    display: inline-block;
    padding: var(--space-3) var(--space-6);
    border-radius: var(--radius-md);
    font-weight: 600;
    text-decoration: none;
    transition: filter 150ms ease;
  }
  .cta:hover { filter: brightness(0.9); }
  .primary {
    background: var(--color-brand);
    color: var(--color-brand-fg);
  }
  .secondary {
    background: var(--color-surface);
    color: var(--color-fg);
    border: 1px solid var(--color-border);
  }
</style>
```

- [ ] **Step 5: Write `Hero.astro`**

File: `C:\Users\rchampion\source\repos\affiliate-sites\packages\shared-ui\src\components\Hero.astro`

```astro
---
interface Props {
  title: string;
  tagline?: string;
}
const { title, tagline } = Astro.props;
---
<section class="hero">
  <h1>{title}</h1>
  {tagline && <p class="tagline">{tagline}</p>}
</section>

<style>
  .hero {
    padding: var(--space-12) 0 var(--space-8);
    text-align: center;
  }
  .hero h1 {
    font-size: var(--text-4xl);
    margin: 0 0 var(--space-4);
    line-height: 1.1;
  }
  .tagline {
    color: var(--color-muted);
    font-size: var(--text-lg);
    margin: 0;
  }
</style>
```

- [ ] **Step 6: Write `ComparisonTable.astro`**

File: `C:\Users\rchampion\source\repos\affiliate-sites\packages\shared-ui\src\components\ComparisonTable.astro`

```astro
---
interface Row {
  product: string;
  values: string[];
  ctaHref?: string;
}

interface Props {
  headers: string[];     // first header is product column
  rows: Row[];
}

const { headers, rows } = Astro.props;
---
<div class="table-wrapper">
  <table>
    <thead>
      <tr>{headers.map((h) => <th>{h}</th>)}{rows.some(r => r.ctaHref) && <th>Buy</th>}</tr>
    </thead>
    <tbody>
      {rows.map((row) => (
        <tr>
          <td class="product">{row.product}</td>
          {row.values.map((v) => <td>{v}</td>)}
          {row.ctaHref && (
            <td>
              <a href={row.ctaHref} rel="nofollow sponsored noopener" target="_blank">
                Check price
              </a>
            </td>
          )}
        </tr>
      ))}
    </tbody>
  </table>
</div>

<style>
  .table-wrapper {
    overflow-x: auto;
    margin: var(--space-6) 0;
  }
  table {
    border-collapse: collapse;
    width: 100%;
    font-size: var(--text-sm);
  }
  th, td {
    padding: var(--space-2) var(--space-3);
    border-bottom: 1px solid var(--color-border);
    text-align: left;
  }
  th {
    background: var(--color-surface);
    font-weight: 600;
  }
  .product { font-weight: 600; }
</style>
```

- [ ] **Step 7: Write `AffiliateDisclosure.astro`**

File: `C:\Users\rchampion\source\repos\affiliate-sites\packages\shared-ui\src\components\AffiliateDisclosure.astro`

```astro
---
interface Props {
  siteName: string;
}
const { siteName } = Astro.props;
---
<aside class="disclosure">
  <strong>Affiliate disclosure:</strong> {siteName} is a participant in affiliate
  programs, including the Amazon Services LLC Associates Program. We may earn a
  commission from qualifying purchases made through links on this site, at no
  additional cost to you.
</aside>

<style>
  .disclosure {
    background: var(--color-surface);
    border-left: 3px solid var(--color-muted);
    padding: var(--space-3) var(--space-4);
    margin: var(--space-6) 0;
    font-size: var(--text-sm);
    color: var(--color-muted);
    border-radius: var(--radius-sm);
  }
</style>
```

- [ ] **Step 8: Install workspace**

Run: `cd C:/Users/rchampion/source/repos/affiliate-sites && pnpm install`
Expected: `@affkit/shared-ui` registered, astro installs in shared-ui's devDeps.

- [ ] **Step 9: Commit**

Run:
```bash
git add packages/shared-ui
git commit -m "feat(shared-ui): base Astro components (BaseLayout, CTA, Hero, ComparisonTable, AffiliateDisclosure)"
```

---

## Phase C — Site template

### Task 8: Create the Astro site template skeleton

The template is the source `/aff-bootstrap` copies from. Every site starts as a copy of this.

**Files:**
- Create: `templates/site-template/package.json`
- Create: `templates/site-template/astro.config.mjs`
- Create: `templates/site-template/tsconfig.json`
- Create: `templates/site-template/public/robots.txt`
- Create: `templates/site-template/public/favicon.svg`
- Create: `templates/site-template/src/content/config.ts`

- [ ] **Step 1: Write `package.json`**

File: `C:\Users\rchampion\source\repos\affiliate-sites\templates\site-template\package.json`

```json
{
  "name": "@affkit/site-template",
  "version": "0.0.1",
  "private": true,
  "type": "module",
  "scripts": {
    "dev": "astro dev",
    "build": "astro build",
    "preview": "astro preview",
    "typecheck": "astro check"
  },
  "dependencies": {
    "@affkit/shared-styles": "workspace:*",
    "@affkit/shared-ui": "workspace:*",
    "@affkit/shared-utils": "workspace:*",
    "astro": "^4.16.0"
  },
  "devDependencies": {
    "@astrojs/check": "^0.9.0",
    "typescript": "^5.4.0"
  }
}
```

- [ ] **Step 2: Write `astro.config.mjs`**

File: `C:\Users\rchampion\source\repos\affiliate-sites\templates\site-template\astro.config.mjs`

```js
import { defineConfig } from "astro/config";

// site URL is overridden per-site at build time via SITE env var
const site = process.env.SITE_URL ?? "https://example.com";

export default defineConfig({
  site,
  output: "static",
  build: {
    inlineStylesheets: "auto",
  },
  prefetch: {
    prefetchAll: false,
    defaultStrategy: "hover",
  },
});
```

- [ ] **Step 3: Write `tsconfig.json`**

File: `C:\Users\rchampion\source\repos\affiliate-sites\templates\site-template\tsconfig.json`

```json
{
  "extends": "astro/tsconfigs/strict",
  "include": [".astro/types.d.ts", "**/*"],
  "exclude": ["dist"]
}
```

- [ ] **Step 4: Write `public/robots.txt`**

File: `C:\Users\rchampion\source\repos\affiliate-sites\templates\site-template\public\robots.txt`

```
User-agent: *
Allow: /
Disallow: /go/

Sitemap: __SITE_URL__/sitemap-index.xml
```

(The `__SITE_URL__` placeholder is replaced by `/aff-bootstrap` when copying the template.)

- [ ] **Step 5: Write `public/favicon.svg`**

File: `C:\Users\rchampion\source\repos\affiliate-sites\templates\site-template\public\favicon.svg`

```svg
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 32 32">
  <rect width="32" height="32" rx="6" fill="#2563eb"/>
  <text x="16" y="22" font-family="system-ui, sans-serif" font-size="18" font-weight="700" text-anchor="middle" fill="#ffffff">__INITIAL__</text>
</svg>
```

(The `__INITIAL__` placeholder is replaced by the first letter of the slug by `/aff-bootstrap`.)

- [ ] **Step 6: Write `src/content/config.ts`**

File: `C:\Users\rchampion\source\repos\affiliate-sites\templates\site-template\src\content\config.ts`

```ts
import { defineCollection, z } from "astro:content";

const reviews = defineCollection({
  type: "content",
  schema: z.object({
    title: z.string(),
    description: z.string().max(160),
    product: z.object({
      name: z.string(),
      brand: z.string(),
      sku: z.string().optional(),
      price: z.number().optional(),
      currency: z.string().default("USD"),
      affiliate: z.object({
        amazon: z.string().optional(),
        direct: z.string().optional(),
      }).optional(),
    }),
    rating: z.number().min(1).max(5).optional(),
    classification: z.enum(["review", "buyers-guide"]),
    pubDate: z.date(),
    lastUpdated: z.date(),
    images: z.object({
      hero: z.string().optional(),
      context: z.string().optional(),
      comparison: z.string().optional(),
    }).optional(),
  }),
});

const buyersGuides = defineCollection({
  type: "content",
  schema: z.object({
    title: z.string(),
    description: z.string().max(160),
    products: z.array(z.object({
      name: z.string(),
      brand: z.string(),
      affiliateUrl: z.string(),
    })),
    pubDate: z.date(),
    lastUpdated: z.date(),
  }),
});

const learn = defineCollection({
  type: "content",
  schema: z.object({
    title: z.string(),
    description: z.string().max(160),
    pubDate: z.date(),
    lastUpdated: z.date(),
  }),
});

export const collections = { reviews, "buyers-guides": buyersGuides, learn };
```

- [ ] **Step 7: Install dependencies (this populates the workspace lockfile for astro)**

Run: `cd C:/Users/rchampion/source/repos/affiliate-sites && pnpm install`
Expected: astro and @astrojs/check install.

- [ ] **Step 8: Commit**

Run:
```bash
git add templates/site-template
git commit -m "feat(template): Astro template skeleton with content collections"
```

---

### Task 9: Add the standard pages and layout to the site template

**Files:**
- Create: `templates/site-template/src/layouts/MainLayout.astro`
- Create: `templates/site-template/src/pages/index.astro`
- Create: `templates/site-template/src/pages/about.astro`
- Create: `templates/site-template/src/pages/disclosure.astro`
- Create: `templates/site-template/src/pages/privacy.astro`
- Create: `templates/site-template/src/pages/contact.astro`

The template uses placeholder strings (`__SITE_NAME__`, `__SITE_URL__`, `__NICHE__`, `__TAGLINE__`) that `/aff-bootstrap` replaces when it copies the template into `sites/<slug>/`.

- [ ] **Step 1: Write `MainLayout.astro`**

File: `C:\Users\rchampion\source\repos\affiliate-sites\templates\site-template\src\layouts\MainLayout.astro`

```astro
---
import BaseLayout from "@affkit/shared-ui/BaseLayout.astro";
import AffiliateDisclosure from "@affkit/shared-ui/AffiliateDisclosure.astro";

interface Props {
  title: string;
  description: string;
  canonical?: string;
}

const { title, description, canonical } = Astro.props;
const siteName = "__SITE_NAME__";
---
<BaseLayout title={title} description={description} canonical={canonical} siteName={siteName}>
  <header class="site-header">
    <a href="/" class="brand">__SITE_NAME__</a>
    <nav>
      <a href="/">Home</a>
      <a href="/about/">About</a>
      <a href="/disclosure/">Disclosure</a>
    </nav>
  </header>

  <main>
    <slot />
  </main>

  <AffiliateDisclosure siteName={siteName} />

  <footer class="site-footer">
    <nav>
      <a href="/about/">About</a>
      <a href="/disclosure/">Affiliate disclosure</a>
      <a href="/privacy/">Privacy</a>
      <a href="/contact/">Contact</a>
    </nav>
    <p>© {new Date().getFullYear()} {siteName}. All rights reserved.</p>
  </footer>
</BaseLayout>

<style>
  .site-header {
    display: flex;
    justify-content: space-between;
    align-items: center;
    padding: var(--space-4) 0;
    border-bottom: 1px solid var(--color-border);
    margin-bottom: var(--space-8);
  }
  .brand {
    font-weight: 700;
    font-size: var(--text-lg);
    color: var(--color-fg);
    text-decoration: none;
  }
  nav a {
    color: var(--color-fg);
    text-decoration: none;
    margin-left: var(--space-4);
  }
  nav a:hover { color: var(--color-brand); }
  main { min-height: 60vh; }
  .site-footer {
    margin-top: var(--space-16);
    padding: var(--space-6) 0;
    border-top: 1px solid var(--color-border);
    text-align: center;
    color: var(--color-muted);
    font-size: var(--text-sm);
  }
</style>
```

- [ ] **Step 2: Write `index.astro` (homepage)**

File: `C:\Users\rchampion\source\repos\affiliate-sites\templates\site-template\src\pages\index.astro`

```astro
---
import MainLayout from "../layouts/MainLayout.astro";
import Hero from "@affkit/shared-ui/Hero.astro";
---
<MainLayout
  title="__SITE_NAME__"
  description="__SITE_NAME__ — honest, hands-on reviews and buyer's guides for __NICHE__."
>
  <Hero
    title="__SITE_NAME__"
    tagline="__TAGLINE__"
  />

  <section>
    <h2>Latest reviews</h2>
    <p class="muted">No reviews published yet. New content lands every quarter.</p>
  </section>

  <section>
    <h2>Buyer's guides</h2>
    <p class="muted">Coming soon.</p>
  </section>
</MainLayout>

<style>
  section { margin: var(--space-12) 0; }
  h2 {
    font-size: var(--text-2xl);
    margin: 0 0 var(--space-4);
  }
  .muted { color: var(--color-muted); }
</style>
```

- [ ] **Step 3: Write `about.astro`**

File: `C:\Users\rchampion\source\repos\affiliate-sites\templates\site-template\src\pages\about.astro`

```astro
---
import MainLayout from "../layouts/MainLayout.astro";
---
<MainLayout
  title="About"
  description="About __SITE_NAME__ — who we are and how we review."
>
  <article>
    <h1>About __SITE_NAME__</h1>

    <p>
      __SITE_NAME__ is a small, independent site covering __NICHE__.
      We test products where we can, research thoroughly where we can't,
      and tell you which one we'd actually buy with our own money.
    </p>

    <h2>How we review</h2>
    <p>
      Every product on this site falls into one of two categories:
    </p>
    <ul>
      <li>
        <strong>Reviews</strong> — products we have first-hand experience with.
        Our "My Take" section reflects real use.
      </li>
      <li>
        <strong>Buyer's guides</strong> — comparative roundups of products
        we've researched but don't own. We tell you which one is best for
        which use case, based on specs, reputation, and community feedback.
      </li>
    </ul>

    <h2>How we make money</h2>
    <p>
      We earn affiliate commissions when you buy through our links. It
      doesn't change the price you pay. We don't accept payment in exchange
      for positive coverage and we'll flag any product where we have a
      conflict of interest. Full details in our
      <a href="/disclosure/">affiliate disclosure</a>.
    </p>
  </article>
</MainLayout>

<style>
  article {
    max-width: var(--content-max);
    margin: 0 auto;
  }
  h1 { font-size: var(--text-3xl); margin-bottom: var(--space-6); }
  h2 { margin-top: var(--space-8); }
</style>
```

- [ ] **Step 4: Write `disclosure.astro`**

File: `C:\Users\rchampion\source\repos\affiliate-sites\templates\site-template\src\pages\disclosure.astro`

```astro
---
import MainLayout from "../layouts/MainLayout.astro";
---
<MainLayout
  title="Affiliate disclosure"
  description="Affiliate disclosure for __SITE_NAME__."
>
  <article>
    <h1>Affiliate disclosure</h1>

    <p><strong>Last updated:</strong> {new Date().toLocaleDateString("en-US", { year: "numeric", month: "long", day: "numeric" })}</p>

    <p>
      __SITE_NAME__ ("we", "us", "our") participates in affiliate marketing
      programs. When you click a link on this site and make a purchase,
      we may receive a commission from the retailer at no additional cost
      to you.
    </p>

    <h2>Amazon Services LLC Associates Program</h2>
    <p>
      __SITE_NAME__ is a participant in the Amazon Services LLC Associates
      Program, an affiliate advertising program designed to provide a means
      for sites to earn advertising fees by advertising and linking to
      Amazon.com.
    </p>

    <h2>Other affiliate relationships</h2>
    <p>
      We may also participate in affiliate programs with other retailers
      and manufacturers relevant to __NICHE__. These relationships
      do not influence our editorial recommendations.
    </p>

    <h2>How affiliate links are marked</h2>
    <p>
      All outbound product links on this site use the <code>nofollow sponsored</code>
      rel attribute as required by FTC guidelines and search engine policies.
      You can identify affiliate links by their <code>/go/</code> path prefix.
    </p>

    <h2>FTC disclosure</h2>
    <p>
      In accordance with the Federal Trade Commission's 16 CFR Part 255:
      "Guides Concerning the Use of Endorsements and Testimonials in
      Advertising," this site discloses that it receives compensation
      from affiliated retailers when readers click affiliate links and
      make purchases.
    </p>
  </article>
</MainLayout>

<style>
  article { max-width: var(--content-max); margin: 0 auto; }
  h1 { font-size: var(--text-3xl); margin-bottom: var(--space-6); }
  h2 { margin-top: var(--space-8); }
  code { background: var(--color-surface); padding: 0 var(--space-1); border-radius: var(--radius-sm); }
</style>
```

- [ ] **Step 5: Write `privacy.astro`**

File: `C:\Users\rchampion\source\repos\affiliate-sites\templates\site-template\src\pages\privacy.astro`

```astro
---
import MainLayout from "../layouts/MainLayout.astro";
---
<MainLayout
  title="Privacy policy"
  description="Privacy policy for __SITE_NAME__."
>
  <article>
    <h1>Privacy policy</h1>

    <p><strong>Last updated:</strong> {new Date().toLocaleDateString("en-US", { year: "numeric", month: "long", day: "numeric" })}</p>

    <h2>What we collect</h2>
    <p>
      __SITE_NAME__ uses Cloudflare Web Analytics, which is privacy-friendly
      by design: no cookies, no fingerprinting, and no personal data is
      collected or sold. We see aggregate stats like page views and
      referrers — never individual visitors.
    </p>

    <h2>Affiliate clicks</h2>
    <p>
      When you click a <code>/go/</code> affiliate link, our Cloudflare
      Worker logs the click (timestamp, target product, referring page)
      so we can understand which products our readers find interesting.
      This data is aggregate; no personal identifiers are stored.
    </p>

    <h2>What happens after you click</h2>
    <p>
      Once you leave __SITE_NAME__ via an affiliate link, you're on the
      destination retailer's site under their privacy policy (Amazon, the
      brand's direct site, etc.). We have no control over their tracking.
    </p>

    <h2>Cookies</h2>
    <p>__SITE_NAME__ does not set any first-party tracking cookies.</p>

    <h2>Contact</h2>
    <p>Questions about this policy? See the <a href="/contact/">contact</a> page.</p>
  </article>
</MainLayout>

<style>
  article { max-width: var(--content-max); margin: 0 auto; }
  h1 { font-size: var(--text-3xl); margin-bottom: var(--space-6); }
  h2 { margin-top: var(--space-8); }
  code { background: var(--color-surface); padding: 0 var(--space-1); border-radius: var(--radius-sm); }
</style>
```

- [ ] **Step 6: Write `contact.astro`**

File: `C:\Users\rchampion\source\repos\affiliate-sites\templates\site-template\src\pages\contact.astro`

```astro
---
import MainLayout from "../layouts/MainLayout.astro";
---
<MainLayout
  title="Contact"
  description="Get in touch with __SITE_NAME__."
>
  <article>
    <h1>Contact</h1>

    <p>
      Have a correction, a product suggestion, or feedback on a review?
      Send a note to <a href="mailto:__CONTACT_EMAIL__">__CONTACT_EMAIL__</a>.
    </p>

    <p>
      We read everything but can't always reply. Genuine corrections
      get fixed quickly.
    </p>
  </article>
</MainLayout>

<style>
  article { max-width: var(--content-max); margin: 0 auto; }
  h1 { font-size: var(--text-3xl); margin-bottom: var(--space-6); }
</style>
```

- [ ] **Step 7: Smoke-build the template directly to confirm Astro is happy**

The template references workspace packages, so it has to build from inside its own directory.

Run: `cd C:/Users/rchampion/source/repos/affiliate-sites/templates/site-template && pnpm build`
Expected: `astro build` succeeds with a small number of pages output to `dist/`. There will be warnings about content collections being empty (no reviews yet) — that's fine. There will be `__SITE_NAME__` text literally in the output HTML — that's expected; bootstrap replaces these.

If the build fails, fix the error before proceeding. Common issues: missing dependency in `package.json`, wrong path in an `import`, content schema mismatch.

- [ ] **Step 8: Clean up the smoke-build output**

Run: `cd C:/Users/rchampion/source/repos/affiliate-sites/templates/site-template && rm -rf dist .astro`

Expected: build artifacts removed.

- [ ] **Step 9: Commit**

Run:
```bash
cd C:/Users/rchampion/source/repos/affiliate-sites
git add templates/site-template
git commit -m "feat(template): standard pages (home, about, disclosure, privacy, contact)"
```

---

## Phase D — Link cloaker Cloudflare Worker

### Task 10: Scaffold the `link-cloaker` Worker package

The Worker handles `GET /go/<site>/<slug>?src=<source>` requests:
- Looks up the slug in a KV namespace (`AFFILIATE_LINKS`)
- 302-redirects to the real affiliate URL
- Logs the click via Workers Analytics Engine
- 404s if the slug isn't found

**Files:**
- Create: `workers/link-cloaker/package.json`
- Create: `workers/link-cloaker/tsconfig.json`
- Create: `workers/link-cloaker/wrangler.toml`
- Create: `workers/link-cloaker/vitest.config.ts`
- Create: `workers/link-cloaker/src/index.ts` (skeleton — implemented in Task 11)
- Create: `workers/link-cloaker/test/cloaker.test.ts`

- [ ] **Step 1: Write `package.json`**

File: `C:\Users\rchampion\source\repos\affiliate-sites\workers\link-cloaker\package.json`

```json
{
  "name": "@affkit/link-cloaker",
  "version": "0.0.1",
  "private": true,
  "type": "module",
  "scripts": {
    "dev": "wrangler dev",
    "deploy": "wrangler deploy",
    "test": "vitest run",
    "test:watch": "vitest",
    "typecheck": "tsc --noEmit"
  },
  "devDependencies": {
    "@cloudflare/vitest-pool-workers": "^0.5.0",
    "@cloudflare/workers-types": "^4.20240924.0",
    "typescript": "^5.4.0",
    "vitest": "^1.6.0",
    "wrangler": "^3.78.0"
  }
}
```

- [ ] **Step 2: Write `tsconfig.json`**

File: `C:\Users\rchampion\source\repos\affiliate-sites\workers\link-cloaker\tsconfig.json`

```json
{
  "extends": "../../tsconfig.base.json",
  "compilerOptions": {
    "types": ["@cloudflare/workers-types", "vitest/globals"]
  },
  "include": ["src/**/*", "test/**/*"]
}
```

- [ ] **Step 3: Write `wrangler.toml`**

File: `C:\Users\rchampion\source\repos\affiliate-sites\workers\link-cloaker\wrangler.toml`

```toml
name = "affkit-link-cloaker"
main = "src/index.ts"
compatibility_date = "2026-05-01"
workers_dev = false

# KV namespace for slug → affiliate URL mappings.
# Replace the id after running: wrangler kv:namespace create AFFILIATE_LINKS
[[kv_namespaces]]
binding = "AFFILIATE_LINKS"
id = "REPLACE_WITH_KV_NAMESPACE_ID"

# Analytics Engine dataset for click logging.
[[analytics_engine_datasets]]
binding = "CLICKS"
dataset = "affkit_clicks"

# Routes are added per-site via Wrangler from `/aff-bootstrap`.
# e.g. wrangler deploy and then attach routes by site:
#   wrangler triggers add --pattern "mywildlifecam.fyi/go/*" --zone-id <ZONE_ID>
```

- [ ] **Step 4: Write `vitest.config.ts`**

File: `C:\Users\rchampion\source\repos\affiliate-sites\workers\link-cloaker\vitest.config.ts`

```ts
import { defineWorkersConfig } from "@cloudflare/vitest-pool-workers/config";

export default defineWorkersConfig({
  test: {
    poolOptions: {
      workers: {
        wrangler: { configPath: "./wrangler.toml" },
      },
    },
    include: ["test/**/*.test.ts"],
  },
});
```

- [ ] **Step 5: Write a stub `src/index.ts`**

File: `C:\Users\rchampion\source\repos\affiliate-sites\workers\link-cloaker\src\index.ts`

```ts
export interface Env {
  AFFILIATE_LINKS: KVNamespace;
  CLICKS: AnalyticsEngineDataset;
}

export default {
  async fetch(_req: Request, _env: Env, _ctx: ExecutionContext): Promise<Response> {
    return new Response("not implemented", { status: 501 });
  },
};
```

- [ ] **Step 6: Install dependencies**

Run: `cd C:/Users/rchampion/source/repos/affiliate-sites && pnpm install`
Expected: wrangler, vitest, and workers-types install.

- [ ] **Step 7: Commit**

Run:
```bash
git add workers/link-cloaker
git commit -m "feat(link-cloaker): scaffold Worker package"
```

---

### Task 11: TDD the link-cloaker Worker

Write failing tests for redirect, click logging, source tracking, and 404 behavior. Then implement.

**Files:**
- Modify: `workers/link-cloaker/test/cloaker.test.ts`
- Modify: `workers/link-cloaker/src/index.ts`

- [ ] **Step 1: Write the failing tests**

File: `C:\Users\rchampion\source\repos\affiliate-sites\workers\link-cloaker\test\cloaker.test.ts`

```ts
import { describe, it, expect, beforeEach, vi } from "vitest";
import { env, createExecutionContext, waitOnExecutionContext } from "cloudflare:test";
import worker from "../src/index";

declare module "cloudflare:test" {
  interface ProvidedEnv {
    AFFILIATE_LINKS: KVNamespace;
    CLICKS: AnalyticsEngineDataset;
  }
}

async function dispatch(url: string, init?: RequestInit) {
  const request = new Request(url, init);
  const ctx = createExecutionContext();
  const response = await worker.fetch(request, env, ctx);
  await waitOnExecutionContext(ctx);
  return response;
}

describe("link-cloaker", () => {
  beforeEach(async () => {
    // Reset KV state between tests
    const keys = await env.AFFILIATE_LINKS.list();
    await Promise.all(keys.keys.map((k) => env.AFFILIATE_LINKS.delete(k.name)));
  });

  it("302-redirects /go/<site>/<slug> to the affiliate URL stored in KV", async () => {
    await env.AFFILIATE_LINKS.put(
      "mywildlifecam:reconyx-hc600",
      "https://amazon.com/dp/B07X?tag=affkit-20"
    );
    const res = await dispatch("https://mywildlifecam.fyi/go/mywildlifecam/reconyx-hc600");
    expect(res.status).toBe(302);
    expect(res.headers.get("location")).toBe("https://amazon.com/dp/B07X?tag=affkit-20");
    expect(res.headers.get("cache-control")).toBe("private, no-store");
  });

  it("respects an optional ?src= source tag in the redirect query (but does not include it in the location)", async () => {
    await env.AFFILIATE_LINKS.put(
      "fussybean:breville-bambino",
      "https://amazon.com/dp/B08Y?tag=affkit-20"
    );
    const res = await dispatch(
      "https://fussybean.com/go/fussybean/breville-bambino?src=comparison-table"
    );
    expect(res.status).toBe(302);
    expect(res.headers.get("location")).toBe("https://amazon.com/dp/B08Y?tag=affkit-20");
  });

  it("returns 404 when the slug is not in KV", async () => {
    const res = await dispatch("https://mywildlifecam.fyi/go/mywildlifecam/unknown-product");
    expect(res.status).toBe(404);
  });

  it("returns 400 for malformed /go paths", async () => {
    const res = await dispatch("https://mywildlifecam.fyi/go/onlyonepart");
    expect(res.status).toBe(400);
  });

  it("returns 404 for non-/go paths", async () => {
    const res = await dispatch("https://mywildlifecam.fyi/something-else");
    expect(res.status).toBe(404);
  });

  it("writes an analytics data point including site, slug, and source", async () => {
    await env.AFFILIATE_LINKS.put(
      "mywildlifecam:reconyx-hc600",
      "https://amazon.com/dp/B07X?tag=affkit-20"
    );
    const writeSpy = vi.spyOn(env.CLICKS, "writeDataPoint");
    await dispatch(
      "https://mywildlifecam.fyi/go/mywildlifecam/reconyx-hc600?src=review-cta",
      { headers: { Referer: "https://mywildlifecam.fyi/reviews/reconyx-hc600" } }
    );
    expect(writeSpy).toHaveBeenCalledOnce();
    const payload = writeSpy.mock.calls[0][0] as AnalyticsEngineDataPoint;
    expect(payload.indexes).toEqual(["mywildlifecam"]);
    expect(payload.blobs).toEqual([
      "mywildlifecam",
      "reconyx-hc600",
      "review-cta",
      "https://mywildlifecam.fyi/reviews/reconyx-hc600",
    ]);
    expect(payload.doubles).toEqual([1]);
  });

  it("does not write analytics for a 404 lookup miss", async () => {
    const writeSpy = vi.spyOn(env.CLICKS, "writeDataPoint");
    await dispatch("https://mywildlifecam.fyi/go/mywildlifecam/missing");
    expect(writeSpy).not.toHaveBeenCalled();
  });
});
```

- [ ] **Step 2: Run tests to confirm they fail**

Run: `cd C:/Users/rchampion/source/repos/affiliate-sites/workers/link-cloaker && pnpm test`
Expected: tests fail — the worker currently returns 501 for everything.

- [ ] **Step 3: Implement the Worker**

File: `C:\Users\rchampion\source\repos\affiliate-sites\workers\link-cloaker\src\index.ts`

```ts
export interface Env {
  AFFILIATE_LINKS: KVNamespace;
  CLICKS: AnalyticsEngineDataset;
}

export default {
  async fetch(req: Request, env: Env, _ctx: ExecutionContext): Promise<Response> {
    const url = new URL(req.url);
    const parts = url.pathname.split("/").filter(Boolean);

    // Path shape: /go/<site>/<slug>
    if (parts[0] !== "go") {
      return new Response("not found", { status: 404 });
    }
    if (parts.length !== 3) {
      return new Response("bad request", { status: 400 });
    }

    const site = parts[1];
    const slug = parts[2];
    const source = url.searchParams.get("src") ?? "";
    const referer = req.headers.get("Referer") ?? "";

    const kvKey = `${site}:${slug}`;
    const target = await env.AFFILIATE_LINKS.get(kvKey);

    if (!target) {
      return new Response("not found", { status: 404 });
    }

    env.CLICKS.writeDataPoint({
      indexes: [site],
      blobs: [site, slug, source, referer],
      doubles: [1],
    });

    return new Response(null, {
      status: 302,
      headers: {
        location: target,
        "cache-control": "private, no-store",
      },
    });
  },
};
```

- [ ] **Step 4: Run tests to confirm they pass**

Run: `pnpm test`
Expected: all 7 tests pass.

- [ ] **Step 5: Typecheck**

Run: `pnpm typecheck`
Expected: no errors.

- [ ] **Step 6: Commit**

Run:
```bash
cd C:/Users/rchampion/source/repos/affiliate-sites
git add workers/link-cloaker
git commit -m "feat(link-cloaker): KV lookup, 302 redirect, analytics click logging"
```

---

### Task 12: Provision Cloudflare resources for the Worker (one-time)

This task deploys the Worker and creates the KV namespace + Analytics Engine dataset. It's a one-time setup step using Wrangler. The human runs these commands; output gets pasted into `wrangler.toml`.

**Files:**
- Modify: `workers/link-cloaker/wrangler.toml`

- [ ] **Step 1: Create the KV namespace**

Run: `cd C:/Users/rchampion/source/repos/affiliate-sites/workers/link-cloaker && wrangler kv namespace create AFFILIATE_LINKS`

Expected output:
```
🌀 Creating namespace with title "affkit-link-cloaker-AFFILIATE_LINKS"
✨ Success!
Add the following to your configuration file in your kv_namespaces array:
[[kv_namespaces]]
binding = "AFFILIATE_LINKS"
id = "abc123def456..."
```

Copy the `id` value.

- [ ] **Step 2: Update `wrangler.toml` with the real KV namespace id**

In `workers/link-cloaker/wrangler.toml`, replace:

```toml
[[kv_namespaces]]
binding = "AFFILIATE_LINKS"
id = "REPLACE_WITH_KV_NAMESPACE_ID"
```

with the actual id from Step 1's output.

- [ ] **Step 3: Deploy the Worker**

Run: `wrangler deploy`

Expected output:
```
Total Upload: X.XX KiB / gzip: X.XX KiB
Uploaded affkit-link-cloaker (X.XXs)
Deployed affkit-link-cloaker
```

The Worker is now live but not routed to any domain yet. Routes attach per-site in `/aff-bootstrap`.

- [ ] **Step 4: Verify the Worker is accessible**

Run: `wrangler tail affkit-link-cloaker --once` (or just visit the workers.dev URL Wrangler printed — though we set `workers_dev = false`, we can sanity-check via `wrangler tail` once a request comes in later).

For now, just confirm `wrangler deployments list` shows the deployment.

Run: `wrangler deployments list`
Expected: at least one entry with the current timestamp.

- [ ] **Step 5: Commit the updated wrangler.toml**

Run:
```bash
cd C:/Users/rchampion/source/repos/affiliate-sites
git add workers/link-cloaker/wrangler.toml
git commit -m "chore(link-cloaker): record production KV namespace id"
```

---

## Phase E — Bootstrap tooling

### Task 13: Scaffold `tools/bootstrap` package

This is the TypeScript CLI invoked by `/aff-bootstrap`. It handles the deterministic pieces: copying the template, replacing placeholders, calling Wrangler.

**Files:**
- Create: `tools/bootstrap/package.json`
- Create: `tools/bootstrap/tsconfig.json`
- Create: `tools/bootstrap/vitest.config.ts`
- Create: `tools/bootstrap/src/index.ts` (CLI entry — stub)
- Create: `tools/bootstrap/src/config.ts`

- [ ] **Step 1: Write `package.json`**

File: `C:\Users\rchampion\source\repos\affiliate-sites\tools\bootstrap\package.json`

```json
{
  "name": "@affkit/bootstrap",
  "version": "0.0.1",
  "private": true,
  "type": "module",
  "bin": {
    "affkit-bootstrap": "./dist/index.js"
  },
  "scripts": {
    "build": "tsc",
    "dev": "tsx src/index.ts",
    "test": "vitest run",
    "test:watch": "vitest",
    "typecheck": "tsc --noEmit"
  },
  "dependencies": {
    "@affkit/shared-utils": "workspace:*"
  },
  "devDependencies": {
    "@types/node": "^20.11.0",
    "tsx": "^4.16.0",
    "typescript": "^5.4.0",
    "vitest": "^1.6.0"
  }
}
```

- [ ] **Step 2: Write `tsconfig.json`**

File: `C:\Users\rchampion\source\repos\affiliate-sites\tools\bootstrap\tsconfig.json`

```json
{
  "extends": "../../tsconfig.base.json",
  "compilerOptions": {
    "outDir": "./dist",
    "rootDir": "./src",
    "module": "NodeNext",
    "moduleResolution": "NodeNext",
    "types": ["node", "vitest/globals"]
  },
  "include": ["src/**/*", "test/**/*"]
}
```

- [ ] **Step 3: Write `vitest.config.ts`**

File: `C:\Users\rchampion\source\repos\affiliate-sites\tools\bootstrap\vitest.config.ts`

```ts
import { defineConfig } from "vitest/config";

export default defineConfig({
  test: {
    globals: true,
    environment: "node",
    include: ["test/**/*.test.ts"],
  },
});
```

- [ ] **Step 4: Write `src/config.ts`** (reads the plugin config)

File: `C:\Users\rchampion\source\repos\affiliate-sites\tools\bootstrap\src\config.ts`

```ts
import { readFile } from "node:fs/promises";
import { homedir } from "node:os";
import { join } from "node:path";

export interface PluginConfig {
  monorepo_path: string;
  tone: "polite" | "snarky" | "spicy";
  tokens: {
    cloudflare_api: string;
    cloudflare_account_id: string;
    amazon_paapi_access?: string;
    amazon_paapi_secret?: string;
    indexnow_key?: string;
    contact_email?: string;
  };
}

export async function loadConfig(): Promise<PluginConfig> {
  const path = join(homedir(), ".claude", "plugins", "affiliate-kit", "config.json");
  try {
    const raw = await readFile(path, "utf-8");
    const parsed = JSON.parse(raw) as PluginConfig;
    if (!parsed.tokens?.cloudflare_api) {
      throw new Error("config.json missing tokens.cloudflare_api");
    }
    if (!parsed.tokens.cloudflare_account_id) {
      throw new Error("config.json missing tokens.cloudflare_account_id");
    }
    if (!parsed.monorepo_path) {
      throw new Error("config.json missing monorepo_path");
    }
    return parsed;
  } catch (err) {
    if ((err as NodeJS.ErrnoException).code === "ENOENT") {
      throw new Error(
        `Plugin config not found at ${path}. Run /aff-bootstrap first-time setup.`
      );
    }
    throw err;
  }
}
```

- [ ] **Step 5: Write `src/index.ts`** (CLI entry, fleshed out in later tasks)

File: `C:\Users\rchampion\source\repos\affiliate-sites\tools\bootstrap\src\index.ts`

```ts
#!/usr/bin/env node
import { argv, exit } from "node:process";

async function main() {
  const slug = argv[2];
  if (!slug) {
    console.error("usage: affkit-bootstrap <slug>");
    exit(2);
  }
  console.log(`bootstrap stub for: ${slug}`);
  console.log("(real implementation lands in later tasks)");
}

main().catch((err) => {
  console.error(err);
  exit(1);
});
```

- [ ] **Step 6: Install dependencies**

Run: `cd C:/Users/rchampion/source/repos/affiliate-sites && pnpm install`
Expected: tsx and @types/node install.

- [ ] **Step 7: Smoke-run the stub**

Run: `cd tools/bootstrap && pnpm dev mywildlifecam`
Expected:
```
bootstrap stub for: mywildlifecam
(real implementation lands in later tasks)
```

- [ ] **Step 8: Commit**

Run:
```bash
cd C:/Users/rchampion/source/repos/affiliate-sites
git add tools/bootstrap
git commit -m "feat(bootstrap): scaffold tool package with config loader"
```

---

### Task 14: Implement the template-copy helper (TDD)

The first real piece of the bootstrap: copy `templates/site-template/` to `sites/<slug>/`, replacing placeholder strings with site-specific values.

**Files:**
- Create: `tools/bootstrap/src/copy-template.ts`
- Create: `tools/bootstrap/test/copy-template.test.ts`

- [ ] **Step 1: Write failing tests**

File: `C:\Users\rchampion\source\repos\affiliate-sites\tools\bootstrap\test\copy-template.test.ts`

```ts
import { describe, it, expect, beforeEach, afterEach } from "vitest";
import { mkdtemp, mkdir, writeFile, readFile, rm } from "node:fs/promises";
import { tmpdir } from "node:os";
import { join } from "node:path";
import { copyTemplate } from "../src/copy-template";

let workDir: string;

async function makeFakeTemplate(root: string) {
  await mkdir(join(root, "templates", "site-template", "src", "pages"), {
    recursive: true,
  });
  await mkdir(join(root, "templates", "site-template", "public"), {
    recursive: true,
  });
  await writeFile(
    join(root, "templates", "site-template", "package.json"),
    JSON.stringify({ name: "@affkit/site-template", scripts: { build: "astro build" } }, null, 2)
  );
  await writeFile(
    join(root, "templates", "site-template", "src", "pages", "index.astro"),
    `<h1>Welcome to __SITE_NAME__</h1>\n<p>__TAGLINE__</p>`
  );
  await writeFile(
    join(root, "templates", "site-template", "public", "robots.txt"),
    `User-agent: *\nSitemap: __SITE_URL__/sitemap-index.xml\n`
  );
  await writeFile(
    join(root, "templates", "site-template", "public", "favicon.svg"),
    `<svg><text>__INITIAL__</text></svg>`
  );
}

describe("copyTemplate", () => {
  beforeEach(async () => {
    workDir = await mkdtemp(join(tmpdir(), "affkit-test-"));
    await makeFakeTemplate(workDir);
  });

  afterEach(async () => {
    await rm(workDir, { recursive: true, force: true });
  });

  it("copies the template into sites/<slug>/", async () => {
    await copyTemplate({
      monorepoRoot: workDir,
      slug: "mywildlifecam",
      siteName: "MyWildlifeCam",
      siteUrl: "https://mywildlifecam.fyi",
      niche: "trail cameras",
      tagline: "Honest reviews of wildlife cameras.",
      contactEmail: "hello@mywildlifecam.fyi",
    });
    const pkg = JSON.parse(
      await readFile(join(workDir, "sites", "mywildlifecam", "package.json"), "utf-8")
    );
    expect(pkg.name).toBe("@affkit/mywildlifecam");
  });

  it("replaces __SITE_NAME__ placeholders", async () => {
    await copyTemplate({
      monorepoRoot: workDir,
      slug: "mywildlifecam",
      siteName: "MyWildlifeCam",
      siteUrl: "https://mywildlifecam.fyi",
      niche: "trail cameras",
      tagline: "Honest reviews of wildlife cameras.",
      contactEmail: "hello@mywildlifecam.fyi",
    });
    const index = await readFile(
      join(workDir, "sites", "mywildlifecam", "src", "pages", "index.astro"),
      "utf-8"
    );
    expect(index).toContain("Welcome to MyWildlifeCam");
    expect(index).toContain("Honest reviews of wildlife cameras.");
    expect(index).not.toContain("__SITE_NAME__");
    expect(index).not.toContain("__TAGLINE__");
  });

  it("replaces __SITE_URL__ in robots.txt", async () => {
    await copyTemplate({
      monorepoRoot: workDir,
      slug: "mywildlifecam",
      siteName: "MyWildlifeCam",
      siteUrl: "https://mywildlifecam.fyi",
      niche: "trail cameras",
      tagline: "Honest reviews of wildlife cameras.",
      contactEmail: "hello@mywildlifecam.fyi",
    });
    const robots = await readFile(
      join(workDir, "sites", "mywildlifecam", "public", "robots.txt"),
      "utf-8"
    );
    expect(robots).toContain("https://mywildlifecam.fyi/sitemap-index.xml");
    expect(robots).not.toContain("__SITE_URL__");
  });

  it("replaces __INITIAL__ with the first letter of the slug, uppercased", async () => {
    await copyTemplate({
      monorepoRoot: workDir,
      slug: "fussybean",
      siteName: "FussyBean",
      siteUrl: "https://fussybean.com",
      niche: "coffee",
      tagline: "Picky about coffee.",
      contactEmail: "hello@fussybean.com",
    });
    const svg = await readFile(
      join(workDir, "sites", "fussybean", "public", "favicon.svg"),
      "utf-8"
    );
    expect(svg).toContain("<text>F</text>");
  });

  it("refuses to overwrite an existing site directory", async () => {
    await mkdir(join(workDir, "sites", "mywildlifecam"), { recursive: true });
    await expect(
      copyTemplate({
        monorepoRoot: workDir,
        slug: "mywildlifecam",
        siteName: "MyWildlifeCam",
        siteUrl: "https://mywildlifecam.fyi",
        niche: "trail cameras",
        tagline: "Honest reviews of wildlife cameras.",
        contactEmail: "hello@mywildlifecam.fyi",
      })
    ).rejects.toThrow(/already exists/);
  });
});
```

- [ ] **Step 2: Run tests to confirm they fail**

Run: `cd C:/Users/rchampion/source/repos/affiliate-sites/tools/bootstrap && pnpm test`
Expected: tests fail because `../src/copy-template` doesn't exist.

- [ ] **Step 3: Implement `copy-template.ts`**

File: `C:\Users\rchampion\source\repos\affiliate-sites\tools\bootstrap\src\copy-template.ts`

```ts
import { cp, readFile, writeFile, stat, readdir } from "node:fs/promises";
import { join } from "node:path";

export interface CopyTemplateInput {
  monorepoRoot: string;
  slug: string;
  siteName: string;
  siteUrl: string;
  niche: string;
  tagline: string;
  contactEmail: string;
}

const TEXTUAL_EXTENSIONS = new Set([
  ".astro", ".ts", ".tsx", ".js", ".mjs", ".cjs", ".json", ".md", ".mdx",
  ".html", ".css", ".txt", ".svg", ".xml", ".yaml", ".yml",
]);

function isTextFile(path: string): boolean {
  const dot = path.lastIndexOf(".");
  if (dot < 0) return false;
  return TEXTUAL_EXTENSIONS.has(path.slice(dot).toLowerCase());
}

function applyReplacements(content: string, input: CopyTemplateInput): string {
  const initial = input.slug.charAt(0).toUpperCase();
  return content
    .replaceAll("__SITE_NAME__", input.siteName)
    .replaceAll("__SITE_SLUG__", input.slug)
    .replaceAll("__SITE_URL__", input.siteUrl)
    .replaceAll("__NICHE__", input.niche)
    .replaceAll("__TAGLINE__", input.tagline)
    .replaceAll("__CONTACT_EMAIL__", input.contactEmail)
    .replaceAll("__INITIAL__", initial);
}

async function rewriteTextFiles(root: string, input: CopyTemplateInput): Promise<void> {
  const entries = await readdir(root, { withFileTypes: true });
  for (const entry of entries) {
    const full = join(root, entry.name);
    if (entry.isDirectory()) {
      await rewriteTextFiles(full, input);
    } else if (entry.isFile() && isTextFile(entry.name)) {
      const content = await readFile(full, "utf-8");
      const rewritten = applyReplacements(content, input);
      if (rewritten !== content) {
        await writeFile(full, rewritten, "utf-8");
      }
    }
  }
}

async function exists(path: string): Promise<boolean> {
  try {
    await stat(path);
    return true;
  } catch {
    return false;
  }
}

export async function copyTemplate(input: CopyTemplateInput): Promise<void> {
  const source = join(input.monorepoRoot, "templates", "site-template");
  const dest = join(input.monorepoRoot, "sites", input.slug);

  if (await exists(dest)) {
    throw new Error(`sites/${input.slug} already exists`);
  }

  await cp(source, dest, { recursive: true });

  // Update package name to be site-specific
  const pkgPath = join(dest, "package.json");
  if (await exists(pkgPath)) {
    const pkg = JSON.parse(await readFile(pkgPath, "utf-8")) as { name?: string };
    pkg.name = `@affkit/${input.slug}`;
    await writeFile(pkgPath, JSON.stringify(pkg, null, 2) + "\n", "utf-8");
  }

  await rewriteTextFiles(dest, input);
}
```

- [ ] **Step 4: Run tests to confirm they pass**

Run: `pnpm test`
Expected: all 5 tests pass.

- [ ] **Step 5: Commit**

Run:
```bash
cd C:/Users/rchampion/source/repos/affiliate-sites
git add tools/bootstrap
git commit -m "feat(bootstrap): copy-template helper with placeholder replacement"
```

---

### Task 15: Implement the Wrangler wrappers (Cloudflare ops via shell-out)

Thin TypeScript wrappers around `wrangler` and `cloudflare` CLI calls. Each wrapper does one thing.

**Files:**
- Create: `tools/bootstrap/src/wrangler.ts`
- Create: `tools/bootstrap/src/cloudflare-pages.ts`
- Create: `tools/bootstrap/src/cloudflare-dns.ts`
- Create: `tools/bootstrap/src/cloudflare-r2.ts`
- Create: `tools/bootstrap/src/cloudflare-worker-route.ts`

These wrappers are not unit-tested here — they shell out to real APIs, and we test them via the end-to-end bootstrap in Task 17. They are intentionally thin so there is little logic to test in isolation.

- [ ] **Step 1: Write `wrangler.ts`** (the base shell-out)

File: `C:\Users\rchampion\source\repos\affiliate-sites\tools\bootstrap\src\wrangler.ts`

```ts
import { spawn } from "node:child_process";

export interface WranglerResult {
  stdout: string;
  stderr: string;
  exitCode: number;
}

export async function runWrangler(
  args: string[],
  env: NodeJS.ProcessEnv = process.env
): Promise<WranglerResult> {
  return new Promise((resolve, reject) => {
    const child = spawn("wrangler", args, {
      env,
      shell: process.platform === "win32",
    });
    let stdout = "";
    let stderr = "";
    child.stdout.on("data", (chunk) => (stdout += chunk.toString()));
    child.stderr.on("data", (chunk) => (stderr += chunk.toString()));
    child.on("error", reject);
    child.on("close", (code) => {
      resolve({ stdout, stderr, exitCode: code ?? -1 });
    });
  });
}

export function withCfToken(token: string, accountId: string): NodeJS.ProcessEnv {
  return {
    ...process.env,
    CLOUDFLARE_API_TOKEN: token,
    CLOUDFLARE_ACCOUNT_ID: accountId,
  };
}
```

- [ ] **Step 2: Write `cloudflare-pages.ts`**

File: `C:\Users\rchampion\source\repos\affiliate-sites\tools\bootstrap\src\cloudflare-pages.ts`

```ts
import { runWrangler, withCfToken } from "./wrangler";

export interface CreatePagesProjectInput {
  projectName: string;       // e.g. "affkit-mywildlifecam"
  productionBranch: string;  // typically "main"
  apiToken: string;
  accountId: string;
}

export async function createPagesProject(input: CreatePagesProjectInput): Promise<void> {
  const env = withCfToken(input.apiToken, input.accountId);
  const result = await runWrangler(
    [
      "pages",
      "project",
      "create",
      input.projectName,
      "--production-branch",
      input.productionBranch,
    ],
    env
  );
  if (result.exitCode !== 0) {
    // "already exists" is acceptable — bootstrap is idempotent-ish.
    if (result.stderr.includes("already exists") || result.stdout.includes("already exists")) {
      return;
    }
    throw new Error(
      `wrangler pages project create failed (exit ${result.exitCode}): ${result.stderr || result.stdout}`
    );
  }
}

export interface DeployPagesInput {
  projectName: string;
  outputDir: string;          // absolute path to the built `dist/`
  branch: string;             // "main" for prod
  apiToken: string;
  accountId: string;
}

export async function deployPages(input: DeployPagesInput): Promise<{ url: string }> {
  const env = withCfToken(input.apiToken, input.accountId);
  const result = await runWrangler(
    [
      "pages",
      "deploy",
      input.outputDir,
      "--project-name",
      input.projectName,
      "--branch",
      input.branch,
    ],
    env
  );
  if (result.exitCode !== 0) {
    throw new Error(
      `wrangler pages deploy failed (exit ${result.exitCode}): ${result.stderr || result.stdout}`
    );
  }
  // Parse the deployment URL from stdout. Wrangler prints something like:
  //   ✨ Deployment complete! Take a peek over at https://abc.affkit-mywildlifecam.pages.dev
  const match = result.stdout.match(/https:\/\/[^\s]+pages\.dev/);
  if (!match) {
    throw new Error(`could not parse deployment URL from wrangler output: ${result.stdout}`);
  }
  return { url: match[0] };
}

export interface AttachDomainInput {
  projectName: string;
  domain: string;
  apiToken: string;
  accountId: string;
}

export async function attachDomain(input: AttachDomainInput): Promise<void> {
  const env = withCfToken(input.apiToken, input.accountId);
  const result = await runWrangler(
    ["pages", "domain", "add", input.domain, "--project-name", input.projectName],
    env
  );
  if (result.exitCode !== 0) {
    if (result.stderr.includes("already") || result.stdout.includes("already")) {
      return;
    }
    throw new Error(
      `wrangler pages domain add failed (exit ${result.exitCode}): ${result.stderr || result.stdout}`
    );
  }
}
```

- [ ] **Step 3: Write `cloudflare-dns.ts`**

DNS records are NOT in wrangler. We'll shell out to the Cloudflare REST API directly via `fetch`. Wrap it in the same module style.

File: `C:\Users\rchampion\source\repos\affiliate-sites\tools\bootstrap\src\cloudflare-dns.ts`

```ts
export interface DnsInput {
  zoneId: string;
  apiToken: string;
}

export interface CreateRecordInput extends DnsInput {
  type: "A" | "AAAA" | "CNAME" | "TXT";
  name: string;       // e.g. "@" for apex, "www", or "_acme-challenge"
  content: string;
  proxied?: boolean;
  ttl?: number;
}

async function cfFetch(
  path: string,
  apiToken: string,
  init?: RequestInit
): Promise<unknown> {
  const res = await fetch(`https://api.cloudflare.com/client/v4${path}`, {
    ...init,
    headers: {
      Authorization: `Bearer ${apiToken}`,
      "Content-Type": "application/json",
      ...(init?.headers ?? {}),
    },
  });
  const body = (await res.json()) as { success: boolean; errors?: unknown[]; result?: unknown };
  if (!body.success) {
    throw new Error(
      `Cloudflare API ${path} failed: ${JSON.stringify(body.errors)}`
    );
  }
  return body.result;
}

export async function getZoneId(domain: string, apiToken: string): Promise<string> {
  const result = (await cfFetch(`/zones?name=${encodeURIComponent(domain)}`, apiToken)) as Array<{
    id: string;
    name: string;
  }>;
  if (result.length === 0) {
    throw new Error(
      `zone ${domain} not found in this Cloudflare account. Add it via dashboard first.`
    );
  }
  return result[0].id;
}

export async function createOrUpdateRecord(input: CreateRecordInput): Promise<void> {
  const existing = (await cfFetch(
    `/zones/${input.zoneId}/dns_records?type=${input.type}&name=${encodeURIComponent(input.name)}`,
    input.apiToken
  )) as Array<{ id: string }>;

  const payload = {
    type: input.type,
    name: input.name,
    content: input.content,
    proxied: input.proxied ?? false,
    ttl: input.ttl ?? 1,
  };

  if (existing.length > 0) {
    await cfFetch(
      `/zones/${input.zoneId}/dns_records/${existing[0].id}`,
      input.apiToken,
      { method: "PUT", body: JSON.stringify(payload) }
    );
  } else {
    await cfFetch(`/zones/${input.zoneId}/dns_records`, input.apiToken, {
      method: "POST",
      body: JSON.stringify(payload),
    });
  }
}
```

- [ ] **Step 4: Write `cloudflare-r2.ts`**

File: `C:\Users\rchampion\source\repos\affiliate-sites\tools\bootstrap\src\cloudflare-r2.ts`

```ts
import { runWrangler, withCfToken } from "./wrangler";

export interface CreateR2BucketInput {
  bucketName: string;
  apiToken: string;
  accountId: string;
}

export async function createR2Bucket(input: CreateR2BucketInput): Promise<void> {
  const env = withCfToken(input.apiToken, input.accountId);
  const result = await runWrangler(["r2", "bucket", "create", input.bucketName], env);
  if (result.exitCode !== 0) {
    if (
      result.stderr.includes("already exists") ||
      result.stdout.includes("already exists")
    ) {
      return;
    }
    throw new Error(
      `wrangler r2 bucket create failed (exit ${result.exitCode}): ${result.stderr || result.stdout}`
    );
  }
}
```

- [ ] **Step 5: Write `cloudflare-worker-route.ts`**

The link-cloaker Worker needs a route per domain (so `<domain>/go/*` hits the Worker).

File: `C:\Users\rchampion\source\repos\affiliate-sites\tools\bootstrap\src\cloudflare-worker-route.ts`

```ts
async function cfFetch(
  path: string,
  apiToken: string,
  init?: RequestInit
): Promise<unknown> {
  const res = await fetch(`https://api.cloudflare.com/client/v4${path}`, {
    ...init,
    headers: {
      Authorization: `Bearer ${apiToken}`,
      "Content-Type": "application/json",
      ...(init?.headers ?? {}),
    },
  });
  const body = (await res.json()) as { success: boolean; errors?: unknown[]; result?: unknown };
  if (!body.success) {
    throw new Error(`Cloudflare API ${path} failed: ${JSON.stringify(body.errors)}`);
  }
  return body.result;
}

export interface AttachWorkerRouteInput {
  zoneId: string;
  pattern: string;      // e.g. "mywildlifecam.fyi/go/*"
  scriptName: string;   // "affkit-link-cloaker"
  apiToken: string;
}

export async function attachWorkerRoute(input: AttachWorkerRouteInput): Promise<void> {
  // Check for existing route with the same pattern
  const existing = (await cfFetch(
    `/zones/${input.zoneId}/workers/routes`,
    input.apiToken
  )) as Array<{ id: string; pattern: string; script: string }>;

  const match = existing.find((r) => r.pattern === input.pattern);
  if (match) {
    if (match.script === input.scriptName) return; // already correct
    await cfFetch(
      `/zones/${input.zoneId}/workers/routes/${match.id}`,
      input.apiToken,
      {
        method: "PUT",
        body: JSON.stringify({ pattern: input.pattern, script: input.scriptName }),
      }
    );
  } else {
    await cfFetch(`/zones/${input.zoneId}/workers/routes`, input.apiToken, {
      method: "POST",
      body: JSON.stringify({ pattern: input.pattern, script: input.scriptName }),
    });
  }
}
```

- [ ] **Step 6: Typecheck**

Run: `cd C:/Users/rchampion/source/repos/affiliate-sites/tools/bootstrap && pnpm typecheck`
Expected: no errors.

- [ ] **Step 7: Commit**

Run:
```bash
cd C:/Users/rchampion/source/repos/affiliate-sites
git add tools/bootstrap
git commit -m "feat(bootstrap): Cloudflare ops wrappers (Pages, DNS, R2, Worker routes)"
```

---

### Task 16: Wire the full bootstrap flow into the CLI

Tie the helpers together. `affkit-bootstrap <slug>` now does the full end-to-end.

**Files:**
- Modify: `tools/bootstrap/src/index.ts`

The CLI orchestrates:
1. Load config
2. Prompt for site-specific values (siteName, siteUrl, niche, tagline, contactEmail) — OR accept from CLI flags
3. Copy template → `sites/<slug>/`
4. `pnpm install` to wire workspace deps
5. Build the site (`pnpm --filter @affkit/<slug> build`)
6. Resolve Cloudflare zone id from the apex domain
7. Create R2 bucket
8. Create Pages project
9. Deploy to Pages
10. Attach custom domain
11. Create DNS record (CNAME apex → `<project>.pages.dev`, proxied)
12. Attach Worker route (`<domain>/go/*` → `affkit-link-cloaker`)
13. Print `Next:` block

- [ ] **Step 1: Add minimal flag parsing utility**

We won't pull in a CLI library — keep it simple. Add a `parseFlags` helper inline.

- [ ] **Step 2: Replace `src/index.ts` with the full orchestrator**

File: `C:\Users\rchampion\source\repos\affiliate-sites\tools\bootstrap\src\index.ts`

```ts
#!/usr/bin/env node
import { argv, exit, stdout } from "node:process";
import { join } from "node:path";
import { spawn } from "node:child_process";
import { loadConfig } from "./config";
import { copyTemplate } from "./copy-template";
import { createPagesProject, deployPages, attachDomain } from "./cloudflare-pages";
import { getZoneId, createOrUpdateRecord } from "./cloudflare-dns";
import { createR2Bucket } from "./cloudflare-r2";
import { attachWorkerRoute } from "./cloudflare-worker-route";

interface BootstrapArgs {
  slug: string;
  siteName: string;
  siteUrl: string;
  niche: string;
  tagline: string;
  contactEmail: string;
  apex: string;     // e.g. "mywildlifecam.fyi"
}

function parseFlags(args: string[]): Record<string, string> {
  const result: Record<string, string> = {};
  for (let i = 0; i < args.length; i++) {
    const a = args[i];
    if (a.startsWith("--")) {
      const key = a.slice(2);
      const value = args[i + 1];
      if (value === undefined || value.startsWith("--")) {
        result[key] = "true";
      } else {
        result[key] = value;
        i++;
      }
    }
  }
  return result;
}

function usage(): never {
  console.error(
    `usage: affkit-bootstrap <slug> --site-name <s> --site-url <https://...> ` +
      `--niche <s> --tagline <s> --contact-email <s> --apex <s>`
  );
  exit(2);
}

function runShell(cmd: string, args: string[], cwd: string): Promise<void> {
  return new Promise((resolve, reject) => {
    const child = spawn(cmd, args, { cwd, shell: process.platform === "win32", stdio: "inherit" });
    child.on("error", reject);
    child.on("close", (code) => {
      if (code === 0) resolve();
      else reject(new Error(`${cmd} ${args.join(" ")} exited with code ${code}`));
    });
  });
}

async function main() {
  const positional: string[] = [];
  const flagArgs: string[] = [];
  for (const a of argv.slice(2)) {
    if (a.startsWith("--")) flagArgs.push(a);
    else if (flagArgs[flagArgs.length - 1]?.startsWith("--") && !a.startsWith("--")) flagArgs.push(a);
    else positional.push(a);
  }

  const slug = positional[0];
  if (!slug) usage();

  const flags = parseFlags(flagArgs);
  const args: BootstrapArgs = {
    slug,
    siteName: flags["site-name"] ?? "",
    siteUrl: flags["site-url"] ?? "",
    niche: flags["niche"] ?? "",
    tagline: flags["tagline"] ?? "",
    contactEmail: flags["contact-email"] ?? "",
    apex: flags["apex"] ?? "",
  };

  for (const [k, v] of Object.entries(args)) {
    if (typeof v === "string" && v.length === 0) {
      console.error(`missing required flag: --${k.replace(/[A-Z]/g, (m) => "-" + m.toLowerCase())}`);
      usage();
    }
  }

  const config = await loadConfig();
  const root = config.monorepo_path;
  const projectName = `affkit-${args.slug}`;

  stdout.write(`\n🪛 Bootstrapping ${args.slug}\n`);

  stdout.write("  → copying template into sites/" + args.slug + "/ ...\n");
  await copyTemplate({
    monorepoRoot: root,
    slug: args.slug,
    siteName: args.siteName,
    siteUrl: args.siteUrl,
    niche: args.niche,
    tagline: args.tagline,
    contactEmail: args.contactEmail,
  });

  stdout.write("  → installing dependencies (pnpm install) ...\n");
  await runShell("pnpm", ["install"], root);

  stdout.write("  → building the site ...\n");
  await runShell("pnpm", ["--filter", `@affkit/${args.slug}`, "build"], root);

  stdout.write("  → resolving Cloudflare zone for " + args.apex + " ...\n");
  const zoneId = await getZoneId(args.apex, config.tokens.cloudflare_api);

  stdout.write("  → creating R2 bucket " + args.slug + "-images ...\n");
  await createR2Bucket({
    bucketName: `${args.slug}-images`,
    apiToken: config.tokens.cloudflare_api,
    accountId: config.tokens.cloudflare_account_id,
  });

  stdout.write("  → creating Cloudflare Pages project " + projectName + " ...\n");
  await createPagesProject({
    projectName,
    productionBranch: "main",
    apiToken: config.tokens.cloudflare_api,
    accountId: config.tokens.cloudflare_account_id,
  });

  const distDir = join(root, "sites", args.slug, "dist");
  stdout.write("  → deploying to Pages ...\n");
  const deployment = await deployPages({
    projectName,
    outputDir: distDir,
    branch: "main",
    apiToken: config.tokens.cloudflare_api,
    accountId: config.tokens.cloudflare_account_id,
  });
  stdout.write(`    Deployed to: ${deployment.url}\n`);

  stdout.write("  → attaching custom domain " + args.apex + " ...\n");
  await attachDomain({
    projectName,
    domain: args.apex,
    apiToken: config.tokens.cloudflare_api,
    accountId: config.tokens.cloudflare_account_id,
  });
  // Also attach www if you want — leaving out for v1; spec didn't require it.

  stdout.write("  → creating apex CNAME → " + projectName + ".pages.dev ...\n");
  await createOrUpdateRecord({
    zoneId,
    apiToken: config.tokens.cloudflare_api,
    type: "CNAME",
    name: "@",
    content: `${projectName}.pages.dev`,
    proxied: true,
  });

  stdout.write("  → attaching link-cloaker Worker route " + args.apex + "/go/* ...\n");
  await attachWorkerRoute({
    zoneId,
    pattern: `${args.apex}/go/*`,
    scriptName: "affkit-link-cloaker",
    apiToken: config.tokens.cloudflare_api,
  });

  stdout.write(`\n✓ ${args.slug} is live at ${args.siteUrl}\n\n`);
  stdout.write("Next:\n");
  stdout.write(`  → Visit ${args.siteUrl} in 1-2 minutes (DNS propagation)\n`);
  stdout.write(`  → Verify ${args.apex} in Google Search Console: https://search.google.com/search-console\n`);
  stdout.write(`  → Apply to affiliate programs for "${args.niche}" — see docs/programs.md (Phase 2)\n`);
  stdout.write("  → Phase 2 ships /aff-new-review, /aff-refresh, /aff-status, /aff-next. None of those exist yet.\n");
}

main().catch((err: Error) => {
  console.error(`\n✗ bootstrap failed: ${err.message}`);
  exit(1);
});
```

- [ ] **Step 3: Build the CLI**

Run: `cd C:/Users/rchampion/source/repos/affiliate-sites/tools/bootstrap && pnpm build`
Expected: `dist/index.js` and friends produced. No type errors.

- [ ] **Step 4: Commit**

Run:
```bash
cd C:/Users/rchampion/source/repos/affiliate-sites
git add tools/bootstrap
git commit -m "feat(bootstrap): orchestrate end-to-end site bootstrap (template + CF Pages + DNS + Worker route)"
```

---

## Phase F — Plugin and proof against mywildlifecam

### Task 17: Create the Claude Code plugin source

The plugin source lives in `plugin/`. An install script copies it to `~/.claude/plugins/affiliate-kit/` so Claude Code can find it.

**Files:**
- Create: `plugin/plugin.json`
- Create: `plugin/commands/aff-bootstrap.md`
- Create: `plugin/README.md`
- Create: `scripts/install-plugin.ps1`
- Create (manual, gitignored): `~/.claude/plugins/affiliate-kit/config.json`

- [ ] **Step 1: Write `plugin/plugin.json`**

File: `C:\Users\rchampion\source\repos\affiliate-sites\plugin\plugin.json`

```json
{
  "name": "affiliate-kit",
  "version": "0.1.0",
  "description": "Operate 5 affiliate sites with one bootstrap command and a quarterly content cycle.",
  "author": "champrt78"
}
```

- [ ] **Step 2: Write `plugin/README.md`**

File: `C:\Users\rchampion\source\repos\affiliate-sites\plugin\README.md`

```markdown
# affiliate-kit plugin

Source for the Claude Code plugin. To install:

```powershell
pnpm install-plugin
```

This copies `plugin/` to `~/.claude/plugins/affiliate-kit/`.

## First-time setup

After installing, create `~/.claude/plugins/affiliate-kit/config.json` (gitignored, never committed) with:

```json
{
  "monorepo_path": "C:/Users/rchampion/source/repos/affiliate-sites",
  "tone": "snarky",
  "tokens": {
    "cloudflare_api": "<your CF API token>",
    "cloudflare_account_id": "<your CF account id>"
  }
}
```

## Commands

Only `/aff-bootstrap` is implemented in Phase 1. Phase 2 adds the rest.
```

- [ ] **Step 3: Write `plugin/commands/aff-bootstrap.md`**

This is the actual command Claude reads when the user types `/aff-bootstrap <slug>`. It instructs Claude to gather input, call the CLI, and present the result.

File: `C:\Users\rchampion\source\repos\affiliate-sites\plugin\commands\aff-bootstrap.md`

````markdown
---
description: Scaffold a new affiliate site and deploy it to Cloudflare Pages. Usage: /aff-bootstrap <slug>
---

# /aff-bootstrap

Scaffolds a new affiliate site under `sites/<slug>/`, deploys it to Cloudflare Pages, points DNS at it, and attaches the link-cloaker Worker route. By the end, the site is live on its custom domain.

## How to run this

The user invoked: `/aff-bootstrap <slug>` (plus possibly more args).

**Step 1: Validate the slug.**

The slug must be lowercase, alphanumeric, with single dashes between words. It must match one of the 5 known sites:
- `mywildlifecam` → `mywildlifecam.fyi` — niche: trail cameras / wildlife cams
- `fussybean` → `fussybean.com` — niche: coffee and espresso
- `detailerpicks` → `detailerpicks.com` — niche: car detailing
- `starteraquarium` → `starteraquarium.com` — niche: beginner aquariums
- `gameovergear` → `gameovergear.games` — niche: retro gaming gear

If the slug doesn't match a known site, stop and ask the user to clarify (or pass a `--custom` flag and ask for niche/apex/etc.).

**Step 2: Gather the per-site values.**

If the slug matches a known site, you already know:
- `siteName` — the human-readable name (e.g. "FussyBean")
- `apex` — the apex domain
- `niche` — the niche

You still need to ask the user (or accept from flags):
- `tagline` — one-line site tagline (e.g. "Honest reviews of wildlife cameras for the backyard naturalist.")
- `contactEmail` — contact email (e.g. "hello@mywildlifecam.fyi")

Ask politely if any are missing.

**Step 3: Confirm.**

Show the user the gathered values in a small table and ask them to confirm before kicking off the bootstrap. The bootstrap is mostly reversible (you can delete the site directory, the CF Pages project, the DNS record), but it does make real changes to Cloudflare.

**Step 4: Run the CLI.**

Once confirmed, run:

```bash
cd ~/source/repos/affiliate-sites/tools/bootstrap
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

**Step 6: Update `tools/status/sites.json`.**

(NOT YET — this file doesn't exist in Phase 1. It lands in Phase 2 when the status engine is built. For now, leave a TODO note that `<slug>` should be added to sites.json when the status engine ships.)

## Pre-flight checks

Before running the CLI, verify:

1. `~/.claude/plugins/affiliate-kit/config.json` exists and has `tokens.cloudflare_api` and `tokens.cloudflare_account_id`. If not, ask the user to populate it and re-run.
2. The apex domain is added to Cloudflare (check via `wrangler` or the dashboard). If not, ask the user to add it via the Cloudflare dashboard first.
3. Porkbun nameservers point at Cloudflare. If propagation isn't done, the bootstrap will still succeed but the site won't be reachable until propagation completes — note this to the user.

## On failure

If the CLI exits non-zero, capture the error, present it to the user, and suggest the most likely fix:
- "zone not found" → user needs to add the domain to Cloudflare first
- "API token missing" → user needs to update `config.json`
- "already exists" on a site directory → user needs to delete or rename the existing one
- "pnpm install failed" → likely network or registry; suggest retrying

Do not attempt destructive recovery automatically. Surface the error and let the user decide.
````

- [ ] **Step 4: Write `scripts/install-plugin.ps1`**

File: `C:\Users\rchampion\source\repos\affiliate-sites\scripts\install-plugin.ps1`

```powershell
# Copies plugin/ to ~/.claude/plugins/affiliate-kit/
# Does NOT overwrite config.json (which holds secrets).

$ErrorActionPreference = "Stop"

$repoRoot = Split-Path -Parent $PSScriptRoot
$src = Join-Path $repoRoot "plugin"
$dest = Join-Path $env:USERPROFILE ".claude/plugins/affiliate-kit"

if (-not (Test-Path $dest)) {
    New-Item -ItemType Directory -Path $dest -Force | Out-Null
}

# Copy everything from plugin/ to dest, except config.json which we never overwrite.
$preserveConfig = $null
$configPath = Join-Path $dest "config.json"
if (Test-Path $configPath) {
    $preserveConfig = Get-Content $configPath -Raw
}

Copy-Item -Path "$src/*" -Destination $dest -Recurse -Force

if ($preserveConfig) {
    Set-Content -Path $configPath -Value $preserveConfig -NoNewline
    Write-Host "✓ Plugin installed; preserved existing config.json"
} else {
    Write-Host "✓ Plugin installed to $dest"
    Write-Host ""
    Write-Host "Next:"
    Write-Host "  → Create $configPath with your Cloudflare API token and account id."
    Write-Host "  → See plugin/README.md for the config schema."
}
```

- [ ] **Step 5: Run the install script**

Run: `cd C:/Users/rchampion/source/repos/affiliate-sites && pnpm install-plugin`

Expected: plugin files copied to `~/.claude/plugins/affiliate-kit/`, prompting you to create config.json.

- [ ] **Step 6: Create the plugin config file (NOT committed — gitignored)**

File: `C:\Users\rchampion\.claude\plugins\affiliate-kit\config.json`

Replace `<your CF API token>` with the token you created in pre-flight. Get your account id from Cloudflare dashboard → right sidebar of any domain → "Account ID".

```json
{
  "monorepo_path": "C:/Users/rchampion/source/repos/affiliate-sites",
  "tone": "snarky",
  "tokens": {
    "cloudflare_api": "<your CF API token>",
    "cloudflare_account_id": "<your CF account id>"
  }
}
```

**Important:** This file is gitignored. It MUST NEVER be committed.

- [ ] **Step 7: Commit the plugin source + install script**

Run:
```bash
cd C:/Users/rchampion/source/repos/affiliate-sites
git add plugin scripts
git commit -m "feat(plugin): Claude Code plugin source + install script"
git push
```

---

### Task 18: Bootstrap mywildlifecam end-to-end (the proof)

This is the moment of truth. Run `/aff-bootstrap mywildlifecam` and have a real site live on the internet.

**Files:**
- Created by the bootstrap: `sites/mywildlifecam/` (entire Astro site)

- [ ] **Step 1: Verify prerequisites**

Run all of these to confirm readiness:

```bash
# pnpm version
pnpm --version    # expect 9.x

# wrangler version + auth
wrangler --version    # expect 3.x
wrangler whoami        # expect your Cloudflare email

# config.json exists with real values
cat ~/.claude/plugins/affiliate-kit/config.json
# Expect: monorepo_path set, cloudflare_api set, cloudflare_account_id set.

# mywildlifecam.fyi nameservers
# Confirm via `nslookup -type=ns mywildlifecam.fyi` that the 2 Cloudflare NS records are showing.
# (If propagation isn't done, bootstrap still works — site just won't be reachable yet.)
```

If any check fails, fix before proceeding.

- [ ] **Step 2: Invoke `/aff-bootstrap mywildlifecam` from Claude Code**

In a Claude Code session opened in the monorepo:

```
/aff-bootstrap mywildlifecam
```

Claude will:
1. Recognize `mywildlifecam` as a known site.
2. Ask you for `tagline` and `contactEmail`.
3. Show you the summary table and ask to confirm.
4. Run the CLI.

Provide:
- `tagline`: "Honest reviews of trail cameras for the backyard naturalist." (or your own wording)
- `contactEmail`: `hello@mywildlifecam.fyi`

- [ ] **Step 3: Watch the CLI output**

You should see progress lines like:

```
🪛 Bootstrapping mywildlifecam
  → copying template into sites/mywildlifecam/ ...
  → installing dependencies (pnpm install) ...
  → building the site ...
  → resolving Cloudflare zone for mywildlifecam.fyi ...
  → creating R2 bucket mywildlifecam-images ...
  → creating Cloudflare Pages project affkit-mywildlifecam ...
  → deploying to Pages ...
    Deployed to: https://<hash>.affkit-mywildlifecam.pages.dev
  → attaching custom domain mywildlifecam.fyi ...
  → creating apex CNAME → affkit-mywildlifecam.pages.dev ...
  → attaching link-cloaker Worker route mywildlifecam.fyi/go/* ...

✓ mywildlifecam is live at https://mywildlifecam.fyi
```

If any step fails, the CLI exits with the error message. Refer to "On failure" in the command markdown.

- [ ] **Step 4: Verify the site is live**

In a browser (or curl):

```bash
curl -I https://mywildlifecam.fyi
```

Expected: 200 OK, with `cf-ray:` and `server: cloudflare` headers. Body is the site's homepage with "MyWildlifeCam" rendered correctly (no `__SITE_NAME__` placeholder strings).

If DNS hasn't propagated yet, you'll get NXDOMAIN — wait 5-15 minutes and retry.

- [ ] **Step 5: Test the link-cloaker end-to-end**

Add a test entry to the KV namespace:

```bash
wrangler kv key put --namespace-id=<your-AFFILIATE_LINKS-id> "mywildlifecam:test-product" "https://example.com/test"
```

Visit `https://mywildlifecam.fyi/go/mywildlifecam/test-product` in a browser — it should 302-redirect to `https://example.com/test`.

Visit `https://mywildlifecam.fyi/go/mywildlifecam/does-not-exist` — should return 404.

Delete the test KV entry when done:

```bash
wrangler kv key delete --namespace-id=<your-AFFILIATE_LINKS-id> "mywildlifecam:test-product"
```

- [ ] **Step 6: Commit the generated site directory**

Run:
```bash
cd C:/Users/rchampion/source/repos/affiliate-sites
git add sites/mywildlifecam
git commit -m "feat: bootstrap mywildlifecam.fyi"
git push
```

- [ ] **Step 7: Mark Phase 1 complete**

Update the status note in `COMMANDS.md`:

Replace:
```markdown
Phase 1 (foundation + `/aff-bootstrap`): in progress.
```

with:
```markdown
Phase 1 (foundation + `/aff-bootstrap`): COMPLETE — mywildlifecam.fyi is live.
```

Commit:
```bash
git add COMMANDS.md
git commit -m "docs: mark Phase 1 complete"
git push
```

---

## End of Phase 1

At this point you should have:

- `~/source/repos/affiliate-sites/` — the monorepo (also at `champrt78/affiliate-kit` on GitHub)
- A `pnpm` workspace with 3 shared packages, a site template, a Worker, and a bootstrap tool
- A Cloudflare Pages project running the live site
- The link-cloaker Worker deployed and routed at `mywildlifecam.fyi/go/*`
- A working `/aff-bootstrap` command in the Claude Code plugin
- `mywildlifecam.fyi` live on the internet with five pages (home, about, disclosure, privacy, contact)

**What's still empty:**
- No reviews yet — content commands ship in Phase 2.
- The site is structurally complete but has no actual product content. That's fine; the bones are right.

**Phase 2 will cover:**
- `tools/status/` engine with `sites.json` and the scanners (broken-link, price-drift, age, GSC-rank-drop)
- `/aff-status [site]`
- `/aff-next` (the routing entry point)
- `/aff-help` (cheatsheet command — same content as COMMANDS.md, rendered in-chat)
- `/aff-new-review <site> <product>` (the review writer)
- `/aff-refresh <site> [page]`
- `/aff-cycle <site>` (the quarterly orchestrator)
- The `Next:` footer helper, retrofitted across all commands
- Bootstrapping the remaining 4 sites
- The first real cycle on mywildlifecam (5 actual reviews)

When you're ready, run `/aff-bootstrap mywildlifecam` to confirm Phase 1 works end-to-end, then start Phase 2 planning.

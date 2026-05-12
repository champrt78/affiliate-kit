#!/usr/bin/env node
import { argv, exit, stdout } from "node:process";
import { join } from "node:path";
import { spawn } from "node:child_process";
import { loadConfig } from "./config.js";
import { copyTemplate } from "./copy-template.js";
import { createPagesProject, deployPages, attachDomain } from "./cloudflare-pages.js";
import { getZoneId, createOrUpdateRecord } from "./cloudflare-dns.js";
import { createR2Bucket } from "./cloudflare-r2.js";
import { attachWorkerRoute } from "./cloudflare-worker-route.js";

interface BootstrapArgs {
  slug: string;
  siteName: string;
  siteUrl: string;
  niche: string;
  tagline: string;
  contactEmail: string;
  apex: string;
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
  let inFlag = false;
  for (const a of argv.slice(2)) {
    if (a.startsWith("--")) {
      flagArgs.push(a);
      inFlag = true;
    } else if (inFlag) {
      flagArgs.push(a);
      inFlag = false;
    } else {
      positional.push(a);
    }
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

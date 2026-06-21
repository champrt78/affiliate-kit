#!/usr/bin/env node
import { program } from "commander";
import { join } from "node:path";
import { loadConfig } from "./config.js";
import { copyTemplate } from "./copy-template.js";
import { createPagesProject, deployPages, attachDomain } from "./cloudflare-pages.js";
import { getZoneId, createOrUpdateRecord } from "./cloudflare-dns.js";
import { createR2Bucket } from "./cloudflare-r2.js";
import { attachWorkerRoute } from "./cloudflare-worker-route.js";
import { runShell } from "./run-shell.js";

program
  .name("affkit-bootstrap")
  .description("Bootstrap a new affiliate site")
  .version("0.0.1");

program
  .command("create <slug>")
  .description("Create a new site from the template")
  .requiredOption("--site-name <name>", "Site display name")
  .requiredOption("--site-url <url>", "Site URL")
  .requiredOption("--niche <niche>", "Site niche")
  .requiredOption("--tagline <tagline>", "Site tagline")
  .requiredOption("--contact-email <email>", "Contact email")
  .requiredOption("--apex <apex>", "Apex domain")
  .action(async (slug, options) => {
    const config = await loadConfig();
    const sitePath = join(config.monorepo_path, "sites", slug);

    await copyTemplate({
      monorepoRoot: config.monorepo_path,
      slug,
      siteName: options.siteName,
      siteUrl: options.siteUrl,
      niche: options.niche,
      tagline: options.tagline,
      contactEmail: options.contactEmail,
    });
    console.log(`Created sites/${slug}`);

    const projectName = `affkit-${slug}`;
    const accountId = config.tokens.cloudflare_account_id;
    const apiToken = config.tokens.cloudflare_api;

    console.log("Installing dependencies...");
    await runShell("pnpm", ["install"], config.monorepo_path);

    console.log("Building site...");
    await runShell("pnpm", ["--filter", `@affkit/${slug}`, "build"], config.monorepo_path);

    console.log("Provisioning Cloudflare...");
    const zoneId = await getZoneId(options.apex, apiToken);
    await createR2Bucket({ bucketName: `${slug}-images`, apiToken, accountId });
    await createPagesProject({ projectName, productionBranch: "main", apiToken, accountId });
    const deployment = await deployPages({
      projectName,
      outputDir: join(sitePath, "dist"),
      branch: "main",
      apiToken,
      accountId,
    });
    await attachDomain({ projectName, domain: options.apex, apiToken, accountId });
    await createOrUpdateRecord({
      zoneId,
      apiToken,
      type: "CNAME",
      name: "@",
      content: `${projectName}.pages.dev`,
      proxied: true,
    });
    await attachWorkerRoute({
      zoneId,
      pattern: `${options.apex}/go/*`,
      scriptName: "affkit-link-cloaker",
      apiToken,
    });

    console.log(`Site live at ${deployment.url}`);
  });

program.parse();

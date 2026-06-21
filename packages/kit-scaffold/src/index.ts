#!/usr/bin/env node
import { program } from "commander";
import { scaffoldReview } from "./scaffold-review.js";
import { scaffoldGuide } from "./scaffold-guide.js";
import { writeReviewPrompt } from "./prompt.js";
import { registerCloakedLink } from "./kv.js";
import { readSiteConfig } from "./config-reader.js";
import { runShell } from "./run-shell.js";

program.name("affkit-scaffold").version("0.0.1");

program
  .command("review <site> <slug>")
  .requiredOption("--product <product>", "Product name")
  .requiredOption("--brand <brand>", "Brand")
  .requiredOption("--url <url>", "Amazon affiliate URL")
  .option("--description <description>", "Short description")
  .option("--sku <sku>", "SKU")
  .option("--tag <tag>", "Amazon tag")
  .action(async (site, slug, options) => {
    const repoRoot = process.cwd();
    const path = await scaffoldReview({
      repoRoot,
      site,
      slug,
      productName: options.product,
      brand: options.brand,
      amazonUrl: options.url,
      description: options.description ?? "",
      sku: options.sku,
      tag: options.tag,
    });
    await writeReviewPrompt({
      repoRoot,
      site,
      slug,
      productName: options.product,
      brand: options.brand,
      amazonUrl: options.url,
      description: options.description ?? "",
    });

    const apiToken = process.env.CLOUDFLARE_API_TOKEN;
    const accountId = process.env.CLOUDFLARE_ACCOUNT_ID;
    if (!apiToken || !accountId) {
      throw new Error("CLOUDFLARE_API_TOKEN and CLOUDFLARE_ACCOUNT_ID must be set to register cloaked links");
    }

    await registerCloakedLink({
      repoRoot,
      site,
      slug,
      url: options.url,
      tag: options.tag,
      merchant: "amazon",
      apiToken,
      accountId,
    });
    console.log(`Registered cloaked link /go/${slug}`);

    await runShell("pnpm", ["--filter", site, "build"], repoRoot);
    console.log(`Scaffolded review at ${path} and build clean.`);
  });

program
  .command("guide <site> <slug>")
  .requiredOption("--title <title>", "Guide title")
  .requiredOption("--niche <niche>", "Niche")
  .option("--description <description>", "Short description")
  .action(async (site, slug, options) => {
    const repoRoot = process.cwd();
    const config = await readSiteConfig(repoRoot, site);
    const path = await scaffoldGuide({
      repoRoot,
      site,
      slug,
      title: options.title,
      niche: options.niche ?? config.niche,
      description: options.description ?? "",
    });
    console.log(`Scaffolded buyer's guide at ${path}`);
    await runShell("pnpm", ["--filter", site, "build"], repoRoot);
    console.log("Build clean.");
  });

program.parse();

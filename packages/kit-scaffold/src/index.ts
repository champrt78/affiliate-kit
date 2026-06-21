#!/usr/bin/env node
import { program } from "commander";
import { scaffoldReview } from "./scaffold-review.js";
import { scaffoldGuide } from "./scaffold-guide.js";
import { writeReviewPrompt } from "./prompt.js";
import { registerCloakedLink } from "./kv.js";
import { readSiteConfig } from "./config-reader.js";

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
    console.log(`Scaffolded review at ${path}`);
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
  });

program.parse();

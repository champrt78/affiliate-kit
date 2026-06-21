#!/usr/bin/env node
import { program } from "commander";
import { loadConfig } from "./config.js";
import { copyTemplate } from "./copy-template.js";

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
  });

program.parse();

import { cp, readFile, writeFile, stat } from "node:fs/promises";
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

function applyReplacements(content: string, input: CopyTemplateInput): string {
  return content
    .replaceAll("__SITE_NAME__", input.siteName)
    .replaceAll("__SITE_SLUG__", input.slug)
    .replaceAll("__SITE_URL__", input.siteUrl)
    .replaceAll("__NICHE__", input.niche)
    .replaceAll("__TAGLINE__", input.tagline)
    .replaceAll("__CONTACT_EMAIL__", input.contactEmail);
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

  await cp(source, dest, {
    recursive: true,
    filter: (src) => {
      const normalized = src.replaceAll("\\", "/");
      return !normalized.includes("/node_modules") && !normalized.includes("/.astro") && !normalized.includes("/dist");
    },
  });

  const pkgPath = join(dest, "package.json");
  if (await exists(pkgPath)) {
    const pkg = JSON.parse(await readFile(pkgPath, "utf-8")) as { name?: string };
    pkg.name = `@affkit/${input.slug}`;
    await writeFile(pkgPath, JSON.stringify(pkg, null, 2) + "\n", "utf-8");
  }

  const configPath = join(dest, "src", "data", "site-config.json");
  if (await exists(configPath)) {
    const config = await readFile(configPath, "utf-8");
    const updated = applyReplacements(config, input);
    await writeFile(configPath, updated, "utf-8");
  }

  const astroConfigPath = join(dest, "astro.config.mjs");
  if (await exists(astroConfigPath)) {
    const config = await readFile(astroConfigPath, "utf-8");
    const updated = applyReplacements(config, input);
    await writeFile(astroConfigPath, updated, "utf-8");
  }
}

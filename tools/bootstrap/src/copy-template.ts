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

  await rewriteTextFiles(dest, input);
}

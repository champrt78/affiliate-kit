import { readFile } from "node:fs/promises";
import { join } from "node:path";

export interface SiteConfig {
  siteName: string;
  siteUrl: string;
  niche: string;
  tagline: string;
  contactEmail: string;
  affiliate?: { amazonTag?: string };
  brandTone?: string;
}

export async function readSiteConfig(repoRoot: string, site: string): Promise<SiteConfig> {
  const path = join(repoRoot, "sites", site, "src", "data", "site-config.json");
  const raw = await readFile(path, "utf-8");
  return JSON.parse(raw) as SiteConfig;
}

import { readFile } from "node:fs/promises";
import { homedir } from "node:os";
import { join } from "node:path";

export interface PluginConfig {
  monorepo_path: string;
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
        `Plugin config not found at ${path}. See docs/SETUP.md for first-time setup.`
      );
    }
    throw err;
  }
}

import { readFile } from "node:fs/promises";
import { join } from "node:path";
import { runWrangler, withCfToken } from "./wrangler.js";

export async function registerCloakedLink(options: {
  repoRoot: string;
  site: string;
  slug: string;
  url: string;
  tag?: string;
  merchant?: "amazon" | "other";
  apiToken: string;
  accountId: string;
}): Promise<void> {
  const wranglerTomlPath = join(options.repoRoot, "workers/link-cloaker/wrangler.toml");
  const namespaceId = await parseKvNamespaceId(wranglerTomlPath);
  const envelope = {
    url: options.url,
    merchant: options.merchant ?? "amazon",
    status: "active",
    updated: new Date().toISOString().slice(0, 10),
    ...(options.tag ? { tag: options.tag } : {}),
  };
  const key = `${options.site}:${options.slug}`;
  const env = withCfToken(options.apiToken, options.accountId);
  const result = await runWrangler(
    ["kv", "key", "put", "--remote", "--namespace-id", namespaceId, key, JSON.stringify(envelope)],
    env
  );
  if (result.exitCode !== 0) {
    throw new Error(`KV put failed: ${result.stderr || result.stdout}`);
  }
}

async function parseKvNamespaceId(tomlPath: string): Promise<string> {
  const content = await readFile(tomlPath, "utf-8");
  const lines = content.split("\n");
  let inKv = false;
  for (const line of lines) {
    const trimmed = line.trim();
    if (trimmed === "[[kv_namespaces]]") { inKv = true; continue; }
    if (inKv && trimmed.startsWith("[[")) { inKv = false; continue; }
    if (inKv) {
      const match = trimmed.match(/^id\s*=\s*"([^"]+)"/);
      if (match) return match[1];
    }
  }
  throw new Error(`Could not find KV namespace id in ${tomlPath}`);
}

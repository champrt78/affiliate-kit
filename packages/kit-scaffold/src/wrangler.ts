import { spawn } from "node:child_process";

export interface WranglerResult {
  stdout: string;
  stderr: string;
  exitCode: number;
}

export async function runWrangler(args: string[], env: NodeJS.ProcessEnv = process.env): Promise<WranglerResult> {
  return new Promise((resolve, reject) => {
    const child = spawn("wrangler", args, { env, shell: process.platform === "win32" });
    let stdout = "";
    let stderr = "";
    child.stdout.on("data", (chunk) => (stdout += chunk.toString()));
    child.stderr.on("data", (chunk) => (stderr += chunk.toString()));
    child.on("error", reject);
    child.on("close", (code) => resolve({ stdout, stderr, exitCode: code ?? -1 }));
  });
}

export function withCfToken(token: string, accountId: string): NodeJS.ProcessEnv {
  return { ...process.env, CLOUDFLARE_API_TOKEN: token, CLOUDFLARE_ACCOUNT_ID: accountId };
}

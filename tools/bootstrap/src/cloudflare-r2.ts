import { runWrangler, withCfToken } from "./wrangler";

export interface CreateR2BucketInput {
  bucketName: string;
  apiToken: string;
  accountId: string;
}

export async function createR2Bucket(input: CreateR2BucketInput): Promise<void> {
  const env = withCfToken(input.apiToken, input.accountId);
  const result = await runWrangler(["r2", "bucket", "create", input.bucketName], env);
  if (result.exitCode !== 0) {
    const combined = `${result.stderr}\n${result.stdout}`;
    if (combined.includes("already exists")) {
      return;
    }
    if (combined.includes("Please enable R2") || combined.includes("[code: 10042]")) {
      console.warn(
        `  ⚠  R2 not enabled on account — skipping bucket create for ${input.bucketName}. Enable R2 in the Cloudflare dashboard when ready for Phase 2 image hosting.`
      );
      return;
    }
    throw new Error(
      `wrangler r2 bucket create failed (exit ${result.exitCode}): ${result.stderr || result.stdout}`
    );
  }
}

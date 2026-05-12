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
    if (
      result.stderr.includes("already exists") ||
      result.stdout.includes("already exists")
    ) {
      return;
    }
    throw new Error(
      `wrangler r2 bucket create failed (exit ${result.exitCode}): ${result.stderr || result.stdout}`
    );
  }
}

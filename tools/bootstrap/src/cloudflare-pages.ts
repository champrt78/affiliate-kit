import { runWrangler, withCfToken } from "./wrangler";

export interface CreatePagesProjectInput {
  projectName: string;
  productionBranch: string;
  apiToken: string;
  accountId: string;
}

export async function createPagesProject(input: CreatePagesProjectInput): Promise<void> {
  const env = withCfToken(input.apiToken, input.accountId);
  const result = await runWrangler(
    [
      "pages",
      "project",
      "create",
      input.projectName,
      "--production-branch",
      input.productionBranch,
    ],
    env
  );
  if (result.exitCode !== 0) {
    if (result.stderr.includes("already exists") || result.stdout.includes("already exists")) {
      return;
    }
    throw new Error(
      `wrangler pages project create failed (exit ${result.exitCode}): ${result.stderr || result.stdout}`
    );
  }
}

export interface DeployPagesInput {
  projectName: string;
  outputDir: string;
  branch: string;
  apiToken: string;
  accountId: string;
}

export async function deployPages(input: DeployPagesInput): Promise<{ url: string }> {
  const env = withCfToken(input.apiToken, input.accountId);
  const result = await runWrangler(
    [
      "pages",
      "deploy",
      input.outputDir,
      "--project-name",
      input.projectName,
      "--branch",
      input.branch,
    ],
    env
  );
  if (result.exitCode !== 0) {
    throw new Error(
      `wrangler pages deploy failed (exit ${result.exitCode}): ${result.stderr || result.stdout}`
    );
  }
  const match = result.stdout.match(/https:\/\/[^\s]+pages\.dev/);
  if (!match) {
    throw new Error(`could not parse deployment URL from wrangler output: ${result.stdout}`);
  }
  return { url: match[0] };
}

export interface AttachDomainInput {
  projectName: string;
  domain: string;
  apiToken: string;
  accountId: string;
}

export async function attachDomain(input: AttachDomainInput): Promise<void> {
  const env = withCfToken(input.apiToken, input.accountId);
  const result = await runWrangler(
    ["pages", "domain", "add", input.domain, "--project-name", input.projectName],
    env
  );
  if (result.exitCode !== 0) {
    if (result.stderr.includes("already") || result.stdout.includes("already")) {
      return;
    }
    throw new Error(
      `wrangler pages domain add failed (exit ${result.exitCode}): ${result.stderr || result.stdout}`
    );
  }
}

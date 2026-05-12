async function cfFetch(
  path: string,
  apiToken: string,
  init?: RequestInit
): Promise<unknown> {
  const res = await fetch(`https://api.cloudflare.com/client/v4${path}`, {
    ...init,
    headers: {
      Authorization: `Bearer ${apiToken}`,
      "Content-Type": "application/json",
      ...(init?.headers ?? {}),
    },
  });
  const body = (await res.json()) as { success: boolean; errors?: unknown[]; result?: unknown };
  if (!body.success) {
    throw new Error(`Cloudflare API ${path} failed: ${JSON.stringify(body.errors)}`);
  }
  return body.result;
}

export interface AttachWorkerRouteInput {
  zoneId: string;
  pattern: string;
  scriptName: string;
  apiToken: string;
}

export async function attachWorkerRoute(input: AttachWorkerRouteInput): Promise<void> {
  const existing = (await cfFetch(
    `/zones/${input.zoneId}/workers/routes`,
    input.apiToken
  )) as Array<{ id: string; pattern: string; script: string }>;

  const match = existing.find((r) => r.pattern === input.pattern);
  if (match) {
    if (match.script === input.scriptName) return;
    await cfFetch(
      `/zones/${input.zoneId}/workers/routes/${match.id}`,
      input.apiToken,
      {
        method: "PUT",
        body: JSON.stringify({ pattern: input.pattern, script: input.scriptName }),
      }
    );
  } else {
    await cfFetch(`/zones/${input.zoneId}/workers/routes`, input.apiToken, {
      method: "POST",
      body: JSON.stringify({ pattern: input.pattern, script: input.scriptName }),
    });
  }
}

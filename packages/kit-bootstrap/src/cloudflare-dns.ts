export interface DnsInput {
  zoneId: string;
  apiToken: string;
}

export interface CreateRecordInput extends DnsInput {
  type: "A" | "AAAA" | "CNAME" | "TXT";
  name: string;
  content: string;
  proxied?: boolean;
  ttl?: number;
}

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
    throw new Error(
      `Cloudflare API ${path} failed: ${JSON.stringify(body.errors)}`
    );
  }
  return body.result;
}

export async function getZoneId(domain: string, apiToken: string): Promise<string> {
  const result = (await cfFetch(`/zones?name=${encodeURIComponent(domain)}`, apiToken)) as Array<{
    id: string;
    name: string;
  }>;
  if (result.length === 0) {
    throw new Error(
      `zone ${domain} not found in this Cloudflare account. Add it via dashboard first.`
    );
  }
  return result[0].id;
}

export async function createOrUpdateRecord(input: CreateRecordInput): Promise<void> {
  const existing = (await cfFetch(
    `/zones/${input.zoneId}/dns_records?type=${input.type}&name=${encodeURIComponent(input.name)}`,
    input.apiToken
  )) as Array<{ id: string }>;

  const payload = {
    type: input.type,
    name: input.name,
    content: input.content,
    proxied: input.proxied ?? false,
    ttl: input.ttl ?? 1,
  };

  if (existing.length > 0) {
    await cfFetch(
      `/zones/${input.zoneId}/dns_records/${existing[0].id}`,
      input.apiToken,
      { method: "PUT", body: JSON.stringify(payload) }
    );
  } else {
    await cfFetch(`/zones/${input.zoneId}/dns_records`, input.apiToken, {
      method: "POST",
      body: JSON.stringify(payload),
    });
  }
}

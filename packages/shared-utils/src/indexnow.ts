export interface IndexNowInput {
  host: string;
  key: string;
  keyLocation: string;
  urls: string[];
}

export interface IndexNowResult {
  ok: boolean;
  status: number;
}

const INDEXNOW_ENDPOINT = "https://api.indexnow.org/IndexNow";

export async function submitToIndexNow(input: IndexNowInput): Promise<IndexNowResult> {
  if (input.urls.length === 0) {
    throw new Error("urls cannot be empty");
  }
  if (input.urls.length > 10000) {
    throw new Error("urls cannot exceed 10000 entries per request");
  }

  const response = await fetch(INDEXNOW_ENDPOINT, {
    method: "POST",
    headers: { "Content-Type": "application/json; charset=utf-8" },
    body: JSON.stringify({
      host: input.host,
      key: input.key,
      keyLocation: input.keyLocation,
      urlList: input.urls,
    }),
  });

  return { ok: response.ok, status: response.status };
}

import { describe, it, expect, vi, beforeEach } from "vitest";
import { submitToIndexNow } from "../src/indexnow";

describe("submitToIndexNow", () => {
  beforeEach(() => {
    vi.restoreAllMocks();
  });

  it("posts a single-URL payload to api.indexnow.org", async () => {
    const fetchMock = vi
      .spyOn(globalThis, "fetch")
      .mockResolvedValue(new Response(null, { status: 200 }));
    const result = await submitToIndexNow({
      host: "mywildlifecam.fyi",
      key: "abc123",
      keyLocation: "https://mywildlifecam.fyi/abc123.txt",
      urls: ["https://mywildlifecam.fyi/reviews/reconyx-hc600"],
    });
    expect(result.ok).toBe(true);
    expect(result.status).toBe(200);
    expect(fetchMock).toHaveBeenCalledOnce();
    const [url, init] = fetchMock.mock.calls[0];
    expect(url).toBe("https://api.indexnow.org/IndexNow");
    expect(init?.method).toBe("POST");
    expect(init?.headers).toMatchObject({
      "Content-Type": "application/json; charset=utf-8",
    });
    expect(JSON.parse(init?.body as string)).toEqual({
      host: "mywildlifecam.fyi",
      key: "abc123",
      keyLocation: "https://mywildlifecam.fyi/abc123.txt",
      urlList: ["https://mywildlifecam.fyi/reviews/reconyx-hc600"],
    });
  });

  it("returns ok=false when the API responds with 4xx", async () => {
    vi.spyOn(globalThis, "fetch").mockResolvedValue(
      new Response("bad request", { status: 422 })
    );
    const result = await submitToIndexNow({
      host: "mywildlifecam.fyi",
      key: "abc123",
      keyLocation: "https://mywildlifecam.fyi/abc123.txt",
      urls: ["https://mywildlifecam.fyi/x"],
    });
    expect(result.ok).toBe(false);
    expect(result.status).toBe(422);
  });

  it("rejects an empty URL list", async () => {
    await expect(
      submitToIndexNow({
        host: "mywildlifecam.fyi",
        key: "abc123",
        keyLocation: "https://mywildlifecam.fyi/abc123.txt",
        urls: [],
      })
    ).rejects.toThrow("urls cannot be empty");
  });

  it("rejects more than 10000 URLs in one call", async () => {
    const urls = Array.from(
      { length: 10001 },
      (_, i) => `https://mywildlifecam.fyi/p${i}`
    );
    await expect(
      submitToIndexNow({
        host: "mywildlifecam.fyi",
        key: "abc123",
        keyLocation: "https://mywildlifecam.fyi/abc123.txt",
        urls,
      })
    ).rejects.toThrow("urls cannot exceed 10000 entries per request");
  });
});

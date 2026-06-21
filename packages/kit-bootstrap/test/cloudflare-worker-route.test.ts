import { describe, it, expect, vi, beforeEach, afterEach } from "vitest";
import { attachWorkerRoute } from "../src/cloudflare-worker-route.js";

describe("attachWorkerRoute", () => {
  let originalFetch: typeof global.fetch;

  beforeEach(() => {
    originalFetch = global.fetch;
  });

  afterEach(() => {
    global.fetch = originalFetch;
  });

  it("posts a worker route to the Cloudflare API", async () => {
    global.fetch = vi
      .fn()
      .mockResolvedValueOnce({
        json: async () => ({ success: true, result: [] }),
      } as Response)
      .mockResolvedValueOnce({
        json: async () => ({ success: true, result: { id: "route123" } }),
      } as Response);

    await attachWorkerRoute({
      zoneId: "zone123",
      pattern: "example.com/go/*",
      scriptName: "affkit-link-cloaker",
      apiToken: "token",
    });

    expect(global.fetch).toHaveBeenCalledTimes(2);
    const [url, init] = vi.mocked(global.fetch).mock.calls[1];
    expect(url).toContain("zones/zone123/workers/routes");
    expect(init?.method).toBe("POST");
  });
});

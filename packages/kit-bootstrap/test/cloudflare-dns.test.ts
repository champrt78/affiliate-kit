import { describe, it, expect, vi, beforeEach, afterEach } from "vitest";
import { getZoneId, createOrUpdateRecord } from "../src/cloudflare-dns.js";

describe("getZoneId", () => {
  let originalFetch: typeof global.fetch;

  beforeEach(() => {
    originalFetch = global.fetch;
  });

  afterEach(() => {
    global.fetch = originalFetch;
  });

  it("returns the zone id when fetch succeeds", async () => {
    global.fetch = vi.fn().mockResolvedValue({
      json: async () => ({ success: true, result: [{ id: "zone123", name: "example.com" }] }),
    } as Response);

    const id = await getZoneId("example.com", "token");
    expect(id).toBe("zone123");
  });

  it("throws when zone is not found", async () => {
    global.fetch = vi.fn().mockResolvedValue({
      json: async () => ({ success: true, result: [] }),
    } as Response);

    await expect(getZoneId("example.com", "token")).rejects.toThrow(/not found/);
  });
});

describe("createOrUpdateRecord", () => {
  let originalFetch: typeof global.fetch;

  beforeEach(() => {
    originalFetch = global.fetch;
  });

  afterEach(() => {
    global.fetch = originalFetch;
  });

  it("creates a new record when none exists", async () => {
    global.fetch = vi.fn().mockResolvedValue({
      json: async () => ({ success: true, result: [] }),
    } as Response);

    await createOrUpdateRecord({
      zoneId: "zone123",
      apiToken: "token",
      type: "A",
      name: "sub.example.com",
      content: "192.0.2.1",
    });

    expect(global.fetch).toHaveBeenCalledTimes(2);
    const [, secondInit] = (global.fetch as ReturnType<typeof vi.fn>).mock.calls[1];
    expect(secondInit.method).toBe("POST");
  });
});

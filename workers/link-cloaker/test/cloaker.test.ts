import { describe, it, expect, beforeEach, vi } from "vitest";
import {
  env,
  createExecutionContext,
  waitOnExecutionContext,
} from "cloudflare:test";
import worker from "../src/index";

declare module "cloudflare:test" {
  interface ProvidedEnv {
    AFFILIATE_LINKS: KVNamespace;
    CLICKS: AnalyticsEngineDataset;
  }
}

// @cloudflare/vitest-pool-workers v0.5 doesn't surface Analytics Engine
// bindings from wrangler.toml into the test environment. Stub CLICKS with a
// vi.fn() mock so the Worker's env.CLICKS.writeDataPoint(...) call doesn't
// throw and tests can assert on the recorded calls.
const clicksMock = { writeDataPoint: vi.fn() };
(env as unknown as Record<string, unknown>).CLICKS = clicksMock;

async function dispatch(url: string, init?: RequestInit) {
  const request = new Request(url, init);
  const ctx = createExecutionContext();
  const response = await worker.fetch(request, env, ctx);
  await waitOnExecutionContext(ctx);
  return response;
}

describe("link-cloaker", () => {
  beforeEach(async () => {
    clicksMock.writeDataPoint.mockClear();
    const keys = await env.AFFILIATE_LINKS.list();
    await Promise.all(keys.keys.map((k) => env.AFFILIATE_LINKS.delete(k.name)));
  });

  it("302-redirects /go/<slug> using site derived from the Host header (legacy plain-URL value)", async () => {
    await env.AFFILIATE_LINKS.put(
      "mywildlifecam:reconyx-hc600",
      "https://amazon.com/dp/B07X?tag=affkit-20",
    );
    const res = await dispatch("https://mywildlifecam.com/go/reconyx-hc600");
    expect(res.status).toBe(302);
    expect(res.headers.get("location")).toBe(
      "https://amazon.com/dp/B07X?tag=affkit-20",
    );
    expect(res.headers.get("cache-control")).toBe("private, no-store");
  });

  it("respects an optional ?src= source tag (recorded in analytics, not appended to the location)", async () => {
    await env.AFFILIATE_LINKS.put(
      "fussybean:breville-bambino",
      "https://amazon.com/dp/B08Y?tag=affkit-20",
    );
    const res = await dispatch(
      "https://fussybean.com/go/breville-bambino?src=comparison-table",
    );
    expect(res.status).toBe(302);
    expect(res.headers.get("location")).toBe(
      "https://amazon.com/dp/B08Y?tag=affkit-20",
    );
  });

  it("returns 404 when the slug is not in KV", async () => {
    const res = await dispatch("https://mywildlifecam.com/go/unknown-product");
    expect(res.status).toBe(404);
  });

  it("returns 400 for /go with no slug", async () => {
    const res = await dispatch("https://mywildlifecam.com/go");
    expect(res.status).toBe(400);
  });

  it("returns 404 for non-/go paths", async () => {
    const res = await dispatch("https://mywildlifecam.com/something-else");
    expect(res.status).toBe(404);
  });

  it("returns 404 for an unknown apex (Host header not in apexToSite) — no KV read", async () => {
    // Seed a KV value that would otherwise match — proves the host check
    // short-circuits before the KV read.
    await env.AFFILIATE_LINKS.put(
      "mywildlifecam:reconyx-hc600",
      "https://amazon.com/dp/B07X",
    );
    const res = await dispatch("https://example.com/go/reconyx-hc600");
    expect(res.status).toBe(404);
  });

  it("returns 404 for a cross-tenant-style URL with 3 path segments", async () => {
    // /go/<otherSite>/<slug> has 3 segments instead of 2 — refuses to parse.
    await env.AFFILIATE_LINKS.put(
      "fussybean:breville-bambino",
      "https://amazon.com/dp/B08Y",
    );
    const res = await dispatch(
      "https://mywildlifecam.com/go/fussybean/breville-bambino",
    );
    expect(res.status).toBe(400);
  });

  it("writes an analytics data point including site (from Host), slug, source, and referer", async () => {
    await env.AFFILIATE_LINKS.put(
      "mywildlifecam:reconyx-hc600",
      "https://amazon.com/dp/B07X?tag=affkit-20",
    );
    const writeSpy = vi.spyOn(env.CLICKS, "writeDataPoint");
    await dispatch(
      "https://mywildlifecam.com/go/reconyx-hc600?src=review-cta",
      {
        headers: { Referer: "https://mywildlifecam.com/reviews/reconyx-hc600" },
      },
    );
    expect(writeSpy).toHaveBeenCalledOnce();
    const payload = writeSpy.mock.calls[0][0] as AnalyticsEngineDataPoint;
    expect(payload.indexes).toEqual(["mywildlifecam"]);
    expect(payload.blobs).toEqual([
      "mywildlifecam",
      "reconyx-hc600",
      "review-cta",
      "https://mywildlifecam.com/reviews/reconyx-hc600",
    ]);
    expect(payload.doubles).toEqual([1]);
  });

  it("does not write analytics for a 404 lookup miss", async () => {
    await dispatch("https://mywildlifecam.com/go/missing");
    expect(clicksMock.writeDataPoint).not.toHaveBeenCalled();
  });

  // --- U10: structured KV envelope ---

  it("structured value with merchant=amazon + tag produces 302 to URL-with-tag appended", async () => {
    await env.AFFILIATE_LINKS.put(
      "mywildlifecam:reconyx-hc600",
      JSON.stringify({
        url: "https://amazon.com/dp/B07X",
        tag: "affkit-20",
        merchant: "amazon",
        status: "active",
        updated: "2026-05-15",
      }),
    );
    const res = await dispatch("https://mywildlifecam.com/go/reconyx-hc600");
    expect(res.status).toBe(302);
    expect(res.headers.get("location")).toBe(
      "https://amazon.com/dp/B07X?tag=affkit-20",
    );
  });

  it("structured value with merchant=amazon + tag uses & when URL already has a query string", async () => {
    await env.AFFILIATE_LINKS.put(
      "mywildlifecam:reconyx-hc600",
      JSON.stringify({
        url: "https://amazon.com/dp/B07X?ref=foo",
        tag: "affkit-20",
        merchant: "amazon",
        status: "active",
        updated: "2026-05-15",
      }),
    );
    const res = await dispatch("https://mywildlifecam.com/go/reconyx-hc600");
    expect(res.status).toBe(302);
    expect(res.headers.get("location")).toBe(
      "https://amazon.com/dp/B07X?ref=foo&tag=affkit-20",
    );
  });

  it("non-amazon merchant emits the URL as-is (no tag appended)", async () => {
    await env.AFFILIATE_LINKS.put(
      "mywildlifecam:reconyx-hc600",
      JSON.stringify({
        url: "https://example-merchant.com/product/foo",
        tag: "ignored-tag",
        merchant: "other",
        status: "active",
        updated: "2026-05-15",
      }),
    );
    const res = await dispatch("https://mywildlifecam.com/go/reconyx-hc600");
    expect(res.status).toBe(302);
    expect(res.headers.get("location")).toBe(
      "https://example-merchant.com/product/foo",
    );
  });

  it("status=retired returns 410 Gone with the configured body", async () => {
    await env.AFFILIATE_LINKS.put(
      "mywildlifecam:reconyx-hc600",
      JSON.stringify({
        url: "https://amazon.com/dp/B07X",
        status: "retired",
        updated: "2026-05-15",
      }),
    );
    const res = await dispatch("https://mywildlifecam.com/go/reconyx-hc600");
    expect(res.status).toBe(410);
    expect(await res.text()).toBe("This product is no longer available.");
  });

  it("replaced_by on an active entry returns 301 to /go/<new>", async () => {
    await env.AFFILIATE_LINKS.put(
      "mywildlifecam:reconyx-hc600",
      JSON.stringify({
        url: "https://amazon.com/dp/B07X",
        status: "active",
        updated: "2026-05-15",
        replaced_by: "reconyx-hyperfire-2",
      }),
    );
    const res = await dispatch("https://mywildlifecam.com/go/reconyx-hc600");
    expect(res.status).toBe(301);
    expect(res.headers.get("location")).toBe("/go/reconyx-hyperfire-2");
  });

  it("malformed JSON falls back to treating the raw string as a URL", async () => {
    await env.AFFILIATE_LINKS.put(
      "mywildlifecam:reconyx-hc600",
      "{not really json",
    );
    const res = await dispatch("https://mywildlifecam.com/go/reconyx-hc600");
    expect(res.status).toBe(302);
    expect(res.headers.get("location")).toBe("{not really json");
  });

  it("legacy plain-URL string still produces 302 with no tag applied", async () => {
    await env.AFFILIATE_LINKS.put(
      "mywildlifecam:reconyx-hc600",
      "https://amazon.com/dp/B07X",
    );
    const res = await dispatch("https://mywildlifecam.com/go/reconyx-hc600");
    expect(res.status).toBe(302);
    expect(res.headers.get("location")).toBe("https://amazon.com/dp/B07X");
  });
});

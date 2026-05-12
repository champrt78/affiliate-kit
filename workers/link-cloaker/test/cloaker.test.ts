import { describe, it, expect, beforeEach, vi } from "vitest";
import { env, createExecutionContext, waitOnExecutionContext } from "cloudflare:test";
import worker from "../src/index";

declare module "cloudflare:test" {
  interface ProvidedEnv {
    AFFILIATE_LINKS: KVNamespace;
    CLICKS: AnalyticsEngineDataset;
  }
}

async function dispatch(url: string, init?: RequestInit) {
  const request = new Request(url, init);
  const ctx = createExecutionContext();
  const response = await worker.fetch(request, env, ctx);
  await waitOnExecutionContext(ctx);
  return response;
}

describe("link-cloaker", () => {
  beforeEach(async () => {
    const keys = await env.AFFILIATE_LINKS.list();
    await Promise.all(keys.keys.map((k) => env.AFFILIATE_LINKS.delete(k.name)));
  });

  it("302-redirects /go/<site>/<slug> to the affiliate URL stored in KV", async () => {
    await env.AFFILIATE_LINKS.put(
      "mywildlifecam:reconyx-hc600",
      "https://amazon.com/dp/B07X?tag=affkit-20"
    );
    const res = await dispatch("https://mywildlifecam.fyi/go/mywildlifecam/reconyx-hc600");
    expect(res.status).toBe(302);
    expect(res.headers.get("location")).toBe("https://amazon.com/dp/B07X?tag=affkit-20");
    expect(res.headers.get("cache-control")).toBe("private, no-store");
  });

  it("respects an optional ?src= source tag in the redirect query (but does not include it in the location)", async () => {
    await env.AFFILIATE_LINKS.put(
      "fussybean:breville-bambino",
      "https://amazon.com/dp/B08Y?tag=affkit-20"
    );
    const res = await dispatch(
      "https://fussybean.com/go/fussybean/breville-bambino?src=comparison-table"
    );
    expect(res.status).toBe(302);
    expect(res.headers.get("location")).toBe("https://amazon.com/dp/B08Y?tag=affkit-20");
  });

  it("returns 404 when the slug is not in KV", async () => {
    const res = await dispatch("https://mywildlifecam.fyi/go/mywildlifecam/unknown-product");
    expect(res.status).toBe(404);
  });

  it("returns 400 for malformed /go paths", async () => {
    const res = await dispatch("https://mywildlifecam.fyi/go/onlyonepart");
    expect(res.status).toBe(400);
  });

  it("returns 404 for non-/go paths", async () => {
    const res = await dispatch("https://mywildlifecam.fyi/something-else");
    expect(res.status).toBe(404);
  });

  it("writes an analytics data point including site, slug, and source", async () => {
    await env.AFFILIATE_LINKS.put(
      "mywildlifecam:reconyx-hc600",
      "https://amazon.com/dp/B07X?tag=affkit-20"
    );
    const writeSpy = vi.spyOn(env.CLICKS, "writeDataPoint");
    await dispatch(
      "https://mywildlifecam.fyi/go/mywildlifecam/reconyx-hc600?src=review-cta",
      { headers: { Referer: "https://mywildlifecam.fyi/reviews/reconyx-hc600" } }
    );
    expect(writeSpy).toHaveBeenCalledOnce();
    const payload = writeSpy.mock.calls[0][0] as AnalyticsEngineDataPoint;
    expect(payload.indexes).toEqual(["mywildlifecam"]);
    expect(payload.blobs).toEqual([
      "mywildlifecam",
      "reconyx-hc600",
      "review-cta",
      "https://mywildlifecam.fyi/reviews/reconyx-hc600",
    ]);
    expect(payload.doubles).toEqual([1]);
  });

  it("does not write analytics for a 404 lookup miss", async () => {
    const writeSpy = vi.spyOn(env.CLICKS, "writeDataPoint");
    await dispatch("https://mywildlifecam.fyi/go/mywildlifecam/missing");
    expect(writeSpy).not.toHaveBeenCalled();
  });
});

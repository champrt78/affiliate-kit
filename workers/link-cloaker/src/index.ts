export interface Env {
  AFFILIATE_LINKS: KVNamespace;
  CLICKS: AnalyticsEngineDataset;
}

export default {
  async fetch(req: Request, env: Env, _ctx: ExecutionContext): Promise<Response> {
    const url = new URL(req.url);
    const parts = url.pathname.split("/").filter(Boolean);

    if (parts[0] !== "go") {
      return new Response("not found", { status: 404 });
    }
    if (parts.length !== 3) {
      return new Response("bad request", { status: 400 });
    }

    const site = parts[1];
    const slug = parts[2];
    const source = url.searchParams.get("src") ?? "";
    const referer = req.headers.get("Referer") ?? "";

    const kvKey = `${site}:${slug}`;
    const target = await env.AFFILIATE_LINKS.get(kvKey);

    if (!target) {
      return new Response("not found", { status: 404 });
    }

    env.CLICKS.writeDataPoint({
      indexes: [site],
      blobs: [site, slug, source, referer],
      doubles: [1],
    });

    return new Response(null, {
      status: 302,
      headers: {
        location: target,
        "cache-control": "private, no-store",
      },
    });
  },
};

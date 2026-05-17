export interface Env {
  AFFILIATE_LINKS: KVNamespace;
  CLICKS: AnalyticsEngineDataset;
}

// Map each known apex to its canonical site slug. Requests from any other
// host return 404 with no KV read — closes the cross-tenant link-leak.
const apexToSite: Record<string, string> = {
  "mywildlifecam.com": "mywildlifecam",
  "fussybean.com": "fussybean",
  "detailerpicks.com": "detailerpicks",
  "starteraquarium.com": "starteraquarium",
  "gameovergear.games": "gameovergear",
};

type KVLinkValue = {
  url: string;
  tag?: string;
  merchant?: "amazon" | "other";
  status: "active" | "retired";
  updated: string;
  replaced_by?: string;
};

// Inlined parser (mirrors packages/shared-utils/src/kv-link.ts; Workers build
// keeps the runtime bundle tiny — no cross-package import to avoid bundling
// extra surface area into the Worker).
function parseKVValue(raw: string): KVLinkValue {
  try {
    const parsed: unknown = JSON.parse(raw);
    if (
      parsed !== null &&
      typeof parsed === "object" &&
      !Array.isArray(parsed) &&
      typeof (parsed as { url?: unknown }).url === "string" &&
      (parsed as { url: string }).url.length > 0
    ) {
      const obj = parsed as Record<string, unknown>;
      const status: "active" | "retired" = obj.status === "retired" ? "retired" : "active";
      const value: KVLinkValue = {
        url: obj.url as string,
        status,
        updated: typeof obj.updated === "string" ? obj.updated : "unknown",
      };
      if (typeof obj.tag === "string" && obj.tag.length > 0) {
        value.tag = obj.tag;
      }
      if (obj.merchant === "amazon" || obj.merchant === "other") {
        value.merchant = obj.merchant;
      }
      if (typeof obj.replaced_by === "string" && obj.replaced_by.length > 0) {
        value.replaced_by = obj.replaced_by;
      }
      return value;
    }
  } catch {
    // fall through to legacy fallback
  }
  return { url: raw, status: "active", updated: "unknown" };
}

function applyAmazonTag(url: string, tag: string): string {
  return `${url}${url.includes("?") ? "&" : "?"}tag=${tag}`;
}

export default {
  async fetch(req: Request, env: Env, _ctx: ExecutionContext): Promise<Response> {
    const url = new URL(req.url);

    // Derive site from Host header, not from URL path. Unknown host → 404
    // with no KV read.
    const host = (req.headers.get("host") ?? url.hostname).toLowerCase();
    const site = apexToSite[host];
    if (!site) {
      return new Response("not found", { status: 404 });
    }

    const parts = url.pathname.split("/").filter(Boolean);

    if (parts[0] !== "go" || !parts[1]) {
      return new Response("not found", { status: 404 });
    }
    // Slug is parts[1]; ignore anything past it. CF Pages may rewrite
    // /go/<slug> to /go/<slug>/index.html or similar after the domain
    // migration from direct-upload to Git-connected projects. The original
    // U9 strict-length check (parts.length !== 2 → 400) was too rigid and
    // bit us after the 2026-05-16 mywildlifecam Pages migration.
    // Cross-tenant attempts (e.g. /go/<otherSite>/<slug>) end up looking up
    // a slug that won't exist in this site's KV namespace, so the 404 from
    // the KV miss below still closes the cross-tenant leak.
    const slug = parts[1];
    const source = url.searchParams.get("src") ?? "";
    const referer = req.headers.get("Referer") ?? "";

    // KV storage stays namespaced by site even though the URL is clean.
    const kvKey = `${site}:${slug}`;
    const raw = await env.AFFILIATE_LINKS.get(kvKey);

    if (!raw) {
      return new Response("not found", { status: 404 });
    }

    const value = parseKVValue(raw);

    if (value.status === "retired") {
      return new Response("This product is no longer available.", { status: 410 });
    }

    if (value.replaced_by) {
      return new Response(null, {
        status: 301,
        headers: {
          location: `/go/${value.replaced_by}`,
          "cache-control": "private, no-store",
        },
      });
    }

    const target =
      value.merchant === "amazon" && value.tag
        ? applyAmazonTag(value.url, value.tag)
        : value.url;

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

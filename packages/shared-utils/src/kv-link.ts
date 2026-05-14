export type KVLinkMerchant = "amazon" | "other";
export type KVLinkStatus = "active" | "retired";

export interface KVLinkValue {
  url: string;
  tag?: string;
  merchant?: KVLinkMerchant;
  status: KVLinkStatus;
  updated: string; // ISO date string, or "unknown" for legacy fallback
  replaced_by?: string;
}

/**
 * Parse a raw KV value into a structured KVLinkValue.
 *
 * Tries JSON.parse first. If the parsed result is a plain object with a `url`
 * field, returns it (filling in defaults for status/updated when omitted).
 * Otherwise — JSON parse failure, non-object, or missing `url` — falls back
 * to treating the raw string as a plain URL. This makes the migration from
 * legacy plain-URL KV values zero-effort.
 */
export function parseKVValue(raw: string): KVLinkValue {
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
      const status: KVLinkStatus = obj.status === "retired" ? "retired" : "active";
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

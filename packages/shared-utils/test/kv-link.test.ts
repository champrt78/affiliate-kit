import { describe, it, expect } from "vitest";
import { parseKVValue } from "../src/kv-link";

describe("parseKVValue", () => {
  it("parses a structured envelope with all fields", () => {
    const raw = JSON.stringify({
      url: "https://amazon.com/dp/B07X",
      tag: "affkit-20",
      merchant: "amazon",
      status: "active",
      updated: "2026-05-15",
    });
    const v = parseKVValue(raw);
    expect(v.url).toBe("https://amazon.com/dp/B07X");
    expect(v.tag).toBe("affkit-20");
    expect(v.merchant).toBe("amazon");
    expect(v.status).toBe("active");
    expect(v.updated).toBe("2026-05-15");
    expect(v.replaced_by).toBeUndefined();
  });

  it("recognizes status: retired", () => {
    const raw = JSON.stringify({
      url: "https://amazon.com/dp/B07X",
      status: "retired",
      updated: "2026-05-15",
    });
    expect(parseKVValue(raw).status).toBe("retired");
  });

  it("preserves replaced_by when present", () => {
    const raw = JSON.stringify({
      url: "https://amazon.com/dp/B07X",
      status: "active",
      updated: "2026-05-15",
      replaced_by: "newer-slug",
    });
    expect(parseKVValue(raw).replaced_by).toBe("newer-slug");
  });

  it("falls back to plain-URL treatment when the JSON is malformed", () => {
    const v = parseKVValue("{not really json");
    expect(v.url).toBe("{not really json");
    expect(v.status).toBe("active");
    expect(v.updated).toBe("unknown");
    expect(v.tag).toBeUndefined();
    expect(v.merchant).toBeUndefined();
  });

  it("treats a legacy plain-URL string as { url, status: active, updated: unknown }", () => {
    const v = parseKVValue("https://amazon.com/dp/B07X");
    expect(v.url).toBe("https://amazon.com/dp/B07X");
    expect(v.status).toBe("active");
    expect(v.updated).toBe("unknown");
  });

  it("falls back when JSON parses but is missing the url field", () => {
    const raw = JSON.stringify({ tag: "affkit-20", status: "active" });
    const v = parseKVValue(raw);
    // Without a `url` field the parsed object is rejected and we fall back to
    // treating the raw input string as the url.
    expect(v.url).toBe(raw);
    expect(v.status).toBe("active");
    expect(v.updated).toBe("unknown");
  });
});

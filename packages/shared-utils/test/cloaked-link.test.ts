import { describe, it, expect } from "vitest";
import { cloakedLink, sanitizeSlug } from "../src/cloaked-link";

describe("sanitizeSlug", () => {
  it("lowercases and dashes spaces", () => {
    expect(sanitizeSlug("Reconyx HC600")).toBe("reconyx-hc600");
  });

  it("strips non-alphanumerics other than dash", () => {
    expect(sanitizeSlug("Breville Barista Express® (BES870)")).toBe(
      "breville-barista-express-bes870"
    );
  });

  it("collapses repeated dashes", () => {
    expect(sanitizeSlug("foo --  bar")).toBe("foo-bar");
  });

  it("trims leading and trailing dashes", () => {
    expect(sanitizeSlug("--foo--")).toBe("foo");
  });

  it("rejects empty input", () => {
    expect(() => sanitizeSlug("")).toThrow("slug cannot be empty");
    expect(() => sanitizeSlug("   ")).toThrow("slug cannot be empty");
  });
});

describe("cloakedLink", () => {
  it("builds a /go/<site>/<slug> path", () => {
    expect(cloakedLink({ site: "mywildlifecam", slug: "reconyx-hc600" })).toBe(
      "/go/mywildlifecam/reconyx-hc600"
    );
  });

  it("sanitizes the slug input", () => {
    expect(cloakedLink({ site: "mywildlifecam", slug: "Reconyx HC600" })).toBe(
      "/go/mywildlifecam/reconyx-hc600"
    );
  });

  it("accepts an optional source tag and appends it as a query param", () => {
    expect(
      cloakedLink({
        site: "fussybean",
        slug: "breville-bambino",
        source: "comparison-table",
      })
    ).toBe("/go/fussybean/breville-bambino?src=comparison-table");
  });

  it("sanitizes the source tag", () => {
    expect(
      cloakedLink({
        site: "fussybean",
        slug: "breville-bambino",
        source: "Comparison Table!",
      })
    ).toBe("/go/fussybean/breville-bambino?src=comparison-table");
  });

  it("rejects empty site", () => {
    expect(() => cloakedLink({ site: "", slug: "x" })).toThrow(
      "site cannot be empty"
    );
  });
});

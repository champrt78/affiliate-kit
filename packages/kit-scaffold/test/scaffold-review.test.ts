import { describe, it, expect, beforeEach, afterEach } from "vitest";
import { mkdtempSync, writeFileSync, mkdirSync, rmSync, readFileSync } from "node:fs";
import { tmpdir } from "node:os";
import { join } from "node:path";
import { scaffoldReview } from "../src/scaffold-review.js";

describe("scaffoldReview", () => {
  let root: string;

  beforeEach(() => {
    root = mkdtempSync(join(tmpdir(), "kit-scaffold-"));
    mkdirSync(join(root, "templates"), { recursive: true });
    mkdirSync(join(root, "sites", "mywildlifecam", "src", "content", "reviews"), { recursive: true });
    writeFileSync(
      join(root, "templates", "review.md.tmpl"),
      `---\ntitle: "__PRODUCT_NAME__ review"\n---\n# __PRODUCT_NAME__\n__SHORT_DESCRIPTION__`
    );
  });

  afterEach(() => {
    rmSync(root, { recursive: true, force: true });
  });

  it("writes the review file with replacements", async () => {
    const path = await scaffoldReview({
      repoRoot: root,
      site: "mywildlifecam",
      slug: "moultrie-edge-2-pro",
      productName: "Moultrie Edge 2 Pro",
      brand: "Moultrie",
      amazonUrl: "https://amzn.to/123",
      description: "A cellular trail camera.",
    });

    const content = readFileSync(path, "utf-8");
    expect(content).toContain("Moultrie Edge 2 Pro review");
    expect(content).toContain("A cellular trail camera.");
    expect(content).not.toContain("__PRODUCT_NAME__");
  });
});

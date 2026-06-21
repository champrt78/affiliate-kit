import { describe, it, expect, beforeEach, afterEach } from "vitest";
import { readFileSync } from "node:fs";
import { mkdtempSync, writeFileSync, mkdirSync, rmSync } from "node:fs";
import { tmpdir } from "node:os";
import { join } from "node:path";
import { copyTemplate } from "../src/copy-template.js";

describe("copyTemplate", () => {
  let root: string;

  beforeEach(() => {
    root = mkdtempSync(join(tmpdir(), "kit-bootstrap-"));
    mkdirSync(join(root, "templates", "site-template", "src"), { recursive: true });
    mkdirSync(join(root, "sites"), { recursive: true });
    writeFileSync(
      join(root, "templates", "site-template", "package.json"),
      JSON.stringify({ name: "@affkit/site-template" }, null, 2)
    );
    writeFileSync(
      join(root, "templates", "site-template", "src", "index.astro"),
      "Hello __SITE_NAME__ from __NICHE__"
    );
  });

  afterEach(() => {
    rmSync(root, { recursive: true, force: true });
  });

  it("copies the template and applies replacements", async () => {
    await copyTemplate({
      monorepoRoot: root,
      slug: "fussybeanv2",
      siteName: "Fussy Bean V2",
      siteUrl: "https://fussybeanv2.com",
      niche: "coffee",
      tagline: "Better beans",
      contactEmail: "hi@fussybeanv2.com",
    });

    const content = readFileSync(join(root, "sites", "fussybeanv2", "src", "index.astro"), "utf-8");
    expect(content).toContain("Hello Fussy Bean V2 from coffee");
    expect(content).not.toContain("__SITE_NAME__");

    const pkg = JSON.parse(readFileSync(join(root, "sites", "fussybeanv2", "package.json"), "utf-8"));
    expect(pkg.name).toBe("@affkit/fussybeanv2");
  });

  it("throws when the target site already exists", async () => {
    mkdirSync(join(root, "sites", "fussybeanv2"));
    await expect(
      copyTemplate({
        monorepoRoot: root,
        slug: "fussybeanv2",
        siteName: "Fussy Bean V2",
        siteUrl: "https://fussybeanv2.com",
        niche: "coffee",
        tagline: "Better beans",
        contactEmail: "hi@fussybeanv2.com",
      })
    ).rejects.toThrow(/already exists/);
  });
});

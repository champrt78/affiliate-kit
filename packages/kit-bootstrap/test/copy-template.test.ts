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
    mkdirSync(join(root, "templates", "site-template", "src", "data"), { recursive: true });
    mkdirSync(join(root, "sites"), { recursive: true });
    writeFileSync(
      join(root, "templates", "site-template", "package.json"),
      JSON.stringify({ name: "@affkit/site-template" }, null, 2)
    );
    writeFileSync(
      join(root, "templates", "site-template", "astro.config.mjs"),
      'export default { site: "__SITE_URL__" };'
    );
    writeFileSync(
      join(root, "templates", "site-template", "src", "index.astro"),
      "Hello {siteConfig.siteName} from {siteConfig.niche}"
    );
    writeFileSync(
      join(root, "templates", "site-template", "src", "data", "site-config.json"),
      JSON.stringify({
        siteName: "__SITE_NAME__",
        siteUrl: "__SITE_URL__",
        niche: "__NICHE__",
        tagline: "__TAGLINE__",
        contactEmail: "__CONTACT_EMAIL__",
      }, null, 2)
    );
  });

  afterEach(() => {
    rmSync(root, { recursive: true, force: true });
  });

  it("copies the template and applies replacements only to site-config.json", async () => {
    await copyTemplate({
      monorepoRoot: root,
      slug: "fussybeanv2",
      siteName: "Fussy Bean V2",
      siteUrl: "https://fussybeanv2.com",
      niche: "coffee",
      tagline: "Better beans",
      contactEmail: "hi@fussybeanv2.com",
    });

    const astroContent = readFileSync(join(root, "sites", "fussybeanv2", "src", "index.astro"), "utf-8");
    expect(astroContent).toContain("{siteConfig.siteName}");
    expect(astroContent).not.toContain("__SITE_NAME__");

    const astroConfig = readFileSync(join(root, "sites", "fussybeanv2", "astro.config.mjs"), "utf-8");
    expect(astroConfig).toContain("https://fussybeanv2.com");
    expect(astroConfig).not.toContain("__SITE_URL__");

    const config = JSON.parse(readFileSync(join(root, "sites", "fussybeanv2", "src", "data", "site-config.json"), "utf-8"));
    expect(config.siteName).toBe("Fussy Bean V2");
    expect(config.siteUrl).toBe("https://fussybeanv2.com");
    expect(config.niche).toBe("coffee");
    expect(config.tagline).toBe("Better beans");
    expect(config.contactEmail).toBe("hi@fussybeanv2.com");

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

import { describe, it, expect, beforeEach, afterEach } from "vitest";
import { mkdtemp, mkdir, writeFile, readFile, rm } from "node:fs/promises";
import { tmpdir } from "node:os";
import { join } from "node:path";
import { copyTemplate } from "../src/copy-template";

let workDir: string;

async function makeFakeTemplate(root: string) {
  await mkdir(join(root, "templates", "site-template", "src", "pages"), {
    recursive: true,
  });
  await mkdir(join(root, "templates", "site-template", "public"), {
    recursive: true,
  });
  await writeFile(
    join(root, "templates", "site-template", "package.json"),
    JSON.stringify({ name: "@affkit/site-template", scripts: { build: "astro build" } }, null, 2)
  );
  await writeFile(
    join(root, "templates", "site-template", "src", "pages", "index.astro"),
    `<h1>Welcome to __SITE_NAME__</h1>\n<p>__TAGLINE__</p>`
  );
  await writeFile(
    join(root, "templates", "site-template", "public", "robots.txt"),
    `User-agent: *\nSitemap: __SITE_URL__/sitemap-index.xml\n`
  );
  await writeFile(
    join(root, "templates", "site-template", "public", "favicon.svg"),
    `<svg><text>__INITIAL__</text></svg>`
  );
}

describe("copyTemplate", () => {
  beforeEach(async () => {
    workDir = await mkdtemp(join(tmpdir(), "affkit-test-"));
    await makeFakeTemplate(workDir);
  });

  afterEach(async () => {
    await rm(workDir, { recursive: true, force: true });
  });

  it("copies the template into sites/<slug>/", async () => {
    await copyTemplate({
      monorepoRoot: workDir,
      slug: "mywildlifecam",
      siteName: "MyWildlifeCam",
      siteUrl: "https://mywildlifecam.fyi",
      niche: "trail cameras",
      tagline: "Honest reviews of wildlife cameras.",
      contactEmail: "hello@mywildlifecam.fyi",
    });
    const pkg = JSON.parse(
      await readFile(join(workDir, "sites", "mywildlifecam", "package.json"), "utf-8")
    );
    expect(pkg.name).toBe("@affkit/mywildlifecam");
  });

  it("replaces __SITE_NAME__ placeholders", async () => {
    await copyTemplate({
      monorepoRoot: workDir,
      slug: "mywildlifecam",
      siteName: "MyWildlifeCam",
      siteUrl: "https://mywildlifecam.fyi",
      niche: "trail cameras",
      tagline: "Honest reviews of wildlife cameras.",
      contactEmail: "hello@mywildlifecam.fyi",
    });
    const index = await readFile(
      join(workDir, "sites", "mywildlifecam", "src", "pages", "index.astro"),
      "utf-8"
    );
    expect(index).toContain("Welcome to MyWildlifeCam");
    expect(index).toContain("Honest reviews of wildlife cameras.");
    expect(index).not.toContain("__SITE_NAME__");
    expect(index).not.toContain("__TAGLINE__");
  });

  it("replaces __SITE_URL__ in robots.txt", async () => {
    await copyTemplate({
      monorepoRoot: workDir,
      slug: "mywildlifecam",
      siteName: "MyWildlifeCam",
      siteUrl: "https://mywildlifecam.fyi",
      niche: "trail cameras",
      tagline: "Honest reviews of wildlife cameras.",
      contactEmail: "hello@mywildlifecam.fyi",
    });
    const robots = await readFile(
      join(workDir, "sites", "mywildlifecam", "public", "robots.txt"),
      "utf-8"
    );
    expect(robots).toContain("https://mywildlifecam.fyi/sitemap-index.xml");
    expect(robots).not.toContain("__SITE_URL__");
  });

  it("replaces __INITIAL__ with the first letter of the slug, uppercased", async () => {
    await copyTemplate({
      monorepoRoot: workDir,
      slug: "fussybean",
      siteName: "FussyBean",
      siteUrl: "https://fussybean.com",
      niche: "coffee",
      tagline: "Picky about coffee.",
      contactEmail: "hello@fussybean.com",
    });
    const svg = await readFile(
      join(workDir, "sites", "fussybean", "public", "favicon.svg"),
      "utf-8"
    );
    expect(svg).toContain("<text>F</text>");
  });

  it("refuses to overwrite an existing site directory", async () => {
    await mkdir(join(workDir, "sites", "mywildlifecam"), { recursive: true });
    await expect(
      copyTemplate({
        monorepoRoot: workDir,
        slug: "mywildlifecam",
        siteName: "MyWildlifeCam",
        siteUrl: "https://mywildlifecam.fyi",
        niche: "trail cameras",
        tagline: "Honest reviews of wildlife cameras.",
        contactEmail: "hello@mywildlifecam.fyi",
      })
    ).rejects.toThrow(/already exists/);
  });
});

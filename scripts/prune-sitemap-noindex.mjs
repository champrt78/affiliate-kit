#!/usr/bin/env node
/**
 * prune-sitemap-noindex.mjs — post-build sitemap hygiene.
 *
 * @astrojs/sitemap lists every built route. Our DRAFT pages render
 * `<meta name="robots" content="noindex, nofollow">` (the empty-bottomLine /
 * empty-verdict gate), but they still land in sitemap-0.xml. Search engines
 * honor the noindex tag so they will not index them, but listing them yields
 * "Submitted URL marked noindex" warnings in Search Console and wastes crawl
 * budget. This prunes any <url> whose page HTML carries `noindex` out of the
 * sitemap. When a draft gets a verdict (flips to index,follow), it re-enters
 * the sitemap on the next build automatically — no manual list to maintain.
 *
 * Runs as each site's `postbuild` (cwd = site dir). Pure Node, no deps, so it
 * works on the GitHub Actions ubuntu runner and locally on Windows alike.
 * Idempotent and fail-safe: any error is logged and the sitemap left untouched
 * (better a slightly-noisy sitemap than a broken deploy).
 */
import { readFileSync, writeFileSync, existsSync, readdirSync } from "node:fs";
import { join } from "node:path";

const DIST = "dist";

function pageIsNoindex(locUrl) {
  // Map a <loc> URL to its built HTML file. Astro builds directory-style:
  //   https://site.com/            -> dist/index.html
  //   https://site.com/foo/bar/    -> dist/foo/bar/index.html
  let path;
  try {
    path = new URL(locUrl).pathname; // "/", "/foo/bar/"
  } catch {
    return false; // unparseable -> keep it (fail-safe)
  }
  const clean = path.replace(/^\/+|\/+$/g, ""); // "", "foo/bar"
  const candidates = clean === ""
    ? [join(DIST, "index.html")]
    : [join(DIST, clean, "index.html"), join(DIST, clean + ".html")];
  for (const f of candidates) {
    if (existsSync(f)) {
      const html = readFileSync(f, "utf8");
      // match <meta name="robots" content="...noindex...">
      const m = html.match(/<meta[^>]+name=["']robots["'][^>]*>/i);
      if (m && /noindex/i.test(m[0])) return true;
      return false;
    }
  }
  return false; // no file found -> keep (fail-safe)
}

function pruneSitemap(file) {
  const xml = readFileSync(file, "utf8");
  let pruned = 0;
  // Replace each <url>...</url> block: drop it if its <loc> is a noindex page.
  const out = xml.replace(/<url>([\s\S]*?)<\/url>/g, (block, inner) => {
    const loc = inner.match(/<loc>([^<]+)<\/loc>/);
    if (loc && pageIsNoindex(loc[1])) {
      pruned++;
      return "";
    }
    return block;
  });
  if (pruned > 0) writeFileSync(file, out, "utf8");
  return pruned;
}

function main() {
  if (!existsSync(DIST)) {
    console.log("[prune-sitemap] no dist/, skipping");
    return;
  }
  const maps = readdirSync(DIST).filter(f => /^sitemap-\d+\.xml$/.test(f));
  if (maps.length === 0) {
    console.log("[prune-sitemap] no sitemap-N.xml found, skipping");
    return;
  }
  let total = 0;
  for (const m of maps) {
    try {
      total += pruneSitemap(join(DIST, m));
    } catch (e) {
      console.warn(`[prune-sitemap] error on ${m}, left untouched: ${e.message}`);
    }
  }
  console.log(`[prune-sitemap] removed ${total} noindex URL(s) from sitemap`);
}

main();

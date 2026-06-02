#!/usr/bin/env node
/**
 * indexnow-submit.mjs — ping IndexNow (Bing + Yandex + others) with each site's
 * live URLs so new/changed pages get crawled in hours instead of weeks.
 *
 * IndexNow protocol: POST { host, key, keyLocation, urlList } to the endpoint.
 * The search engine fetches https://<host>/<key>.txt to verify ownership, so
 * the key file (sites/<slug>/public/<key>.txt) MUST already be live in prod.
 *
 * URLs come from each site's built dist/sitemap-0.xml — which the postbuild
 * prune already strips of noindex drafts, so we only ever submit indexable
 * pages. Run AFTER a deploy so the sitemap + key file are live:
 *   node scripts/indexnow-submit.mjs           # submit all 5
 *   node scripts/indexnow-submit.mjs fussybean # submit one
 *
 * Cloudflare's "Crawler Hints" does the same thing automatically once toggled
 * in the dashboard; this is the API-driven equivalent we control directly.
 */
import { readFileSync, existsSync, readdirSync } from "node:fs";
import { join } from "node:path";

const ENDPOINT = "https://api.indexnow.org/indexnow";
const SITES = {
  mywildlifecam:   "mywildlifecam.com",
  detailerpicks:   "detailerpicks.com",
  fussybean:       "fussybean.com",
  starteraquarium: "starteraquarium.com",
  gameovergear:    "gameovergear.games",
};

function keyFor(slug) {
  const pub = `sites/${slug}/public`;
  if (!existsSync(pub)) return null;
  const f = readdirSync(pub).find(n => /^[a-f0-9]{16,}\.txt$/.test(n));
  return f ? f.replace(/\.txt$/, "") : null;
}

function urlsFor(slug) {
  const sm = `sites/${slug}/dist/sitemap-0.xml`;
  if (!existsSync(sm)) return [];
  const xml = readFileSync(sm, "utf8");
  return [...xml.matchAll(/<loc>([^<]+)<\/loc>/g)].map(m => m[1]);
}

async function submit(slug) {
  const host = SITES[slug];
  const key = keyFor(slug);
  const urlList = urlsFor(slug);
  if (!key) return console.log(`${slug}: no IndexNow key file in public/, skipping`);
  if (!urlList.length) return console.log(`${slug}: no sitemap URLs (build first), skipping`);
  const body = { host, key, keyLocation: `https://${host}/${key}.txt`, urlList };
  try {
    const res = await fetch(ENDPOINT, {
      method: "POST",
      headers: { "Content-Type": "application/json; charset=utf-8" },
      body: JSON.stringify(body),
    });
    // IndexNow returns 200 (accepted) or 202 (accepted, key validation pending).
    // 403 = key file not reachable; 422 = a URL doesn't match host.
    console.log(`${slug} (${host}): submitted ${urlList.length} URLs -> HTTP ${res.status}` +
      (res.ok || res.status === 202 ? " OK" : "  ⚠ check key file is live + URLs match host"));
  } catch (e) {
    console.log(`${slug}: submit failed - ${e.message}`);
  }
}

const only = process.argv[2];
const slugs = only ? [only] : Object.keys(SITES);
for (const s of slugs) await submit(s);

#!/usr/bin/env node
/**
 * apply-verdicts.mjs — write Claude's recommended verdict into each draft,
 * flipping it from noindex DRAFT to live. Reads the option data fragments,
 * picks an option per piece (default 0 = confident; overrides below), and
 * injects the YAML block into frontmatter:
 *   reviews     -> `bottomLine: { verdict, supporting }`
 *   comparisons -> `verdict:    { verdict, supporting }`
 * Idempotent: skips a file that already has the gate field. JSON.stringify
 * yields a valid YAML double-quoted scalar, so quotes/colons are safe.
 */
import { readFileSync, writeFileSync } from "node:fs";
import { readdirSync } from "node:fs";
import { join } from "node:path";

const DATA = "docs/playgrounds/verdict-queue/data";
const entries = [];
for (const f of readdirSync(DATA).filter(f => f.endsWith(".json"))) {
  entries.push(...JSON.parse(readFileSync(join(DATA, f), "utf8")));
}

// Option index per piece. Default 0 (confident recommend / clear winner).
// Overrides (matched by slug substring) where the headline should hedge:
const OVERRIDE = [
  { match: "fellow-atmos",                  opt: 1 }, // incremental-benefit accessory
  { match: "8bitdo-arcade-stick-vs-hori",   opt: 1 }, // $80 vs $200 tier mismatch
];

function optionFor(e) {
  for (const o of OVERRIDE) if ((e.slug || e.path).includes(o.match)) return o.opt;
  return 0;
}

function inject(content, key, verdict, supporting) {
  const m = content.match(/^(---\r?\n)([\s\S]*?)(\r?\n---\r?\n)([\s\S]*)$/);
  if (!m) throw new Error("no frontmatter");
  const block =
    `${key}:\n` +
    `  verdict: ${JSON.stringify(verdict)}\n` +
    `  supporting: ${JSON.stringify(supporting)}`;
  return m[1] + m[2] + "\n" + block + m[3] + m[4];
}

let applied = 0, skipped = 0;
const log = [];
for (const e of entries) {
  const key = e.type === "comparison" ? "verdict" : "bottomLine";
  const content = readFileSync(e.path, "utf8");
  // idempotency: skip if the gate key already present at root of frontmatter
  if (new RegExp(`^${key}:`, "m").test(content)) { skipped++; continue; }
  const opt = optionFor(e);
  const o = e.options[opt];
  writeFileSync(e.path, inject(content, key, o.verdict, o.supporting), "utf8");
  applied++;
  const prod = e.product || (e.products || []).join(" vs ");
  log.push(`[${e.site}/${e.type}] opt${opt}  ${prod}  ::  ${o.verdict.slice(0, 90)}`);
}
log.sort();
for (const l of log) console.log(l);
console.log(`\napplied ${applied}, skipped ${skipped} (already had verdict)`);

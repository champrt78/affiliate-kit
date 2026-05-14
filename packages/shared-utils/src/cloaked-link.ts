export interface CloakedLinkOptions {
  slug: string;
  source?: string;
}

export function sanitizeSlug(input: string): string {
  const trimmed = input.trim();
  if (trimmed.length === 0) {
    throw new Error("slug cannot be empty");
  }
  const slug = trimmed
    .toLowerCase()
    .replace(/[^a-z0-9]+/g, "-")
    .replace(/-+/g, "-")
    .replace(/^-|-$/g, "");
  if (slug.length === 0) {
    throw new Error("slug cannot be empty");
  }
  return slug;
}

/**
 * Build a cloaked affiliate-link path.
 *
 * Post-U9: the URL no longer carries a `<site>` segment. The Worker derives
 * the site from the Host header (each apex has its own canonical site slug),
 * which closes the cross-tenant link-leak and produces a cleaner URL.
 *
 * KV storage keys remain namespaced as `<site>:<slug>` inside the Worker —
 * only the URL shape changed.
 */
export function cloakedLink(options: CloakedLinkOptions): string {
  const slug = sanitizeSlug(options.slug);
  const base = `/go/${slug}`;
  if (options.source) {
    const src = sanitizeSlug(options.source);
    return `${base}?src=${src}`;
  }
  return base;
}

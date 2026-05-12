export interface CloakedLinkOptions {
  site: string;
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

export function cloakedLink(options: CloakedLinkOptions): string {
  if (options.site.trim().length === 0) {
    throw new Error("site cannot be empty");
  }
  const site = sanitizeSlug(options.site);
  const slug = sanitizeSlug(options.slug);
  const base = `/go/${site}/${slug}`;
  if (options.source) {
    const src = sanitizeSlug(options.source);
    return `${base}?src=${src}`;
  }
  return base;
}

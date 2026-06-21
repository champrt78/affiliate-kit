import { readFile, writeFile, mkdir } from "node:fs/promises";
import { join } from "node:path";

export interface ScaffoldReviewInput {
  repoRoot: string;
  site: string;
  slug: string;
  productName: string;
  brand: string;
  amazonUrl: string;
  description: string;
  sku?: string;
  tag?: string;
}

export async function scaffoldReview(input: ScaffoldReviewInput): Promise<string> {
  const templatePath = join(input.repoRoot, "templates", "review.md.tmpl");
  const targetDir = join(input.repoRoot, "sites", input.site, "src", "content", "reviews");
  const targetPath = join(targetDir, `${input.slug}.md`);

  let template = await readFile(templatePath, "utf-8");
  const pubDate = new Date().toISOString().slice(0, 10);

  template = template
    .replaceAll("__PRODUCT_NAME__", input.productName)
    .replaceAll("__PRODUCT_BRAND__", input.brand)
    .replaceAll("__PRODUCT_SKU__", input.sku ?? "")
    .replaceAll("__SLUG__", input.slug)
    .replaceAll("__PUB_DATE__", pubDate)
    .replaceAll("__RATING__", "# RATING_PLACEHOLDER")
    .replaceAll("__AMAZON_URL__", input.amazonUrl)
    .replaceAll("__SHORT_DESCRIPTION__", input.description)
    .replaceAll("__TAGLINE_HOOK_ONE_LINER__", "")
    .replaceAll("__FAQ_QUESTION_1__", "")
    .replaceAll("__FAQ_QUESTION_2__", "")
    .replaceAll("__FAQ_QUESTION_3__", "");

  await mkdir(targetDir, { recursive: true });
  await writeFile(targetPath, template, "utf-8");
  return targetPath;
}

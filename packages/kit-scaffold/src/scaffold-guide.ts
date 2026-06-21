import { readFile, writeFile, mkdir } from "node:fs/promises";
import { join } from "node:path";

export interface ScaffoldGuideInput {
  repoRoot: string;
  site: string;
  slug: string;
  title: string;
  niche: string;
  description: string;
}

export async function scaffoldGuide(input: ScaffoldGuideInput): Promise<string> {
  const templatePath = join(input.repoRoot, "templates", "buyers-guide.md.tmpl");
  const targetDir = join(input.repoRoot, "sites", input.site, "src", "content", "buyers-guides");
  const targetPath = join(targetDir, `${input.slug}.md`);

  let template = await readFile(templatePath, "utf-8");
  const pubDate = new Date().toISOString().slice(0, 10);

  template = template
    .replaceAll("__GUIDE_TITLE__", input.title)
    .replaceAll("__GUIDE_SLUG__", input.slug)
    .replaceAll("__PUB_DATE__", pubDate)
    .replaceAll("__NICHE__", input.niche)
    .replaceAll("__DESCRIPTION__", input.description)
    .replaceAll("__BUYER_PROFILE_1__", "")
    .replaceAll("__BUYER_PROFILE_2__", "")
    .replaceAll("__BUYER_PROFILE_3__", "")
    .replaceAll("__TOP_PICK_NAME__", "")
    .replaceAll("__RUNNER_UP_NAME__", "")
    .replaceAll("__BUDGET_PICK_NAME__", "")
    .replaceAll("__UPGRADE_PICK_NAME__", "");

  await mkdir(targetDir, { recursive: true });
  await writeFile(targetPath, template, "utf-8");
  return targetPath;
}

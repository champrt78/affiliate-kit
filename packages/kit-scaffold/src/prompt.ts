import { writeFile, mkdir } from "node:fs/promises";
import { join } from "node:path";

export async function writeReviewPrompt(options: {
  repoRoot: string;
  site: string;
  slug: string;
  productName: string;
  brand: string;
  amazonUrl: string;
  description: string;
}): Promise<string> {
  const promptDir = join(options.repoRoot, "sites", options.site, "prompts");
  const promptPath = join(promptDir, `${options.slug}.prompt.md`);

  const content = `# AI Draft Prompt: ${options.productName}

Product: ${options.productName}
Brand: ${options.brand}
Amazon URL: ${options.amazonUrl}
Short description: ${options.description}

Write a first-person, use-case-driven review in the site’s voice. Include:
- A one-paragraph bottom line with verdict
- Who it is for and who should skip it
- Real-world pros and cons
- A concise specs callout
- 3 FAQs
- The cloaked affiliate link: /go/${options.slug}

Do not publish the draft. Stop after generating the body text.
`;

  await mkdir(promptDir, { recursive: true });
  await writeFile(promptPath, content, "utf-8");
  return promptPath;
}

import { defineCollection, z } from "astro:content";

/* Polish-pattern additions (2026-05-17, per docs/competitive-recon-2026-05-17.md).
   All new fields are optional — pieces without them render with graceful fallback. */

const bottomLineSchema = z.object({
  verdict: z.string(),
  // supporting can be a single paragraph OR a bulleted list of items
  supporting: z.union([z.string(), z.array(z.string())]).optional(),
}).optional();

const scorecardSchema = z.object({
  axes: z.array(z.object({
    name: z.string(),
    weight: z.number().min(0).max(100),
    score: z.number().min(0).max(10),
  })).min(2).max(8),
  note: z.string().optional(),
}).optional();

const buyIfSchema = z.object({
  buy: z.array(z.string()).min(1),
  skip: z.array(z.string()).min(1),
}).optional();

const flawsSchema = z.array(z.object({
  title: z.string(),
  body: z.string(),
})).optional();

const faqSchema = z.array(z.object({
  question: z.string(),
  answer: z.string(),
})).optional();

/* bgTheme — per-page forest gutter theme. Defaults to "dawn" when omitted.
   Pick the theme that matches the content (twilight for covert/no-glow,
   moss for grounded/entry-level, canopy for cellular/open, etc.).
   Locked 2026-05-23. */
const bgThemeSchema = z.enum([
  "dawn",
  "canopy",
  "moss",
  "twilight",
  "pine",
  "solid",
]).optional();

const reviews = defineCollection({
  type: "content",
  schema: z.object({
    title: z.string(),
    description: z.string().max(160),
    rubric: z.string().optional(),
    deck: z.string().optional(),
    product: z.object({
      name: z.string(),
      brand: z.string(),
      sku: z.string().optional(),
      price: z.number().optional(),
      currency: z.string().default("USD"),
      affiliate: z.object({
        amazon: z.string().optional(),
        direct: z.string().optional(),
      }).optional(),
    }),
    rating: z.number().min(1).max(5).optional(),
    classification: z.enum(["review", "buyers-guide"]),
    pubDate: z.date(),
    lastUpdated: z.date(),
    images: z.object({
      hero: z.string().optional(),
      heroCaption: z.string().optional(),
      context: z.string().optional(),
      comparison: z.string().optional(),
    }).optional(),
    bottomLine: bottomLineSchema,
    scorecard: scorecardSchema,
    buyIf: buyIfSchema,
    flaws: flawsSchema,
    faq: faqSchema,
    bgTheme: bgThemeSchema,
  }),
});

const buyersGuides = defineCollection({
  type: "content",
  schema: z.object({
    title: z.string(),
    description: z.string().max(160),
    rubric: z.string().optional(),
    deck: z.string().optional(),
    products: z.array(z.object({
      name: z.string(),
      brand: z.string(),
      affiliateUrl: z.string(),
      image: z.string().optional(),
      tagline: z.string().optional(),
      cloakedSlug: z.string().optional(),
      bestFor: z.string().optional(),
      priceFrom: z.number().optional(),
      priceUnit: z.string().optional(),
      /* hook = 1-sentence at-a-glance summary on the quick card */
      hook: z.string().optional(),
      /* reason = the italic deep-card heading lead-in, e.g. "The cellular default" */
      reason: z.string().optional(),
      /* facts = right-rail mini-table on the deep card (label -> value) */
      facts: z.record(z.string(), z.string()).optional(),
      /* body = HTML string with the per-pick prose, rendered into the deep card */
      body: z.string().optional(),
    })),
    pubDate: z.date(),
    lastUpdated: z.date(),
    images: z.object({
      hero: z.string().optional(),
      heroCaption: z.string().optional(),
      // Multi-image hero array — when present (with 3+ URLs) the featured
      // BuyersGuideCard renders a magazine 1+2 layout (large left + 2 stacked right)
      // instead of a single full-bleed image.
      heroImages: z.array(z.string()).optional(),
    }).optional(),
    bottomLine: bottomLineSchema,
    buyIf: buyIfSchema,
    faq: faqSchema,
    bgTheme: bgThemeSchema,
  }),
});

const learn = defineCollection({
  type: "content",
  schema: z.object({
    title: z.string(),
    description: z.string().max(160),
    pubDate: z.date(),
    lastUpdated: z.date(),
  }),
});

/* Head-to-head "X vs Y" comparisons (revenue plan 2026-06-01). 2-3 products
   compared head-to-head; `winner` highlights in the table; `verdict` is the
   human-written winner call and is the DRAFT/noindex GATE (empty => noindex). */
const comparisonProductSchema = z.object({
  name: z.string(),
  brand: z.string(),
  affiliateUrl: z.string(),
  image: z.string().optional(),
  priceFrom: z.number().optional(),
  priceUnit: z.string().optional(),
  bestFor: z.string().optional(),
  facts: z.record(z.string(), z.string()).optional(),
  body: z.string().optional(),
});
const comparisons = defineCollection({
  type: "content",
  schema: z.object({
    title: z.string(),
    description: z.string().max(160),
    rubric: z.string().optional(),
    deck: z.string().optional(),
    products: z.array(comparisonProductSchema).min(2).max(3),
    winner: z.string().optional(),
    verdict: bottomLineSchema,
    dealBreakers: z.array(z.string()).optional(),
    pubDate: z.date(),
    lastUpdated: z.date(),
    images: z.object({
      hero: z.string().optional(),
      heroCaption: z.string().optional(),
    }).optional(),
    faq: faqSchema,
    bgTheme: bgThemeSchema,
  }),
});

export const collections = { reviews, "buyers-guides": buyersGuides, learn, comparisons };

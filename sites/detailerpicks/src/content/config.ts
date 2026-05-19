import { defineCollection, z } from "astro:content";

/* Polish-pattern schemas — mirrored from sites/mywildlifecam/src/content/config.ts.
   All new fields are optional — pieces without them render with graceful fallback.
   See docs/competitive-recon-2026-05-17.md for the rationale. */

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
      imageScale: z.number().optional(),
      context: z.string().optional(),
      comparison: z.string().optional(),
    }).optional(),
    bottomLine: bottomLineSchema,
    scorecard: scorecardSchema,
    buyIf: buyIfSchema,
    flaws: flawsSchema,
    faq: faqSchema,
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
      imageScale: z.number().optional(),
      tagline: z.string().optional(),
      cloakedSlug: z.string().optional(),
      bestFor: z.string().optional(),
      priceFrom: z.number().optional(),
      priceUnit: z.string().optional(),
      /* hook = 1-sentence at-a-glance summary, shown on the quick card */
      hook: z.string().optional(),
      /* reason = the italic lead-in on the deep-card heading, e.g. "The one-bottle workflow" */
      reason: z.string().optional(),
      /* facts = right-rail mini-table on the deep card. Keys are labels, values are short answers. */
      facts: z.record(z.string(), z.string()).optional(),
      /* body = HTML string with the per-pick prose for the deep card. Use <p> tags + <a href>. */
      body: z.string().optional(),
    })),
    pubDate: z.date(),
    lastUpdated: z.date(),
    images: z.object({
      hero: z.string().optional(),
      heroCaption: z.string().optional(),
      heroImages: z.array(z.string()).optional(),
    }).optional(),
    bottomLine: bottomLineSchema,
    buyIf: buyIfSchema,
    faq: faqSchema,
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

export const collections = { reviews, "buyers-guides": buyersGuides, learn };

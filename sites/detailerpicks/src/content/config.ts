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

/* bgTheme — per-page detailing gutter theme. Defaults to "foam-cascade"
   when omitted. Six options locked 2026-05-23 from the D-playground:
     foam-cascade      — foam-covered car (default, homepage + foam-cannon)
     wheel-suds        — alloy wheel covered in soap (wheel-cleaner)
     suds-closeup      — hand + sponge + bubbles (car-wash-soap)
     interior-detail   — interior cleaning at pro shop (interior-cleaner)
     chrome-reflection — vintage chrome detail (about / methodology)
     solid             — no photo, ink #14181C (legal / admin) */
const bgThemeSchema = z.enum([
  "foam-cascade",
  "wheel-suds",
  "suds-closeup",
  "interior-detail",
  "chrome-reflection",
  "solid",
]).optional();

const reviews = defineCollection({
  type: "content",
  schema: z.object({
    title: z.string(),
    description: z.string().max(160),
    rubric: z.string().optional(),
    deck: z.string().optional(),
    pillar: z.string().optional(),   // FK → navigation.pillars[].slug
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
    pillar: z.string().optional(),   // FK → navigation.pillars[].slug
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
   compared head-to-head; the recommended `winner` highlights in the table; the
   `verdict` is the human-written winner call and is the DRAFT/noindex GATE
   (empty verdict => noindex, same as bottomLine on guides/reviews). */
const comparisonProductSchema = z.object({
  name: z.string(),
  brand: z.string(),
  affiliateUrl: z.string(),
  image: z.string().optional(),
  priceFrom: z.number().optional(),
  priceUnit: z.string().optional(),
  bestFor: z.string().optional(),                       // who should buy THIS one
  facts: z.record(z.string(), z.string()).optional(),   // spec rows for the comparison table
  body: z.string().optional(),                          // per-product prose (HTML)
});
const comparisons = defineCollection({
  type: "content",
  schema: z.object({
    title: z.string(),
    description: z.string().max(160),
    rubric: z.string().optional(),
    deck: z.string().optional(),
    pillar: z.string().optional(),   // FK → navigation.pillars[].slug
    products: z.array(comparisonProductSchema).min(2).max(3),
    winner: z.string().optional(),     // name of the recommended product (table highlight)
    verdict: bottomLineSchema,         // {verdict, supporting} — the winner call; Ray's gate
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

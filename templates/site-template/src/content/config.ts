import { defineCollection, z } from "astro:content";

const reviews = defineCollection({
  type: "content",
  schema: z.object({
    title: z.string(),
    description: z.string().max(160),
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
      context: z.string().optional(),
      comparison: z.string().optional(),
    }).optional(),
  }),
});

const buyersGuides = defineCollection({
  type: "content",
  schema: z.object({
    title: z.string(),
    description: z.string().max(160),
    products: z.array(z.object({
      name: z.string(),
      brand: z.string(),
      affiliateUrl: z.string(),
      image: z.string().optional(),
      tagline: z.string().optional(),
      cloakedSlug: z.string().optional(),
      bestFor: z.string().optional(),
      priceFrom: z.number().optional(),
    })),
    pubDate: z.date(),
    lastUpdated: z.date(),
    images: z.object({
      hero: z.string().optional(),
    }).optional(),
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

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
    })),
    pubDate: z.date(),
    lastUpdated: z.date(),
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

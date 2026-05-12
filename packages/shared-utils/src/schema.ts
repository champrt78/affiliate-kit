export type Availability = "InStock" | "OutOfStock" | "PreOrder" | "Discontinued";

export interface ProductSchemaInput {
  name: string;
  brand: string;
  sku: string;
  image: string;
  description: string;
  offerUrl?: string;
  price?: number;
  currency?: string;
  availability?: Availability;
}

export interface ReviewSchemaInput {
  productName: string;
  rating: number;
  author: string;
  datePublished: string;
  reviewBody: string;
}

export interface FaqEntry {
  q: string;
  a: string;
}

export function productSchema(input: ProductSchemaInput): Record<string, unknown> {
  const result: Record<string, unknown> = {
    "@context": "https://schema.org",
    "@type": "Product",
    name: input.name,
    brand: { "@type": "Brand", name: input.brand },
    sku: input.sku,
    image: input.image,
    description: input.description,
  };

  if (input.offerUrl && input.price !== undefined && input.currency) {
    result.offers = {
      "@type": "Offer",
      url: input.offerUrl,
      priceCurrency: input.currency,
      price: input.price.toFixed(2),
      availability: `https://schema.org/${input.availability ?? "InStock"}`,
    };
  }

  return result;
}

export function reviewSchema(input: ReviewSchemaInput): Record<string, unknown> {
  if (input.rating < 1 || input.rating > 5) {
    throw new Error("rating must be between 1 and 5");
  }

  return {
    "@context": "https://schema.org",
    "@type": "Review",
    itemReviewed: { "@type": "Product", name: input.productName },
    reviewRating: {
      "@type": "Rating",
      ratingValue: input.rating.toString(),
      bestRating: "5",
      worstRating: "1",
    },
    author: { "@type": "Person", name: input.author },
    datePublished: input.datePublished,
    reviewBody: input.reviewBody,
  };
}

export function faqSchema(entries: FaqEntry[]): Record<string, unknown> {
  if (entries.length === 0) {
    throw new Error("FAQ list cannot be empty");
  }
  return {
    "@context": "https://schema.org",
    "@type": "FAQPage",
    mainEntity: entries.map((e) => ({
      "@type": "Question",
      name: e.q,
      acceptedAnswer: { "@type": "Answer", text: e.a },
    })),
  };
}

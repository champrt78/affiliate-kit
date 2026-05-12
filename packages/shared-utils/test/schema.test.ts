import { describe, it, expect } from "vitest";
import { productSchema, reviewSchema, faqSchema } from "../src/schema";

describe("productSchema", () => {
  it("emits a Product JSON-LD object", () => {
    const result = productSchema({
      name: "Reconyx HC600",
      brand: "Reconyx",
      sku: "HC600",
      image: "https://example.com/hc600.jpg",
      description: "A trail camera",
      offerUrl: "https://example.com/buy",
      price: 549.99,
      currency: "USD",
      availability: "InStock",
    });
    expect(result["@context"]).toBe("https://schema.org");
    expect(result["@type"]).toBe("Product");
    expect(result.name).toBe("Reconyx HC600");
    expect(result.brand).toEqual({ "@type": "Brand", name: "Reconyx" });
    expect(result.sku).toBe("HC600");
    expect(result.image).toBe("https://example.com/hc600.jpg");
    expect(result.offers).toEqual({
      "@type": "Offer",
      url: "https://example.com/buy",
      priceCurrency: "USD",
      price: "549.99",
      availability: "https://schema.org/InStock",
    });
  });

  it("omits offers when no offer info given", () => {
    const result = productSchema({
      name: "X",
      brand: "Y",
      sku: "Z",
      image: "img",
      description: "d",
    });
    expect(result.offers).toBeUndefined();
  });
});

describe("reviewSchema", () => {
  it("emits a Review JSON-LD object with a 5-star scale by default", () => {
    const result = reviewSchema({
      productName: "Reconyx HC600",
      rating: 4.5,
      author: "Ray Champion",
      datePublished: "2026-05-12",
      reviewBody: "Solid trail cam, fires too easily in wind.",
    });
    expect(result["@context"]).toBe("https://schema.org");
    expect(result["@type"]).toBe("Review");
    expect(result.itemReviewed).toEqual({
      "@type": "Product",
      name: "Reconyx HC600",
    });
    expect(result.reviewRating).toEqual({
      "@type": "Rating",
      ratingValue: "4.5",
      bestRating: "5",
      worstRating: "1",
    });
    expect(result.author).toEqual({ "@type": "Person", name: "Ray Champion" });
    expect(result.datePublished).toBe("2026-05-12");
    expect(result.reviewBody).toBe("Solid trail cam, fires too easily in wind.");
  });

  it("rejects ratings outside [1, 5]", () => {
    expect(() =>
      reviewSchema({
        productName: "X",
        rating: 6,
        author: "A",
        datePublished: "2026-01-01",
        reviewBody: "",
      })
    ).toThrow("rating must be between 1 and 5");
    expect(() =>
      reviewSchema({
        productName: "X",
        rating: 0,
        author: "A",
        datePublished: "2026-01-01",
        reviewBody: "",
      })
    ).toThrow("rating must be between 1 and 5");
  });
});

describe("faqSchema", () => {
  it("emits an FAQPage with Question/Answer pairs", () => {
    const result = faqSchema([
      { q: "Is it weatherproof?", a: "Yes, IP66 rated." },
      { q: "Does it use cellular?", a: "No, SD card only." },
    ]);
    expect(result["@context"]).toBe("https://schema.org");
    expect(result["@type"]).toBe("FAQPage");
    expect((result.mainEntity as unknown[]).length).toBe(2);
    expect((result.mainEntity as unknown[])[0]).toEqual({
      "@type": "Question",
      name: "Is it weatherproof?",
      acceptedAnswer: { "@type": "Answer", text: "Yes, IP66 rated." },
    });
  });

  it("rejects an empty FAQ list", () => {
    expect(() => faqSchema([])).toThrow("FAQ list cannot be empty");
  });
});

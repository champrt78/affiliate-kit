import { defineConfig } from "astro/config";
import sitemap from "@astrojs/sitemap";

export default defineConfig({
  site: "__SITE_URL__",
  output: "static",
  integrations: [
    sitemap({
      filter: (page) => !page.startsWith("/go/"),
    }),
  ],
  build: {
    inlineStylesheets: "auto",
  },
  prefetch: {
    prefetchAll: false,
    defaultStrategy: "hover",
  },
});

import { defineConfig } from "astro/config";
import sitemap from "@astrojs/sitemap";

export default defineConfig({
  site: "https://starteraquarium.com",
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

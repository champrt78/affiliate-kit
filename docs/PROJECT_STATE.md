# Project State — Affiliate Kit

Running list of wins and milestones. Most recent on top.

- **2026-05-12** — **Phase 1 complete: all 5 affiliate sites live on Cloudflare Pages** with the link-cloaker Worker (`affkit-link-cloaker`) deployed and routed at `<apex>/go/*` on each. mywildlifecam.com (hero), fussybean.com, detailerpicks.com, starteraquarium.com, gameovergear.games — all returning HTTP 200 via Cloudflare. KV namespace `AFFILIATE_LINKS` ready for affiliate slug→URL entries. Three real bootstrap CLI bugs found and patched along the way (Windows symlink copy, R2 graceful fallback, wrangler 4.x Pages API migration).
- **2026-05-12** — Locked the Phase 2 services-business brand: **Semper Fi Studios**. Purchased `semperfistudios.com` ($11, Porkbun). Marine-veteran-owned positioning, will cover both done-for-you affiliate site sales and local-business web design under one roof. SaaS products stay on a separate brand.
- **2026-05-12** — Phase 1 toolkit code complete (monorepo, shared packages, template, link-cloaker Worker, bootstrap CLI, Claude Code plugin). Ready for basement-PC bringup per `docs/BASEMENT_SETUP.md`.

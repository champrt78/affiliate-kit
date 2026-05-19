# Pic Handoff — what I need from Ray

Format and dropoff instructions are at the bottom.

---

## DetailerPicks — 5 product images (currently text-only cards)

| # | Product | What I need | Where it goes |
|---|---|---|---|
| 1 | ~~**P&S Brake Buster Total Wheel Cleaner**~~ ✅ **DONE** | ~~Bottle shot, any size (gallon ideal). Clean background.~~ Wired in 2026-05-19. | `sites/detailerpicks/src/content/buyers-guides/best-wheel-cleaner-for-home-detailers.md` → products[1].image |
| 2 | **CarPro Iron X** | 500ml red-cap spray bottle. Clean background. | same file → products[4].image |
| 3 | **Gyeon Q²M Bathe** | 500ml or 1L bottle (the **shampoo**, NOT Gyeon Foam — they look similar). | `sites/detailerpicks/src/content/buyers-guides/best-car-wash-soap-for-home-detailers.md` → products[1].image |
| 4 | **Labocosmetica SÈMPER** | 500ml bottle. Their branding is usually black + minimal. | same file → products[0].image |
| 5 | **Pan The Organizer Demineralizing Shampoo** | Bottle shot (gallon or pint, either works). | same file → products[4].image |

---

## MyWildlifeCam — Article heroes (replace fox, currently reused on 2 guides)

| # | Asset | What I need | Where it goes |
|---|---|---|---|
| 6 | **Best Stealth Cam Trail Camera by Use Case** hero | A trail-cam-related editorial photo — camera mounted on tree, woods at dusk, deer at edge of cover, anything NOT the fox we use elsewhere. Wide aspect (16:6+ ideal). | `sites/mywildlifecam/src/content/buyers-guides/best-stealth-cam-trail-camera-by-use-case.md` → images.hero |
| 7 | **Best Trail Cameras for Backyard Wildlife** hero | Different wildlife scene — buck at dawn, raccoon on porch, owl in tree, anything backyard-feeling and NOT the fox. Wide aspect. | `sites/mywildlifecam/src/content/buyers-guides/best-trail-cameras-for-backyard-wildlife.md` → images.hero |
| 8 | **Backyard Wildlife guide — heroImages array (3 small thumbnails)** | The first one in the array is the fox AGAIN, used in the magazine-style hero card on the homepage. Need a replacement. The other two (`photo-1469125155630-7ed37e065743`, `photo-1452570053594-1b985d6ea890`) are different wildlife and might be fine — confirm visually if you can. | same file → images.heroImages[0] |

---

## MyWildlifeCam — Review hero issues

| # | Asset | What I need | Where it goes |
|---|---|---|---|
| 9 | **Vikeri Trail Camera review hero** | Product shot of the Vikeri trail camera (look like a Bushnell-shaped camo box). Need this so the review's hero block stops showing the "Vikeri" text fallback on the homepage. | `sites/mywildlifecam/src/content/reviews/vikeri-trail-camera-review.md` → images.hero (add the field if missing) |
| 10 | **Spypoint Flex-M review hero** | Current hero is the giant zoomed-in product shot you flagged. Want either: (a) the same product but framed wider with more whitespace, or (b) the camera shown in-context (mounted on a tree). | `sites/mywildlifecam/src/content/reviews/spypoint-flex-m-review.md` → images.hero |

---

## MyWildlifeCam — Stealth Cam guide picks (7 product images, currently empty)

These are for the Phase C port. Stealth Cam keeps the same family-style product photos across their lineup. Brand site is **stealthcam.com**.

| # | Product | What I need | Where it goes |
|---|---|---|---|
| 11 | **Stealth Cam DS4K Ultimate** | Product shot. The "Ultimate" model. | guide file → products[0].image |
| 12 | **Stealth Cam DS4K Transmit** | "Transmit" model. Has antenna. | products[1].image |
| 13 | **Stealth Cam Deceptor MAX 2.0** | "Deceptor MAX" 2.0. True 940nm IR. | products[2].image |
| 14 | **Stealth Cam Revolver Pro 2.0 360** | "Revolver Pro 2.0 360" — distinctive 360° lens style. | products[3].image |
| 15 | **Stealth Cam Fusion MAX 2.0** | "Fusion MAX" 2.0. Budget cellular. | products[4].image |
| 16 | **Stealth Cam QS24** | "QS24" entry-level. Smaller form factor. | products[5].image |
| 17 | **Stealth Cam GMAX32** | "GMAX32" non-cellular no-glow. | products[6].image |

All in: `sites/mywildlifecam/src/content/buyers-guides/best-stealth-cam-trail-camera-by-use-case.md`

---

## MyWildlifeCam — Backyard Wildlife guide picks (3 product images)

Two already have images (Spypoint Flex-M, Stealth Cam DS4K Ultimate). One is missing.

| # | Product | What I need | Where it goes |
|---|---|---|---|
| 18 | **Vikeri Trail Camera** | Same product shot as #9 above — they can be the same file. | guide file → products[2].image (currently missing) |

In: `sites/mywildlifecam/src/content/buyers-guides/best-trail-cameras-for-backyard-wildlife.md`

---

## How to hand them off

**Preferred: URLs.** Paste links to image URLs (Amazon CDN, brand CDN, Unsplash, Pexels, anywhere stable). I'll paste them straight into the frontmatter. Format:

```
1. https://...
2. https://...
3. https://...
```

Or, for the wildlife heroes where you might find one you like by scrolling Unsplash:

```
7. https://unsplash.com/photos/<slug> — buck at dawn
```

I can pull either the full Unsplash URL or just the photo ID (`photo-1774105344779-25249e12af00`).

**Alternative: Downloads.** If you have files locally or save some, drop them in `docs/pics-inbox/` at the repo root (`C:\Users\Ray\documents\github\affiliate-sites\docs\pics-inbox\`) named like `1-brake-buster.jpg`, `9-vikeri.jpg`, etc. (numbering matches the list above). I'll move them into the right `public/products/` folder per site and reference as `/products/<name>.jpg`. No need to resize — I'll do that.

**Either format is fine for any item.** Mix and match as you go.

---

## What I'll do without your help

While you work on this list, I'm:
- Starting the Phase C port (MWC template migration — no pics required for the template work)
- Fixing the Spypoint Flex-M hero zoom (CSS issue, not a pic issue)
- Continuing to scrape Amazon / brand sites for the items above in parallel; if I find clean working URLs, I'll just wire them in and update this file to remove items from your list

This file is a living checklist. As items get filled, I'll cross them off here so we don't dup-work.

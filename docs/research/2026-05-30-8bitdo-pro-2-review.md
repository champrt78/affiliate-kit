---
title: "8BitDo Pro 2 Review"
target_site: gameovergear
target_slug: 8bitdo-pro-2-review
type: review
date: 2026-05-30
---

# 8BitDo Pro 2 Review, Research Note

> Research note only. Single-product review for gameovergear.games (retro gaming gear). Amazon tag `gameovergear-20`.

## IMPORTANT, edition substitution (read before scaffolding)

The "8BitDo Pro 2" exists in **three distinct, easily-confused listings**, plus a separate Xbox product. The edition this note targets is **not** the original 2021 Pro 2 the task assumed. Here is why.

- **Original Pro 2 (ALPS joystick), Gray `B08XY8H9D5`**, the classic 2021 release. **FAILED the availability gate:** the `/dp` scrape on 2026-05-30 returned **"Currently unavailable. We don't know when or if this item will be back in stock."** Amazon's own page points to a newer version. Same pattern that killed the Browning Pro XD on 2026-05-29, do not target a dead listing.
- **Pro 2 (Hall Effect joystick refresh), Switch/Switch 2**, the current in-production Pro 2. Same name, **different spec sheet** than the original: Hall Effect sticks (anti-drift) instead of ALPS, and explicit Switch 2 support. This is the buyable affiliate target. Two colors, both in stock:
  - Black `B0CSPHXJYM`, **$39.99**, clean "In Stock". **← RECOMMENDED TARGET.**
  - Gray `B0CSPH1JYV`, $42.49, but "Only 1 left in stock - order soon" (thin inventory; price higher; skip).
- **Pro 3 `B0FFGRQ6XY`**, the *successor* product (TMR joysticks, swappable ABXY, charging dock), ~$58. Amazon labels it "There is a newer version of this item." NOT the Pro 2. Do not conflate.
- **Pro 2 for Xbox `B0CYZKNSS1`**, a *different product* (officially licensed for Xbox, wired, Hall triggers, 3.5mm jack). The task's H1 warning was about this one. NOT our target.

**Net:** the task said "base Pro 2 (no Switch 2 / limited Xbox)." That framing described the discontinued ALPS unit. The buyable Pro 2 is the **Hall Effect refresh, which DOES support Switch 2**, so the "no Switch 2" flaw the task suggested does **not** apply. Specs and flaws below are re-sourced from the Hall Effect listing + manufacturer page, not carried over from the dead original.

## Confirmed ASIN + edition + availability gate

- **ASIN: `B0CSPHXJYM`**, 8BitDo Pro 2, **Hall Effect Joystick, Black Edition**. Confirmed via Firecrawl `/dp` scrape of `https://www.amazon.com/dp/B0CSPHXJYM` on 2026-05-30.
- **Exact Amazon title (page H1):** "8BitDo Pro 2 Bluetooth Controller for Switch/Switch 2, Hall Effect Joysticks, 2 Pro Back Paddle Buttons, Wireless Gaming Controller for Switch, PC, Android, and Steam Deck & Apple (Black Edition)"
- **Color/edition:** Black Edition. (Gray `B0CSPH1JYV` and a "G Classic" retro colorway are sibling SKUs on the same parent; Black has the cleanest stock + lowest price.)
- **Brand store / model:** 8Bitdo. Listing "Model Name" is the GTIN `6922621505051` (Amazon shows the barcode, not a marketing model name); product line is "Pro 2." 1-year warranty.
- **IN STOCK confirmed:** Buy box reads "In Stock" with quantity selector 1-30 and Add to Cart / Buy Now. Availability gate **PASSED**. (Cross-checked: this is per-SKU, the Gray sibling shows thin stock, the original ALPS Gray is dead. Black is the safe pick.)
- **Single buyable unit:** standalone controller, not a bundle. Includes gamepad + USB cable + manual (8bitdo.com spec sheet).
- **Rating:** 4.4 out of 5 stars, 1,589 ratings (shown on listing; this rating is shared across the Hall Effect color SKUs).

## Price

- **$39.99** as of the 2026-05-30 Firecrawl scrape. Source: `https://www.amazon.com/dp/B0CSPHXJYM` (buy box: "$39.99", and price block "$39.99 with 20 percent savings -20%, List Price: $49.99").
  - Note 1: a used/other-seller offer shows $33.99 and an Amazon Store Card "$10 off instantly → $29.99" financing promo dangles on the page. Those are not the product price. **Quote $39.99.**
  - Note 2: the Gray sibling `B0CSPH1JYV` is $42.49, if Black goes out of stock, Gray is the fallback at a slightly higher price.

## Sourced specs (each cited)

Primary sources: 8BitDo manufacturer page `https://www.8bitdo.com/pro2/` and the Amazon listing `https://www.amazon.com/dp/B0CSPHXJYM`. Where a named reviewer adds measured/real-world color, it is labeled.

1. **Joysticks: Hall Effect**, the defining upgrade of this edition. 8bitdo.com Tech Specs ("Hall Effect joysticks") `https://www.8bitdo.com/pro2/`; Amazon "About this item" ("Hall Effect Joystick Update") `https://www.amazon.com/dp/B0CSPHXJYM`. Hall Effect sticks use magnetic sensors instead of contact potentiometers, the design class marketed as drift-resistant. (Frame as a design property, not a tested-by-us durability claim.)
2. **Connectivity: Bluetooth 4.0 + USB-C wired**, 8bitdo.com Connectivity ("Wireless Bluetooth 4.0 / USB-C") and "You can even use Pro 2 as a wired USB controller with the included USB cable" `https://www.8bitdo.com/pro2/`; Amazon ("Wireless Bluetooth ... USB-C") `https://www.amazon.com/dp/B0CSPHXJYM`. (No dedicated 2.4GHz dongle on the Pro 2, connection is Bluetooth or USB-C wired. The 2.4GHz/dongle path is an 8BitDo *Ultimate* series feature, not Pro 2.)
3. **Platform support: Switch & Switch 2, Windows, SteamOS/Steam Deck, Android, Raspberry Pi, Apple (iOS/iPadOS/tvOS/macOS/visionOS)**, 8bitdo.com Compatibility block `https://www.8bitdo.com/pro2/`: Switch 1/2 (3.0.0+ / Switch 2 20.1.1+), Windows 10 (1903)+, SteamOS 3.7.13+, Android 9.0+, Raspberry Pi (2B/2B+/3B/Zero), Apple iOS/iPadOS/tvOS 16.3+, macOS 13.2+, visionOS 1.1+. Amazon platform line: "Mac, iOS, Windows, Nintendo Switch, Android" and About-item "Compatible with Switch, Windows, Apple, Android, Steam Deck, and Raspberry Pi" `https://www.amazon.com/dp/B0CSPHXJYM`.
4. **Four-way mode switch (Switch / X-input / D-input / macOS)**, 8bitdo.com ("4-way mode switch ... instantly pair") and Controller Mode list "Switch mode / X-input / D-input" `https://www.8bitdo.com/pro2/`. SlashGear specifies the four modes as "Switch, macOS, X-input (Windows), and D-input (Android)" `https://www.slashgear.com/811511/8bitdo-pro-2-controller-review-excellence-refined/`.
5. **Three onboard custom profiles + profile-switch button**, 8bitdo.com ("custom profile switch button holds 3 custom profiles that can be switched on the fly") `https://www.8bitdo.com/pro2/`; Amazon About-item ("Custom profile switching") `https://www.amazon.com/dp/B0CSPHXJYM`.
6. **Two Pro-level back paddle buttons**, 8bitdo.com ("two Pro-level back buttons ... assign any button") `https://www.8bitdo.com/pro2/`; Amazon About-item ("2 pro-level back buttons") `https://www.amazon.com/dp/B0CSPHXJYM`. Title: "2 Pro Back Paddle Buttons."
7. **8BitDo Ultimate Software on PC, Android, and iOS**, remap buttons, adjust stick & trigger sensitivity, tune vibration, build macros, store profiles. 8bitdo.com ("Ultimate Software ... now on Android and iOS. Customize button mapping, adjust stick & trigger sensitivity, vibration control and create macros") `https://www.8bitdo.com/pro2/`. **Caveat to surface:** "Ultimate Software is not supported on Mac mode" (8bitdo.com footnote, same page).
8. **Rumble vibration + motion controls (motion = Switch only); NOT HD Rumble**, 8bitdo.com Special Features ("Motion control (for Switch only)") and footnote 1 ("The Pro 2 features regular rumble vibration, not HD Rumble") `https://www.8bitdo.com/pro2/`; Amazon About-item ("rumble vibration, motion controls") `https://www.amazon.com/dp/B0CSPHXJYM`. Also: "Switch compatibility does not support HD rumble or amiibo scanning" (8bitdo.com).
9. **Battery: 1000mAh Li-ion rechargeable pack, ~20 play hours / ~4 hour charge**, 8bitdo.com ("1000mAh Li-on battery, rechargeable / 20 play hours with 4 hour charging time") `https://www.8bitdo.com/pro2/`; Amazon About-item ("20 hour rechargeable battery") `https://www.amazon.com/dp/B0CSPHXJYM`. **AA-battery nuance (see flaws):** the original ALPS Pro 2 shipped a *removable* pack that could be swapped for 2x AA (SlashGear, `https://www.slashgear.com/811511/8bitdo-pro-2-controller-review-excellence-refined/`). The Hall Effect refresh's 8bitdo.com "Includes" list shows only "gamepad, USB cable, manual" and lists battery type as "1000mAh Li-on" with no AA mention, treat AA-swap as **applies to original; unconfirmed for this Hall Effect SKU.** Do NOT assert AA support for `B0CSPHXJYM` without a primary confirmation.
10. **Physical: 153.6 x 100.6 x 64.5 mm, 228 g; enhanced textured grip**, 8bitdo.com Dimension/Weight + Special Features ("Enhanced grip") `https://www.8bitdo.com/pro2/`.

## Attributed reviewer notes (3-5)

1. **Best d-pad since the SNES era.** Eric Abent, SlashGear: "the D-Pad in particular is probably the best D-Pad I've used since the SNES days. If you're a fan of retro games or 2D games and you need a good D-Pad, the one on the Pro 2 won't disappoint." `https://www.slashgear.com/811511/8bitdo-pro-2-controller-review-excellence-refined/` (Directly relevant to gameovergear's retro audience.)
2. **Back buttons are well-placed, not accidentally triggered.** SlashGear: "I've accidentally hit these buttons a shockingly low number of times ... placed pretty far up the grip, so they aren't in the way ... my middle fingers fall perfectly on the rear buttons." Same URL.
3. **On-the-fly profile switching is the headline upgrade over the SN30 Pro+.** SlashGear: the profile button lets you "define three profiles once through the Ultimate Software app, sync them to the controller, and then swap through them whenever you want," removing the SN30 Pro+'s need to reconnect to software for every layout change. Same URL.
4. **Verdict: best third-party controller the reviewer had used.** SlashGear: "It is, unquestionably, the best third-party controller I've ever used." Same URL.
5. **Amazon verified-buyer signal (named review IDs).** Buyers repeatedly praise feel and value: "Love the size and feel and how good the buttons feel" (review `R16256OO8VBP9R`); "this blows away the switch pro controller and the Xbox ... super easy to pair and has 3 profiles" (`R2QW45KVBE7HPS`); "The motion controls are working amazingly ... vibrations are FAR better than my Nintendo pro [controller]" (`R11FTV6EBMBVEG`). All on `https://www.amazon.com/dp/B0CSPHXJYM`.

## Sourced flaws (candid, voice doctrine requires it)

- **Can't wake/power on a Switch.** SlashGear: "the biggest consideration is the fact that you can't use the Pro 2 to turn the Switch on like you can with the Pro Controller, which is disappointing." `https://www.slashgear.com/811511/8bitdo-pro-2-controller-review-excellence-refined/`
- **No NFC (no amiibo) and no HD Rumble.** SlashGear (no NFC/HD rumble) + 8bitdo.com ("does not support HD rumble or amiibo scanning") `https://www.8bitdo.com/pro2/`. Standard for third-party Switch pads, but worth stating.
- **Star/Heart buttons sit awkwardly.** SlashGear: "the star and heart buttons are in somewhat awkward positions ... they can be a little difficult to hit in the midst of action." Same URL.
- **Ultimate Software does not work in Mac mode.** 8bitdo.com footnote `https://www.8bitdo.com/pro2/`, Mac users get the controller but not the customization app.
- **Switch 2 connection is not bulletproof in the field.** Despite the "for Switch 2" marketing, at least one Amazon verified review on this exact SKU reports "Does not connect to switch 2" (review `RSLUNWVG3N62S`, `https://www.amazon.com/dp/B0CSPHXJYM`). 8bitdo notes Switch 2 needs system 20.1.1+ and may require a firmware update from support.8bitdo.com (8bitdo.com compatibility footnote). Frame as: Switch 2 support exists but may require firmware updates / has scattered failure reports.
- **D-pad/trigger unit variance.** An Amazon reviewer reported a defective unit then a replacement with a "too stiff" d-pad (review on `B0CSPHXJYM`, dated 2026-05-14): "the dpad is still too stiff ... in the end im returning both." A minority report against an otherwise strongly-praised d-pad, but real and recent.
- **AA-battery flexibility is uncertain on this edition.** The frequently-cited "pop in 2 AA batteries" perk belongs to the original ALPS Pro 2 (SlashGear). The Hall Effect refresh's published spec/includes list does not confirm it. Don't promise it.

## Who this is for / who should skip

**For:**
- Retro / 2D / fighting-game players who prioritize a d-pad, the single most-praised feature, repeatedly called the best since the SNES.
- Multi-platform players (PC + Switch/Switch 2 + Steam Deck + phone/tablet + Raspberry Pi) who want one pad and on-the-fly profiles + 4-way mode switch.
- People who want paddle buttons and deep remapping/macros without paying flagship-pad prices ($39.99).
- Anyone wary of stick drift who values the Hall Effect joystick design.

**Skip if:**
- You need to power on a Switch from the couch, want amiibo/NFC, or want true HD Rumble, go first-party Switch Pro Controller.
- You're a Mac-primary user who wants to customize via app (Ultimate Software won't run in Mac mode).
- You want 2.4GHz low-latency dongle wireless, that's the 8BitDo Ultimate line, not the Pro 2 (Pro 2 is Bluetooth or USB-C wired).
- You want the newest hotness with TMR sticks + charging dock, look at the Pro 3 (`B0FFGRQ6XY`), a different/pricier product.

## How it compares

- **vs. 8BitDo SN30 Pro+** (the predecessor): Pro 2 adds the three-profile on-the-fly switch button, two rear paddle buttons, the 4-way hardware mode switch, enhanced textured grip, and (this edition) Hall Effect sticks. Same 1000mAh / ~20hr battery. SlashGear frames the Pro 2 as a refinement of the SN30 Pro+ that finally stores multiple profiles onboard. `https://www.slashgear.com/811511/8bitdo-pro-2-controller-review-excellence-refined/`
- **vs. 8BitDo Ultimate (2.4GHz / Bluetooth)**: the Ultimate line is the "modern competitive" pad, 2.4GHz low-latency dongle, charging dock, often Hall Effect sticks. The Pro 2 is the "retro-feel" pad: classic SNES-style body and the standout d-pad, Bluetooth/USB-C only (no 2.4GHz dongle), no dock in-box. Choose Pro 2 for d-pad/retro feel, Ultimate for wireless latency + dock convenience.
- **vs. 8BitDo Pro 3** (`B0FFGRQ6XY`, ~$58): the successor, TMR joysticks, swappable ABXY buttons, charging dock, Hall triggers. Amazon explicitly tags it "newer version." More money, more features; the Pro 2 is the value/retro pick.
- **vs. Pro 2 for Xbox** (`B0CYZKNSS1`): a *different* product, officially licensed for Xbox, wired, with a 3.5mm headset jack. Not cross-platform like this Bluetooth Pro 2. Mentioned only to disambiguate.

## Image (validated ASIN only)

- Validated product ASIN for image sourcing: **`B0CSPHXJYM`** (8BitDo Pro 2, Hall Effect, Black Edition). Pull the hero from Amazon PA-API for this ASIN at scaffold time (per repo rule, no AI product images; Amazon/brand media only). Do not reuse the dead `B08XY8H9D5` images.

## Sources

- Amazon (recommended target, Black): `https://www.amazon.com/dp/B0CSPHXJYM`
- Amazon (Gray sibling, fallback): `https://www.amazon.com/dp/B0CSPH1JYV`
- Amazon (original ALPS Gray, DEAD, availability-gate fail): `https://www.amazon.com/dp/B08XY8H9D5`
- Amazon (Pro 3 successor, NOT target): `https://www.amazon.com/dp/B0FFGRQ6XY`
- Amazon (Pro 2 for Xbox, different product): `https://www.amazon.com/dp/B0CYZKNSS1`
- 8BitDo manufacturer page: `https://www.8bitdo.com/pro2/`
- SlashGear review (Eric Abent): `https://www.slashgear.com/811511/8bitdo-pro-2-controller-review-excellence-refined/`

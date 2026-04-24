# Store Compliance — Жопокалипсис: Оборона Трона

**Document status:** Authoritative  
**Last updated:** 2026-04-23  
**Owner:** Production Lead + Legal Review  
**Referenced by:** `design/gdd/game-concept.md`, `design/gdd/master-gdd.md`

> This document is binding for all agents and contributors. Any design or asset decision that touches store-visible content, IAP, or ads MUST be checked against this document first.

---

## Table of Contents

1. [Apple App Store — Key Rules for This Project](#1-apple-app-store--key-rules-for-this-project)
2. [Google Play — Key Rules for This Project](#2-google-play--key-rules-for-this-project)
3. [Content Boundary Table](#3-content-boundary-table)
4. [director_build vs. store_build Split Rules](#4-director_build-vs-store_build-split-rules)
5. [Icon and Screenshot Rules (store_build)](#5-icon-and-screenshot-rules-store_build)
6. [IAP Requirements](#6-iap-requirements)
7. [Ad Placement Rules](#7-ad-placement-rules)
8. [Banned Content Checklist](#8-banned-content-checklist)

---

## 1. Apple App Store — Key Rules for This Project

### 1.1 Objectionable Content (App Store Review Guidelines 1.1)

Apple's guidelines prohibit content that a "reasonable person would find offensive, insensitive, upsetting, intended to disgust, or in exceptionally poor taste." This is the most subjective and highest-risk rule for this project.

**How we comply:**
- The store_build represents a clearly cartoon, comedic presentation — not realistic bodily content.
- All metadata (description, screenshots, name) for the store_build uses abstracted language (see §4).
- The 17+ age rating is self-declared and consistent with content; Apple reviews this declaration.
- We do not submit the director_build to the App Store.

**Risk notes:**
- Apple review is human and inconsistent. A reviewer who finds toilet humor personally offensive may reject even a compliant build.
- Mitigation: appeal process is available. Prepare a content comparison document showing similarity to approved apps (Toilet Tower Defense, South Park: Phone Destroyer) before submission.
- The Russian-language primary title and Russian metadata carry higher risk. Provide full English translation in the metadata notes field during review.

### 1.2 Metadata Requirements

**App name:** Must accurately represent the app. "Apocabutt: Defense of the Throne" (EN) is acceptable; the Russian transliteration should be in the subtitle field only.

**Description:** Must not misrepresent gameplay. Must not contain profanity. store_build description must avoid crude language even if gameplay is crude.

**Keywords:** No profanity in keyword fields. Common alternative: use "gross-out," "toilet," "sewer," "defense," "cartoon" as keyword descriptors.

**Screenshots:** Must show actual gameplay. Cannot show content not present in the build being submitted. See §5.

**Age rating declarations (Content Descriptions):**
| Category | Our declaration |
|---|---|
| Cartoon or Fantasy Violence | Frequent/Intense |
| Mature/Suggestive Themes | Infrequent/Mild |
| Horror/Fear Themes | Infrequent/Mild |
| Profanity or Crude Humor | Frequent/Intense |
| All other sexual/drug/gambling categories | None |

**Result:** 17+ rating.

### 1.3 IAP Rules (Apple)

- ALL in-app purchases for digital goods must use Apple's In-App Purchase API. No third-party payment processors for digital items.
- Consumable (Crystal packs): Standard Apple consumable product type.
- Non-consumable (No Ads): Standard Apple non-consumable. Must be restorable if app is reinstalled.
- Subscription (Sludge Pass): Auto-renewable subscription. Requires:
  - Clear price and renewal terms displayed before purchase
  - Cancelation method clearly explained (iOS Settings → Subscriptions)
  - Free trial (if offered) with explicit end-date disclosure
  - Subscription must unlock features beyond what the base app provides
- IAP prices must be set using Apple's pricing tiers — no custom pricing.
- "No Ads" IAP must actually remove the stated ads. Rewarded ads (player-initiated) may remain; this must be stated in the product description.

### 1.4 Age Rating System

Apple uses a 4+ / 9+ / 12+ / 17+ scale. Our target is **17+**.

17+ is Apple's highest available rating. It does NOT prevent store discovery or download — it simply requires the user to have their parental controls set to allow 17+ apps. Unlike AO (Adults Only) in ESRB, there is no "above 17+" category on Apple — we cannot be rejected solely on age rating.

The 17+ rating is triggered by our Frequent/Intense Violence and Frequent/Intense Crude Humor declarations.

---

## 2. Google Play — Key Rules for This Project

### 2.1 Inappropriate Content Policy

Google Play's Inappropriate Content policy covers:
- Sexual content and profanity
- Violence and disturbing content
- Hate speech
- Dangerous products or activities

**How we comply:**
- Cartoon violence is explicitly categorized as moderate by Google's policy guidelines, distinct from graphic/realistic violence.
- Crude humor (toilet-themed) is not classified as prohibited content on Google Play; it may affect the rating tier.
- No sexual content of any kind.
- No hate speech, no real-world group mockery.

**Risk notes:**
- Google's automated content scanning may flag Russian-language text with profanity. All Russian-language metadata for the store_build must be reviewed before submission.
- User reports can trigger manual review. The director_build must never be distributed through Google Play; sideload only.

### 2.2 Inappropriate Content — Profanity and Lewd Content

Google Play's policy distinguishes between:
- Profanity in user-facing UI/metadata (higher risk, may cause rating bump or rejection)
- Profanity within gameplay (acceptable at Mature rating with appropriate declaration)

**store_build rule:** All player-facing UI text and all store metadata must use the sanitized vocabulary table (§4.3). In-game crude comedy content is acceptable at the Mature 17+ rating with correct content declaration.

### 2.3 Google Play Billing Policy

- ALL in-app purchases of digital goods within Android apps must use Google Play Billing. No exceptions for digital goods.
- Physical goods, peer-to-peer sales, and tipping mechanisms have separate rules — not applicable to this project.
- Price display: Google requires the price in local currency to be displayed at the point of purchase.
- Subscription terms: must clearly display price, billing cycle, and cancellation method before the user confirms purchase.
- Families policy: our 17+ rating excludes us from the Families program, which reduces compliance surface area significantly.

### 2.4 Rating System (Google Play / IARC)

Google Play uses the **IARC (International Age Rating Coalition)** questionnaire-based system.

Our expected ratings by territory:
| Rating System | Expected Rating |
|---|---|
| Google Play (IARC) | Mature 17+ |
| USK (Germany) | USK 18 |
| ClassInd (Brazil) | 16+ |
| PEGI (Europe) | PEGI 18 |
| ESRB (Americas) | M (17+) |

IARC ratings are self-declared via the questionnaire. Accurate declaration is required. Inaccurate declarations can result in app removal.

**IARC questionnaire answers for this project:**
- Violence: Moderate (cartoon, fantasy — not realistic, not graphic)
- Language: Mild to Moderate (crude humor, no extreme profanity in store_build)
- Sexual content: None
- Fear/Horror: Mild (cartoon grotesque)
- Drugs/Alcohol: None
- Gambling: None (no loot boxes, no simulated gambling)

---

## 3. Content Boundary Table

This table is the authoritative reference for all content decisions. All agents must check new content against this table.

### 3.1 ALLOWED Content

| Category | Examples | Notes |
|---|---|---|
| Toilet humor | Fart jokes, poop visual gags, wet slime, urine imagery (cartoon) | Core to the game's identity |
| Cartoon violence | Enemies being blasted, splattered, "popped" | Must remain cartoon, not realistic gore |
| Gross-out imagery | Slime, mold, parasites, cartoon bacteria | Central to the visual language |
| Crude language | Crude humor in dialogue, achievement strings, level names | In-game only; store metadata uses sanitized variants |
| Adult comedy | Dark comedy, absurdist gross-out, satirical edge | Must not tip into hate speech or real-group mockery |
| Biological horror | Body horror framing of enemies (parasites, mutation) | Cartoon register only |
| Cartoon death animations | Splatting, deflating, flushing away, comical X-eyes | Must be clearly non-realistic |
| Monster/creature violence | Tower attacks killing enemies with VFX | No realistic blood; brown/green/slime fluids only |
| Mature themes in comedy context | References to bodily functions, crude medical humor | Must be clearly comedic, not clinical or disturbing |

### 3.2 NOT ALLOWED Content (All Builds)

| Category | Examples | Reason |
|---|---|---|
| Explicit nudity | Exposed genitalia, bare breasts, sexual anatomy | Apple 1.1, Google Play Inappropriate Content |
| Sexual content | Sex acts, sexual arousal scenarios, erotic framing | Apple 1.1, Google Play; out of scope |
| Sexual fetish content | Any sexual or bodily fetish framing, even comedic | Hard content line for this project |
| Realistic gore | Realistic blood pools, dismemberment with realistic detail | Apple 1.1, Google Play Violence policy |
| Minors in gross/violent contexts | Child characters harmed, child-adjacent grotesque | Apple 1.1, Google Play |
| Hate speech | Content targeting real ethnic, national, religious groups | Apple 1.1, Google Play |
| Real-person mockery | Jokes targeting real public figures | Defamation risk, Apple 1.1 |
| Drug promotion | Portraying drug use positively, paraphernalia in a promoting context | Apple, Google Play |
| Gambling mechanics | Loot boxes, mystery purchases, simulated casino | Apple 1.7, Google Play Gambling policy |
| Unauthorized IP | Assets resembling copyrighted characters or properties | IP/legal |

### 3.3 CONDITIONAL Content (director_build only)

| Category | director_build | store_build |
|---|---|---|
| Explicit scatological imagery (visible excrement detail) | Allowed | Replaced with abstracted "sludge/goo" |
| Strong crude language in UI text | Allowed (RU/EN) | Replaced with sanitized vocabulary |
| Extreme visceral VFX (high-detail burst effects) | Allowed | Toned to cartoon splash level |
| Russian crude/profane enemy names | Allowed | English cartoon-neutral equivalents |

---

## 4. director_build vs. store_build Split Rules

### 4.1 Build Flag

The build type is controlled by a single compile-time export flag:

```
DIRECTOR_BUILD = true   → director_build
DIRECTOR_BUILD = false  → store_build (default for all store submissions)
```

This flag must be set in Godot Export Templates per export target. It must **not** be a runtime toggle. There is no in-game mechanism to switch builds.

### 4.2 Asset Swap System

Asset swaps are managed by the `PlatformBridge` autoload. On initialization, `PlatformBridge` reads the `DIRECTOR_BUILD` flag and sets the active asset path prefix:
- `director_build`: loads from `assets/director/`
- `store_build`: loads from `assets/store/`

All swappable assets exist in both paths. The game's resource loading layer always queries `PlatformBridge.get_asset_path(asset_id)` rather than hardcoding paths.

**Swappable asset categories:**
- Enemy sprite sheets (detailed vs. abstracted variants)
- Tower and cannon VFX particle systems
- UI icon variants
- Achievement and level-name strings (via localization key swap)
- App icon and splash screen

### 4.3 Sanitized Vocabulary Table

| director_build name (EN) | store_build name (EN) | Notes |
|---|---|---|
| Shit Demon | Sludge Demon | Boss |
| Shit Stream | Sludge Stream | Generic VFX reference |
| Diarrhea Mode | Rapid Fire Mode | Fire mode name in store UI |
| Fart Wave | Gas Blast | Ultimate name |
| Turd (any usage) | Goo Chunk / Slime Ball | Generic projectile names |
| Piss Stream | Acid Stream | Ultimate name |
| Toilet Roll Toss | Roll Toss | Ultimate name (shorter, neutral) |
| Enema of the Apocalypse | Purge of the Apocalypse | Chapter ultimate name |
| Chunk Burst | Chunk Burst | No change needed — already acceptable |
| Flush | Flush | No change needed |

**Note:** Russian-language names in director_build are preserved as-is (used in the full-content sideload APK). Russian names never appear in any store metadata — only English names appear in store-facing fields.

### 4.4 Metadata Swap

Store submissions use the following substitutions in all store-facing metadata:

| Field | director_build value | store_build value |
|---|---|---|
| App name | Жопокалипсис: Оборона Трона | Throne Defense: Gross-Out Tower Wars |
| Short description | — | "Defend the ancient Throne from biological horrors! Strategic tower defense with active manual combat." |
| Keywords | Not applicable | "tower defense, gross out, sewer, cartoon, strategy, RPG" |
| Content description | Not applicable | Uses standard cartoon violence + crude humor language |

---

## 5. Icon and Screenshot Rules (store_build)

### 5.1 App Icon

| Rule | Requirement |
|---|---|
| Must show gameplay-relevant imagery | Yes — Throne and cannon are the app identity |
| No explicit/crude content | Icon must not show excrement, anatomical detail, or sexual content |
| Readable at small sizes (29dp / 40dp) | Yes — main silhouette must be identifiable at 29dp |
| No misleading imagery | Icon must not imply different genre |
| director_build icon | May show more extreme gross-out imagery; not submitted to stores |

**store_build icon spec:** Ceramic throne on a dark sewer background; cannon barrel prominent; stylized color grading (browns and teals); comic-book fat outline. No visible excrement. The cannon is the hero element.

### 5.2 Screenshots

| Rule | Requirement |
|---|---|
| Must show actual gameplay | Screenshots must be taken from the store_build, not director_build |
| No deceptive representations | Cannot show content that is not present in the build |
| Age-appropriate preview | Screenshots must not show content that would exceed the age rating when viewed by a minor |
| Text overlays | Allowed for feature callouts; must not contain profanity |

**Required screenshot set (minimum 5):**
1. Active wave gameplay — cannon aiming, towers firing
2. Tower placement / pre-wave strategy view
3. Ultimate activation (store_build VFX variant)
4. Boss encounter (Засор/Blockage — most visually accessible boss)
5. Meta progression hub screen

**Optional screenshots (recommended):**
6. Chapter 1 environment establishing shot
7. Combo reaction VFX (non-crude element)

### 5.3 Preview Video (optional, recommended)

If a preview video is submitted, it must:
- Use store_build visuals only
- Not contain profanity in any audio track
- Be under 30 seconds (Apple) / under 30 seconds (Google Play)
- Show genuine gameplay, not pre-rendered cutscenes

---

## 6. IAP Requirements

### 6.1 Mandatory Platform Billing

| Scenario | Required processor | Prohibited alternatives |
|---|---|---|
| Digital consumable (Crystal packs) | Apple IAP / Google Play Billing | PayPal, Stripe, web payment, any third party |
| Digital non-consumable (No Ads) | Apple IAP / Google Play Billing | Same |
| Auto-renewing subscription (Sludge Pass) | Apple IAP / Google Play Billing | Same |
| Physical goods (if any, e.g., merch) | Any payment processor | N/A — physical goods exempt |

Violation of this rule results in immediate app removal. There are no exceptions.

### 6.2 Subscription (Sludge Pass) Compliance Checklist

Before submitting any build containing the Sludge Pass subscription:

- [ ] Price and renewal period displayed in the purchase dialog before confirmation
- [ ] Auto-renewal explicitly stated ("Automatically renews at $4.99/month")
- [ ] Free trial disclosure (if applicable): exact end date shown
- [ ] Cancellation instructions accessible in-app ("Manage in Settings → Subscriptions")
- [ ] Subscription terms link points to active Terms of Service URL
- [ ] Privacy policy link is valid and up to date
- [ ] Apple: subscription declared in App Store Connect with all required metadata fields
- [ ] Google: subscription declared in Google Play Console with correct billing period

### 6.3 No Ads IAP Compliance

- The No Ads purchase **removes interstitial ads** and **banner ads** (if any).
- The No Ads purchase does **not** remove rewarded ads — rewarded ads are player-initiated and explicitly optional. This distinction must be stated clearly in the IAP product description (both App Store and Google Play).
- The purchase must be restorable on iOS (standard non-consumable restore behavior via `StoreKit`).

### 6.4 No Loot Box Policy

**The game must not have loot boxes or mystery purchases in 1.0.** All IAP must have deterministic, clearly disclosed rewards. This policy applies to:
- Crystal packs: exact Crystal quantity disclosed before purchase
- No Ads: effect clearly stated
- Sludge Pass: all included benefits listed before purchase

If a gacha or loot mechanism is considered for a future update, a separate store compliance review is required before implementation.

---

## 7. Ad Placement Rules

### 7.1 Core Ad Placement Principles

These rules are derived from Apple and Google policy, industry standards, and our product philosophy.

**Rule 1 — No gameplay interruption.** No ad of any type (rewarded, interstitial, banner) may appear during an active wave, during a boss encounter, during a cutscene, or during any ultimate animation.

**Rule 2 — Rewarded ads are always player-initiated.** The player must tap a clearly labeled button to trigger a rewarded ad. The button must be visually distinct from gameplay elements and must include ad iconography (a small play/video icon). No auto-play rewarded ads.

**Rule 3 — Interstitial frequency cap.** Interstitial ads fire at most once per three completed sessions. A "session" for this purpose is defined as a level attempt (win or loss) that lasted more than 60 seconds. Very short sessions and tutorial sessions do not trigger interstitials.

**Rule 4 — Skip availability.** All interstitial ads must be skippable after 5 seconds. Rewarded ads may not be skippable until completion (standard rewarded ad behavior).

**Rule 5 — No_ads purchase fully respected.** After purchasing No Ads, the game must suppress all interstitial ad loads. The rewarded ad CTA buttons remain visible but are optional and clearly marked as optional.

### 7.2 Approved Ad Placement Points

| Placement | Ad Type | Trigger Condition | Player Action Required |
|---|---|---|---|
| Defeat screen | Rewarded | Player taps "Watch ad for +1 life" | Yes — button tap |
| Level complete screen | Rewarded | Player taps "Double your currency reward" | Yes — button tap |
| Level complete screen (3rd session+) | Interstitial | Auto after result animation completes | No — but skippable after 5 sec |
| Pre-wave break | Rewarded (banner CTA) | Player taps optional "Bonus" banner | Yes — button tap |

### 7.3 Banned Ad Placement Points

| Placement | Why Banned |
|---|---|
| During any active wave | Apple/Google policy; also directly harms gameplay feel |
| During boss encounters | Same as above; ruins boss pacing |
| During ultimate activation | Interrupts the product's key emotional beat |
| App launch / loading screen | Apple guideline 2.3.7 (interstitials at app launch) |
| Tutorial levels (first 3 levels) | New user experience protection |
| More than 1 interstitial per session | Frequency cap rule |
| Before the player has played 2+ sessions | Cold start experience protection |

### 7.4 Ad SDK Integration

- Ad SDK is encapsulated in `AdsBridge` autoload only. No ad SDK calls may exist outside `AdsBridge`.
- `AdsBridge` exposes signals only: `ad_rewarded_complete`, `ad_interstitial_closed`, `ad_load_failed`.
- Gameplay code must never import or call ad SDK functions directly.
- `AdsBridge` reads the `no_ads_purchased` flag from `EconomyService` and suppresses interstitial loads when true.

---

## 8. Banned Content Checklist

Use this checklist as a final gate before any build submission or any major content addition.

### 8.1 Visual Content Checklist

- [ ] No visible realistic human genitalia or explicit sexual anatomy in any asset
- [ ] No sexual acts depicted or strongly implied in any context
- [ ] No realistic blood (cartoon slime/goo substitutes are acceptable)
- [ ] No realistic dismemberment with detailed anatomical accuracy
- [ ] No child/minor characters in violent, gross, or sexualized contexts
- [ ] All excrement/scatological imagery in store_build is cartoon-abstracted ("goo/sludge"), not depicted realistically
- [ ] No real-world brands, logos, or trademarks used without license in any visible asset
- [ ] No symbols of hate, extremism, or real-world political movements
- [ ] No real-world weapon manufacturer names or logos

### 8.2 Text and Metadata Checklist

- [ ] No profanity in store_build app name, subtitle, description, or keywords
- [ ] No profanity in store_build screenshots or preview video text overlays
- [ ] No hate speech, slurs, or derogatory language targeting real groups in any metadata
- [ ] Russian-language text in store metadata reviewed by a native speaker for inadvertent profanity
- [ ] All IAP descriptions accurately describe what the purchase provides
- [ ] Subscription auto-renewal terms are stated in the IAP description
- [ ] Age rating declarations (Apple CARS / Google IARC) match actual content

### 8.3 Gameplay Mechanic Checklist

- [ ] No simulated gambling or loot box mechanics with real-money purchase
- [ ] No hidden IAP costs (no forced mandatory purchases to continue play)
- [ ] Energy system caps at 5 (base) / 8 (subscription); regen is not faster than 30 min/life
- [ ] No ads during active gameplay waves
- [ ] Rewarded ads require explicit player tap to initiate
- [ ] No_ads purchase purchase suppresses all interstitials
- [ ] Subscription cancellation is accessible without leaving the app (deep link to platform subscription management)

### 8.4 Audio Checklist

- [ ] No sexually explicit lyrics or speech in any audio asset
- [ ] No hate speech or slurs in any voiceover or ambient audio
- [ ] All profanity in audio is within gameplay (not store preview video)
- [ ] store_build audio tracks reviewed for crude language if any voiced lines exist

---

*This document should be reviewed before each store submission. Any changes to IAP structure, ad placement, or visual content outside the parameters established here require a compliance review by the Production Lead.*

# Game Concept — Жопокалипсис: Оборона Трона (Apocabutt: Defense of the Throne)

**Document status:** Authoritative  
**Last updated:** 2026-04-23  
**Owner:** Design Lead  

---

## 1. Working Title and Alternatives

**Primary title (RU):** Жопокалипсис: Оборона Трона  
**Primary title (EN):** Apocabutt: Defense of the Throne  
**Working slug:** `apocabutt`  

**Considered alternatives:**
- Toilet Siege: Butt Cannon Defense
- Throne Room Terror
- The Porcelain Last Stand
- Дерьмовая Оборона (Shit Defense) — rejected; too on-the-nose for store metadata

**Store-facing title (store_build):** Throne Defense: Gross-Out Tower Wars  
*(Avoids profanity in store listings while preserving the concept.)*

---

## 2. Elevator Pitch

A grotesque cartoon tower defense where you personally man a living butt-cannon to defend the sacred Throne of Shame from waves of microscopic monsters — mixing the strategic depth of classic TD with a visceral, active-combat feel and a gross-out comedy voice unlike anything on the mobile charts.

**One-liner:** "Your finger IS the cannon. Defend the Throne. Release the pressure."

---

## 3. Genre and Platform

| Field | Value |
|---|---|
| Genre | Vertical-portrait Tower Defense RPG with active manual combat |
| Sub-genre | Session-based mobile TD with meta progression |
| Platform | Android (Play Store) + iOS (App Store) |
| Orientation | Portrait only (9:16, safe area aware) |
| Renderer | Godot 4.6 Mobile renderer |
| Target device | Mid-range smartphones (2021+), 3 GB RAM minimum |
| Input | Multi-touch only; no keyboard/controller support required |

---

## 4. Core Fantasy / Player Power Fantasy

The player fantasy is **pressure release** — both literally and emotionally. Every wave builds tension as enemies surge from the top of the screen toward the Throne below. The player is never passive. The right thumb directly aims and fires the central butt-cannon in real time, producing a tactile, impactful response on every shot. When the Pressure Meter fills, the player unleashes an Ultimate ability — an outsized, screen-clearing spectacle that feels genuinely cathartic.

The secondary fantasy is **grotesque mastery**: the player learns to read a chaotic, disgusting battlefield and impose order through elegant placement of biological-horror towers, smart combo chaining, and well-timed ability use. Success feels like being the one sane (if crass) general in a very filthy war.

**Emotional arc per session:** Anxiety → Escalation → Cathartic Release → Satisfaction.

---

## 5. Target Audience

**Primary:** Men 18–35 who enjoy mobile TD games (Kingdom Rush, Bloons, Plants vs. Zombies) but are fatigued by sanitized aesthetics and pay-to-win structures. They respond to adult gross-out comedy in the vein of South Park, Beavis and Butt-Head, and Rick and Morty.

**Secondary:** Hardcore mobile TD players 25–45 who want strategic depth (elemental combos, branching tower trees, boss encounters with distinct phases) and are willing to invest time in meta progression.

**Excluded:** Under-17 audience. Players offended by crude humor. Players who expect erotic or fetish content.

**Retention profile:** Daily session player, 3–8 minutes per run, 2–4 runs per day.

---

## 6. Key Differentiators

**What makes this not just another TD:**

1. **Active manual fire.** Most mobile TDs are fully passive after placement. Here the central tower is permanently under direct player control with a joystick-aimed cannon. The player must split attention between the macro (tower management, ultimates) and the micro (aiming at priority targets). This creates genuine skill expression and replayability beyond build optimization.

2. **Pressure Meter as narrative punctuation.** Instead of cooldown timers, the Pressure Meter fills from damage taken and enemies killed. Ultimates fire when the meter peaks. This means every ultimate eruption is earned and dramatically timed, not metronomically triggered. Eight distinct ultimates with different tactical roles give the player a meaningful identity.

3. **Elemental combo system built on a gross-out vocabulary.** Heat/Cold/Mold tags interact in ways that feel intuitive to the theme — boiling infected slime creates toxic steam; sterile freeze plus rot creates a cryo-parasite explosion. The comedy tone makes the complexity approachable because the player mentally models it as cartoon logic, not spreadsheet logic.

4. **Tone as a genuine differentiator.** The gross-out cartoon comedy space is almost entirely unoccupied in the TD genre. The visual language (ceramic gloss, sewer grime, comic-book impact panels), audio (wet BLORP hit feedback, strained tuba stabs, cartoonish gurgles), and copy (enemy names, chapter titles, achievement strings) all reinforce a consistent comedic identity that stands out on the app store grid.

5. **Two-build compliance strategy.** `director_build` and `store_build` are mechanically identical; only visuals and metadata differ. This means the studio can ship on all major stores without maintaining a separate game, preserving development velocity.

---

## 7. Rating and Store Compliance Stance

**Target ratings:**
- Apple App Store: 17+ (Frequent/Intense: Cartoon or Fantasy Violence, Infrequent/Mild: Mature/Suggestive Themes, Horror/Fear Themes)
- Google Play: Mature 17+ (Violence: Moderate, Crude Humor: Present)
- ESRB self-classification (if pursued): M (17+)

**Compliance philosophy:** The game earns its 17+ rating through crude humor and cartoon violence — the same space occupied by South Park: Phone Destroyer and Toilet Tower Defense. It does NOT earn that rating through sexual content, nudity, or graphic gore. This keeps the submission window predictable and avoids "objectionable content" rejection risk.

**Content hard stops (ALL agents, ALL builds):**
- No explicit nudity or sexual content of any kind
- No sexual fetish framing, even comedic
- No realistic depiction of bodily harm or gore
- No content involving minors in gross/violent contexts
- No hate speech, slurs, or real-group mockery

See `/docs/platform/store-compliance.md` for the full content boundary table.

---

## 8. Two-Build Strategy: director_build vs. store_build

Both builds share 100% of gameplay code, data, and progression systems. The split is surface-level only and managed through export flags and asset swaps.

| Dimension | director_build | store_build |
|---|---|---|
| **Purpose** | Full creative intent, side-loading / alternate stores | Apple App Store + Google Play main submission |
| **Visuals** | Full gross-out: visible excrement, extreme slime, visceral burst VFX | Abstracted: excrement replaced with "sludge/goo," burst VFX dialed to cartoon splat |
| **Copy/Naming** | Russian + English crude names (Дерьмодемон, Shit Demon, etc.) | English renamed to cartoon-neutral equivalents (Sludge Demon, Goop Golem, etc.) |
| **Store metadata** | Not for major stores | Sanitized description, age-safe screenshots, safe icon variant |
| **IAP** | Same backend | Same backend — Apple IAP / Google Play Billing mandatory |
| **Ads** | Same SDK | Same SDK — same placement rules |
| **Build flag** | `DIRECTOR_BUILD = true` | `DIRECTOR_BUILD = false` |
| **Delivery** | APK sideload or alternate Android stores | App Store Connect + Google Play Console |

Asset swap is handled by conditional resource loading in `PlatformBridge` based on the build flag. No runtime toggle — the flag is set at export time only.

---

## 9. Project Risks (Top 3)

### Risk 1 — Store Rejection for Content (Probability: Medium / Impact: High)

Both Apple and Google have broad "objectionable content" clauses. Cartoon toilet humor has precedent on both stores, but the review process is inconsistent, especially for non-English-language metadata. The store_build asset swap mitigates this, but the first submission is an unknown.

**Mitigation:**
- Dedicated store_build with explicitly sanitized screenshots, icon, and description
- Pre-submission content review checklist against Apple and Google guidelines
- Brief legal review of Russian-language metadata before submission
- Contingency: APK direct distribution via studio website if Play Store rejects

### Risk 2 — Active-Aim Fatigue on Mobile (Probability: Medium / Impact: Medium)

Thumb-joystick aiming over 5–8 minute sessions can cause fatigue or imprecision on small screens. If the manual combat feel is not tight, the core differentiator becomes a liability.

**Mitigation:**
- Auto-aim assist with configurable strength (default: light)
- Vertical Slice must validate feel on at least 3 physical device sizes
- Input deadzone and sensitivity tunable in Settings
- Auto-fire fallback mode for accessibility (designates manual cannon as the weakest tower in auto mode)

### Risk 3 — Scope Creep from 8 Ultimates × 3 Tower Schools × 6 Chapters (Probability: High / Impact: High)

The design is rich. Eight ultimates, twelve tower branches, six boss encounters, and a meta progression tree represent significant content volume. If each is treated as fully custom art + VFX + SFX work, production timeline doubles.

**Mitigation:**
- Vertical Slice uses placeholder VFX for non-showcase ultimates
- Tower tiers 3–4 share base meshes with palette swaps; branching is stat-only until late milestone
- Chapter environments share tileset base; Chapter 1 (Sewers) is the foundation tileset
- Content is additive per milestone — Milestones 1–2 deliver the core loop with 2 schools and 4 ultimates

---

## 10. Visual Identity Anchor

Жопокалипсис lives at the intersection of **gleaming ceramic dread and cartoon carnage**. Every asset reads as if sculpted from gross-out bathroom materials — wet porcelain, rusted pipes, iridescent slime, mold-blooming grout — then lit like a toy commercial and detonated like a Saturday morning cartoon. Fat outlines keep everything readable at 375 dp portrait width. Comic-book impact panels (KA-SPLAT!, BLORP!, РЫГНУЛО!) punctuate every significant hit, reinforcing the comedic register and ensuring the player always knows when damage is landing. The unified shader pass — palette clamp, wetness mask, grime overlay, outline, emissive accent — is the visual contract: if it doesn't look like it came out of the same disgusting pipe, it doesn't belong in this game.

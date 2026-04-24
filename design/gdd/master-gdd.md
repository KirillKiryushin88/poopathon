# Master GDD — Жопокалипсис: Оборона Трона (Apocabutt: Defense of the Throne)

**Document status:** Authoritative  
**Last updated:** 2026-04-23  
**Owner:** Design Lead  
**Cross-reference:** `design/gdd/game-concept.md`, `docs/platform/store-compliance.md`

---

## Table of Contents

1. [Product Vision](#1-product-vision)
2. [Core Loop](#2-core-loop)
3. [Central Tower / Player System](#3-central-tower--player-system)
4. [Ultimates](#4-ultimates)
5. [Tower System](#5-tower-system)
6. [Enemy Roster](#6-enemy-roster)
7. [Boss Encounter Design](#7-boss-encounter-design)
8. [Campaign Structure](#8-campaign-structure)
9. [Meta Progression System](#9-meta-progression-system)
10. [Mobile UX Spec](#10-mobile-ux-spec)
11. [Monetization Spec](#11-monetization-spec)

---

## 1. Product Vision

### 1.1 Statement

Жопокалипсис is a vertical-portrait tower defense RPG in which the player directly controls a central butt-cannon while managing a ring of biological horror towers. The game is powered by a gross-out cartoon comedy identity — grotesque, adult, and funny, never sexual or graphically gory — and differentiates itself from passive TD competitors through active manual combat, a Pressure Meter ultimate system, and deep elemental combo design rooted in a toilet-biology theme.

### 1.2 Design Pillars

| Pillar | Statement |
|---|---|
| **Feel First** | Every shot must feel wet, heavy, and satisfying. Feedback (VFX, SFX, screen shake, impact panels) before balance. |
| **Active Presence** | The player is never just watching. Every second is aim-or-decide. |
| **Earned Explosions** | Ultimates are not timers. They are rewards. The Pressure Meter builds through struggle. |
| **Theme Coherence** | Mechanics, visuals, and comedy all emerge from the same gross-biology fantasy. |
| **Mobile Respect** | 5-minute sessions. No punishing energy walls. Rewarded ads at natural breaks only. No gameplay interruptions. |

### 1.3 Scope Boundaries

**In scope for 1.0:**
- 6 campaign chapters, each with 5–7 waves and a boss
- 1 central tower with 3 fire modes + Pressure Meter system
- 8 ultimates (may ship 6 in 1.0, +2 post-launch)
- 3 tower schools × 4 tiers with tier-3 branching
- 8 enemy types + 6 boss encounters
- Full meta progression tree
- IAP economy + rewarded/interstitial ad integration
- director_build and store_build export targets

**Out of scope for 1.0:**
- PvP or async multiplayer
- Guild/clan systems
- Endless/survival mode beyond Chapter 6 endurance variant
- Seasonal events (Sludge Pass reserved for post-launch live ops)

---

## 2. Core Loop

### 2.1 Flow Diagram

```
┌─────────────────────────────────────────────────────────────────┐
│                        SESSION START                            │
│   Load level → Play tower placement tutorial (first run only)   │
└───────────────────────────┬─────────────────────────────────────┘
                            │
                    ┌───────▼────────┐
                    │  PRE-WAVE PREP │
                    │  (15–20 sec)   │
                    │  • Place/swap  │
                    │    towers      │
                    │  • Review next │
                    │    enemy pool  │
                    └───────┬────────┘
                            │
                    ┌───────▼────────────────────────────────────┐
                    │                WAVE ACTIVE                  │
                    │                                             │
                    │  RIGHT THUMB: Aim joystick → fire cannon    │
                    │    - Tap: Chunk Burst                       │
                    │    - Hold: Auto Diarrhea                    │
                    │    - Swipe up: Gas Cone                     │
                    │                                             │
                    │  LEFT THUMB: Radial menu / Ultimate button  │
                    │    - Long press tower: upgrade/sell radial  │
                    │    - Tap ultimate button: activate if ready │
                    │                                             │
                    │  PRESSURE METER fills from:                 │
                    │    - Damage taken by Throne                 │
                    │    - Enemies killed                         │
                    │    - Tower kill streaks                     │
                    │                                             │
                    │  → ULTIMATE AVAILABLE: button pulses,       │
                    │    haptic buzz, glow ring on cannon         │
                    └───────┬────────────────────────────────────┘
                            │
            ┌───────────────┼───────────────┐
            │               │               │
    ┌───────▼──────┐ ┌──────▼──────┐ ┌─────▼──────────┐
    │ WAVE CLEARED │ │  THRONE HP  │ │ PLAYER DEFEAT  │
    │              │ │  reaches 0  │ │                │
    └───────┬──────┘ └──────┬──────┘ └─────┬──────────┘
            │               │               │
            │        ┌──────▼──────┐  ┌─────▼──────────┐
            │        │   DEFEAT    │  │  DEFEAT SCREEN  │
            │        │   SCREEN    │  │  • Retry        │
            │        │  (see §11)  │  │  • Rewarded ad  │
            │        └─────────────┘  │    for partial  │
            │                         │    energy refund│
            │                         └─────────────────┘
            │
    ┌───────▼──────────────────────────────┐
    │          INTER-WAVE BREAK            │
    │  (auto-paused, 12 sec countdown)     │
    │  • Slime currency drops collected    │
    │  • Tower upgrade prompts             │
    │  • Pressure Meter partially retained │
    └───────┬──────────────────────────────┘
            │
    [Waves 1–4]   [Wave 5 = BOSS WAVE]
            │               │
            │       ┌───────▼────────────┐
            │       │    BOSS ENCOUNTER  │
            │       │  2–3 phases, cinematic│
            │       │  intro + finisher  │
            │       └───────┬────────────┘
            │               │
            └───────────────┘
                            │
                    ┌───────▼──────────────────────────┐
                    │         CHAPTER END SCREEN        │
                    │  • Stars awarded (1–3)            │
                    │  • Dirty Challenge completed?     │
                    │  • Perfect Clear bonus?           │
                    │  • Currency summary               │
                    │  • Rewarded ad prompt (optional)  │
                    │  • Next chapter unlock check      │
                    └───────────────────────────────────┘
                            │
                    ┌───────▼──────────────────────────┐
                    │         META LAYER                │
                    │  • Spend Slime / Crystals         │
                    │  • Upgrade skill trees            │
                    │  • Unlock new towers / alt slots  │
                    └───────────────────────────────────┘
```

### 2.2 Session Length Targets

| Mode | Target Duration |
|---|---|
| Normal chapter level (5 waves) | 3–5 minutes |
| Boss chapter level (5 waves + boss) | 6–8 minutes |
| Endurance chapter (post-clear, Chapter 6) | Up to 10 minutes |

### 2.3 Wave Structure

Each level has N waves (5–7) set in the level data Resource. Wave data defines:
- Enemy types and quantities
- Spawn interval
- Lane distribution (left, center, right, or random)
- Any scripted events (ambush, elite spawn)
- Pressure Meter bonus multiplier (boss waves: ×1.5)

---

## 3. Central Tower / Player System

### 3.1 Overview

The central tower is the Throne of Shame itself — a ceramic toilet-throne mounted at the bottom center of the play field. The cannon emerges from the bowl. It cannot be moved or sold. It is the player avatar. All three fire modes are available from the start; the player switches between them via gesture on the right-hand joystick zone.

### 3.2 Fire Modes

#### Mode 1 — Chunk Burst

| Field | Value |
|---|---|
| **Gesture** | Tap joystick |
| **Fantasy** | Heavy artillery round, gross ballistic impact |
| **Projectile** | Single large chunk, moderate arc, ballistic travel |
| **Damage** | High single-target damage |
| **Armor pierce** | Ignores 50% of armor on the target |
| **Stagger** | Knocks enemy back ~1 tile |
| **Fire rate** | 0.8 shots/sec (base) |
| **Range** | Full vertical screen |
| **Combo tag** | IMPACT |
| **VFX** | Brown ballistic arc, large ceramic-wet splat on contact, debris scatter |
| **SFX** | Wet heavy thud + distant "plop" echo |
| **Best against** | Armored tanks (Bacteria), single high-HP targets, boss phase openers |

#### Mode 2 — Automatic Diarrhea

| Field | Value |
|---|---|
| **Gesture** | Hold joystick |
| **Fantasy** | Relentless stream, stagger-locking enemies in their lane |
| **Projectile** | Rapid small pellets, straight line, no arc |
| **Damage** | Low per-hit, high cumulative over hold duration |
| **Stagger** | Very high — pellets tick stagger; enemies cannot advance during sustained fire |
| **Fire rate** | 12 shots/sec (base) |
| **Range** | 60% of vertical screen |
| **Combo tag** | STREAM |
| **Overheat** | Meter builds during hold; at full, cannon sputters for 1.5 sec before reset |
| **VFX** | Yellow-brown continuous stream, small splats, twitching enemy stagger animation |
| **SFX** | Continuous wet rattle, per-splat micro-clicks |
| **Best against** | Runners (Virus), groups, stagger-locking boss phase transitions |

#### Mode 3 — Gas Cone

| Field | Value |
|---|---|
| **Gesture** | Swipe up on joystick |
| **Fantasy** | Short-range fan of toxic gas that debuffs and enables elemental combos |
| **Projectile** | Fan-shaped AoE cloud, instant, no travel |
| **Damage** | Low direct damage |
| **Debuff** | Applies **Stench** to all enemies in cone for 4 sec |
| **Stench effect** | Stench-tagged enemies take +40% damage from elemental towers (Heat/Cold/Mold) and are primed for elemental combos |
| **Cooldown** | 3 sec after each use |
| **Range** | Short (~40% vertical screen), wide fan (~90°) |
| **Combo tag** | GAS — triggers combo reactions with Heat, Cold, and Mold |
| **VFX** | Green-yellow gas billow, wavy heat-shimmer distortion in cone |
| **SFX** | Deep wet bwamp, then ambient hissing gas |
| **Best against** | Grouped enemies before tower fire, setting up elemental combos, Spore flyers at mid-screen |

### 3.3 Central Tower Base Stats

| Stat | Base | Max (fully upgraded) |
|---|---|---|
| Throne HP | 100 | 250 |
| Chunk Burst damage | 40 | 110 |
| Auto Diarrhea damage/hit | 4 | 11 |
| Gas Cone base damage | 10 | 28 |
| Armor pierce (Chunk) | 50% | 80% |
| Stench duration | 4 sec | 7 sec |
| Pressure gain on kill | 5 | 8 |
| Pressure gain on Throne hit | 10 | 10 (uncapped) |

### 3.4 Pressure Meter

The Pressure Meter is a 0–100 gauge displayed prominently above the left thumb zone.

**Gain sources:**
- Enemy killed by cannon: +5 pressure (upgradeable)
- Enemy killed by tower: +2 pressure
- Throne takes damage: +(damage × 0.15) pressure
- Kill streak bonus (5+ kills in 3 sec): +10 pressure burst

**Decay:** Pressure does not decay during a wave. Between waves, it decays at 5/sec after a 10-second grace window.

**At 100:** Pressure gauge shakes, glows, cannon emits steam vents. Ultimate button becomes active. Player must tap the Ultimate button within 30 sec or pressure auto-releases as a weak Смыв (Flush) to prevent permanent overcharge.

**Tuning knob:** `pressure_gain_scale` (float, default 1.0) — global multiplier for all gain sources. Tuned per level in level data to pace ultimate frequency.

---

## 4. Ultimates

All ultimates are activated from the Ultimate button in the left thumb zone when the Pressure Meter is full. The active ultimate is selected from a quick radial (hold) or defaults to the last used (tap). Each ultimate drains the Pressure Meter completely.

---

### 4.1 Нассать (Piss Stream)

| Field | Value |
|---|---|
| **Fantasy** | Sustained acid beam that eats through armor like nothing |
| **Role** | Armor strip + sustained single-lane DPS |
| **Targeting** | Player-aimed joystick beam (holds finger to steer) |
| **Duration** | 4 sec channeled |
| **Damage** | Moderate per-tick, ×3 multiplier vs armored enemies |
| **Armor effect** | Reduces target armor by 60% for 8 sec (persists after beam ends) |
| **Cooldown/Cost** | Full Pressure Meter |
| **VFX** | Yellow arc beam, sparkling acid dissolve on armored targets, glow outline on stripped-armor debuff |
| **SFX** | High-pressure hiss, sizzling contact, satisfying ceramic crackle on armor break |
| **Tower synergy** | Armor-stripped enemies take full damage from Red (Heat) towers that normally under-perform vs. armor |
| **Boss utility** | Core tool for Засор (Blockage) phase 1, Крыса (Rat) when armor buff is active |
| **Mobile UX** | Finger held on aim joystick steers beam in real time; auto-tracks nearest armored enemy if aim zone is released |

---

### 4.2 Бросить туалетку (Toilet Roll Toss)

| Field | Value |
|---|---|
| **Fantasy** | A giant toilet roll careens down the lane, bouncing off everything |
| **Role** | Multi-lane horizontal sweeper, gap-filler |
| **Targeting** | Tap a lane to launch (or auto-launches down densest lane) |
| **Travel** | Bounces between lane walls ~3 times before expiring |
| **Damage** | Moderate AoE per bounce, no armor pierce |
| **Status** | Wraps enemies in wet paper — applies **Soaked** (slows by 30% for 3 sec) |
| **Cooldown/Cost** | Full Pressure Meter |
| **VFX** | Spinning paper cylinder, wet unravel on bounce impact, paper confetti trail |
| **SFX** | Cardboard thwop, wet splatter, comedic boing on bounce |
| **Tower synergy** | Soaked enemies hit by Blue (Cold) towers immediately apply Freeze proc instead of requiring accumulated slow stacks |
| **Boss utility** | Effective against Цепень (Tapeworm) body segments — can hit multiple segments in one roll |
| **Mobile UX** | Single tap selects lane; no sustained input required; satisfying passive to drop and watch |

---

### 4.3 Смыв (Flush)

| Field | Value |
|---|---|
| **Fantasy** | The Throne erupts with a tidal flush that sweeps the board |
| **Role** | Global wave reset / emergency defense |
| **Targeting** | No targeting — affects entire play field |
| **Effect** | Pushes all ground enemies back to their spawn line; deals (enemy current HP × 0.20) as true damage |
| **Does not affect** | Flyers (Spore), bosses (partial — pushes boss back one phase marker) |
| **Cooldown/Cost** | Full Pressure Meter |
| **VFX** | Screen-wide brown-water wave from bottom, enemies visibly ragdolled back, foam residue on lane surfaces for 2 sec |
| **SFX** | Building rumble, explosive water crash, distant enemy wail chorus |
| **Tower synergy** | Enemies in foam residue zone take +20% damage from all towers for 2 sec (wet debuff) |
| **Boss utility** | Essential panic button vs. Дерьмодемон phase 2 when summons overwhelm; boss itself is pushed back one phase segment |
| **Mobile UX** | One tap — no aim required; clearly communicates as "get out of jail" button; brief screen flash confirms activation |

---

### 4.4 Пердеж (Fart)

| Field | Value |
|---|---|
| **Fantasy** | A colossal fart detonates around the Throne, scattering everything |
| **Role** | Radial AoE fear + stealth counter |
| **Targeting** | Radial AoE centered on the Throne, full-width, ~40% vertical reach |
| **Damage** | Low direct damage |
| **Fear effect** | All affected ground enemies flee back ~3 tiles and lose 2 sec of pathing coherence |
| **Reveal effect** | Instantly reveals all invisible/stealthed enemies on the entire field for 6 sec |
| **Cooldown/Cost** | Full Pressure Meter |
| **VFX** | Expanding green-yellow gas ring from Throne base, wavy distortion, enemies visually "spooked" (pop-up scared eyes) |
| **SFX** | Deep resonant BWWAAAP, wind-like dispersal, tiny screams from scattered enemies |
| **Tower synergy** | Feared enemies clump near mid-field — perfect timing for Mold tower AoE poison pulses |
| **Boss utility** | Reveals Змея (Snake) burrowed phase; interrupts Цепень invisible-segment attacks |
| **Mobile UX** | One tap, instant; strong audio-visual payoff makes it feel powerful even when damage is low |

---

### 4.5 Бульон (Broth)

| Field | Value |
|---|---|
| **Fantasy** | A foul biological soup that slowly dissolves everything that stands in it |
| **Role** | Zone-denial, slow, infection setup |
| **Targeting** | Player-placed puddle (tap to position anywhere on field within range) |
| **Duration** | Puddle persists 8 sec |
| **Effect** | Slows all enemies in puddle by 50%; applies **Infection** stack every 1 sec (max 3 stacks); 3 stacks = Diseased (×1.5 DoT taken) |
| **Cooldown/Cost** | Full Pressure Meter |
| **VFX** | Bubbling brown-green pool, infected enemies gain visible pustule particles, stack count shown as small indicator |
| **SFX** | Wet boiling gloop loop, infection tick chirp |
| **Tower synergy** | Diseased enemies interacting with Green (Mold/Parasite) towers trigger **Parasite Burst** — worm splinter projectiles on death |
| **Boss utility** | Place under Засор (Blockage) mini-clog spawn points to slow and infect them as they emerge |
| **Mobile UX** | One tap to place; no drag required; placement preview circle shown before commit |

---

### 4.6 Гельминты (Helminths)

| Field | Value |
|---|---|
| **Fantasy** | Summon a swarm of burrowing worms that infest enemy bodies |
| **Role** | Multi-target DoT summoner, synergizes with worm-based towers |
| **Targeting** | Targets up to 5 enemies on field (priority: highest HP) — auto-targeted |
| **Worm behavior** | Each worm burrows into a target, dealing DoT for 6 sec; if target dies, worm transfers to nearest enemy |
| **Damage** | Per worm: moderate total DoT over duration |
| **Transfer** | Up to 2 transfers per worm before expiring |
| **Cooldown/Cost** | Full Pressure Meter |
| **VFX** | Worm projectiles arc from Throne cannon to targets, visible burrowing animation, pulsing exit wounds on targets |
| **SFX** | Wet launch squirt, burrowing crunch per impact, flesh-crawl ambience on infested targets |
| **Tower synergy** | Infested targets hit by Green tier-4 (Parasites) towers have worm count doubled |
| **Boss utility** | Effective against Цепень (Tapeworm) — each segment is treated as a separate target |
| **Mobile UX** | Instant auto-target, no aim; visual clarity requires targets to display worm count indicator over HP bar |

---

### 4.7 Глаз-лазер из жопы (Butt Eye Laser)

| Field | Value |
|---|---|
| **Fantasy** | A single enormous targeting eye appears from the Throne bowl and fires a screaming concentrated laser |
| **Role** | Maximum single-target burst; boss finisher |
| **Targeting** | Player-aimed joystick; locks to target when within a generous snap radius |
| **Duration** | 2-sec wind-up + 3-sec sustained beam |
| **Damage** | Very high burst; ignores all armor and damage reduction |
| **Charge** | Wind-up phase shows targeting reticle and growing eye animation; damage fires at beam activation |
| **Cooldown/Cost** | Full Pressure Meter |
| **VFX** | Giant eye rises from bowl during wind-up; beam is hot-pink with white core; beam path scorches lane surface |
| **SFX** | Building hum during wind-up, charged pop at activation, sustained sizzle shriek during beam, comedic "eye blink" at end |
| **Tower synergy** | Scorched-path debuff (2 sec): all enemies moving through scorched tiles take +25% damage from Heat towers |
| **Boss utility** | Primary tool for Дерьмодемон phase transitions; the intended showpiece ultimate |
| **Mobile UX** | Joystick aim during wind-up; snap-to-boss if player releases during boss encounter; distinct visual + haptic for the charge-up |

---

### 4.8 Клизма Апокалипсиса (Enema of the Apocalypse)

| Field | Value |
|---|---|
| **Fantasy** | A chapter-scale purge that changes the rules of the battle temporarily |
| **Role** | Rare chapter ultimate; tempo shift; emergency reset |
| **Availability** | Unlocked only in Chapters 5–6; costs full Pressure Meter + 1 Enema Charge (earned from chapter progression) |
| **Targeting** | No targeting — global effect |
| **Effect** | Clears all standard enemies from the field (bosses exempt); floods field with a 10-sec cleansing torrent that: deals sustained AoE damage to newly spawned enemies, grants all towers +50% fire rate, and fills 30% of Pressure Meter |
| **Duration** | 10 sec active effect |
| **Cooldown/Cost** | Full Pressure Meter + 1 Enema Charge |
| **VFX** | Cinematic cutaway: giant pipe overhead opens, field floods, enemies washed away in comical waterfall; field surface remains wet for effect duration |
| **SFX** | Epic trumpet swell, tidal roar, comedic splash chorus, exuberant cannon fire during tower rate-up period |
| **Tower synergy** | Wet field surface applies blanket Soaked status to all new spawns for 10 sec |
| **Boss utility** | The intended method for surviving Дерьмодемон phase 3 summon overload |
| **Mobile UX** | Locked behind dual-cost to signal rarity; animated lock icon shows Enema Charge count; confirm dialog ("RELEASE THE APOCALYPSE?") with 1-sec auto-confirm to prevent accidental use |

---

## 5. Tower System

### 5.1 Overview

Ten altar slots ring the play field in a U-shape (sides and top). Four slots are active at game start; remaining six unlock via meta progression. The player places towers by dragging from a tower palette, or replaces existing towers by dragging a new tower over an occupied slot.

**Selling:** Tap held tower → radial menu → Sell → returns 60% of total upgrade investment.

**Placement cost:** All towers cost Slime currency. Cost scales per tier. Placement is instant during pre-wave phase; costs +30% if placed mid-wave.

### 5.2 The Three Schools

| School | Theme | Damage Type | Primary Role |
|---|---|---|---|
| **Red** | Heat / Boiling / Welding | Thermal — burn, fire, lava | Direct damage, DoT, armor melting |
| **Blue** | Cold / Chlorine / Sterile Freeze | Cryo — frost, ice, chemical cold | Slow, freeze proc, chain chill |
| **Green** | Mold / Poison / Parasites | Biological — rot, corrosion, worms | DoT stacking, debuff aura, summons |

### 5.3 Four Tiers Per School

Tiers 1–2 are linear upgrades. Tier 3 branches into two specializations. Tier 4 is the endpoint of each branch.

#### Red School

| Tier | Name | Description |
|---|---|---|
| 1 | Ember Pipe | Basic flame thrower. Short range, moderate DPS, no armor pierce. Tag: HEAT |
| 2 | Boiler Cannon | Longer range, fires superheated steam. Applies **Burn** (DoT, 3 sec). Tag: HEAT, BURN |
| 3A | Lava Spigot | Drops lava puddle on kill — puddle damages all enemies crossing it for 5 sec. Tag: HEAT, BURN, LAVA |
| 3B | Welding Torch | Piercing beam that cuts through lines of enemies; armor pierce 70%. Tag: HEAT, PIERCE |
| 4A | Magma Font | Lava puddles merge and persist for 10 sec; puddle pulses expanding burning splash every 2 sec. Tag: HEAT, BURN, LAVA, AOE |
| 4B | Plasma Cutter | Beam gains ricochet (bounces to nearest enemy once); applies **Melt** (armor reduction 40% for 5 sec). Tag: HEAT, PIERCE, MELT |

#### Blue School

| Tier | Name | Description |
|---|---|---|
| 1 | Chill Pipe | Short-range cold spray. Slow 20% per hit, no freeze proc. Tag: COLD |
| 2 | Chlorine Cannon | Longer range, applies **Corrode** (reduces defense 15%); slow 35%. Tag: COLD, CORRODE |
| 3A | Freeze Condenser | Slow stacks apply faster; at 3 stacks: target Frozen (immobile 2 sec). Tag: COLD, FREEZE |
| 3B | Cryo Spray | Short-range cone that applies **Brittle** (next physical hit deals +60% damage). Tag: COLD, BRITTLE |
| 4A | Absolute Zero Core | Frozen enemies who die explode in a **Chain Chill** burst (cold wave to nearby enemies, 2-tile radius). Tag: COLD, FREEZE, CHAIN |
| 4B | Sterile Shard Launcher | Fires crystalline shards: each shard applies Brittle; 3 shards on one target trigger **Shatter** (instant burst damage equal to 30% max HP). Tag: COLD, BRITTLE, SHATTER |

#### Green School

| Tier | Name | Description |
|---|---|---|
| 1 | Mold Vent | Puffs spores. Applies **Mold** (light DoT, 4 sec). Tag: MOLD |
| 2 | Poison Sprinkler | Faster spore rate, Mold DoT increases, applies **Slick** (10% slow). Tag: MOLD, POISON |
| 3A | Corrosion Aura | Passive aura — enemies within radius constantly lose armor (2% per sec, max 40%). Tag: MOLD, POISON, CORRODE |
| 3B | Worm Launcher | On kill: launches a worm projectile to nearest live enemy, applies Mold + stagger. Tag: MOLD, WORM |
| 4A | Plague Nexus | Corrosion Aura doubles; enemies that die while Corroded release a **Plague Cloud** (AoE Mold to nearby enemies). Tag: MOLD, POISON, CORRODE, AOE |
| 4B | Parasite Cannon | Each worm can transfer once on kill; infested targets take ×1.5 damage from all sources; max 3 worms active per cannon. Tag: MOLD, WORM, INFEST |

### 5.4 Elemental Tag Synergy Rules

| Combo | Tags Required | Reaction | Notes |
|---|---|---|---|
| Scalded | HEAT + MOLD on same target | Burns out the mold, deals burst DoT = (Mold DoT remaining × 3) | Destroys Mold stack |
| Toxic Steam | HEAT + COLD on same target | Creates **Steam Cloud** AoE (3-tile radius, applies BURN + CORRODE to enemies in cloud) | Cloud lasts 3 sec |
| Bio-Freeze | COLD + MOLD on same target | Target Frozen + Mold DoT paused; on Freeze expiry, Mold DoT resumes at ×2 rate | Mold stack preserved |
| Stench Ignition | GAS (Stench) + HEAT | Stench-tagged enemies explode in a small fire burst when first hit by HEAT | One-time per Stench application |
| Stench Chill | GAS (Stench) + COLD | Stench-tagged enemies receive ×1.5 slow intensity from all COLD sources | Persists until Stench expires |
| Wet Ignition | SOAKED + HEAT | Soaked enemies become Steamed: takes Heat DoT; COLD attacks ignored for duration | Steam overrides Cold |
| Parasite Feast | WORM + MOLD | Infested enemies spread Mold to adjacent enemies via worm transfer | Triggers on worm transfer events |

### 5.5 Tower Cost Curve

| Tier | Base Slime Cost | Upgrade from Previous |
|---|---|---|
| Tier 1 | 80 | — |
| Tier 2 | 180 (total) | +100 |
| Tier 3 (either branch) | 380 (total) | +200 |
| Tier 4 (either branch) | 700 (total) | +320 |

*Tuning knob: `tower_cost_multiplier` per level (float, default 1.0). Boss chapter levels use 0.85 to compensate for longer session costs.*

---

## 6. Enemy Roster

### 6.1 Priority Logic Global Rules

1. **Closest to Throne wins** — if two enemies are equal in other priority criteria, the closer one gets cannon focus auto-suggest.
2. **Elite marker** — elite variants (wave modifiers) always rank above non-elites.
3. **Threat flag** — Pus and Sanitizer Exorcist are flagged as high-priority regardless of position; tower auto-target weights them heavily.

---

### 6.2 Enemy Entries

#### Virus

| Field | Value |
|---|---|
| **Silhouette** | Small, ovoid with spike protrusions; 2 small legs; reads as "angry germ" |
| **Movement** | Fast straight-line runner; no pathing detours |
| **HP** | Low |
| **Speed** | High (fastest base enemy) |
| **Armor** | None |
| **Role** | Pressure applicant; forces cannon attention away from armored targets |
| **Special gimmick** | Pack spawn — spawns in groups of 5–8; kills from any source grant bonus pressure |
| **Death VFX** | Small pop-splat, green mist puff, micro-debris scatter |
| **Priority logic** | High if group is within 40% of Throne; medium otherwise |

#### Bacteria

| Field | Value |
|---|---|
| **Silhouette** | Fat bulbous body, short stubby limbs, visible nucleus bump; reads as "armored tank" |
| **Movement** | Slow, steadfast, pushes through stagger |
| **HP** | High |
| **Speed** | Low |
| **Armor** | High — reduces all damage by 45% |
| **Role** | Absorber; soaks cannon fire while other enemies advance |
| **Special gimmick** | On death: drops a small **Nutrient Glob** collectible that heals nearby enemies by 15% of max HP if not collected by player |
| **Death VFX** | Large wet explosion, yellow-white nucleus burst, puddle residue |
| **Priority logic** | Low distance priority unless armor stripped; high priority when stripped (cannon auto-suggest) |

#### Worm

| Field | Value |
|---|---|
| **Silhouette** | Long segmented worm, visible burrowing dust particles; segments animate independently |
| **Movement** | Moves in one lane, then burrows (disappears underground), surfaces in a different lane after 2 sec |
| **HP** | Medium |
| **Speed** | Medium |
| **Armor** | None |
| **Role** | Lane disruptor; forces players to track across the field |
| **Special gimmick** | Immune to ground-target towers while burrowed; flyer-target towers can still hit burrowed worm |
| **Death VFX** | Segment-by-segment deflation, dirt explosion at burrow point |
| **Priority logic** | Medium; elevated when approaching Throne side of field |

#### Slime

| Field | Value |
|---|---|
| **Silhouette** | Blob with single visible eye; semi-transparent body |
| **Movement** | Medium speed, direct path |
| **HP** | Medium |
| **Speed** | Medium |
| **Armor** | None |
| **Role** | Resource and chaos doubler |
| **Special gimmick** | On death: splits into 2 **Mini-Slimes** (25% HP each, same behavior, no further splits). Mini-Slimes each drop Slime currency on death |
| **Death VFX** | Wet rupture, two smaller blobs emerge from split animation, currency sparkle on mini-slime death |
| **Priority logic** | Low overall; elevated when Slime count on field exceeds 6 (to prevent multiplicative spawn overload) |

#### Pus

| Field | Value |
|---|---|
| **Silhouette** | Yellow-white blob, distended spit-gland visible on "face," constant drool |
| **Movement** | Slow; frequently stops to spit |
| **HP** | Medium-Low |
| **Speed** | Low |
| **Armor** | None |
| **Role** | Tower debuffer; soft-disables towers if ignored |
| **Special gimmick** | Ranged spit attack targeting nearest tower — applies **Gunk** (reduces tower fire rate by 40% for 6 sec). Towers with Gunk have visible slime overlay |
| **Death VFX** | Pressurized burst, large spit-spray, Gunk residue radius |
| **Priority logic** | High — always flagged as threat; cannon auto-suggest when Pus has line of sight to any tower |

#### Spore

| Field | Value |
|---|---|
| **Silhouette** | Floating spore pod; pulsing membrane; no legs; visible spore cloud around body |
| **Movement** | Flies in straight line, ignores ground-based obstacles and lane walls |
| **HP** | Low-Medium |
| **Speed** | Medium |
| **Armor** | None |
| **Role** | Forces flyer-capable towers to be present; punishes ground-only setups |
| **Special gimmick** | On reaching Throne: explodes dealing AoE to Throne and releasing a **Spore Cloud** (applies Mold to nearby towers) |
| **Death VFX** | Membrane rupture, rainbow-sickly spore scatter, cloud dissipation |
| **Priority logic** | Medium-high; elevated when no flyer-capable towers are in range of its path |

#### Carrier Parasite

| Field | Value |
|---|---|
| **Silhouette** | Crab-like, carrying a glowing resource pack on its back; reads as "delivery enemy" |
| **Movement** | Medium speed; avoids direct cannon fire (slight pathfinding drift) |
| **HP** | Medium |
| **Speed** | Medium |
| **Armor** | Light (15%) |
| **Role** | Resource denial target; optional chase for bonus economy |
| **Special gimmick** | Carries a **Resource Pickup** (Slime bundle, Crystal shard, or special material) — on kill by player cannon, pickup drops and is collected. On kill by tower, pickup is destroyed |
| **Death VFX** | Pack explosion, resource particles fly outward with collection arc to player |
| **Priority logic** | Low default; elevated by player tapping on the Carrier manually |

#### Sanitizer Exorcist

| Field | Value |
|---|---|
| **Silhouette** | Humanoid-ish with a large spray bottle body; bleach-white with orange accents; toxic-clean aesthetic |
| **Movement** | Medium speed; actively pathfinds toward active summons or debuffed targets |
| **HP** | Medium-High |
| **Speed** | Medium |
| **Armor** | Medium (30%) |
| **Role** | Counter-summon; meta-disruptor |
| **Special gimmick** | Periodic **Sanitize** spray: dispels all active player summons (Helminths worms) in a radius and removes all debuffs (Mold, Burn, Corrode) from allies within range. Spray has a visible 1.5 sec wind-up |
| **Death VFX** | Chemical explosion, bleach-white burst, green Mold particles returning to nearby enemies |
| **Priority logic** | High — always threat-flagged; priority spike when the Sanitize wind-up animation is detected |

---

## 7. Boss Encounter Design

### 7.1 Boss Design Rules

- All bosses have 2–3 distinct phases, separated by health thresholds.
- Each phase transition triggers a brief cinematic interrupt (0.5 sec slow-mo + sound sting).
- Bosses do NOT reward Pressure Meter from hits; only from phase-transition kill of a segment/summon.
- Each boss has one **Punish Window** — a period of vulnerability that rewards aggressive play.
- Intro: 2-second comedic entry animation before boss becomes targetable.
- Finisher: Custom death animation on final HP depletion.

---

### 7.2 Засор (The Blockage)

| Field | Value |
|---|---|
| **Chapter** | 1 — Канализация (Sewers) |
| **Visual concept** | Massive congealed clog of hair, grease, and miscellaneous refuse; shaped vaguely like an angry toad |
| **HP pool** | 3 phases (100% / 70% / 40%) |
| **Lane gimmick** | Occupies center lane entirely; forces players to rely on side towers |
| **Phase 1** | Slow advance, periodic **Grease Spit** (applies Slick to random towers: -20% fire rate) |
| **Phase 2** | Splits into 3 **Mini-Clogs** (33% HP each); Mini-Clogs advance down all 3 lanes simultaneously |
| **Phase 3** | Mini-Clogs reform into a leaner, faster Blockage variant; gains charge attack (dashes 5 tiles toward Throne) |
| **Punish window** | During Mini-Clog reform animation (1.5 sec): boss is stationary and takes ×2 damage from all sources |
| **Intro VFX** | Pipe burst from top; clog forces its way through with suction sound |
| **Finisher VFX** | Boss dissolves with industrial drain gurgle; currency coins spiral out |
| **Reward** | Sewers material ×3, Slime ×150, first unlock of Blue Tower Tier 1 |

---

### 7.3 Цепень (The Tapeworm)

| Field | Value |
|---|---|
| **Chapter** | 2 — Общественный туалет (Public Restroom) |
| **Visual concept** | Long segmented tapeworm filling multiple lanes; each segment is independently targetable |
| **HP pool** | 12 segments × individual HP; head segment has ×2 HP |
| **Lane gimmick** | Body writhes across multiple lanes simultaneously; tail covers one lane, body covers another, head advances in center |
| **Phase 1** | Head advances while body segments block tower fire on crossed lanes |
| **Phase 2** | (at 8 segments remaining) Head detaches and becomes an independent fast-mover while body segments gain a **Regenerate** buff (heal 2% HP/sec) |
| **Phase 3** | (at 4 segments remaining) Surviving segments merge; head grows spines (+50% armor) |
| **Punish window** | When segment HP drops to 1: segment flashes white; next hit is a guaranteed kill regardless of armor |
| **Intro VFX** | Wriggles in from top of screen through multiple pipes simultaneously |
| **Finisher VFX** | Head death: giant splat; segments writhe separately and individually pop |
| **Reward** | Restroom material ×3, Slime ×200, Helminths ultimate unlock |

---

### 7.4 Крыса (The Rat)

| Field | Value |
|---|---|
| **Chapter** | 3 — Больничная сантехника (Hospital Plumbing) |
| **Visual concept** | Massive sewer rat in tattered hospital gown; carries gnawed pipe as a weapon |
| **HP pool** | Single large pool, 2 phases |
| **Lane gimmick** | Jumps between tower altar slots (not lanes) — physically lands on a slot, gnawing the tower: disabling it for 3 sec per visit |
| **Phase 1** | Rat attacks from side slots; jumps on-screen every 20 sec; meantime, normal wave continues |
| **Phase 2** | (at 50% HP) Rat gains **Hospital Armor** (bandage wrap visual, +60% armor); begins jumping every 10 sec; also gnaws a second tower on each visit |
| **Punish window** | After gnawing a tower: Rat pauses for 2 sec (visible satisfied animation) — takes ×3 damage during this pause |
| **Intro VFX** | Drops from ceiling (top-center), lands in dust cloud, chittering sound |
| **Finisher VFX** | Rat stumbles comically, hospital gown unravels, falls flat, X-eyes |
| **Reward** | Hospital material ×3, Slime ×250, 5th altar slot unlock |

---

### 7.5 Змея (The Snake)

| Field | Value |
|---|---|
| **Chapter** | 4 — Биолаборатория (Bio Lab) |
| **Visual concept** | Lab experiment snake — mutated with visible syringes embedded in scales; glowing venom sacs |
| **HP pool** | 3 phases |
| **Lane gimmick** | **Lane Controller** — at start, Snake bodies up all 3 lanes; periodically **blocks** one lane with its coiled body (enemies in that lane get speed boost from slipstream) |
| **Phase 1** | Snake coils around left lane: left-side towers fire through its body (reduced damage); right lane enemies advance freely |
| **Phase 2** | Snake shifts to block center lane; **Venom Spit** projectile targets a random tower (applies Gunk for 8 sec) |
| **Phase 3** | Snake uncoils fully, becomes a direct-path boss advancing toward Throne; scales gain Burn immunity (neutralizes Red towers) |
| **Punish window** | When Snake transitions between lanes (1 sec movement window): all attacks against it deal ×2 damage and ignore armor |
| **Intro VFX** | Slithers in from left edge, wraps dramatically, hiss-rattle sound |
| **Finisher VFX** | Snake rears up dramatically, then deflates like a punctured toy |
| **Reward** | Lab material ×3, Slime ×300, Green Tower Tier 3A or 3B unlock choice |

---

### 7.6 Смытая рыбка-мутант (The Flushed Fish Mutant)

| Field | Value |
|---|---|
| **Chapter** | 5 — Мутантный коллектор (Mutant Collector) |
| **Visual concept** | Toilet bowl goldfish, now the size of a car; mutated fins, toilet-water sheen, googly eyes |
| **HP pool** | 3 phases |
| **Lane gimmick** | **Wave attacks** — Fish flops its tail, sending a physical wave down a lane (AoE knockback to towers briefly); dash charges across lanes |
| **Phase 1** | Fish swims figure-eight across the top of the field; periodically dashes down a random lane (deals damage to Throne on pass-through) |
| **Phase 2** | (at 60% HP) Fish spawns 3 small **Mutant Guppies** (Virus-tier HP, fast); begins **Belly Flop** AoE (chooses a lane, warns for 1.5 sec, then deals heavy damage in that lane's top half) |
| **Phase 3** | (at 30% HP) Fish loses googly eye (comedic injury), becomes enraged: dash cooldown halved, wave attacks every 4 sec |
| **Punish window** | Immediately after a Belly Flop (Fish is flopped and stunned for 2 sec) |
| **Intro VFX** | Flushes in from the top-center pipe with a torrent of water; lands flopping |
| **Finisher VFX** | Explodes into fish-slurry confetti, a tiny toilet-bowl "flush" complete sound |
| **Reward** | Collector material ×3, Slime ×350, Enema Charge introduction cutscene + unlock |

---

### 7.7 Дерьмодемон (The Shit Demon)

| Field | Value |
|---|---|
| **Chapter** | 6 — Инфернальный слив (Infernal Drain) |
| **Visual concept** | Towering infernal entity composed of compressed biological waste; crown of bones; glowing lava eyes; wings made of bent pipe |
| **HP pool** | 4 phases (100% / 75% / 50% / 25%) |
| **Lane gimmick** | **Field domination** — occupies a different section of the field each phase; wave enemies change each phase |
| **Phase 1** | Demon hovers at top of field; **Lava Gaze** (sweeping HEAT attack across top tiles, disabling towers hit for 2 sec); standard wave continues |
| **Phase 2** | (at 75%) Demon drops to mid-field; begins summoning **Bacteria Cultists** (Bacteria variant with +50% HP); **Flame Aura** (towers in a radius take tick damage) |
| **Phase 3** | (at 50%) Demon gains **Infernal Shell** (temporary full armor immunity for 15 sec per phase); environment lights change (red tint); begins **Summon Rush** (continuous wave of Virus + Worm pairs) |
| **Phase 4** | (at 25%) Shell breaks (punish window); Demon becomes frantic: all previous attacks plus **Void Slam** (telegraphed AoE on Throne base — Throne takes 20 damage regardless of defense if not countered by Смыв/Клизма) |
| **Punish window** | Infernal Shell breaks: Demon takes full damage from all sources for 8 sec. Shell break requires sustained fire from 3+ different element types simultaneously |
| **Intro VFX** | Infernal portal tears open at field top; Demon emerges with screen-wide fire burst; comedic beat: Demon cracks knuckles and adjusts crown |
| **Finisher VFX** | Full-screen cutscene: Demon screams, implodes, becomes a very normal turd on a small pile; toilet flush; fade to results |
| **Reward** | Infernal material ×5, Crystal ×20, credits roll, New Game+ unlock |

---

## 8. Campaign Structure

### 8.1 Chapter Overview

| # | Name (RU/EN) | Tone | Boss | Session count |
|---|---|---|---|---|
| 1 | Канализация / The Sewers | Gross discovery, introductory | Засор | 5 |
| 2 | Общественный туалет / The Public Restroom | Chaotic, crowded, escalating | Цепень | 6 |
| 3 | Больничная сантехника / Hospital Plumbing | Sterile dread, clinical grotesque | Крыса | 6 |
| 4 | Биолаборатория / The Bio Lab | Mad science, elemental combo tutorial | Змея | 7 |
| 5 | Мутантный коллектор / The Mutant Collector | Weird, surreal, ecological horror | Смытая рыбка | 7 |
| 6 | Инфернальный слив / The Infernal Drain | Epic, infernal, full chaos | Дерьмодемон | 7 |

---

### 8.2 Chapter Detail Sheets

#### Chapter 1 — Канализация (The Sewers)

| Field | Value |
|---|---|
| **Tone** | Damp, foul, claustrophobic. The player's introduction to the world. Played for wonder and disgust in equal measure |
| **Palette** | Muted browns and grays; green sewer water accents; rusted orange piping; a single sickly yellow light source |
| **Enemy pool** | Virus (dominant), Bacteria (heavy), Worm (3rd wave+), Slime (4th wave+) |
| **Boss** | Засор |
| **Environmental hazard** | **Drip Grates** — periodic acid drip zones on random tiles that apply CORRODE to any enemy and tower in contact |
| **Progression unlock** | Tower slots 1–4 active; Red Tier 1 available; Blue Tier 1 unlocked on boss clear |

#### Chapter 2 — Общественный туалет (The Public Restroom)

| Field | Value |
|---|---|
| **Tone** | Overwhelmingly busy. Fluorescent tube flicker. Graffiti walls. Feels like Friday night in the worst public bathroom |
| **Palette** | Dirty white tiles, piss-yellow lighting, graffiti-green accents, grimy chrome |
| **Enemy pool** | All Chapter 1 enemies + Pus, Spore (introduces flyer mechanic) |
| **Boss** | Цепень |
| **Environmental hazard** | **Slippery Floor** — random floor zones become slippery each wave; enemies crossing gain +15% speed, player towers on adjacent altar slots get -10% fire rate |
| **Progression unlock** | 5th altar slot unlocked; Green Tier 1 available |

#### Chapter 3 — Больничная сантехника (Hospital Plumbing)

| Field | Value |
|---|---|
| **Tone** | Unsettlingly clean and gross simultaneously. Sterile white corrupted by biological intrusion |
| **Palette** | Surgical white and stainless steel base; vivid biological intrusions in yellow-green; blood-red emergency lighting in phase 3 |
| **Enemy pool** | Virus, Bacteria, Spore, Carrier Parasite (introduced), Sanitizer Exorcist (introduced) |
| **Boss** | Крыса |
| **Environmental hazard** | **Biohazard Spill** — a spreading Mold puddle appears on the field mid-wave, buffing nearby Mold-tagged enemies (+20% move speed) |
| **Progression unlock** | Red Tier 2, Blue Tier 2; 6th altar slot |

#### Chapter 4 — Биолаборатория (The Bio Lab)

| Field | Value |
|---|---|
| **Tone** | Mad science energy. Bubbling vats, broken containment, experiment labels on enemies |
| **Palette** | Glass and steel; neon green experiment glow; orange emergency strips; UV-blue accent lights |
| **Enemy pool** | All previous + Worm (elite variant with armor), Spore (elite variant, explosive death) |
| **Boss** | Змея |
| **Environmental hazard** | **Containment Breach** — every 2 waves, a random vat on the field ruptures, releasing a status cloud (random: HEAT, COLD, or MOLD) that affects both enemies and towers in range |
| **Progression unlock** | Green Tier 2; Tier 3 branching choice unlocked (first branch decision); 7th altar slot |

#### Chapter 5 — Мутантный коллектор (The Mutant Collector)

| Field | Value |
|---|---|
| **Tone** | Ecological nightmare. Forgotten pipes under an urban wetland. Strange beauty laced with horror |
| **Palette** | Murky teal water, overgrown green-brown, bioluminescent pink accent; surface reflections from water |
| **Enemy pool** | All enemies, including Carrier Parasite (increased frequency) + mutant variants of Bacteria and Slime |
| **Boss** | Смытая рыбка-мутант |
| **Environmental hazard** | **Flood Surge** — a wave of water floods the bottom third of the field every 3 waves (Soaked applied to all enemies there; also slows towers' targeting) |
| **Progression unlock** | Tier 3 second branch choice; Enema Charge mechanic introduced; 8th altar slot |

#### Chapter 6 — Инфернальный слив (The Infernal Drain)

| Field | Value |
|---|---|
| **Tone** | Full epic gross-out horror. The sewers have breached hell itself |
| **Palette** | Infernal red-orange base; bone-white accents; lava cracks in the tile floor; sickly green bile drips from above |
| **Enemy pool** | All enemies + infernal variants (Bacteria Cultists, Infernal Virus); Sanitizer Exorcist appears more frequently as a counter |
| **Boss** | Дерьмодемон |
| **Environmental hazard** | **Infernal Tide** — slow-moving lava wave enters from the top every boss phase transition; towers in its path take tick damage until the wave recedes |
| **Progression unlock** | Tier 4 access; altar slots 9–10; New Game+ (NG+) mode |

---

## 9. Meta Progression System

### 9.1 Overview

Meta progression operates between sessions in the main hub (the Throne Room lobby). All upgrades persist across runs. There is no run-based roguelite reset — Жопокалипсис is a permanent progression TD, not a roguelite.

### 9.2 Currencies

| Currency | Earn sources | Spend targets | Store purchase? |
|---|---|---|---|
| **Slime** (soft) | Wave completion, enemy kills, level stars, daily tasks | Tower placement, upgrades, skill tree nodes | No (earn only) |
| **Crystals** (hard) | IAP, rare drop, level challenges, daily tasks | Speed upgrades, extra lives, cosmetics, one-time big unlocks | Yes (IAP) |
| **Chapter Materials** | Chapter-specific drops, boss rewards | Specific tier unlocks, branch choices in that chapter's tower school | No (earn only) |
| **Enema Charges** | Chapter 5–6 progression, specific challenge completion | Клизма Апокалипсиса ultimate activation | No (earn only) |

### 9.3 Account Level System

**Account XP sources:**
- Level completed (first time): 100 XP
- Each star earned (first time): 25 XP
- Dirty Challenge completed: 50 XP
- Perfect Clear: 75 XP
- Daily task completed: 30 XP

**Account level unlocks:**
| Level | Unlock |
|---|---|
| 1–3 | Tutorial gates clear; first 4 altar slots active |
| 4 | Pressure Meter upgrade node access |
| 5 | 5th altar slot (also requires boss 1 clear) |
| 6 | Red Tower Tier 2 node access |
| 8 | Blue Tower Tier 2 node access |
| 10 | Green Tower Tier 2 node access |
| 12 | Ultimate selection radial unlocked (choose which ultimate to queue) |
| 15 | Tier 3 branching choices available |
| 20 | All 10 altar slots available |
| 25 | Tier 4 nodes available |
| 30 | NG+ mode if Chapter 6 is cleared |

### 9.4 Skill Trees

**Central Tower Skill Tree** (Slime + Crystal cost):
- Throne HP upgrades (×3 nodes, +25 HP each)
- Chunk Burst damage (×3 nodes)
- Auto Diarrhea fire rate (×3 nodes)
- Gas Cone range + duration (×2 nodes each)
- Pressure gain on kill (×2 nodes)
- Pressure meter max overage buffer (×1 node — allows 110% max before auto-release)
- Ultimate cooldown recovery speed (×2 nodes)

**Tower Upgrade Tree** (Chapter Materials + Slime cost):
- Per-school, per-tier upgrade nodes (stat increases within tier)
- Branch unlock nodes at Tier 3 (one choice per school, permanent)
- Synergy amplifier nodes (increase combo reaction damage by 15%)

**Altar Slot Tree** (Account Level + Crystal cost):
- Slots 5–10 unlock as level-gated purchases
- Slot quality upgrades (unlocks "Prime" slots that grant +10% fire rate to tower placed there)

### 9.5 Level Star and Challenge System

**Stars (1–3 per level):**
| Stars | Condition |
|---|---|
| 1 | Complete the level (Throne survives) |
| 2 | Complete with Throne HP above 50% |
| 3 | Complete with Throne HP above 80% |

**Dirty Challenge:**
Each level has one Dirty Challenge — a specific optional condition (examples: "Kill 20 Virus with Automatic Diarrhea only," "Do not use any ultimate," "Clear wave 3 with only Green towers"). Reward: Slime ×100 + Chapter Material ×1.

**Perfect Clear:**
Kill every enemy in a wave without any reaching the Throne, in all waves. Reward: Crystal ×5 + Account XP bonus.

### 9.6 Retention Loop

```
Daily login
    → Daily tasks available (3 tasks per day, Slime rewards)
    → Energy refill notification (if < 3 lives)
    
Play session
    → Earn Slime + Chapter Materials
    → Unlock new tower/skill tree nodes
    → "One more wave" pull from proximity to next level clear / star upgrade
    
Session end
    → Chapter Material → tree unlock → new tower behavior to try
    → Star count → "Almost 3 stars!" replayability pull
    → Account level progress → anticipation of next permanent unlock
    
Weekly
    → Dirty Challenges reset new variants
    → Boss Rush event (post-launch, Sludge Pass)
```

---

## 10. Mobile UX Spec

### 10.1 Layout Zones (Portrait 9:16)

```
┌────────────────────────────────────┐  ← Top safe area (status bar)
│  [Wave indicator] [Lives] [Pause]  │  ← HUD row 1 (top 8%)
│  [Chapter name]  [Pressure Meter]  │  ← HUD row 2 (8–14%)
├────────────────────────────────────┤
│                                    │
│          PLAY FIELD                │  ← 14%–78% of screen height
│  (Altar slots on left/right edge   │
│   and top edge)                    │
│                                    │
├────────────────────────────────────┤
│  [LEFT THUMB ZONE]  [RIGHT THUMB]  │  ← 78%–94% of screen height
│  Ultimate btn +     Aim joystick   │
│  tower palette      + fire ring    │
├────────────────────────────────────┤
│  [Bottom safe area / home bar]     │  ← 94%–100%
└────────────────────────────────────┘
```

### 10.2 Thumb Zone Details

**Right Thumb Zone (aim + fire):**
- Virtual joystick: 120dp radius dead zone center, 60dp max travel
- Tap (< 150ms press): fires Chunk Burst at last aimed direction
- Hold (> 150ms, joystick held): activates Automatic Diarrhea (hold to sustain)
- Swipe up (fast upward gesture > 30dp): fires Gas Cone
- Visual: subtle radial glow behind joystick area; direction indicator arc
- Aim direction shown as a faint trajectory preview line from cannon

**Left Thumb Zone (management + ultimates):**
- Ultimate button: 80dp circle, glows and pulses when Pressure Meter full
  - Tap: fire current selected ultimate
  - Long press (> 400ms): open ultimate radial menu (all 8, tap to select + fire)
- Tower palette: swipe up from left zone to expand 3-tower quick palette
  - Drag tower to altar slot to place
  - Tap occupied altar slot: open tower radial (Upgrade / Sell / Info)
- Pressure Meter: vertical bar, left edge of left zone, always visible

### 10.3 One-Handed Fallback Mode

Accessible from Settings. In fallback mode:
- Right thumb zone expands to 70% of screen width
- Ultimate activates by double-tap in right zone
- Tower placement enters "select + confirm" mode (tap slot → select tower from bottom sheet → confirm)
- Auto-aim assist increases from Light to Heavy in this mode
- Note: designed for temporary one-handed use, not as primary intended mode

### 10.4 Colorblind Indicators

| Element | Default | Colorblind variant |
|---|---|---|
| Health bars | Red | Blue-white gradient |
| Armor indicator | Yellow border | Diamond shape |
| Burn DoT | Orange particles | Orange + triangle icon |
| Freeze | Blue particles | Blue + snowflake icon |
| Mold/Poison | Green particles | Green + circle icon |
| Stench debuff | Yellow-green cloud | Distinct wave pattern |
| Tower school color coding | Red/Blue/Green | All schools gain unique icon overlay (flame / crystal / spiral) |

Settings: Colorblind Mode toggle (enables all indicator variants simultaneously). Off by default.

### 10.5 Feedback Systems

**Hit feedback:**
- Physical: haptic pulse per Chunk Burst hit, short buzz per Auto Diarrhea burst
- Visual: screen micro-shake (0.5dp amplitude) on heavy hits; comic impact panel (KA-SPLAT! etc.) on Chunk Burst hit > 30 damage
- Audio: wet impact SFX timed to frame of contact; pitch-shifted per enemy type

**Ultimate feedback:**
- Haptic: long buzz (300ms) on activation
- Visual: screen desaturation + color flash (unique per ultimate) for 0.3 sec
- Audio: unique activation sting + SFX layer

**Tower level up:**
- Haptic: double pulse
- Visual: star burst from tower, "+TIER" floating text
- Audio: upgrade chime

**Throne damage:**
- Haptic: strong pulse
- Visual: screen red vignette flash (intensity scales with damage %)
- Audio: ceramic crack SFX + throne "oof" vocal

---

## 11. Monetization Spec

### 11.1 Philosophy

The game is designed around the principle that **no game mechanic is paywalled**. All gameplay content (towers, ultimates, chapters, bosses) is earnable through play. Monetization accelerates progression and removes mild friction — it does not create a power ceiling that free players cannot eventually reach.

### 11.2 Energy System

| Parameter | Value |
|---|---|
| Max lives | 5 (expandable to 8 with subscription) |
| Regen rate | 1 life per 30 minutes |
| Cost per attempt | 1 life |
| Free refill | Unlimited for first 3 days of install (retention hook) |
| Full refill purchase | 3 Crystals (hard currency) |
| Rewarded ad refill | Watch 1 ad → +1 life (max 3 times per day) |

### 11.3 IAP Catalog

| Product ID | Type | Price Tier | Description |
|---|---|---|---|
| `crystal_pack_sm` | Consumable | Tier 1 (~$0.99) | 50 Crystals |
| `crystal_pack_md` | Consumable | Tier 3 (~$4.99) | 280 Crystals |
| `crystal_pack_lg` | Consumable | Tier 5 (~$9.99) | 600 Crystals + 50 Slime bonus |
| `crystal_pack_xl` | Consumable | Tier 9 (~$19.99) | 1400 Crystals + 100 Slime bonus |
| `no_ads` | Non-consumable | Tier 4 (~$7.99) | Removes all interstitial ads permanently; rewarded ads remain (optional) |
| `sludge_pass` | Auto-renewing subscription | Tier 3/month (~$4.99) | 8 lives max, daily Crystal allowance (+10/day), exclusive cosmetic throne skin, post-launch live ops access |

*Note: All IAP prices are guidelines subject to Apple/Google pricing tiers. Actual prices set in App Store Connect / Google Play Console. All digital goods must use Apple IAP or Google Play Billing exclusively — no third-party payment processor.*

### 11.4 Ad Placement

| Placement | Type | Trigger | Rules |
|---|---|---|---|
| After defeat screen | Rewarded (optional) | Player taps "Watch ad for +1 life" | Player-initiated only; skip available after 5 sec |
| After level complete screen | Rewarded (optional) | Player taps "Watch ad for ×1.5 currency bonus" | Player-initiated only; separate CTA button |
| After level complete screen | Interstitial (mandatory) | Displayed after result screen closes | Only fires every 3rd non-rewarded session; skippable after 5 sec; **never during gameplay** |
| Natural break (pre-wave) | Rewarded (optional) | Player taps ad banner in pre-wave UI | Appears as optional banner, not interruption |

**Banned ad placements:**
- During a wave (any ad type)
- During boss encounters
- During ultimate activation animations
- At launch / loading screens
- More than 1 interstitial per session

### 11.5 Store Compliance Notes

- `no_ads` IAP described as "remove banner/interstitial ads" — rewarded ads remain explicitly noted as optional and player-initiated (Apple guideline compliance)
- `sludge_pass` subscription: must clearly state auto-renewal terms in purchase UI and in App Store listing. Cancellation policy must be visible.
- No loot boxes: all IAP has clearly disclosed deterministic rewards. No mystery boxes in 1.0.
- Crystal spending is always one-step-removed from real money: player buys Crystals, Crystals buy game items. Requires clear value display (e.g., "This costs 3 Crystals (~$0.06)") — recommended but not currently required by stores.

See `docs/platform/store-compliance.md` for full IAP rules, content policy, and platform requirements.

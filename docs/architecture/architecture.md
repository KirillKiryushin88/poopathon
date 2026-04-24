# Жопокалипсис: Оборона Трона — Master Architecture

---

## Document Status

| Field | Value |
|-------|-------|
| **Version** | 0.1.0 |
| **Status** | Draft — Pre-ADR |
| **Author** | Technical Director (generated) |
| **Created** | 2026-04-24 |
| **Engine** | Godot 4.6 (pinned 2026-02-12) |
| **Source GDDs** | design/gdd/master-gdd.md, design/gdd/game-concept.md |
| **Tech Prefs** | .claude/docs/technical-preferences.md |
| **Next Review** | After all Must-Before-Coding ADRs are Accepted |

This document is the single source of architectural truth for the project. All
stories, ADRs, and sprint plans reference it. Changes require a new version
stamp and a corresponding ADR if they affect API boundaries or layer rules.

---

## Engine Knowledge Gap Summary

The LLM's training data covers Godot through approximately **4.3**. This project
pins **Godot 4.6 (January 2026)** — three full minor versions beyond the
knowledge cutoff. Every agent touching engine APIs MUST consult
`docs/engine-reference/godot/` before suggesting or writing code.

### High-Risk Post-Cutoff Changes (affecting this project)

| Version | Change | Project Impact |
|---------|--------|----------------|
| 4.5 | Dedicated 2D NavigationServer (no longer proxied through 3D) | Enemy pathfinding ADR must target 2D-only server |
| 4.5 | `duplicate_deep()` added; nested Resource duplication changed | LevelConfig/TowerData loading patterns |
| 4.5 | Android 16KB page support required for Play targeting Android 15+ | Export preset configuration |
| 4.5 | Shader Baker eliminates startup hitching | VFX pipeline: bake shaders in CI |
| 4.5 | `@abstract` decorator available | Base class design (EnemyBase, TowerBase) |
| 4.6 | Jolt is now **default** 3D physics (not relevant — project is 2D) | N/A |
| 4.6 | Glow post-process runs **before** tonemapping | Any bloom VFX must be re-tuned |
| 4.6 | D3D12 default on Windows | Editor-only; no runtime impact on Android/iOS |
| 4.6 | Dual-focus UI system (touch vs keyboard focus separated) | HUD/menu focus management |
| 4.4 | `FileAccess.store_*` now returns `bool` (was `void`) | SaveService write verification |
| 4.3 | `TileMap` deprecated → `TileMapLayer` | Any tilemap use must use new node |

### Safe Post-Cutoff Patterns (verified)
- `NavigationAgent2D` — still valid, uses dedicated 2D server in 4.5+
- `GPUParticles2D` — unchanged, preferred over CPUParticles2D for mobile
- `signal.connect(callable)` — correct since 4.0
- `await signal` — correct since 4.0 (not `yield`)
- `PackedScene.instantiate()` — correct (not `instance()`)
- Typed arrays `Array[Type]` — fully supported, compiler-optimized

---

## Architecture Principles

### P1 — Static Typing Everywhere
All GDScript files use `@static_untyped` set to false (the default in 4.6).
Every variable, parameter, and return type is explicitly typed. `var x` is a
build error. This is enforced by the `/story-done` hook and `/architecture-review`.

### P2 — Layer Isolation
Code may only call downward through layers (Presentation → Feature → Core →
Foundation → Platform). No upward calls. Cross-layer communication at the same
level uses `CombatEventBus` (signals only). UI scripts contain zero combat logic.
Monetization calls exist only in Platform and Foundation bridge layers.

### P3 — Resource-Driven Configuration
No magic numbers in game logic. All tunable values — tower stats, enemy stats,
wave configs, upgrade costs, ability costs — live in `.tres` Resource files.
Game logic reads Resources; it never hard-codes values. The `/architecture-review`
checks that no numeric literals appear in Core or Feature layer scripts.

### P4 — Mobile-First Performance Budget
Target: 60 fps on mid-range Android 2021+. Hard limits:
- ≤ 150 draw calls per frame
- ≤ 40 simultaneous enemies
- ≤ 200 active particles (GPUParticles2D preferred)
- ≤ 512 MB RAM
Degradation is tiered: reduce particles → reduce enemy cap → reduce shadow
resolution. VFX is designed for the Mobile renderer first; any effect that
does not look acceptable on Mobile renderer is reworked before being accepted.

### P5 — Explicit Ownership, No Singletons-as-Globals
Autoloads are services with defined interfaces, not global state bags. No
autoload holds a reference to another autoload's nodes. Inter-autoload
communication happens through typed signals only. Every autoload owns exactly
one domain of state; nothing is co-owned.

---

## System Layer Map

```
┌──────────────────────────────────────────────────────────────────────┐
│  PRESENTATION LAYER                                                  │
│  HUD · MainMenu · ResultScreen · MetaScreen · TowerRadialMenu        │
│  (reads state via signals, never writes game state directly)         │
└────────────────────────┬─────────────────────────────────────────────┘
                         │ signals / method calls (downward only)
┌────────────────────────▼─────────────────────────────────────────────┐
│  FEATURE LAYER                                                       │
│  CampaignManager · LevelConfig (Resource) · LevelLoader             │
│  (orchestrates sequences; no direct enemy/tower node manipulation)   │
└────────────────────────┬─────────────────────────────────────────────┘
                         │ signals / method calls (downward only)
┌────────────────────────▼─────────────────────────────────────────────┐
│  CORE LAYER                                                          │
│  CentralTowerController · TowerSystem · UltimateSystem              │
│  EnemySystem · WaveManager · BossController · VFXSystem             │
│  CombatEventBus (signal hub — lateral within Core only)             │
└────────────────────────┬─────────────────────────────────────────────┘
                         │ autoload service calls (downward only)
┌────────────────────────▼─────────────────────────────────────────────┐
│  FOUNDATION LAYER (Autoloads)                                        │
│  GameSession · MetaProgression · EconomyService · SaveService        │
│  PlatformBridge · AudioRouter · SceneManager                        │
│  (stateful services; communicate only via typed signals)             │
└────────────────────────┬─────────────────────────────────────────────┘
                         │ native bridge calls (downward only)
┌────────────────────────▼─────────────────────────────────────────────┐
│  PLATFORM LAYER                                                      │
│  AdsBridge (stub) · BillingBridge (stub)                            │
│  OS/hardware abstraction (screen size, orientation, audio focus)    │
│  (GDExtension or pure-GDScript stubs; no game logic here)           │
└──────────────────────────────────────────────────────────────────────┘
```

**Lateral communication rule:** Within the Core Layer, systems communicate
through `CombatEventBus` signals only. `WaveManager` does not hold a reference
to `EnemySystem`; it listens to `CombatEventBus.enemy_died`. This keeps all
Core systems independently testable.

---

## Module Ownership Map

| Module | Owns | Exposes | Consumes | Engine APIs |
|--------|------|---------|----------|-------------|
| **GameSession** (autoload) | `current_level`, `wave_number`, `pressure` float, `LevelResult` | `level_started`, `level_ended`, `pressure_changed` signals | LevelConfig resource | Node — autoload |
| **MetaProgression** (autoload) | Account level, chapter unlock state, upgrade tree state, NG+ flag | `progression_changed` signal, `get_upgrade_level(id)` | SaveService (serialization) | Resource, Dictionary |
| **EconomyService** (autoload) | Soft currency (Slime), Hard currency (Crystals), Chapter Materials, Enema Charges | `balance_changed` signal, `add_soft`, `spend_soft`, `add_hard`, `spend_hard` | SaveService (serialization) | — |
| **SaveService** (autoload) | File I/O, serialization format, save slot management | `save_completed`, `load_completed` signals, `save_game`, `load_game`, `has_save` | GameSession, MetaProgression, EconomyService (pull data via signals) | FileAccess (use `store_*` return bool — 4.4+) |
| **PlatformBridge** (autoload) | AdsBridge ref, BillingBridge ref, OS abstraction | `ad_ready`, rewarded/interstitial results, purchase results | AdsBridge, BillingBridge (Platform Layer) | OS, DisplayServer |
| **AudioRouter** (autoload) | AudioBus config, SFX pool, music stack | `play_sfx(id)`, `play_music(id)`, `set_bus_volume` | AudioStreamPlayer nodes | AudioServer, AudioStreamPlayer |
| **SceneManager** (autoload) | Scene stack, transition state | `change_scene(path)`, `push_scene(path)`, `pop_scene()` | — | SceneTree, ResourceLoader |
| **CentralTowerController** | Touch input routing, aim direction, fire mode state (Burst/Auto/Cone) | `fire_requested(direction, mode)`, `aim_changed(direction)` | InputRouter (Godot Input singleton) | Input, Node2D |
| **TowerSystem** | Tower slot state, tower nodes, upgrade state | `place_tower`, `upgrade_tower`, `sell_tower`; `tower_placed`, `tower_sold` signals | TowerData resources, EconomyService | Node2D, Area2D |
| **UltimateSystem** | Ultimate ability state, cooldowns, Enema Charge count | `activate_ultimate(id)`, `ultimate_ready` signal | GameSession (pressure), EconomyService (Enema Charge) | — |
| **EnemySystem** | Active enemy pool, enemy state machines | `enemy_died(enemy, pos)`, `enemy_reached_throne(enemy)` via CombatEventBus | EnemyData resources, NavigationAgent2D | NavigationAgent2D, NavigationServer2D (4.5+ dedicated) |
| **WaveManager** | Wave sequence, spawn timing, fast-forward state | `start_wave`, `fast_forward`; `wave_started`, `wave_completed`, `all_waves_completed` | WaveConfig resources, CombatEventBus | Timer, SceneTree |
| **BossController** | Boss state machines, phase transitions, lane gimmicks | `boss_phase_changed`, `boss_died` via CombatEventBus | BossData resources, EnemySystem | AnimationPlayer, AnimationMixer (4.3+) |
| **VFXSystem** | VFX pool, particle budget tracking, screen-space effects | `play_vfx(id, position)`, `play_ultimate_vfx(id)` | GPUParticles2D, Shader baker output | GPUParticles2D, Compositor/CompositorEffect (glow — 4.3+) |
| **CombatEventBus** | Signal definitions only (no state) | All combat signals: `enemy_died`, `enemy_reached_throne`, `tower_fired`, `damage_dealt`, `boss_phase_changed`, `element_tag_applied` | — | — |
| **CampaignManager** | Chapter/level sequence, level unlock state | `level_completed`, `chapter_completed` signals; `get_next_level()` | MetaProgression, LevelConfig resources | — |
| **LevelConfig** (Resource) | All per-level data: wave list, path curves, tower slots, background, music | Exported properties, `.tres` file | WaveConfig, EnemyData resources | Resource |
| **LevelLoader** | Scene instantiation for a level, wiring systems together | `load_level(config: LevelConfig)`, `level_ready` signal | LevelConfig, SceneManager | ResourceLoader, PackedScene.instantiate() |
| **HUD** | Display only: health, pressure meter, currency, wave counter, ultimate button | Touch events → CentralTowerController, UltimateSystem | GameSession signals, EconomyService.balance_changed | Control, TouchScreenButton |
| **MainMenu** | Menu navigation, settings entry | — | SceneManager | Control |
| **ResultScreen** | End-of-level result display, reward summary | — | GameSession.level_ended, EconomyService.balance_changed | Control |
| **MetaScreen** | Tower shop, upgrade tree, chapter select | — | MetaProgression, EconomyService | Control |
| **TowerRadialMenu** | Tower placement/sell/upgrade radial UI | Tower slot selection → TowerSystem | TowerSystem signals | Control, Popup |
| **AdsBridge** (stub) | Ad mediation abstraction | `show_rewarded`, `show_interstitial`; `rewarded_completed`, `ad_failed` signals | — | GDExtension (native) or stub .gd |
| **BillingBridge** (stub) | IAP abstraction | `purchase`, `restore_purchases`; `purchase_completed`, `purchase_failed` signals | — | GDExtension (native) or stub .gd |

---

## Data Flow

### Frame Update Path (ASCII)

```
_physics_process(delta)
        │
        ├─► CentralTowerController._physics_process(delta)
        │       └─► reads Input (touch joystick delta)
        │       └─► emits aim_changed(direction: Vector2)
        │       └─► emits fire_requested(dir, mode) when fire condition met
        │
        ├─► EnemySystem._physics_process(delta)
        │       └─► for each active enemy:
        │               └─► NavigationAgent2D.get_next_path_position()
        │               └─► move_and_collide() / velocity update
        │               └─► check throne collision → CombatEventBus.enemy_reached_throne
        │
        ├─► WaveManager._process(delta)
        │       └─► spawn timer tick → EnemySystem.spawn_enemy(type, path)
        │       └─► listens CombatEventBus.enemy_died → decrement alive count
        │               └─► if alive == 0: emit wave_completed
        │
        ├─► TowerSystem._process(delta)  [each TowerBase]
        │       └─► attack timer tick → scan for targets in range (Area2D overlap)
        │       └─► select target by priority (nearest throne-distance)
        │       └─► call target.take_damage(amount, type)
        │               └─► CombatEventBus.damage_dealt(target, amount, type)
        │               └─► CombatEventBus.element_tag_applied(target, tag) if applicable
        │
        └─► VFXSystem._process(delta)
                └─► update active particle budgets
                └─► release expired pooled VFX nodes
```

### Signal/Event Path

```
Player touch (right joystick drag)
    → InputRouter (Godot Input)
    → CentralTowerController.aim_changed(direction: Vector2)
        → HUD._on_aim_changed()  [visual crosshair update]
    → CentralTowerController.fire_requested(direction, mode)
        → TowerSystem handles if mode is tower auto-fire coordination
        → CombatEventBus.tower_fired(tower_id, target, damage_type)

Enemy dies:
    EnemyBase.take_damage() → hp <= 0
    → EnemyBase.died(enemy, position) [instance signal]
    → EnemySystem._on_enemy_died(enemy, position)
    → CombatEventBus.enemy_died(enemy, position)
        → WaveManager._on_enemy_died()  [decrement alive counter]
        → EconomyService._on_enemy_died()  [add soft currency drop]
        → GameSession._on_enemy_died()  [update pressure meter +5]
        → VFXSystem._on_enemy_died(position)  [play death VFX]
        → MetaProgression._on_enemy_died()  [kill counter for quests]

Pressure meter fills to 100:
    GameSession.pressure >= 100.0
    → GameSession.pressure_maxed signal
    → UltimateSystem._on_pressure_maxed()
        → UltimateSystem.ultimate_ready signal
        → HUD._on_ultimate_ready()  [enable ultimate button glow]

Ultimate activated (player taps ultimate button):
    HUD._on_ultimate_button_pressed()
    → UltimateSystem.activate_ultimate(selected_id)
        → validates pressure >= 100 AND (if Клизма) enema_charge >= 1
        → EconomyService.spend_enema_charge(1)  [if Клизма]
        → GameSession.pressure = 0
        → CombatEventBus.ultimate_activated(id)
            → EnemySystem._on_ultimate(id)  [apply area effect]
            → VFXSystem.play_ultimate_vfx(id)
            → AudioRouter.play_sfx(ultimate_sfx_id)

Level ends:
    WaveManager.all_waves_completed
    → CampaignManager._on_all_waves_completed()
        → GameSession.emit level_ended(result: LevelResult)
            → EconomyService.add_soft(drop_total)
            → MetaProgression.record_level_complete(level_id, stars)
            → SaveService.save_game()
            → SceneManager.change_scene("res://scenes/ui/ResultScreen.tscn")
```

### Save/Load Path

```
SAVE:
SaveService.save_game()
    ├─► GameSession.get_save_data() → Dictionary
    ├─► MetaProgression.get_save_data() → Dictionary
    ├─► EconomyService.get_save_data() → Dictionary
    ├─► merge into single save Dictionary
    ├─► JSON.stringify() or custom serializer (ADR-005 decision pending)
    └─► FileAccess.open(save_path, WRITE)
            └─► store_string(serialized)  [check return bool — 4.4+ change]
            └─► close()
    → emit save_completed()

LOAD:
SaveService.load_game()
    ├─► FileAccess.open(save_path, READ)
    ├─► get_as_text() → raw string
    ├─► deserialize → Dictionary
    ├─► GameSession.apply_save_data(data["session"])
    ├─► MetaProgression.apply_save_data(data["meta"])
    └─► EconomyService.apply_save_data(data["economy"])
    → emit load_completed(save_data)
```

### Initialization Order

Autoloads initialize in declaration order (project.godot `[autoload]` section).
The required order is:

```
1. PlatformBridge      — OS/display info available first; AdsBridge/BillingBridge init
2. AudioRouter         — audio bus config; no game dependencies
3. EconomyService      — no dependencies on other autoloads
4. MetaProgression     — no dependencies on other autoloads
5. GameSession         — may read MetaProgression for NG+ state check
6. SaveService         — all data owners (steps 3-5) must exist before load
7. SceneManager        — scene tree operations; must be last foundational service
```

Rule: no autoload may call methods on another autoload during `_ready()`.
Post-init wiring uses `call_deferred("_post_init")` or signal connections only.
`SaveService._ready()` calls `load_game()` via `call_deferred` to ensure all
autoloads have completed their own `_ready()` first.

---

## API Boundaries

GDScript typed pseudocode for all key interfaces. Implementations must match
these signatures exactly. Deviations require an ADR amendment.

```gdscript
# ─────────────────────────────────────────────
# FOUNDATION LAYER — Autoloads
# ─────────────────────────────────────────────

class_name GameSession
extends Node

var current_level: LevelConfig
var wave_number: int
var pressure: float  # 0.0–100.0

signal level_started(config: LevelConfig)
signal level_ended(result: LevelResult)
signal pressure_changed(new_value: float)
signal pressure_maxed()

func get_save_data() -> Dictionary: pass
func apply_save_data(data: Dictionary) -> void: pass


# ─────────────────────────────────────────────
class_name MetaProgression
extends Node

signal progression_changed()

func get_upgrade_level(upgrade_id: String) -> int: pass
func record_level_complete(level_id: String, stars: int) -> void: pass
func is_chapter_unlocked(chapter_id: int) -> bool: pass
func get_account_level() -> int: pass
func get_save_data() -> Dictionary: pass
func apply_save_data(data: Dictionary) -> void: pass


# ─────────────────────────────────────────────
class_name EconomyService
extends Node

signal balance_changed(soft: int, hard: int, chapter_mat: int, enema_charges: int)

func add_soft(amount: int) -> void: pass
func spend_soft(amount: int) -> bool: pass  # false if insufficient
func add_hard(amount: int) -> void: pass
func spend_hard(amount: int) -> bool: pass  # false if insufficient
func add_chapter_material(chapter_id: int, amount: int) -> void: pass
func spend_chapter_material(chapter_id: int, amount: int) -> bool: pass
func add_enema_charge(amount: int) -> void: pass
func spend_enema_charge(amount: int) -> bool: pass
func get_soft() -> int: pass
func get_hard() -> int: pass
func get_save_data() -> Dictionary: pass
func apply_save_data(data: Dictionary) -> void: pass


# ─────────────────────────────────────────────
class_name SaveService
extends Node

signal save_completed()
signal load_completed(save_data: Dictionary)
signal save_failed(error: String)

func save_game() -> void: pass
func load_game() -> void: pass
func has_save() -> bool: pass
func delete_save() -> void: pass


# ─────────────────────────────────────────────
class_name PlatformBridge
extends Node

signal ad_rewarded_completed(placement: String, reward: Dictionary)
signal ad_failed(placement: String, error: String)
signal purchase_completed(product_id: String)
signal purchase_failed(product_id: String, error: String)

func show_rewarded_ad(placement: String) -> void: pass
func show_interstitial_ad(placement: String) -> void: pass
func purchase(product_id: String) -> void: pass
func restore_purchases() -> void: pass
func is_ad_ready(placement: String) -> bool: pass


# ─────────────────────────────────────────────
class_name AudioRouter
extends Node

func play_sfx(sfx_id: String) -> void: pass
func play_music(music_id: String, crossfade: float = 0.5) -> void: pass
func stop_music() -> void: pass
func set_bus_volume(bus_name: String, db: float) -> void: pass
func push_music(music_id: String) -> void: pass  # push/pop for boss themes
func pop_music() -> void: pass


# ─────────────────────────────────────────────
class_name SceneManager
extends Node

signal scene_changed(new_scene_path: String)
signal transition_started()
signal transition_finished()

func change_scene(path: String, transition: StringName = &"fade") -> void: pass
func push_scene(path: String) -> void: pass
func pop_scene() -> void: pass
func get_current_scene_path() -> String: pass


# ─────────────────────────────────────────────
# PLATFORM LAYER — Stubs
# ─────────────────────────────────────────────

class_name AdsBridge
extends Node

signal rewarded_completed(placement: String, reward: Dictionary)
signal ad_failed(placement: String, error: String)
signal interstitial_shown(placement: String)

func show_rewarded(placement: String) -> void: pass
func show_interstitial(placement: String) -> void: pass
func is_initialized() -> bool: pass


# ─────────────────────────────────────────────
class_name BillingBridge
extends Node

signal purchase_completed(product_id: String)
signal purchase_failed(product_id: String, error: String)
signal restore_completed(restored_ids: Array[String])

func purchase(product_id: String) -> void: pass
func restore_purchases() -> void: pass
func is_product_owned(product_id: String) -> bool: pass


# ─────────────────────────────────────────────
# CORE LAYER
# ─────────────────────────────────────────────

class_name CentralTowerController
extends Node2D

signal aim_changed(direction: Vector2)
signal fire_requested(direction: Vector2, mode: FireMode)
signal fire_mode_changed(mode: FireMode)

enum FireMode { BURST, AUTO, CONE }

func get_current_mode() -> FireMode: pass
func set_fire_mode(mode: FireMode) -> void: pass


# ─────────────────────────────────────────────
class_name TowerSystem
extends Node

signal tower_placed(slot_id: int, tower: TowerBase)
signal tower_upgraded(slot_id: int, new_tier: int)
signal tower_sold(slot_id: int, refund: int)

func place_tower(slot_id: int, tower_type: TowerType) -> bool: pass
func upgrade_tower(slot_id: int) -> bool: pass
func sell_tower(slot_id: int) -> int: pass  # returns refund amount
func get_tower_at(slot_id: int) -> TowerBase: pass
func get_available_slots() -> Array[int]: pass


# ─────────────────────────────────────────────
@abstract
class_name TowerBase
extends Node2D

@export var tower_data: TowerData

signal attack_fired(target: EnemyBase, damage: float, damage_type: DamageType)

func get_slot_id() -> int: pass
func get_tier() -> int: pass
func get_sell_value() -> int: pass


# ─────────────────────────────────────────────
class_name UltimateSystem
extends Node

signal ultimate_ready()
signal ultimate_not_ready(reason: String)
signal ultimate_activated(ultimate_id: StringName)

func activate_ultimate(ultimate_id: StringName) -> bool: pass
func get_active_ultimate_id() -> StringName: pass
func can_activate(ultimate_id: StringName) -> bool: pass


# ─────────────────────────────────────────────
class_name WaveManager
extends Node

signal wave_started(wave_number: int)
signal wave_completed(wave_number: int)
signal all_waves_completed()
signal spawn_tick(enemy_type: StringName, spawn_point: Vector2)

func start_wave(wave_config: WaveConfig) -> void: pass
func fast_forward(enabled: bool) -> void: pass
func get_current_wave() -> int: pass
func get_alive_count() -> int: pass


# ─────────────────────────────────────────────
@abstract
class_name EnemyBase
extends CharacterBody2D

@export var enemy_data: EnemyData

var max_hp: float
var current_hp: float
var move_speed: float
var armor: float

signal died(enemy: EnemyBase, position: Vector2)
signal reached_throne(enemy: EnemyBase)
signal hp_changed(new_hp: float, max_hp: float)

func take_damage(amount: float, damage_type: DamageType) -> void: pass
func apply_element_tag(tag: ElementTag) -> void: pass
func get_active_tags() -> Array[ElementTag]: pass


# ─────────────────────────────────────────────
class_name EnemySystem
extends Node

signal enemy_spawned(enemy: EnemyBase)

func spawn_enemy(enemy_type: StringName, spawn_point: Vector2, path_id: int) -> EnemyBase: pass
func get_active_enemies() -> Array[EnemyBase]: pass
func get_enemies_in_radius(center: Vector2, radius: float) -> Array[EnemyBase]: pass
func get_enemy_count() -> int: pass


# ─────────────────────────────────────────────
class_name BossController
extends Node

signal boss_phase_changed(boss_id: StringName, phase: int)
signal boss_died(boss_id: StringName, position: Vector2)
signal boss_intro_finished(boss_id: StringName)

func start_boss_encounter(boss_data: BossData) -> void: pass
func get_current_phase() -> int: pass


# ─────────────────────────────────────────────
class_name VFXSystem
extends Node

func play_vfx(vfx_id: StringName, position: Vector2, parent: Node = null) -> void: pass
func play_ultimate_vfx(ultimate_id: StringName) -> void: pass
func get_active_particle_count() -> int: pass
func set_budget_cap(cap: int) -> void: pass  # runtime degradation hook


# ─────────────────────────────────────────────
class_name CombatEventBus
extends Node
# Signal-only node. No state. No methods. Autoloaded.

signal enemy_died(enemy: EnemyBase, position: Vector2)
signal enemy_reached_throne(enemy: EnemyBase)
signal tower_fired(tower: TowerBase, target: EnemyBase, damage_type: DamageType)
signal damage_dealt(target: EnemyBase, amount: float, damage_type: DamageType)
signal element_tag_applied(target: EnemyBase, tag: ElementTag)
signal element_synergy_triggered(combo: StringName, targets: Array[EnemyBase])
signal ultimate_activated(ultimate_id: StringName)
signal boss_phase_changed(boss_id: StringName, phase: int)
signal boss_died(boss_id: StringName, position: Vector2)


# ─────────────────────────────────────────────
# FEATURE LAYER
# ─────────────────────────────────────────────

class_name CampaignManager
extends Node

signal level_completed(level_id: String, stars: int)
signal chapter_completed(chapter_id: int)

func start_level(level_config: LevelConfig) -> void: pass
func get_next_level() -> LevelConfig: pass
func get_current_chapter() -> int: pass


# ─────────────────────────────────────────────
class_name LevelLoader
extends Node

signal level_ready()
signal level_load_failed(error: String)

func load_level(config: LevelConfig) -> void: pass
func unload_current_level() -> void: pass


# ─────────────────────────────────────────────
# DATA RESOURCES (Resource subclasses — .tres files)
# ─────────────────────────────────────────────

class_name LevelConfig
extends Resource

@export var level_id: String
@export var chapter_id: int
@export var display_name: String
@export var wave_configs: Array[WaveConfig]
@export var enemy_paths: Array[Curve2D]
@export var tower_slots: Array[TowerSlotData]
@export var background_scene: PackedScene
@export var music_id: String
@export var cost_multiplier: float = 1.0  # 0.85 for boss chapters
@export var is_boss_level: bool = false
@export var boss_data: BossData


class_name WaveConfig
extends Resource

@export var wave_index: int
@export var spawns: Array[SpawnEntry]
@export var fast_forward_multiplier: float = 2.0


class_name SpawnEntry
extends Resource

@export var enemy_type: StringName
@export var count: int
@export var spawn_interval: float
@export var path_id: int
@export var delay_from_wave_start: float


class_name EnemyData
extends Resource

@export var enemy_id: StringName
@export var max_hp: float
@export var move_speed: float
@export var armor: float
@export var damage_type: DamageType
@export var soft_drop: int
@export var pressure_grant: float
@export var death_vfx_id: StringName
@export var tags: Array[ElementTag]


class_name TowerData
extends Resource

@export var tower_id: StringName
@export var tower_type: TowerType
@export var tiers: Array[TowerTierData]
@export var base_cost: int
@export var damage_type: DamageType
@export var element_tag: ElementTag


class_name TowerTierData
extends Resource

@export var tier: int
@export var damage: float
@export var attack_speed: float
@export var range: float
@export var upgrade_cost: int
@export var vfx_id: StringName


class_name BossData
extends Resource

@export var boss_id: StringName
@export var phases: Array[BossPhaseData]
@export var intro_vfx_id: StringName
@export var finisher_vfx_id: StringName
@export var reward_chapter_materials: int
```

---

## Required ADRs

ADRs must be authored via `/architecture-decision`. Stories referencing a
system covered by a `Proposed` ADR are blocked until that ADR reaches `Accepted`.

### Must Before Coding (blocks all stories in affected systems)

| # | ADR Title | Blocks |
|---|-----------|--------|
| ADR-001 | Scene management strategy — single-scene vs multi-scene loading, transition system design | SceneManager, LevelLoader, all scene transitions |
| ADR-002 | Autoload initialization order and inter-autoload communication contract | All autoloads, SaveService load-on-startup |
| ADR-003 | Signal bus vs direct signals — CombatEventBus scope and subscription model | All Core systems, HUD subscriptions |
| ADR-004 | Data Resource structure — LevelConfig, TowerData, EnemyData file organization and loading strategy | All data-driven systems |
| ADR-005 | Save format — Dictionary/JSON vs custom binary; slot count; cloud sync stub | SaveService |
| ADR-006 | Mobile renderer VFX constraints — approved effects list, forbidden effects, particle budget enforcement | VFXSystem, all tower/enemy VFX |

### Should Before System Built (blocks stories in that specific system)

| # | ADR Title | Blocks |
|---|-----------|--------|
| ADR-007 | Tower upgrade branching data model — linear tiers vs branching paths; TowerTierData schema | TowerSystem, MetaScreen upgrade UI |
| ADR-008 | Enemy pathfinding approach — NavigationAgent2D with NavigationRegion2D baked paths vs hardcoded Curve2D per level | EnemySystem, LevelConfig path data |
| ADR-009 | Pressure meter persistence — does meter reset between waves? decay rate implementation | GameSession, WaveManager tick interaction |
| ADR-010 | Ad placement policy enforcement — where PlatformBridge.show_*_ad() may legally be called; interstitial cooldown enforcement (3rd non-rewarded session rule) | PlatformBridge, CampaignManager, ResultScreen |
| ADR-011 | Energy system tick rate and storage — if a stamina/energy gate exists for level attempts; integration with EconomyService | EconomyService, CampaignManager |

### Can Defer (does not block pre-production milestones)

| # | ADR Title | Notes |
|---|-----------|-------|
| ADR-012 | Specific IAP product IDs and store configuration | Required before store submission only |
| ADR-013 | Analytics event schema — event names, parameters, provider SDK | Required before soft launch |
| ADR-014 | Localization approach — single locale now; gettext vs Godot CSV; RTL requirements | Required before global launch |

---

## Open Questions

These questions have architectural implications and must be resolved before the
relevant ADR can be written. Unresolved questions block the ADRs listed.

1. **Lane path representation** — Should enemy lane paths be baked
   `NavigationRegion2D` polygons (dynamic, obstacle-aware) or hardcoded
   `Curve2D` per level (simple, deterministic, predictable performance)?
   This is the single biggest decision affecting `EnemySystem` and `LevelConfig`.
   Blocks: ADR-008.

2. **Build variant strategy** — Is `director_build` vs `store_build`
   differentiation handled via Godot export presets (feature tags in
   `OS.has_feature("director")`) or a runtime flag loaded from a config file?
   Affects asset pipeline, stub vs real AdsBridge/BillingBridge loading,
   and CI/CD export job count.
   Blocks: ADR-001 (partially), export pipeline setup.

3. **Android SDK target version** — What is the minimum API level (21? 24?)
   and target API level? Android 15+ requires the 16KB page support added in
   Godot 4.5. This must be confirmed before export preset configuration.
   Blocks: export preset ADR (under ADR-001 or separate).

4. **Tower VFX pooling strategy** — Should projectile and hit VFX be pooled
   (pre-allocated `GPUParticles2D` nodes recycled) or spawned/freed per shot?
   Given the 200-particle and 150-draw-call budgets at 40 enemies, pooling is
   likely required, but the pool size formula needs defining.
   Blocks: ADR-006, VFXSystem implementation.

5. **GUT test runner integration** — Is the GUT test suite run in CI/CD
   (requiring a headless Godot 4.6 runner in the pipeline) or manual-only for
   this project? Affects story acceptance criteria and `/story-done` hook
   validation steps.
   Blocks: testing infrastructure setup (not a gameplay ADR, but a process decision).

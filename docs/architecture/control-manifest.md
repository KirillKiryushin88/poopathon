# Apocabutt: Defense of the Throne — Control Manifest

Generated: 2026-04-24 | Engine: Godot 4.6 | ADRs: 6
Manifest Version: 1.0

> This is the "what", not the "why". See individual ADRs for rationale.
> Stories embed `Manifest Version: 1.0` — run `/story-done` to check for staleness.

---

## How to Use

- Read the layer rules for the system you are implementing.
- Global Rules apply to every `.gd` file in the project — no exceptions.
- Forbidden APIs lists must be checked before any Godot API call.
- VERIFY items require a physical device test before marking a story Done.
- When in doubt: check the source ADR. This manifest is a summary, not a replacement.

---

## Global Rules (apply everywhere)

### GDScript

✅ MUST: Statically type every variable — `var x: int`, `var s: String`, `var node: Node2D`. No bare `var x`.
✅ MUST: Statically type all function parameters and return values — `func foo(a: int) -> void:`.
✅ MUST: Use `@static_untyped` is permanently forbidden. Never add it to any script.
✅ MUST: Use `class_name` for every script that is referenced from another file.
✅ MUST: Name constants `UPPER_SNAKE_CASE`.
✅ MUST: Name variables, functions, parameters `snake_case`.
✅ MUST: Name classes and scene root nodes `PascalCase`.
✅ MUST: Name signals `snake_case` past tense — `enemy_died`, `wave_completed`, `save_failed`.
✅ MUST: Name `.gd` files `snake_case.gd`, scene files `PascalCase.tscn`, data resources `snake_case.tres`.
❌ NEVER: Use bare `var x` — always provide a type annotation.
❌ NEVER: Use string-based signal connections: `connect("signal_name", obj, "method_name")`. Use typed: `signal_name.connect(callable)`.
❌ NEVER: Use untyped arrays: `var arr = []`. Use `var arr: Array[EnemyData] = []`.
❌ NEVER: Hardcode balance values as magic numbers in `.gd` files. All balance values live in `.tres` Resource files.

### Cross-System Communication

✅ MUST: Use signals for all communication between autoloads — no direct method calls across autoloads.
✅ MUST: Connect signals in the **receiving** node's `_ready()`, not the emitter's.
✅ MUST: Emit `initialized` signal at the end of every autoload's `_ready()`.
❌ NEVER: Call methods directly on another autoload (e.g., `GameSession.apply_data()` from `SaveService`). Signals only.
❌ NEVER: Reference autoloads from `res://ui/` scripts for combat logic.

### Resource Access

✅ MUST: Use `ResourceLoader.load_threaded_request()` / `load_threaded_get()` for runtime resource loading of large scenes and `LevelConfig`.
✅ MUST: Use `preload()` for small databases (<50 KB) loaded at startup.
❌ NEVER: Use `FileAccess` for runtime resource loading — use `ResourceLoader`.
❌ NEVER: Mutate a shared `Resource` directly. Call `duplicate_deep()` before mutating per-instance data.

### Platform / Export

✅ MUST: Test all exports on a physical Android device (Samsung Galaxy A34 or equivalent) — editor preview is not sufficient for Mobile renderer.
✅ MUST: Lock orientation to portrait in Project Settings.
✅ MUST: All touch targets ≥ 48 dp.
✅ MUST: Implement one-handed fallback for all critical UI interactions.
❌ NEVER: Write ad or IAP code outside the `PlatformBridge` autoload.
❌ NEVER: Reference ad or billing SDKs from gameplay or UI scripts.

---

## Foundation Layer Rules

> Foundation layer = Autoloads (`res://autoloads/`). Initialized before any scene.

### Autoload Declaration Order

✅ MUST: Maintain this exact declaration order in `project.godot` (immutable — changes require a new ADR):
```
1. GameSession
2. MetaProgression
3. EconomyService
4. SaveService
5. PlatformBridge
6. AudioRouter
7. CombatEventBus
8. SceneManager
9. VFXSystem  ← inserted after CombatEventBus per ADR-006 migration plan
```
✅ MUST: Document this order in a comment block directly in `project.godot`.
❌ NEVER: Reorder autoloads without a new ADR — order is an initialization dependency contract.
❌ NEVER: Add a new autoload without updating `project.godot` comment and this manifest.
📎 Source: ADR-002

### SaveService

✅ MUST: Use `call_deferred("_do_load")` in `SaveService._ready()` so save data loads after all autoloads complete their `_ready()`.
✅ MUST: Check the return value of `ConfigFile.save()` — `if err != OK: emit_signal("save_failed")`.
✅ MUST: Use atomic write before first public build: save to `user://save.cfg.tmp`, then `DirAccess.rename()` to final path.
✅ MUST: Define all ConfigFile section/key names as `const` strings in `SaveService` — no inline string literals.
✅ MUST: Call `_apply_defaults()` and emit `load_completed({})` on load error or missing file — never crash.
✅ MUST: Increment `CURRENT_VERSION` const and add a `_run_migration_step(from, to)` match branch for every schema change.
❌ NEVER: Call `FileAccess`, `ConfigFile.save()`, or `ConfigFile.load()` from any script other than `SaveService`.
❌ NEVER: Use `ResourceSaver` for player save data — `.tres` is authoring format only.
⚠️  VERIFY: `FileAccess.store_*` methods now return `bool` (was `void`) since Godot 4.4 — check return values.
📎 Source: ADR-005

### CombatEventBus

✅ MUST: Keep `CombatEventBus` as signals-only — zero `var` declarations, zero `func` declarations.
✅ MUST: Catalog every cross-layer event as a signal in `CombatEventBus`. Adding a new cross-layer event requires updating the ADR.
✅ MUST: Keep any single `CombatEventBus` signal to ≤ 8 subscribers. Audit quarterly.
✅ MUST: Total `CombatEventBus` dispatches ≤ 0.5ms/frame at peak (target: ~200 dispatches/sec at 40 enemies × 5 events/sec).
❌ NEVER: Put `hp_changed` or per-projectile `attack_fired` on `CombatEventBus` — high-frequency; direct signals only.
❌ NEVER: Add state or methods to `CombatEventBus`.
📎 Source: ADR-003

### PlatformBridge

✅ MUST: Route ALL ad and IAP calls through `PlatformBridge` exclusively.
✅ MUST: Use stub implementations (`AdsBridge`, `BillingBridge`) until mediation strategy is decided.
❌ NEVER: Call ad or billing SDK methods from any script other than `PlatformBridge`.
❌ NEVER: Include concrete ad/billing SDK calls before the stub is replaced with a confirmed integration.
📎 Source: tech-prefs

### AudioRouter

✅ MUST: Route all audio playback through `AudioRouter` — no direct `AudioStreamPlayer` calls from gameplay scripts.
📎 Source: ADR-002

---

## Core Layer Rules

> Core layer = Combat systems, wave management, economy, save logic. Lives in `res://systems/` and `res://autoloads/`.

### SceneManager

✅ MUST: Use `ResourceLoader.load_threaded_request()` for all in-game scene transitions.
✅ MUST: Poll load status in `_process()` using `ResourceLoader.load_threaded_get_status()`.
✅ MUST: Only swap the `SceneContainer` child of `Main.tscn` — never free the HUD.
✅ MUST: Use `use_sub_threads = true` for large level scenes; `false` for small UI scenes.
✅ MUST: Cap push/pop overlay stack depth at 5.
✅ MUST: Handle `THREAD_LOAD_FAILED` — emit `scene_load_failed` signal and show an error dialog.
❌ NEVER: Call `get_tree().change_scene_to_file()` for any in-game transition. It is called exactly once: boot splash → `Main.tscn`.
❌ NEVER: Swap the HUD node — it persists across all scene transitions as a child of `Main.tscn`.
⚠️  VERIFY: `ResourceLoader.load_threaded_*` confirmed stable in Godot 4.6 (Knowledge Risk: MEDIUM — stable since 4.0, but verify on device for load time targets: <16ms scene swap hitch).
📎 Source: ADR-001

### EnemySystem / EnemyBase

✅ MUST: Use the bridge pattern for cross-layer signals: `EnemyBase` emits direct signal to `EnemySystem` first (own bookkeeping), then `EnemySystem` re-emits to `CombatEventBus`.
✅ MUST: Validate `grep -r "EnemyBase\|TowerBase\|WaveManager" res://ui/` returns zero results in CI.
✅ MUST: Keep max active enemies ≤ 40 simultaneously.
✅ MUST: Reference `EnemyData.death_vfx_id` for death effects — never hardcode VFX node paths.
✅ MUST: When approaching 40-enemy cap, call `VFXSystem.set_budget_cap()` to reduce VFX budget.
❌ NEVER: Place combat logic in `res://ui/` scripts.
❌ NEVER: Hardcode enemy stats — all values in `EnemyData.tres` files.
📎 Source: ADR-003, ADR-004, ADR-006

### TowerBase / TowerSystem

✅ MUST: Use `TowerData` and `TowerTierData` resources — no hardcoded stats.
✅ MUST: Emit `attack_fired` as a direct signal (intra-layer) — do NOT put per-shot events on `CombatEventBus`.
✅ MUST: For T3 branching, resolve via `TowerTierData.branch_options: Array[TowerTierData]` — not inline logic.
✅ MUST: Call `duplicate_deep()` on `TowerData` before mutating per-tower instance state (upgrade tier divergence).
❌ NEVER: Mutate the shared `TowerData` resource directly.
❌ NEVER: Hardcode tower stats in `.gd` files.
⚠️  VERIFY: `duplicate_deep()` for nested `Array[Resource]` is a Godot 4.5 post-cutoff feature — integration test required on device.
📎 Source: ADR-004

### WaveManager

✅ MUST: Drive all wave configuration from `WaveConfig` and `SpawnEntry` resources.
✅ MUST: Emit `wave_completed` as a direct signal to `CampaignManager` (intra-layer).
✅ MUST: Emit `CombatEventBus.wave_completed` for cross-layer subscribers (HUD, economy).
❌ NEVER: Hardcode wave compositions or enemy counts in `.gd` files.
📎 Source: ADR-003, ADR-004

### EconomyService

✅ MUST: All currency values initialized from `SaveService.load_completed` handler in `EconomyService._ready()`.
✅ MUST: Connect to `SaveService.load_completed` in `EconomyService._ready()`.
❌ NEVER: Access `SaveService` state directly — receive it via the `load_completed` signal payload.
📎 Source: ADR-002

### CombatTypes / Shared Enums

✅ MUST: Place `DamageType` and `ElementTag` enums in a shared `CombatTypes.gd` autoloaded class.
✅ MUST: Import `CombatTypes` for any script using these enums.
❌ NEVER: Redefine `DamageType` or `ElementTag` locally in individual node scripts.
📎 Source: ADR-003

### Data Resources (General)

✅ MUST: Store all `.gd` Resource class definitions in `res://resources/` (one file per class).
✅ MUST: Store all `.tres` data instances in `res://data/` organized by system (e.g., `res://data/towers/`, `res://data/enemies/`).
✅ MUST: Build and use the CSV → `.tres` batch converter for bulk balance editing (sprint 1 deliverable).
✅ MUST: Treat `class_name` on Resource classes as an immutable contract after the first `.tres` file is created. Renaming breaks existing files.
✅ MUST: Use `effect_params: Dictionary` only for `UltimateData` and `AbilityData` — this is the one permitted untyped export.
❌ NEVER: Rename a Resource `class_name` after `.tres` files reference it.
❌ NEVER: Add hardcoded stats anywhere in `.gd` logic files — put them in `.tres`.
⚠️  VERIFY: `@abstract` decorator (Godot 4.5) used on base Resource classes — confirm available in 4.6.
📎 Source: ADR-004

---

## Feature Layer Rules

> Feature layer = Boss, Ultimate/Ability, Campaign, MetaProgression. Builds on Core layer.

### BossController

✅ MUST: Reference `BossData` and `BossPhaseData` resources for all boss configuration.
✅ MUST: Emit `CombatEventBus.boss_phase_changed` and `CombatEventBus.boss_died` for cross-layer subscribers.
✅ MUST: VFX for boss intro and finisher referenced via `BossData.intro_vfx_id` / `finisher_vfx_id` — played by `VFXSystem`.
❌ NEVER: Hardcode boss phase thresholds or attack patterns in `.gd`.
📎 Source: ADR-004, ADR-006

### UltimateSystem (Клизма Апокалипсиса and others)

✅ MUST: Store ultimate configuration in `UltimateData` resources.
✅ MUST: Use `UltimateData.enema_charge_cost` for the dual-cost field of Клизма Апокалипсиса.
✅ MUST: Emit `CombatEventBus.ultimate_activated` for cross-layer subscribers (VFX, audio, economy).
✅ MUST: Profile every ultimate VFX on device — CRITICAL-priority effects bypass the 200-particle cap; a bad ultimate can spike frame time.
❌ NEVER: Hardcode ultimate costs or parameters in `.gd`.
📎 Source: ADR-003, ADR-004, ADR-006

### MetaProgression

✅ MUST: Initialize state from `SaveService.load_completed` handler.
✅ MUST: Store upgrade tree state as JSON-encoded String in the `[meta]` ConfigFile section (one JSON blob per section max).
❌ NEVER: Access `SaveService` directly — use the `load_completed` signal.
📎 Source: ADR-002, ADR-005

### CampaignManager

✅ MUST: Connect to `WaveManager.wave_completed` (direct signal, intra-layer) for level progression.
✅ MUST: Reference `LevelConfig` resource for all level configuration (including `PackedScene` refs).
✅ MUST: Use `ResourceLoader.load_threaded_request()` for `LevelConfig` scenes (contains `PackedScene` refs).
❌ NEVER: Hardcode level layouts or chapter sequences in `.gd`.
📎 Source: ADR-001, ADR-004

---

## Presentation Layer Rules

> Presentation layer = HUD, menus, VFX. Lives in `res://ui/` and `res://autoloads/VFXSystem.gd`.

### HUD / UI Scripts (`res://ui/`)

✅ MUST: Subscribe to `CombatEventBus` signals for all combat data display (enemy count, HP bars, wave number).
✅ MUST: Keep all UI touch targets ≥ 48 dp.
✅ MUST: Implement one-handed fallback for all critical UI interactions.
❌ NEVER: Place combat logic in `res://ui/` scripts.
❌ NEVER: Directly reference `EnemyBase`, `TowerBase`, or `WaveManager` from UI scripts.
❌ NEVER: Call autoload methods directly from UI — use signals.
📎 Source: ADR-003, tech-prefs

### VFXSystem

✅ MUST: Route all particle emissions through `VFXSystem.play_vfx()` — never instantiate `GPUParticles2D` directly in gameplay scripts.
✅ MUST: Use `GPUParticles2D` for all particle effects.
✅ MUST: Keep active particles ≤ 200 at all times (enforced by `VFXSystem` budget check).
✅ MUST: Keep active decals ≤ 20 per scene (tracked by `VFXSystem`).
✅ MUST: Assign a `VFXPriority` to every effect: `LOW=0`, `MEDIUM=1`, `HIGH=2`, `CRITICAL=3`.
✅ MUST: Author glow at `glow_intensity ≤ 0.4` baseline in the editor.
✅ MUST: Re-tune all glow on a physical device (Samsung Galaxy A34 or equivalent) before marking any VFX story Done.
✅ MUST: Enable HDR 2D (`use_hdr_2d = true`) only on UI elements requiring bloom/glow — not all elements.
✅ MUST: Set `ssao_enabled = false`, `sdfgi_enabled = false`, `ssr_enabled = false` in every `WorldEnvironment`.
✅ MUST: Run Shader Baker in CI export pipeline before packaging APK/IPA.
✅ MUST: Each VFX effect in the registry declares its `particle_count` accurately — `VFXSystem` uses this for pre-check.
✅ MUST: Pool `GPUParticles2D` nodes per `vfx_id` — retrieve from pool on `play_vfx`, return on expiry.
✅ MUST: Profile ultimate VFX (CRITICAL — uncapped) on device before story Accepted; GPU spike must be <5ms.
✅ MUST: `EnemyBase` and `TowerBase` scenes use a single `Sprite2D` or `AnimatedSprite2D` per entity — no nested `CanvasItem` sub-layers unless required.
❌ NEVER: Use `CPUParticles2D` — use `GPUParticles2D` (CPU fallback defeats GPU budget).
❌ NEVER: Use Screen-Space Reflections (SSR) — unsupported on Mobile renderer.
❌ NEVER: Use SSAO — unsupported on Mobile renderer.
❌ NEVER: Use SDFGI — unsupported on Mobile renderer.
❌ NEVER: Write fragment shaders with more than 4 texture samples per pass. Split across passes if more are needed.
❌ NEVER: Instantiate particle nodes directly outside `VFXSystem`.
❌ NEVER: Hardcode particle counts in scene files — all particle counts via VFX registry.
⚠️  VERIFY: Godot 4.6 Mobile renderer applies glow before tonemapping (changed from 4.3). Editor preview will look different from device — mandatory device sign-off on every VFX effect.
⚠️  VERIFY: `GPUParticles2D` runs on GPU thread (not CPU fallback) on mid-range Android (Adreno 610 / Mali G52 class) — test on device.
⚠️  VERIFY: Decal nodes render correctly in 2D Mobile renderer — test on device.
⚠️  VERIFY: HDR 2D mode active and UI glow accents render correctly on device.
⚠️  VERIFY: Shader Baker (Godot 4.5 feature, available in 4.6) runs in CI and confirms APK startup time <3s cold start on device.
📎 Source: ADR-006

---

## Forbidden APIs (Godot 4.6)

| Forbidden | Use Instead | Since | Notes |
|-----------|-------------|-------|-------|
| `TileMap` | `TileMapLayer` | 4.3 | One node per layer |
| `yield()` | `await signal` | 4.0 | GDScript 2.0 syntax |
| `connect("signal", obj, "method")` | `signal.connect(callable)` | 4.0 | String-based connect removed |
| `duplicate()` for nested resources | `duplicate_deep()` | 4.5 | Explicit deep copy control |
| `Texture2D` in shader params | `Texture` base type | 4.4 | Changed in 4.4 |
| `$NodePath` in `_process()` | `@onready var` cached ref | any | Performance — cache in `_ready()` |
| `GodotPhysics3D` for new projects | Jolt Physics 3D | 4.6 | Jolt is default since 4.6 |
| Manual post-process viewport chains | `Compositor` + `CompositorEffect` | 4.3 | |
| `AnimationPlayer.method_call_mode` | `AnimationMixer` base class | 4.3 | Moved to base |
| `AnimationPlayer.playback_active` | `AnimationMixer` base class | 4.3 | Moved to base |
| `CPUParticles2D` | `GPUParticles2D` | project rule | ADR-006 |
| `get_tree().change_scene_to_file()` | `SceneManager.push_scene()` / `load_scene()` | project rule | ADR-001; banned in-game |
| `FileAccess` for resource loading | `ResourceLoader` | project rule | ADR-001 |
| Direct autoload method calls | Signals | project rule | ADR-002 |
| Combat logic in `res://ui/` | Core layer systems | project rule | tech-prefs |
| Ad / IAP code outside `PlatformBridge` | `PlatformBridge` autoload | project rule | tech-prefs |
| Magic numbers in balance code | `.tres` Resource files | project rule | ADR-004 |
| Untyped vars `var x` | `var x: Type` | project rule | tech-prefs |
| Untyped arrays `[]` | `Array[Type]` | project rule | tech-prefs |

---

## Naming Quick Reference

| Thing | Convention | Example |
|-------|-----------|---------|
| GDScript class | `PascalCase` | `EnemyBase`, `TowerData` |
| Variable / function / parameter | `snake_case` | `enemy_count`, `play_vfx()` |
| Signal | `snake_case` past tense | `enemy_died`, `wave_completed` |
| Constant | `UPPER_SNAKE_CASE` | `MAX_ENEMIES`, `CURRENT_VERSION` |
| `.gd` file | `snake_case.gd` | `enemy_base.gd`, `vfx_system.gd` |
| `.tscn` scene file | `PascalCase.tscn` | `EnemyBase.tscn`, `Main.tscn` |
| `.tres` data resource | `snake_case.tres` | `slime_basic.tres`, `wave_01.tres` |
| Autoload node name | `PascalCase` | `GameSession`, `CombatEventBus` |
| Resource class (`class_name`) | `PascalCase` | `EnemyData`, `WaveConfig` |
| Data directory | `res://data/<system>/` | `res://data/enemies/`, `res://data/waves/` |
| Resource class definitions | `res://resources/` | `res://resources/enemy_data.gd` |

---

## Performance Budget Quick Reference

| Metric | Hard Limit | Notes |
|--------|-----------|-------|
| Frame time | 16.6ms (60 fps) | Target: mid-range Android 2021+ |
| Draw calls | ≤ 150 / frame | At peak wave (40 enemies) |
| Active enemies | ≤ 40 simultaneous | `EnemySystem` enforces cap |
| Active particles | ≤ 200 / frame | `VFXSystem` enforces; runtime-adjustable |
| Active decals | ≤ 20 / scene | `VFXSystem` tracks |
| RAM | ≤ 512 MB | Total process |
| CombatEventBus | ≤ 0.5ms / frame | At peak (~200 dispatches/sec) |
| VFXSystem budget check | < 0.2ms / frame | Target < 0.5ms |
| GPU (200 particles, peak) | < 5ms GPU time | Peak wave stress test |
| APK cold start | < 3s | With Shader Baker; < 2s target |
| Scene transition hitch | < 16ms | Async threaded load (vs 200–400ms `change_scene_to_file`) |
| Signal subscribers per bus signal | ≤ 8 | Audit quarterly |

### Degradation Strategy (in order)

1. Reduce particle count (`VFXSystem.set_budget_cap()`)
2. Reduce enemy cap (`EnemySystem` notifies `VFXSystem`)
3. Reduce shadow resolution

### Baseline Test Device

Samsung Galaxy A34 (mid-range Android 2021+). All performance validation must pass on this device or equivalent.

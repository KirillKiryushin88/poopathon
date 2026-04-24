# ADR-004: Data Resource Structure

## Status

Accepted

## Date

2026-04-24

## Last Verified

2026-04-24

## Decision Makers

Technical Director

## Summary

All game configuration (tower stats, enemy stats, wave spawn sequences, level layouts, ultimates, meta abilities) must be data-driven to allow balance iteration without recompilation; no stats may be hardcoded in `.gd` scripts. All configuration is stored in typed `Resource` subclasses (`.tres` files) organized under `res://data/`, loaded via `preload()` for small resources or `ResourceLoader.load_threaded_request()` for large assets.

## Engine Compatibility

| Field | Value |
|-------|-------|
| **Engine** | Godot 4.6 |
| **Domain** | Core / Scripting |
| **Knowledge Risk** | MEDIUM — `duplicate_deep()` for nested Resources added in Godot 4.5 (post-cutoff); `@export` typed arrays of Resources are Godot 4.x stable |
| **References Consulted** | `docs/engine-reference/godot/breaking-changes.md`, `docs/architecture/architecture.md` § API Boundaries (Data Resources section) |
| **Post-Cutoff APIs Used** | `Resource.duplicate_deep()` (Godot 4.5) — required when per-instance tower state must diverge from shared resource data; `@abstract` decorator (Godot 4.5) for base Resource classes |
| **Verification Required** | Confirm `duplicate_deep()` correctly deep-copies `Array[TowerTierData]` on Godot 4.6 device build; verify typed `Array[Resource]` exports round-trip correctly through `.tres` serialization; confirm `ResourceLoader.load_threaded_get()` returns the correct type for typed Resources |

> **Note**: If Knowledge Risk is MEDIUM or HIGH, this ADR must be re-validated if the
> project upgrades engine versions. Flag it as "Superseded" and write a new ADR.

## ADR Dependencies

| Field | Value |
|-------|-------|
| **Depends On** | ADR-002 (autoload init order — Resources are loaded by autoloads; order must be settled first) |
| **Enables** | ADR-007 (tower upgrade branching uses `TowerTierData` Resource defined here), ADR-008 (enemy pathfinding uses `EnemyData` behavior enum defined here) |
| **Blocks** | TowerSystem, EnemySystem, WaveManager, LevelLoader, MetaProgression, UltimateSystem stories |
| **Ordering Note** | Must be Accepted before any data-consuming system is implemented |

## Context

### Problem Statement

A TD game with 18 tower variants, 8 enemy types, 6 bosses, ~30 levels, and a meta upgrade tree requires hundreds of tunable values. If these values are hardcoded in `.gd` files, every balance change requires a code edit, recompile, and redeploy — blocking non-programmer designers from iterating on balance. The project needs a schema that: (a) is strongly typed (catches schema errors at load time, not runtime), (b) is human-readable for inspection, (c) integrates with Godot's editor UI for authoring, and (d) loads efficiently on mobile.

### Current State

Pre-production; no data files or Resource classes exist.

### Constraints

- **Engine**: Godot's `Resource` system natively supports typed `@export` fields, editor UI authoring, and `.tres` text serialization — no addon required
- **Mobile**: Large bundles of `.tres` files add to PCK size; must keep per-resource scope tight to avoid redundant data
- **Team**: Non-programmer designers must be able to edit values in Godot editor without touching code
- **Architecture**: Resources are shared objects — tower instances must `duplicate_deep()` if they need per-instance mutable state derived from shared data
- **Godot 4.5**: `duplicate_deep()` now correctly duplicates nested Resources (fixed in 4.5); project pins 4.6 so this is available

### Requirements

- All tower stats, enemy stats, wave spawn sequences, level layouts, ultimate costs/effects, and meta ability nodes defined in `.tres` files
- No numeric game constant (damage, cost, speed, range, cooldown) hardcoded in any `.gd` file
- Resource classes must be typed (`class_name`) so Godot's type system validates exports
- Resource databases (master lists) stored as typed `Array[Resource]` Resources under `res://data/`
- Small resources (<50KB): loaded via `preload()` at script parse time
- Large or level-specific resources: loaded via `ResourceLoader.load_threaded_request()` during level load
- `LevelConfig` must store enemy path data as `Array[Curve2D]` (resolved by ADR-008; placeholder here)

## Decision

All game configuration is stored in the typed `Resource` hierarchy below. No hardcoded stats in `.gd` files. The `res://data/` directory is the single source of truth for all authored game content.

### Architecture

```
res://data/
├── towers/
│   ├── tower_database.tres         ← Array[TowerData] — all tower definitions
│   ├── tower_fart_cannon.tres      ← TowerData instance
│   ├── tower_slime_sprayer.tres
│   └── ...  (18 tower .tres files)
├── enemies/
│   ├── enemy_database.tres         ← Array[EnemyData] — all enemy definitions
│   ├── enemy_virus.tres
│   ├── enemy_sanitizer_exorcist.tres
│   └── ...  (8 enemy .tres files)
├── waves/                          ← WaveConfig .tres files referenced by LevelConfig
│   └── ch1_level1_wave1.tres
├── levels/
│   ├── chapter_1/
│   │   ├── level_1.tres            ← LevelConfig instance
│   │   └── ...
│   └── ...  (6 chapters)
├── bosses/
│   ├── boss_zasor.tres             ← BossData instance
│   └── ...  (6 boss .tres files)
├── ultimates/
│   ├── ultimate_enema.tres         ← UltimateData instance
│   └── ...
└── abilities/
    └── ability_tree.tres           ← Array[AbilityData] — meta progression tree

Resource Class Hierarchy:
─────────────────────────
Resource
├── TowerData           (res://resources/tower_data.gd)
│   └── tiers: Array[TowerTierData]
├── TowerTierData       (res://resources/tower_tier_data.gd)
├── EnemyData           (res://resources/enemy_data.gd)
├── WaveConfig          (res://resources/wave_config.gd)
│   └── spawns: Array[SpawnEntry]
├── SpawnEntry          (res://resources/spawn_entry.gd)
├── LevelConfig         (res://resources/level_config.gd)
│   ├── wave_configs: Array[WaveConfig]
│   └── boss_data: BossData
├── BossData            (res://resources/boss_data.gd)
│   └── phases: Array[BossPhaseData]
├── BossPhaseData       (res://resources/boss_phase_data.gd)
├── UltimateData        (res://resources/ultimate_data.gd)
└── AbilityData         (res://resources/ability_data.gd)
```

### Key Interfaces

```gdscript
# ── TowerData ──────────────────────────────────────────────────────────────
class_name TowerData
extends Resource

@export var tower_id: StringName
@export var display_name: String
@export var tower_type: TowerType
@export var damage_type: DamageType
@export var element_tag: ElementTag
@export var base_cost: int                  # Tier 1 purchase cost (Slime)
@export var sell_value_percent: float = 0.6 # Sell returns 60% of spent total
@export var icon: Texture2D
@export var scene_path: String              # path to PackedScene for this tower
@export var tiers: Array[TowerTierData]     # index 0=T1 … 3=T4


# ── TowerTierData ───────────────────────────────────────────────────────────
class_name TowerTierData
extends Resource

@export var tier: int                   # 1–4
@export var damage: float
@export var attack_speed: float         # attacks per second
@export var range: float                # pixels
@export var upgrade_cost: int           # Slime to upgrade to this tier
@export var vfx_id: StringName          # projectile / attack VFX key
# T3 only — branching options (empty for T1, T2, T4):
@export var branch_options: Array[TowerTierData]


# ── EnemyData ───────────────────────────────────────────────────────────────
class_name EnemyData
extends Resource

@export var enemy_id: StringName
@export var display_name: String
@export var max_hp: float
@export var move_speed: float           # pixels per second
@export var armor: float                # flat damage reduction
@export var damage_type: DamageType
@export var soft_drop: int              # Slime on death
@export var pressure_grant: float       # pressure added to meter on death
@export var death_vfx_id: StringName
@export var tags: Array[ElementTag]     # initial element tags (if any)
@export var pathfinding_behavior: PathfindingBehavior   # enum (ADR-008)


# ── WaveConfig ───────────────────────────────────────────────────────────────
class_name WaveConfig
extends Resource

@export var wave_index: int
@export var spawns: Array[SpawnEntry]
@export var fast_forward_multiplier: float = 2.0
@export var reward_soft: int            # Slime reward on wave clear


# ── SpawnEntry ───────────────────────────────────────────────────────────────
class_name SpawnEntry
extends Resource

@export var enemy_type: StringName      # must match EnemyData.enemy_id
@export var count: int
@export var spawn_interval: float       # seconds between each spawn
@export var path_id: int                # index into LevelConfig.enemy_paths
@export var delay_from_wave_start: float


# ── LevelConfig ──────────────────────────────────────────────────────────────
class_name LevelConfig
extends Resource

@export var level_id: String
@export var chapter_id: int
@export var display_name: String
@export var wave_configs: Array[WaveConfig]
@export var tower_slots: Array[TowerSlotData]
@export var background_scene: PackedScene
@export var music_id: String
@export var cost_multiplier: float = 1.0    # 0.85 for boss chapters
@export var is_boss_level: bool = false
@export var boss_data: BossData             # null for non-boss levels


# ── UltimateData ─────────────────────────────────────────────────────────────
class_name UltimateData
extends Resource

@export var ultimate_id: StringName
@export var display_name: String
@export var pressure_cost: float = 100.0
@export var enema_charge_cost: int = 0      # 1 for Клизма Апокалипсиса
@export var cooldown: float                 # seconds
@export var targeting_mode: TargetingMode   # enum: GLOBAL, CONE, POINT
@export var vfx_id: StringName
@export var sfx_id: StringName
@export var effect_params: Dictionary       # ultimate-specific params


# ── AbilityData ───────────────────────────────────────────────────────────────
class_name AbilityData
extends Resource

@export var ability_id: String
@export var display_name: String
@export var chapter_material_costs: Array[int]  # per-chapter cost
@export var effect_type: AbilityEffectType       # enum
@export var effect_params: Dictionary            # typed per effect_type
@export var prerequisites: Array[String]         # ability_id dependencies
@export var icon: Texture2D
```

### Implementation Guidelines

1. All Resource class definitions live in `res://resources/` (one `.gd` per class). Data instances (`.tres`) live in `res://data/` organized by system.
2. **Loading strategy**:
   - `preload("res://data/towers/tower_database.tres")` — loaded at script parse time for small databases (<50KB total). Used by `TowerSystem`, `WaveManager`.
   - `ResourceLoader.load_threaded_request("res://data/levels/ch1/level_1.tres")` — used by `LevelLoader` for level assets that include `PackedScene` references (can be large).
3. **Per-instance mutation**: Tower instances read stats from shared `TowerData` Resource. If a running instance needs to mutate stats (e.g., upgrade mid-level), call `tower_data = tower_data.duplicate_deep()` first. Never mutate the shared Resource.
4. **Database pattern**: Each system that has multiple types (towers, enemies) gets a typed `Array[XxxData]` Resource file called `xxx_database.tres`. Systems query by `enemy_id: StringName` using a helper `_find_by_id()` method.
5. No `Dictionary` with string keys as a substitute for typed Resources. If a field cannot be expressed as a typed export, add a new field to the Resource class.
6. `effect_params: Dictionary` on `UltimateData` and `AbilityData` is the ONE exception — these are too varied to enumerate in a class. Document valid keys per `effect_type` enum value in a comment.
7. All `.tres` files must pass Godot's resource validation (`ProjectSettings → Import` no errors) before a story is marked Done.
8. Balance spreadsheet → `.tres` pipeline: use a GDScript batch converter tool (to be created in sprint 1) that reads a CSV and writes `.tres` files. This prevents manual `.tres` editing for bulk changes.

## Alternatives Considered

### Alternative 1: JSON files for all game data

- **Description**: Store all configuration in `.json` files under `res://data/`; GDScript parses JSON at runtime
- **Pros**: Human-readable; editable in any text editor; easy to export from spreadsheets; no Godot import
- **Cons**: No type safety — any schema error is a runtime crash; no Godot editor UI for authoring; manual `Dictionary` access (`data["damage"]`) is error-prone; no refactoring support in IDE
- **Estimated Effort**: Similar setup; higher maintenance
- **Rejection Reason**: Typed Resources catch schema mismatches at load time; editor UI is available; JSON offers no meaningful advantage for this project

### Alternative 2: Hardcoded constants in `const` blocks in GDScript

- **Description**: Stats defined as `const` at the top of each system script
- **Pros**: Zero I/O overhead; simplest possible implementation
- **Cons**: Balance change = code change = recompile = rebuild; non-programmers cannot balance; no data inheritance or branching
- **Estimated Effort**: Lowest initially; highest long-term
- **Rejection Reason**: Violates TR-tower-001 and TR-enemy-001 explicitly; incompatible with designer-facing balance iteration

### Alternative 3: SQLite database via GDExtension

- **Description**: Ship a SQLite database; use a GDExtension plugin to query it at runtime
- **Pros**: Relational queries; easy to export from spreadsheets
- **Cons**: Requires GDExtension addon (third-party dependency, Godot 4.6 compatibility risk); queries are string-based (no type safety); overkill for ~200 records
- **Estimated Effort**: Much higher
- **Rejection Reason**: No meaningful benefit over typed Resources for dataset size; introduces GDExtension dependency risk

## Consequences

### Positive

- Balance iteration does not require code changes — designers edit `.tres` files in Godot editor
- Type errors (wrong field type, missing required field) caught at `.tres` load time, not at gameplay runtime
- Godot editor provides property inspector UI for authoring Resources — no custom tooling needed for basic editing
- Resources are serializable and can be diffed in version control (text `.tres` format)
- `duplicate_deep()` support (Godot 4.5+) enables safe per-instance divergence without corrupting shared data

### Negative

- Initial Resource class setup is boilerplate-heavy (one `.gd` per class, then `.tres` instances)
- Large `LevelConfig` files that embed `PackedScene` references via export can become large; must use `load_threaded_request` not `preload`
- `effect_params: Dictionary` on `UltimateData`/`AbilityData` is a type-safety hole — requires documentation discipline
- Renaming a Resource class name breaks existing `.tres` files (Godot stores `class_name` in `.tres` header) — treat class names as stable contracts

### Neutral

- The `res://data/` directory structure mirrors system architecture — makes it easy to find data for any system
- CSV → `.tres` batch converter must be built in sprint 1 to enable efficient bulk balance editing

## Risks

| Risk | Probability | Impact | Mitigation |
|------|------------|--------|-----------|
| `duplicate_deep()` fails to copy nested Array[Resource] on Godot 4.6 | Low | High — stat corruption during tower upgrade | Add integration test: create TowerData, duplicate_deep, mutate clone, verify original unchanged |
| Resource class renamed after `.tres` files created | Medium | Medium — `.tres` files fail to load | Treat `class_name` as immutable after first `.tres` created; code review block on `class_name` changes |
| `effect_params: Dictionary` keys inconsistent across ultimates | Medium | Low — wrong effect applied | Document valid keys per `effect_type` enum in comment block; add validation in UltimateSystem._validate_params() |
| LevelConfig PackedScene refs cause large threaded load times | Low | Low — handled by async loader | Use `load_threaded_request` for LevelConfig; show transition overlay during load (ADR-001) |

## Performance Implications

| Metric | Before | Expected After | Budget |
|--------|--------|---------------|--------|
| CPU (Resource load at startup) | N/A | Tower DB + Enemy DB preload ~2ms total | <5ms startup overhead |
| Memory (all databases in memory) | N/A | ~2–5MB for all .tres data | <8MB |
| Load Time (LevelConfig threaded) | N/A | <500ms background load on mid-range Android | <2s (covered by transition overlay) |
| Stat access per frame (TowerBase.attack) | N/A | Single property read from Resource | Negligible |

## Migration Plan

Pre-production; no existing data files to migrate.

1. Create all Resource class `.gd` files in `res://resources/`
2. Create `res://data/` directory structure
3. Populate `tower_database.tres` and `enemy_database.tres` with placeholder entries for sprint 1 systems
4. Build CSV → `.tres` batch converter script
5. LevelLoader implementation uses `load_threaded_request` for `LevelConfig` (ADR-001 transition system handles loading overlay)

**Rollback plan**: If Godot's `.tres` format proves unmaintainable at scale (>500 resource files), introduce a custom binary packing step in the CI pipeline that converts `.tres` to a single typed binary blob. The GDScript interfaces remain unchanged.

## Validation Criteria

- [ ] All tower, enemy, wave, level, boss, ultimate, and ability data exists in `.tres` files; `grep -r "= [0-9]" res://autoloads/ res://systems/` returns zero hardcoded stat values
- [ ] `duplicate_deep()` on a `TowerData` with nested `Array[TowerTierData]` returns an independent copy (verified by unit test)
- [ ] `LevelConfig` loads via `load_threaded_request` without blocking main thread (profiler: zero frame spike during level load transition)
- [ ] Godot editor property inspector displays all Resource exports correctly for `TowerData`, `EnemyData`, `LevelConfig`
- [ ] CSV batch converter correctly generates `.tres` files for the full tower and enemy databases

## GDD Requirements Addressed

| GDD Document | System | Requirement | How This ADR Satisfies It |
|-------------|--------|-------------|--------------------------|
| `design/gdd/master-gdd.md` | TowerSystem | TR-tower-001: 18 tower variants; all stats in `TowerData` `.tres` resources | `TowerData` and `TowerTierData` Resource classes defined here; `.tres` instances in `res://data/towers/` |
| `design/gdd/master-gdd.md` | TowerSystem | TR-tower-002: Tower cost curve T1=80, T2=180, T3=380, T4=700 | `TowerData.base_cost` and `TowerTierData.upgrade_cost` fields defined here; values authored in `.tres` files |
| `design/gdd/master-gdd.md` | TowerSystem | TR-tower-003: Boss chapter 0.85 cost multiplier | `LevelConfig.cost_multiplier` field; TowerSystem reads this at placement/upgrade time |
| `design/gdd/master-gdd.md` | TowerSystem | TR-tower-005: Sell formula in TowerData | `TowerData.sell_value_percent` field defined here |
| `design/gdd/master-gdd.md` | EnemySystem | TR-enemy-001: 8 enemy types; all stats in `EnemyData` `.tres` resources | `EnemyData` Resource class defined here |
| `design/gdd/master-gdd.md` | WaveManager | TR-wave-001: WaveManager reads `WaveConfig` resources; no hardcoded spawn sequences | `WaveConfig` and `SpawnEntry` Resource classes defined here |
| `design/gdd/master-gdd.md` | MetaProgression | TR-meta-003: Upgrade tree state in MetaProgression; TowerSystem reads bonuses at tower creation | `AbilityData` Resource class defines upgrade tree nodes; `TowerSystem` reads `MetaProgression.get_upgrade_level()` at creation |
| `design/gdd/master-gdd.md` | BossController | TR-boss-001: 6 bosses with multi-phase data in `BossData` `.tres` resources | `BossData` and `BossPhaseData` Resource classes defined here |

## Related

- ADR-002: Autoload init order (data databases are preloaded by autoloads; order must be stable)
- ADR-007: Tower upgrade branching (extends `TowerTierData.branch_options` defined here)
- ADR-008: Enemy pathfinding (uses `EnemyData.pathfinding_behavior` enum defined here)
- `docs/architecture/architecture.md` § API Boundaries (Data Resources)

# ADR-005: Save Format

## Status

Accepted

## Date

2026-04-24

## Last Verified

2026-04-24

## Decision Makers

Technical Director

## Summary

The project needs a save format that is human-readable for debug inspection, built into Godot without addons, supports typed get-with-default semantics, and is straightforward to version and migrate. Use Godot's built-in `ConfigFile` (INI-style) stored at `user://save.cfg`, with system-scoped sections, versioned by a `save_version` key, and migrated by `SaveService._migrate(from, to)`. `SaveService` is the sole owner of all file I/O.

## Engine Compatibility

| Field | Value |
|-------|-------|
| **Engine** | Godot 4.6 |
| **Domain** | Core / Scripting |
| **Knowledge Risk** | MEDIUM — `FileAccess.store_*` return value changed from `void` to `bool` in Godot 4.4 (post-cutoff); `ConfigFile` API is stable since Godot 3.x |
| **References Consulted** | `docs/engine-reference/godot/breaking-changes.md`, `docs/architecture/architecture.md` § Save/Load Path |
| **Post-Cutoff APIs Used** | `FileAccess.store_string()` → returns `bool` since Godot 4.4 (was `void`). All write operations must check the return value. |
| **Verification Required** | On Android: confirm `user://save.cfg` is writable at `user://` path; confirm `ConfigFile.save()` and `ConfigFile.load()` work correctly under Android file system sandboxing (Godot maps `user://` to internal storage); confirm `FileAccess.store_*` returns `false` on disk-full condition |

> **Note**: If Knowledge Risk is MEDIUM or HIGH, this ADR must be re-validated if the
> project upgrades engine versions. Flag it as "Superseded" and write a new ADR.

## ADR Dependencies

| Field | Value |
|-------|-------|
| **Depends On** | ADR-002 (SaveService initialization order and `call_deferred` load pattern defined there) |
| **Enables** | All persistent state: MetaProgression, EconomyService, GameSession save/load stories |
| **Blocks** | SaveService implementation story |
| **Ordering Note** | Must be Accepted before SaveService is implemented; ADR-002 must be Accepted first for the deferred load contract |

## Context

### Problem Statement

The project needs to persist: meta progression (upgrade tree state, account level, chapter unlocks), economy state (soft currency, crystal balance, enema charges, chapter materials), campaign state (current chapter, level stars), and player settings (audio volumes, graphics quality). The chosen format must work on Android and iOS `user://` paths, be inspectable without a hex editor during development, require no addons, and handle version migration when the data schema changes between releases.

### Current State

Pre-production; no save system exists.

### Constraints

- **Engine**: Godot provides `ConfigFile` (INI-style, built-in), `JSON` (built-in), `FileAccess` raw binary — no addon required for any of these
- **Platform**: `user://` on Android maps to app's internal storage; on iOS to the app's Documents directory; both are sandboxed and writable
- **API change (Godot 4.4)**: `FileAccess.store_*` methods changed return type from `void` to `bool`. Failure to check return value means silent save corruption — this is a hard constraint
- **Data size**: Save data is entirely primitive values (ints, floats, strings, arrays of primitives). No binary assets. Expected total size <100KB
- **Team**: Save file must be human-readable for debugging during development; no proprietary editor needed

### Requirements

- Single save file (no slots) at `user://save.cfg`
- Versioned with `save_version` integer key for migration support
- Sections per system: `[meta]`, `[campaign]`, `[economy]`, `[settings]`
- `SaveService` is the ONLY script that reads or writes this file — no other script accesses `user://` directly
- All write operations check `FileAccess.store_*` return value (Godot 4.4 requirement); emit `save_failed` signal on `false`
- Migration function handles version gaps (e.g., version 1 → version 3 runs migrate(1,2) then migrate(2,3))
- On first launch (no save file): apply default values; do not crash

## Decision

Use `ConfigFile` (Godot built-in INI-style) for the save file at `user://save.cfg`. Section structure: one section per subsystem. All values are Godot primitives (`int`, `float`, `String`, `bool`, `Array`, `Dictionary`). Complex nested data is JSON-encoded as a `String` value. File is versioned with a top-level `save_version` key in `[meta]` section. `SaveService._migrate(from_version, to_version)` handles schema evolution.

### Architecture

```
user://save.cfg  (ConfigFile INI format)
─────────────────────────────────────────
[meta]
save_version = 1
account_level = 12
chapter_1_stars = [3, 3, 2, 0, 0]
chapter_2_stars = []
upgrades_json = "{\"tower_range_1\": 2, \"fire_rate_1\": 1}"
ng_plus_unlocked = false

[campaign]
current_chapter = 2
current_level = "ch2_level_3"
last_completed_level = "ch2_level_2"

[economy]
soft_currency = 450
hard_currency = 0
enema_charges = 1
chapter_materials_json = "{\"ch1\": 5, \"ch2\": 2}"

[settings]
sfx_volume_db = 0.0
music_volume_db = -6.0
graphics_quality = 1
portrait_lock = true

SaveService (Autoload)
─────────────────────────────────────────
    ├── _config: ConfigFile             ← in-memory ConfigFile object
    ├── SAVE_PATH = "user://save.cfg"   ← const, never duplicated elsewhere
    ├── CURRENT_VERSION = 1             ← increment on schema change
    │
    ├── save_game()
    │   ├── _config.set_value("[meta]", "save_version", CURRENT_VERSION)
    │   ├── GameSession.get_save_data() → writes to [campaign] section
    │   ├── MetaProgression.get_save_data() → writes to [meta] section
    │   ├── EconomyService.get_save_data() → writes to [economy] section
    │   └── _config.save(SAVE_PATH) → check return bool
    │       └── if err != OK → emit save_failed(error_string)
    │
    └── _do_load()  [called via call_deferred — see ADR-002]
        ├── if not FileAccess.file_exists(SAVE_PATH): _apply_defaults()
        ├── _config.load(SAVE_PATH)
        ├── ver = _config.get_value("meta", "save_version", 0)
        ├── if ver < CURRENT_VERSION: _migrate(ver, CURRENT_VERSION)
        └── emit load_completed(save_data_dict)
```

### Key Interfaces

```gdscript
class_name SaveService
extends Node

const SAVE_PATH := "user://save.cfg"
const CURRENT_VERSION := 1

signal initialized()
signal save_completed()
signal load_completed(save_data: Dictionary)
signal save_failed(error: String)

var _config: ConfigFile

func _ready() -> void:
    _config = ConfigFile.new()
    initialized.emit()
    call_deferred("_do_load")   # ADR-002: deferred so all autoloads are ready

func save_game() -> void:
    # Each data owner provides its slice as a Dictionary:
    var session_data := GameSession.get_save_data()
    var meta_data := MetaProgression.get_save_data()
    var econ_data := EconomyService.get_save_data()
    # Write to ConfigFile sections:
    _write_section("campaign", session_data)
    _write_section("meta", meta_data)
    _write_section("economy", econ_data)
    _config.set_value("meta", "save_version", CURRENT_VERSION)
    var err := _config.save(SAVE_PATH)
    if err != OK:
        save_failed.emit("ConfigFile.save() returned error: %d" % err)
        return
    save_completed.emit()

func load_game() -> void: pass   # see _do_load

func has_save() -> bool:
    return FileAccess.file_exists(SAVE_PATH)

func delete_save() -> void:
    DirAccess.remove_absolute(ProjectSettings.globalize_path(SAVE_PATH))
    _config = ConfigFile.new()

func _do_load() -> void:
    if not has_save():
        _apply_defaults()
        load_completed.emit({})
        return
    var err := _config.load(SAVE_PATH)
    if err != OK:
        save_failed.emit("ConfigFile.load() returned error: %d" % err)
        _apply_defaults()
        load_completed.emit({})
        return
    var ver: int = _config.get_value("meta", "save_version", 0)
    if ver < CURRENT_VERSION:
        _migrate(ver, CURRENT_VERSION)
    var save_data := _build_save_dict()
    load_completed.emit(save_data)

func _migrate(from_version: int, to_version: int) -> void:
    for v in range(from_version, to_version):
        _run_migration_step(v, v + 1)
    # After migration, re-save to update version:
    var err := _config.save(SAVE_PATH)
    if err != OK:
        save_failed.emit("Migration re-save failed: %d" % err)

func _run_migration_step(from: int, to: int) -> void:
    match [from, to]:
        [0, 1]:
            # Example: rename old key
            pass
        # Future migrations added here

func _apply_defaults() -> void:
    _config.set_value("meta", "save_version", CURRENT_VERSION)
    _config.set_value("meta", "account_level", 1)
    _config.set_value("economy", "soft_currency", 200)   # starter Slime
    _config.set_value("economy", "hard_currency", 0)
    _config.set_value("economy", "enema_charges", 0)
    # settings defaults:
    _config.set_value("settings", "sfx_volume_db", 0.0)
    _config.set_value("settings", "music_volume_db", -6.0)

# Helper for reading with type-safe default:
func get_value(section: String, key: String, default: Variant) -> Variant:
    return _config.get_value(section, key, default)
```

### Implementation Guidelines

1. `SaveService` is the ONLY script that calls `FileAccess`, `ConfigFile.save()`, or `ConfigFile.load()`. Enforce via code review and a CI grep check.
2. Every `ConfigFile.save()` call must check `if err != OK` — do not use `_config.save(SAVE_PATH)` without checking the return. This is the Godot 4.4 API change that previously returned `void`.
3. Complex data structures (upgrade tree state as `{ability_id: level}`, chapter materials as `{chapter_id: amount}`) are JSON-encoded to a single String value using `JSON.stringify()`. Maximum one JSON blob per section to keep the file scannable.
4. `CURRENT_VERSION` is a `const` in `SaveService.gd`. Increment it whenever a schema change is made. Each migration step is a method `_run_migration_step(from, to)` with a `match` block.
5. On load error (corrupted file), call `_apply_defaults()` and emit `load_completed({})` with empty dict — do not crash. Log the error to Godot's error output.
6. `get_value(section, key, default)` wrapper is the safe accessor — always supply a default matching the expected type. This prevents `Variant` type mismatches from corrupted saves.
7. Settings section (`[settings]`) is read by `AudioRouter` and the graphics system — these connect to `SaveService.load_completed` and apply their settings slice.

## Alternatives Considered

### Alternative 1: JSON file via FileAccess

- **Description**: Serialize all save data to a single JSON string; write to `user://save.json` via `FileAccess`
- **Pros**: Universal format; easy to inspect; easy to export to tools
- **Cons**: Requires manual `Dictionary` parse/serialize; no typed get-with-default (every access needs `.get("key", default)`); `FileAccess.store_string()` return must still be checked (same Godot 4.4 issue); slightly more code than `ConfigFile`
- **Estimated Effort**: Similar
- **Rejection Reason**: `ConfigFile` natively handles typed get-with-defaults, section organization, and save/load in fewer lines. JSON offers no advantage for this data size.

### Alternative 2: Custom binary format via FileAccess

- **Description**: Serialize save data to a custom binary format using `FileAccess.store_*` methods
- **Pros**: Smaller file size; harder for players to cheat; potentially faster I/O
- **Cons**: Not human-readable (blocks debugging); requires custom deserializer; `store_*` return bool must be checked (same issue); migration is harder to implement and audit; no measurable performance benefit for <100KB of data
- **Estimated Effort**: Higher
- **Rejection Reason**: Zero performance benefit at this data size. Human readability during development outweighs all advantages.

### Alternative 3: Godot `ResourceSaver` / save a Resource to `.tres`

- **Description**: Create a `SaveData extends Resource` class and use `ResourceSaver.save()` to write it
- **Pros**: Fully typed; Godot-native; can embed nested Resources
- **Cons**: `.tres` text format is verbose and not designed for save files; `ResourceSaver` has overhead for a live-data save (designed for asset authoring); migration is complex (Resource class renames break `.tres`); file is larger than ConfigFile equivalent
- **Estimated Effort**: Similar
- **Rejection Reason**: `ResourceSaver` is designed for authoring-time assets, not runtime save data; ConfigFile is the correct Godot tool for runtime persistent settings/saves

## Consequences

### Positive

- Human-readable save file — developers can open `user://save.cfg` in any text editor to debug save state
- Built-in Godot API — no addon dependency
- Typed `get_value(section, key, default)` semantics prevent null crashes from missing keys on fresh installs or after migration
- Section-per-system structure makes ownership clear and migration scoped
- Single `SaveService` file I/O owner makes auditing and testing straightforward

### Negative

- `ConfigFile` INI format does not support nested sections — complex structures require JSON-encoded String values (a minor abstraction leak)
- No cloud sync in this ADR (deferred; stub in `SaveService` for future implementation)
- INI format allows typos in section/key strings to create silent new keys — must use constants for all section and key strings

### Neutral

- Save file is at `user://save.cfg` — platform-specific path but Godot abstracts this; developers should use Godot's `File System` dock to browse `user://` during development
- File size ~5–10KB text — negligible storage impact

## Risks

| Risk | Probability | Impact | Mitigation |
|------|------------|--------|-----------|
| `ConfigFile.save()` returns error on Android (storage permission) | Low | High — save lost | Test on real device in sprint 1; add `save_failed` signal handler in PlatformBridge that shows alert |
| Save file corrupted by force-quit mid-write | Low | Medium — progress loss | Use write-then-rename (atomic write): save to `user://save.cfg.tmp` then `DirAccess.rename` to final path |
| Schema migration missed when `CURRENT_VERSION` incremented | Medium | Medium — wrong defaults applied | Unit test: create v0 save, load with v1 SaveService, assert migrated values correct |
| Section/key string typo creates silent duplicate key | Medium | Low — wrong value read | Define all section and key names as `const` strings in SaveService; never use inline string literals |

## Performance Implications

| Metric | Before | Expected After | Budget |
|--------|--------|---------------|--------|
| CPU (save_game() call) | N/A | <2ms (ConfigFile serialize + write <100KB) | <5ms |
| CPU (load on startup) | N/A | <3ms via call_deferred (not on critical path) | <10ms |
| Memory (ConfigFile in memory) | N/A | ~50KB | <100KB |
| Storage (save file size) | N/A | ~5–10KB text | <100KB budget |

## Migration Plan

Pre-production; no existing save data to migrate.

1. Implement `SaveService.gd` with `ConfigFile`, `save_game()`, `_do_load()`, `_apply_defaults()`, `_migrate()`
2. Define all section constants (`SECTION_META`, `SECTION_CAMPAIGN`, etc.) as `const` in `SaveService`
3. Connect each data autoload to `load_completed` signal in their own `_ready()` (per ADR-002)
4. Integration test on Android: write a save, force-close app, reopen, confirm data restored
5. Implement atomic write (tmp file + rename) before first public build

**Rollback plan**: If `ConfigFile` proves unsuitable for cloud sync integration (future ADR), introduce a parallel `CloudSaveService` that wraps `SaveService` and pushes the raw `user://save.cfg` content to the cloud service. The `SaveService` public interface does not change.

## Validation Criteria

- [ ] `grep -r "ConfigFile\|FileAccess\|DirAccess" res://` (excluding SaveService.gd and tests) returns zero results — no other script accesses the filesystem
- [ ] `ConfigFile.save()` return value checked in every call path; `save_failed` signal fires when artificially forced to return error
- [ ] Save → force quit → reload correctly restores: soft currency, account level, current chapter, upgrade tree state
- [ ] Schema migration unit test: v0 save (no `enema_charges` key) loads correctly with default `enema_charges = 0` under v1 SaveService
- [ ] `user://save.cfg` is human-readable plain text (not binary) in Android device file browser

## GDD Requirements Addressed

| GDD Document | System | Requirement | How This ADR Satisfies It |
|-------------|--------|-------------|--------------------------|
| `design/gdd/master-gdd.md` | SaveService | TR-save-001: SaveService serializes GameSession, MetaProgression, EconomyService into a single save | ConfigFile with three system sections (`[campaign]`, `[meta]`, `[economy]`) |
| `design/gdd/master-gdd.md` | SaveService | TR-save-002: `load_game()` called via `call_deferred` | Mandated by ADR-002 and implemented in `SaveService._ready()` |
| `design/gdd/master-gdd.md` | SaveService | TR-save-003: `FileAccess.store_*` return `bool` must be checked (Godot 4.4) | `ConfigFile.save()` return value checked in every call; `save_failed` signal emitted on error |
| `design/gdd/master-gdd.md` | EconomyService | TR-econ-003: IAP catalog and economy state persists across sessions | `[economy]` section stores all currency balances; restored on load |
| `design/gdd/master-gdd.md` | MetaProgression | TR-meta-004: 6 chapters with per-chapter material balance tracked independently | `chapter_materials_json` in `[meta]` section stores per-chapter material dict |
| `design/gdd/master-gdd.md` | MetaProgression | TR-meta-001: Permanent progression persists across sessions | `[meta]` section with account level, upgrade states, chapter unlocks |

## Related

- ADR-002: Autoload initialization order (SaveService `call_deferred` pattern and signal contract)
- ADR-004: Data Resource structure (Resources are runtime data, not save data — distinct concerns)
- `docs/architecture/architecture.md` § Save/Load Path

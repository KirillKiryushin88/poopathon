# ADR-002: Autoload Initialization Order and Inter-Autoload Communication

## Status

Accepted

## Date

2026-04-24

## Last Verified

2026-04-24

## Decision Makers

Technical Director

## Summary

Godot instantiates autoloads in project settings declaration order, creating hidden initialization dependencies when autoloads call each other directly during `_ready()`; uncontrolled cross-autoload method calls also make unit testing impossible. Autoloads are declared in a fixed order (`GameSession → MetaProgression → EconomyService → SaveService → PlatformBridge → AudioRouter`) and communicate exclusively through signals — no autoload may call methods on another autoload directly.

## Engine Compatibility

| Field | Value |
|-------|-------|
| **Engine** | Godot 4.6 |
| **Domain** | Core / Scripting |
| **Knowledge Risk** | LOW — autoload instantiation order by declaration is stable Godot behaviour since 4.0 |
| **References Consulted** | `docs/engine-reference/godot/breaking-changes.md`, `docs/architecture/architecture.md` § Initialization Order |
| **Post-Cutoff APIs Used** | `call_deferred("_do_load")` — standard GDScript, no version dependency |
| **Verification Required** | Confirm `SaveService._do_load()` fires after all other autoloads complete `_ready()` by logging timestamps in debug builds; confirm no circular signal connection warnings in Output panel on startup |

> **Note**: If Knowledge Risk is MEDIUM or HIGH, this ADR must be re-validated if the
> project upgrades engine versions. Flag it as "Superseded" and write a new ADR.

## ADR Dependencies

| Field | Value |
|-------|-------|
| **Depends On** | ADR-001 (SceneManager is the last autoload; its position in the order depends on ADR-001 being settled) |
| **Enables** | ADR-005 (SaveService deferred-load pattern is defined here), all autoload implementations |
| **Blocks** | All autoload stories; SaveService load-on-startup story |
| **Ordering Note** | This ADR must be Accepted before any autoload is implemented |

## Context

### Problem Statement

Godot 4.x instantiates autoloads in the exact order they appear in the `[autoload]` section of `project.godot`. Each autoload's `_ready()` fires sequentially before the next autoload is instantiated. If `SaveService._ready()` calls `GameSession.apply_save_data()` directly but `GameSession` has not yet run its own `_ready()`, the call may target a partially-initialized object, causing silent data corruption or crashes. The project needs a binding contract for the initialization order and a communication protocol that prevents these dependencies from forming organically over time.

### Current State

Pre-production; no autoloads exist. Default Godot behaviour (arbitrary ordering, direct method calls) is the baseline anti-pattern to prevent.

### Constraints

- **Engine**: Godot instantiates autoloads sequentially in declaration order; later autoloads can safely reference earlier ones in `_ready()`, but not vice versa
- **Architecture**: `SaveService` must call `apply_save_data` on `GameSession`, `MetaProgression`, and `EconomyService` — these three must be fully ready before `SaveService` loads
- **Testing**: Direct method calls between autoloads create hard coupling that prevents isolated unit testing
- **Team**: Signal-only inter-autoload communication must be enforced by convention (no runtime enforcement mechanism in Godot)

### Requirements

- All autoloads must be ready before `SaveService` calls `load_game()`
- `SaveService.load_game()` must fire via `call_deferred` to ensure all `_ready()` functions have completed
- Each autoload must expose a `ready` signal emitted at the end of its own `_ready()` so dependent systems can sequence against it
- No autoload may call instance methods on another autoload during `_ready()` or at any time during normal operation — signals only
- The order must be explicitly documented and enforced by project settings declaration

## Decision

Autoloads are declared in `project.godot` in this exact order. This order is immutable — changing it requires a new ADR.

```
1. GameSession
2. MetaProgression
3. EconomyService
4. SaveService
5. PlatformBridge
6. AudioRouter
7. CombatEventBus
8. SceneManager
```

`SaveService._ready()` defers its load call via `call_deferred("_do_load")`. All inter-autoload communication uses signals only. Each autoload emits its own `initialized` signal at the end of `_ready()`.

### Architecture

```
project.godot [autoload] declaration order
─────────────────────────────────────────
1. GameSession          _ready() → emit initialized
2. MetaProgression      _ready() → emit initialized
3. EconomyService       _ready() → emit initialized
4. SaveService          _ready() → call_deferred("_do_load")
                        _do_load() → load_game()
                                     → GameSession.apply_save_data()    [via signal]
                                     → MetaProgression.apply_save_data() [via signal]
                                     → EconomyService.apply_save_data()  [via signal]
                                     → emit load_completed
5. PlatformBridge       _ready() → init AdsBridge/BillingBridge → emit initialized
6. AudioRouter          _ready() → configure audio buses → emit initialized
7. CombatEventBus       _ready() → (signal-only relay, no init needed) → emit initialized
8. SceneManager         _ready() → call_deferred → load initial scene

Signal-only inter-autoload communication:
─────────────────────────────────────────
EconomyService ──balance_changed──► HUD (via CombatEventBus subscription)
GameSession ────pressure_changed──► HUD, UltimateSystem
SaveService ─────load_completed───► (any autoload needing post-load init)
SaveService ─────save_failed──────► PlatformBridge (could log analytics)
```

### Key Interfaces

```gdscript
# Every autoload exposes this signal pattern:
signal initialized()

# Canonical _ready() pattern for all autoloads:
func _ready() -> void:
    # ... own initialization only ...
    initialized.emit()

# SaveService — the ONE exception that defers its load:
class_name SaveService
extends Node

signal initialized()
signal save_completed()
signal load_completed(save_data: Dictionary)
signal save_failed(error: String)

func _ready() -> void:
    initialized.emit()
    call_deferred("_do_load")

func _do_load() -> void:
    # All autoloads have completed _ready() by the time this fires.
    load_game()

func save_game() -> void: pass
func load_game() -> void: pass

# FORBIDDEN — no autoload may do this:
# func _ready() -> void:
#     GameSession.apply_save_data(data)   ← FORBIDDEN: direct cross-autoload call
#     MetaProgression.get_account_level() ← FORBIDDEN: direct cross-autoload call
```

### Implementation Guidelines

1. Open `project.godot` and declare autoloads in the exact order listed above under `[autoload]`. The order is the contract — document it in a comment in `project.godot`.
2. Every autoload `_ready()` must end with `initialized.emit()`. Latecomers that need post-init wiring use `call_deferred("_post_init")` before the emit.
3. `SaveService._ready()` calls `call_deferred("_do_load")` and then immediately emits `initialized`. The `_do_load` method runs on the next frame after all `_ready()` calls are complete.
4. When `SaveService._do_load()` calls `load_game()`, it emits `load_completed(save_data)`. Each data-owning autoload (`GameSession`, `MetaProgression`, `EconomyService`) connects to `SaveService.load_completed` in its own `_ready()` and applies its slice of the data.
5. Cross-autoload signals must be connected in the **receiving** autoload's `_ready()`, not the emitting autoload. This is possible because earlier autoloads exist by the time later ones initialise.
6. `CombatEventBus` is a stateless signal relay — it has no `_ready()` logic and its `initialized` emit is a formality.
7. `SceneManager` uses `call_deferred` in `_ready()` to load the initial scene, ensuring all autoloads are ready before any scene script runs.

## Alternatives Considered

### Alternative 1: Initialization manager singleton that sequences autoloads manually

- **Description**: A master "BootManager" autoload that holds references to all others and calls `init()` methods in sequence using `await`
- **Pros**: Explicit sequencing; can use `await` for async init steps
- **Cons**: Requires every autoload to expose a public `init()` method; BootManager becomes a god object with knowledge of all other autoloads; circular dependency risk
- **Estimated Effort**: 2x chosen approach
- **Rejection Reason**: Increases coupling between autoloads; `call_deferred` on SaveService achieves the same sequencing goal with zero extra infrastructure

### Alternative 2: Direct method calls with null checks

- **Description**: Allow direct cross-autoload method calls but add `if is_instance_valid(target)` guards
- **Pros**: Simpler code; no signal plumbing
- **Cons**: Null checks are error-prone; hides real initialization ordering bugs; makes unit testing impossible without instantiating the full autoload graph
- **Estimated Effort**: Same as chosen approach initially; higher maintenance cost
- **Rejection Reason**: Does not solve the root problem; creates false safety through guards

### Alternative 3: Resource-based configuration loaded before any autoload

- **Description**: Write all initial state to a `ConfigFile` on disk; each autoload reads its own slice independently with no inter-autoload communication
- **Pros**: Completely decoupled
- **Cons**: Every autoload must implement its own file I/O; inconsistent save format; no single-point save/load operation
- **Estimated Effort**: Higher (distributed I/O logic)
- **Rejection Reason**: Contradicts ADR-005 (single SaveService owns all I/O); ADR-005 and ADR-002 are co-designed

## Consequences

### Positive

- Initialization order is a documented, auditable contract — no hidden ordering bugs
- Signal-only communication makes each autoload independently unit-testable by connecting mock signal receivers
- `call_deferred` on `SaveService` guarantees all data owners are ready before load data is applied — no partial-init data corruption
- New autoloads added to the project have a clear convention to follow

### Negative

- Signal-only rule is a convention, not a language constraint — requires discipline and code review to enforce
- Connecting signals from earlier autoloads in later autoloads' `_ready()` requires knowing the order (documentation dependency)
- Async signal-based init is harder to trace in the debugger than a linear call stack

### Neutral

- Every autoload gains an `initialized` signal; most consumers will never use it, but it costs nothing
- The strict ordering means the order listed in this ADR must be updated if a new autoload with cross-autoload dependencies is added

## Risks

| Risk | Probability | Impact | Mitigation |
|------|------------|--------|-----------|
| Developer adds direct cross-autoload call | Medium | Medium — initialization bugs under specific conditions | Code review checklist; grep for `GameSession.` / `MetaProgression.` etc. in autoload scripts |
| `call_deferred` on `_do_load` fires before scene tree is ready | Very Low | High — NullReferenceException in load | Godot guarantees deferred calls fire after current frame's `_ready()` cascade; add assert in `_do_load` that checks `is_inside_tree()` |
| New autoload added without updating this ADR | Medium | Low — order confusion | ADR-002 version stamp in project.godot comment; `/story-done` checklist item |
| `load_completed` signal received before autoload connects | Low | Medium — save data not applied | All data-owning autoloads connect to `load_completed` in their own `_ready()`; SaveService defers load, so connection happens first |

## Performance Implications

| Metric | Before | Expected After | Budget |
|--------|--------|---------------|--------|
| CPU (startup time) | Baseline | +1 frame overhead from `call_deferred` | Negligible (<1ms) |
| Memory | Baseline | No change | No change |
| Load Time | Baseline | Identical | No change |
| Signal connection count at startup | N/A | ~12 cross-autoload signal connections | Negligible |

## Migration Plan

Pre-production; no existing autoloads to migrate.

1. Create each autoload script with `initialized` signal and the `_ready()` pattern above
2. Edit `project.godot` to declare autoloads in the specified order with explanatory comment
3. Implement `SaveService._do_load()` deferred pattern
4. Each data autoload connects `SaveService.load_completed` in its own `_ready()`
5. Integration test: add debug logging to all `_ready()` and `_do_load()` calls; confirm order in Output panel on startup

**Rollback plan**: If signal-only communication proves too indirect for debugging, introduce a single `AutoloadBus` helper that provides typed accessor methods — but this should be a new ADR, not a silent rollback.

## Validation Criteria

- [ ] On startup, Output panel logs show `_ready()` calls in the declared order with no out-of-order autoload references
- [ ] `SaveService._do_load()` fires after all 7 preceding autoloads have emitted `initialized`
- [ ] `grep -r "GameSession\." autoloads/` (excluding SaveService's signal connection) returns zero direct method calls
- [ ] Unit tests for `EconomyService` run in isolation without requiring `GameSession` or `MetaProgression` to be instantiated
- [ ] No `null` reference errors in Output panel during cold start on Android

## GDD Requirements Addressed

| GDD Document | System | Requirement | How This ADR Satisfies It |
|-------------|--------|-------------|--------------------------|
| `design/gdd/master-gdd.md` | SaveService | TR-save-002: `SaveService.load_game()` called via `call_deferred` to guarantee all autoloads complete `_ready()` first | This ADR mandates the `call_deferred("_do_load")` pattern in `SaveService._ready()` |
| `design/gdd/master-gdd.md` | EconomyService | TR-econ-001: 4 currency types managed exclusively by EconomyService | Signal-only rule ensures EconomyService state is never mutated by direct method calls from other autoloads |
| `design/gdd/master-gdd.md` | MetaProgression | TR-meta-001: Progression persists across sessions via SaveService | Guaranteed by the load order: `MetaProgression` connects to `SaveService.load_completed` and applies save data in its handler |

## Related

- ADR-001: Scene management (SceneManager is autoload #8; its position in the order is defined here)
- ADR-005: Save format (SaveService implementation uses `_do_load` pattern defined here)
- `docs/architecture/architecture.md` § Initialization Order
- `docs/architecture/architecture.md` § Save/Load Path

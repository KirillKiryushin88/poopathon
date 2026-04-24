# ADR-003: Signal Bus vs Direct Signals

## Status

Accepted

## Date

2026-04-24

## Last Verified

2026-04-24

## Decision Makers

Technical Director

## Summary

High-frequency per-frame combat events (enemy takes damage, projectile fires) have performance overhead when routed through a global signal relay; but cross-scene, cross-layer events need decoupling that direct signals cannot provide without creating forbidden layer violations. Use a hybrid: direct GDScript signals for tight owner-to-observer relationships within the same scene layer, and a `CombatEventBus` autoload for all cross-layer and cross-scene events.

## Engine Compatibility

| Field | Value |
|-------|-------|
| **Engine** | Godot 4.6 |
| **Domain** | Core / Scripting |
| **Knowledge Risk** | LOW — GDScript `signal` keyword and autoload signal relay are stable since Godot 4.0 |
| **References Consulted** | `docs/architecture/architecture.md` § Signal/Event Path, § API Boundaries |
| **Post-Cutoff APIs Used** | None — standard GDScript signals |
| **Verification Required** | Profile signal dispatch cost of `CombatEventBus.enemy_died` with 40 simultaneous subscribers in a stress test scene on device; confirm <0.5ms overhead per frame |

> **Note**: If Knowledge Risk is MEDIUM or HIGH, this ADR must be re-validated if the
> project upgrades engine versions. Flag it as "Superseded" and write a new ADR.

## ADR Dependencies

| Field | Value |
|-------|-------|
| **Depends On** | ADR-002 (CombatEventBus is an autoload; its position in the init order is defined there) |
| **Enables** | All Core system implementations, HUD scripts, VFXSystem |
| **Blocks** | EnemyBase, TowerBase, WaveManager, HUD, VFXSystem stories |
| **Ordering Note** | Must be Accepted before any script that emits or subscribes to combat events is written |

## Context

### Problem Statement

The project has two competing needs. First: high-frequency combat events (an enemy taking damage can happen 20–40 times per second at 40 active enemies) must be dispatched as cheaply as possible — a global signal bus with N subscribers adds unnecessary overhead. Second: the HUD, VFXSystem, EconomyService, and WaveManager all need to react to `enemy_died`, but they live in different scene layers; a direct signal from `EnemyBase` to HUD would require HUD to hold a reference to every enemy — a forbidden cross-layer dependency. The project must define exactly which events use which mechanism and enforce the boundary rules.

### Current State

Pre-production; no signal connections exist. The risk is that without a defined contract, developers will either (a) wire HUD directly to enemy nodes creating layer violations, or (b) route all events through a bus creating per-frame overhead.

### Constraints

- **Architecture layers** (from `architecture.md`): Foundation → Core → Feature → Presentation. Higher layers may depend on lower, but never reverse.
- **Performance**: 40 active enemies; each potentially emitting `hp_changed` per hit per frame. Must not burn significant CPU on signal dispatch overhead.
- **Decoupling**: HUD scripts must contain zero combat logic. HUD reads all state via signals only (TR-ui-003).
- **Testability**: Core systems must be testable without a scene tree (no presentation dependencies).

### Requirements

- Cross-layer events (Core → Presentation, Core → Foundation) must not create direct node references across layers
- High-frequency per-entity events (damage per hit) must use the fastest available signal path
- `CombatEventBus` must be stateless — it relays signals and holds no game state
- No Feature-layer or Presentation-layer script may call methods on Core layer nodes directly
- The set of events on `CombatEventBus` must be explicitly enumerated and documented; ad-hoc additions require ADR amendment

## Decision

Hybrid signal model with two explicit categories:

**Category A — Direct signals** (GDScript `signal` on the emitting node):
Used for tight owner-to-observer relationships within the same scene layer where both nodes are alive at the same time. The observer holds a direct reference to the emitter or is a sibling in the same scene.

**Category B — CombatEventBus** (autoload signal relay):
Used for all cross-layer events, cross-scene events, or events where the subscriber set is unknown at authoring time.

### Architecture

```
DIRECT SIGNALS (Category A — same-layer, tight coupling)
─────────────────────────────────────────────────────────
EnemyBase.died             → EnemySystem._on_enemy_died()
EnemyBase.hp_changed       → (no cross-layer subscription)
EnemyBase.reached_throne   → EnemySystem._on_reached_throne()
TowerBase.attack_fired     → (within TowerSystem only)
WaveManager.wave_completed → CampaignManager._on_wave_completed()
WaveManager.all_waves_completed → CampaignManager._on_all_waves_completed()

COMBATEVENTBUS (Category B — cross-layer relay)
─────────────────────────────────────────────────────────
CombatEventBus (Autoload, signal-only, no state)
    ├── enemy_died(enemy, position)        ← EnemySystem re-emits after own handler
    │       → WaveManager (decrement alive count)
    │       → EconomyService (soft currency drop)
    │       → GameSession (pressure meter +5 cannon / +2 tower)
    │       → VFXSystem (death VFX)
    │       → MetaProgression (kill counter)
    │
    ├── tower_fired(tower, target, damage_type)
    │       → VFXSystem (projectile trail VFX)
    │       → AudioRouter (fire SFX)
    │
    ├── hit_landed(target, amount, damage_type)
    │       → VFXSystem (hit impact VFX)
    │
    ├── pressure_gained(amount, source)
    │       → HUD (pressure bar update)
    │
    ├── ultimate_activated(ultimate_id)
    │       → EnemySystem (apply area effect)
    │       → VFXSystem (ultimate VFX)
    │       → AudioRouter (ultimate SFX)
    │
    ├── element_tag_applied(target, tag)
    │       → (synergy detection in TowerSystem)
    │
    ├── element_synergy_triggered(combo, targets)
    │       → VFXSystem (combo VFX)
    │       → EconomyService (bonus currency)
    │
    ├── boss_phase_changed(boss_id, phase)
    │       → HUD (boss health bar phase indicator)
    │       → AudioRouter (boss theme push)
    │
    └── boss_died(boss_id, position)
            → CampaignManager (chapter material reward)
            → VFXSystem (finisher VFX)
            → AudioRouter (boss theme pop)

LAYER DEPENDENCY RULES
─────────────────────────────────────────────────────────
Foundation ←── Core ←── Feature ←── Presentation
    ↑              ↑          ↑
    └──────────────┴──────────┴── May listen to CombatEventBus
                                   May NOT call Core methods directly
```

### Key Interfaces

```gdscript
# CombatEventBus — autoload, signal-only, no methods, no state
class_name CombatEventBus
extends Node

# Cross-layer combat events:
signal enemy_died(enemy: EnemyBase, position: Vector2)
signal enemy_reached_throne(enemy: EnemyBase)
signal tower_fired(tower: TowerBase, target: EnemyBase, damage_type: DamageType)
signal hit_landed(target: EnemyBase, amount: float, damage_type: DamageType)
signal element_tag_applied(target: EnemyBase, tag: ElementTag)
signal element_synergy_triggered(combo: StringName, targets: Array[EnemyBase])
signal pressure_gained(amount: float, source: StringName)
signal ultimate_activated(ultimate_id: StringName)
signal boss_phase_changed(boss_id: StringName, phase: int)
signal boss_died(boss_id: StringName, position: Vector2)

# EnemySystem — bridges direct signals to CombatEventBus
class_name EnemySystem
extends Node

func _on_enemy_died(enemy: EnemyBase, position: Vector2) -> void:
    # Handle own bookkeeping first (remove from active list, pool recycle)
    _active_enemies.erase(enemy)
    # Then re-emit to bus for cross-layer subscribers:
    CombatEventBus.enemy_died.emit(enemy, position)

# HUD — example cross-layer subscription (Presentation layer)
# HUD subscribes to CombatEventBus in _ready(); never holds enemy refs
func _ready() -> void:
    CombatEventBus.pressure_gained.connect(_on_pressure_gained)
    GameSession.pressure_changed.connect(_on_pressure_changed)
    # FORBIDDEN: EnemyBase.died.connect(...)  — direct ref across layers
```

### Implementation Guidelines

1. `CombatEventBus` is an autoload with zero methods and zero state. If a developer adds a method or variable to `CombatEventBus`, reject in code review.
2. The bridge pattern: Core nodes emit direct signals to their immediate owner (e.g., `EnemyBase.died → EnemySystem`). The system (e.g., `EnemySystem`) handles its own bookkeeping, then re-emits to `CombatEventBus`. This ensures Core-layer cleanup happens before cross-layer subscribers react.
3. High-frequency events (`hp_changed`, per-projectile `attack_fired` per frame) must NOT be on `CombatEventBus` unless a cross-layer subscriber genuinely needs them. Check: does any Presentation or Foundation layer node need `hp_changed` per hit? If yes, throttle the signal (debounce to 4 Hz for UI updates).
4. HUD connects to `CombatEventBus` and autoload signals (`GameSession`, `EconomyService`) in `_ready()`. HUD never holds references to any Core layer node.
5. VFXSystem connects to `CombatEventBus` in `_ready()` and plays effects based on signal parameters only. VFXSystem never inspects enemy node state directly.
6. When adding a new event to `CombatEventBus`, update this ADR's signal list and the `tr-registry.yaml` coverage field.
7. `DamageType`, `ElementTag` are enums defined in a global `CombatTypes.gd` autoloaded class so they are accessible from all layers without import coupling.

## Alternatives Considered

### Alternative 1: Pure global signal bus for all events

- **Description**: All combat events (including per-hit `hp_changed`) route through a single `EventBus` autoload
- **Pros**: Completely decoupled; any script can subscribe to any event; simple mental model
- **Cons**: At 40 enemies with 3–5 hits/second each, `hp_changed` alone generates 120–200 signal dispatches/second through the bus with all subscribers receiving them; profiling Godot signal dispatch cost at this volume shows measurable overhead; harder to trace event origin in debugger
- **Estimated Effort**: Same as chosen approach
- **Rejection Reason**: Performance overhead for high-frequency events; bus becomes a dumping ground with no clear ownership

### Alternative 2: Direct signals only (no bus)

- **Description**: All signals are direct GDScript signals on the emitting node; HUD holds references to relevant game nodes
- **Pros**: Maximum performance; easiest to trace in debugger
- **Cons**: HUD must hold references to `WaveManager`, `EnemySystem`, etc. — violates layer rules; when scenes change, these references break; violates TR-ui-003 ("HUD scripts contain zero combat logic")
- **Estimated Effort**: Lower initial setup, higher maintenance
- **Rejection Reason**: Creates forbidden cross-layer dependencies; HUD breaks when gameplay scene is swapped out (contradicts ADR-001 persistent HUD)

### Alternative 3: Observer pattern via a typed Dictionary registry

- **Description**: EventBus stores `Dictionary[StringName, Array[Callable]]`; systems register callables keyed by event name
- **Pros**: Fully dynamic; events can be added without modifying bus class
- **Cons**: Loses GDScript type checking; no IDE autocomplete; runtime-only errors; essentially reimplements Godot signals in userland
- **Estimated Effort**: Higher
- **Rejection Reason**: Godot signals already provide the observer pattern natively; no benefit to reinventing them

## Consequences

### Positive

- Cross-layer decoupling: HUD, VFXSystem, EconomyService react to combat events without holding references to enemy/tower nodes
- High-frequency intra-system events use direct signals — no overhead from unnecessary subscribers
- `CombatEventBus` is a single auditable list of all cross-system events in the game
- Each Core system is independently testable by connecting mock signal receivers without the full autoload graph
- Layer rules are enforceable: grep for Core class names in Presentation scripts

### Negative

- Two-category mental model requires developers to consciously decide which type to use for each new event
- The EnemySystem bridge pattern (handle own bookkeeping, then re-emit to bus) adds one indirection step that is easy to forget
- Cross-layer subscriptions connected in `_ready()` must be disconnected if the subscriber scene is freed mid-session (deferred cleanup required)

### Neutral

- `DamageType` and `ElementTag` enums must be globally accessible — requires a shared types autoload or global const file
- The explicit signal list on `CombatEventBus` means adding a new event requires touching this ADR — which is a feature (auditable), not a bug

## Risks

| Risk | Probability | Impact | Mitigation |
|------|------------|--------|-----------|
| Developer routes high-frequency event through CombatEventBus | Medium | Medium — frame time spike | Code review; profile pass before each milestone |
| HUD connects directly to enemy node | Medium | Medium — reference breaks on scene swap | Layer rule linting: grep for `EnemyBase` / `TowerBase` in `scenes/ui/` |
| CombatEventBus gains state or methods | Low | Low — defeats the relay pattern | Code review; CI check for variable declarations in CombatEventBus.gd |
| Signal subscriber count grows unbounded | Low | Low — minor GC pressure | Cap: any single CombatEventBus signal should have ≤8 subscribers; audit quarterly |

## Performance Implications

| Metric | Before | Expected After | Budget |
|--------|--------|---------------|--------|
| CPU (per CombatEventBus.enemy_died dispatch, 40 enemies/frame) | N/A | ~0.01ms per dispatch × 40 = 0.4ms/frame | <0.5ms/frame for all bus dispatches |
| CPU (direct EnemyBase.died dispatch) | N/A | ~0.002ms per dispatch | Negligible |
| Memory (CombatEventBus subscriptions) | N/A | ~12 signal × 8 subscribers = ~96 Callable objects | Negligible |
| Signal dispatch per second (peak) | N/A | ~200 (40 enemies × 5 events/sec) | <300/sec ceiling |

## Migration Plan

Pre-production; no existing signal connections to migrate.

1. Create `res://autoloads/CombatEventBus.gd` with signal declarations only (no methods, no vars)
2. Create `res://autoloads/CombatTypes.gd` with `DamageType` and `ElementTag` enums
3. Register `CombatEventBus` as autoload #7 in `project.godot` (per ADR-002 order)
4. Implement `EnemySystem._on_enemy_died()` bridge pattern as the canonical example
5. Implement HUD `_ready()` subscribing to `CombatEventBus` signals (no direct Core refs)

**Rollback plan**: If `CombatEventBus` proves too indirect for debugging, introduce typed helper methods on the bus (e.g., `CombatEventBus.emit_enemy_died(enemy, pos)`) — but this requires an ADR amendment, not a silent change.

## Validation Criteria

- [ ] `grep -r "EnemyBase\|TowerBase\|WaveManager\|EnemySystem" scenes/ui/` returns zero results (no cross-layer direct refs in Presentation)
- [ ] `CombatEventBus.gd` contains zero `var` declarations and zero `func` declarations (signal declarations only)
- [ ] Frame profiler shows total signal dispatch cost ≤0.5ms/frame during peak wave (40 enemies, max fire rate)
- [ ] HUD correctly updates pressure bar and economy displays during gameplay without direct Core node references
- [ ] All cross-layer events trigger correctly in an integration test with mock subscribers on CombatEventBus

## GDD Requirements Addressed

| GDD Document | System | Requirement | How This ADR Satisfies It |
|-------------|--------|-------------|--------------------------|
| `design/gdd/master-gdd.md` | CentralTower | TR-central-003: Cannon projectile trajectory follows aim direction; no auto-aim | `tower_fired` on CombatEventBus carries `damage_type` but trajectory logic stays in Core layer; Presentation cannot call Core aim methods |
| `design/gdd/master-gdd.md` | EnemySystem | TR-enemy-003: Sanitizer Exorcist wind-up animation is a player-punishable window | `EnemyBase` emits direct signal for animation state; VFXSystem subscribes via CombatEventBus re-emit from EnemySystem |
| `design/gdd/master-gdd.md` | WaveManager | TR-wave-002: WaveManager exposes `fast_forward(enabled: bool)` | `WaveManager.fast_forward()` is a direct call from HUD — the HUD connects via GameSession signal which WaveManager subscribes to; no cross-layer direct call |
| `design/gdd/master-gdd.md` | HUD | TR-ui-003: HUD scripts contain zero combat logic; reads all state via signals | This ADR mandates HUD subscribes only to CombatEventBus and autoload signals |

## Related

- ADR-001: Scene management (persistent HUD depends on signal subscriptions surviving scene swaps)
- ADR-002: Autoload order (CombatEventBus is autoload #7)
- ADR-006: VFX constraints (VFXSystem subscribes to CombatEventBus for all VFX trigger events)
- `docs/architecture/architecture.md` § Signal/Event Path
- `docs/architecture/architecture.md` § API Boundaries — CombatEventBus

# ADR-001: Scene Management Strategy

## Status

Accepted

## Date

2026-04-24

## Last Verified

2026-04-24

## Decision Makers

Technical Director

## Summary

Portrait-mobile TD requires a persistent HUD that survives in-game scene transitions; mid-range Android devices stutter when loading scenes on the main thread. Use a single persistent root scene (`Main.tscn`) with a `SceneManager` autoload that loads/unloads child scenes via `add_child`/`remove_child` using `ResourceLoader.load_threaded_request/get` for non-blocking loads — `get_tree().change_scene_to_file()` is never used for in-game transitions.

## Engine Compatibility

| Field | Value |
|-------|-------|
| **Engine** | Godot 4.6 |
| **Domain** | Core / Scripting |
| **Knowledge Risk** | MEDIUM — `ResourceLoader.load_threaded_*` API verified against Godot 4.x; behaviour confirmed stable through 4.6 |
| **References Consulted** | `docs/engine-reference/godot/breaking-changes.md`, `docs/architecture/architecture.md` |
| **Post-Cutoff APIs Used** | `ResourceLoader.load_threaded_request(path, type_hint, use_sub_threads)`, `ResourceLoader.load_threaded_get_status(path)`, `ResourceLoader.load_threaded_get(path)` — all available since Godot 4.0 and confirmed stable in 4.6 |
| **Verification Required** | Confirm `load_threaded_*` returns correct `THREAD_LOAD_LOADED` status on Android mid-range device; verify `Main.tscn` HUD nodes persist across child scene swaps without signal disconnection |

> **Note**: If Knowledge Risk is MEDIUM or HIGH, this ADR must be re-validated if the
> project upgrades engine versions. Flag it as "Superseded" and write a new ADR.

## ADR Dependencies

| Field | Value |
|-------|-------|
| **Depends On** | None |
| **Enables** | ADR-002 (SceneManager is listed as last autoload, depends on this scene structure), ADR-003 (HUD signal subscription model assumes persistent HUD node), ADR-006 (VFXSystem assumes persistent scene context) |
| **Blocks** | SceneManager implementation, LevelLoader implementation, all scene transition stories |
| **Ordering Note** | Must be Accepted before any story touching scene transitions or SceneManager is started |

## Context

### Problem Statement

Godot's built-in `get_tree().change_scene_to_file()` performs a full tree reload — all nodes including autoload scene children are freed and re-instantiated. This causes two critical problems: (1) the persistent HUD (lives at root level, must show across gameplay/result/meta transitions) would be destroyed and re-created on every scene change, losing any in-flight animation state; (2) full-tree reloads on mid-range Android (2–3GB RAM) cause 200–400ms hitches at scene boundary. The project must decide its scene loading approach before any story that crosses a scene boundary can be implemented.

### Current State

Pre-production; no scene management code exists. Default Godot behaviour (`change_scene_to_file`) is the baseline.

### Constraints

- **Engine**: `change_scene_to_file` reloads the entire scene tree including all autoloads' scene children — this is documented Godot 4.x behaviour
- **Platform**: Android mid-range devices (Samsung A-series) run GC and shader compilation during scene loads; blocking the main thread causes visible hitches
- **Layout**: Portrait-locked, single-screen HUD with health/pressure/economy widgets that must not flash or reinitialise between gameplay and result screens
- **Team**: Small team; must use standard Godot APIs, no custom C++ modules

### Requirements

- HUD nodes must survive all in-game scene transitions without reinitialisation
- Scene loads must not block the main thread (no frame hitches >16ms)
- Transition system must support named transition effects (fade, instant)
- Scene stack must support push/pop for overlays (pause menu, settings)
- Only `SaveService` and `SceneManager` may initiate scene transitions
- Initial boot sequence may use `change_scene_to_file` for the splash screen only

## Decision

Use a single persistent root scene `res://scenes/Main.tscn` with the following structure:
- `Main` (Node) — never replaced; always the scene tree root
  - `HUD` (CanvasLayer) — persistent; instantiated in Main, never swapped
  - `SceneContainer` (Node) — child scenes attached/detached here
  - `TransitionLayer` (CanvasLayer, z=100) — transition overlays (fade rect, etc.)

`SceneManager` autoload manages all scene transitions using `ResourceLoader.load_threaded_request/get`. `change_scene_to_file` is called exactly once during the boot sequence (splash → Main.tscn), then never again.

### Architecture

```
Main.tscn (root, persistent)
├── HUD (CanvasLayer, layer=10)         ← always alive, subscribes to autoload signals
│   ├── PressureMeter
│   ├── EconomyDisplay
│   └── UltimateButton
├── SceneContainer (Node)               ← active child scene lives here
│   └── [current scene: GameplayScene | MetaScreen | ResultScreen | ...]
└── TransitionLayer (CanvasLayer, layer=100)
    └── FadeRect (ColorRect, modulate.a=0)

SceneManager (Autoload)
    ├── _current_scene: Node            ← ref to active child in SceneContainer
    ├── _load_path: String              ← pending threaded load target
    └── _scene_stack: Array[Node]       ← push/pop stack for overlays

ResourceLoader (Godot built-in)
    └── load_threaded_request(path)     ← called from SceneManager
        └── load_threaded_get(path)     ← polled in _process until LOADED
```

### Key Interfaces

```gdscript
class_name SceneManager
extends Node

signal scene_changed(new_scene_path: String)
signal transition_started()
signal transition_finished()

# Replace current scene — non-blocking load
func change_scene(path: String, transition: StringName = &"fade") -> void:
    _start_transition(transition)
    ResourceLoader.load_threaded_request(path)
    _load_path = path
    # _process polls load_threaded_get_status until THREAD_LOAD_LOADED
    # then: remove current, instantiate new, add_child to SceneContainer

# Push overlay on top of current scene (pause menu, settings)
func push_scene(path: String) -> void: pass

# Pop overlay, return to scene underneath
func pop_scene() -> void: pass

func get_current_scene_path() -> String: pass

# Internal — called from _process when load completes
func _on_load_complete(packed: PackedScene) -> void:
    var old := _current_scene
    var new_scene := packed.instantiate()
    $SceneContainer.add_child(new_scene)
    _current_scene = new_scene
    if old:
        old.queue_free()
    _finish_transition()
    scene_changed.emit(packed.resource_path)
```

### Implementation Guidelines

1. `Main.tscn` must be the project's main scene in Project Settings → Application → Run → Main Scene.
2. The initial boot sequence in `Main._ready()` calls `SceneManager.change_scene("res://scenes/ui/MainMenu.tscn", &"instant")` via `call_deferred` to display the first UI scene.
3. `SceneManager._process()` checks `ResourceLoader.load_threaded_get_status(path)` each frame. Only swap scenes when status is `THREAD_LOAD_LOADED`. On `THREAD_LOAD_FAILED`, emit `scene_load_failed` signal and log error.
4. Transition overlays (fade rect) live in `TransitionLayer`. `_start_transition` tweens `FadeRect.modulate.a` to 1.0; `_finish_transition` tweens back to 0.0.
5. The `push_scene` / `pop_scene` stack is for overlays only (pause, settings, confirm dialogs). These load synchronously with `ResourceLoader.load` since they are small (<50KB .tscn).
6. No script outside `SceneManager` may call `get_tree().change_scene_to_file()`. Enforce via code review checklist in `/story-done`.
7. `use_sub_threads = true` in `load_threaded_request` for level scenes (large). `false` for small UI scenes.

## Alternatives Considered

### Alternative 1: `get_tree().change_scene_to_file()` everywhere

- **Description**: Standard Godot single-scene approach; each transition calls `change_scene_to_file` which reloads the full tree
- **Pros**: Simplest API; zero boilerplate; works out of the box
- **Cons**: Destroys HUD on every transition (flicker, loss of animation state); full tree reload causes 200–400ms hitches on Android; autoload scene children reset
- **Estimated Effort**: Baseline (no extra code)
- **Rejection Reason**: Incompatible with persistent HUD requirement and mobile performance budget

### Alternative 2: Pure sub-scene swap without SceneManager autoload

- **Description**: `Main.tscn` manages its own child swap logic inline in a `Main.gd` script
- **Pros**: Fewer abstraction layers; easier to trace in debugger
- **Cons**: `Main.gd` becomes a god-script; cannot be called from other autoloads; push/pop for overlays becomes ad-hoc
- **Estimated Effort**: Similar to chosen approach
- **Rejection Reason**: Autoload placement allows any system (e.g., `CampaignManager`) to trigger transitions without coupling to scene hierarchy

### Alternative 3: GDNative / C++ custom scene loader

- **Description**: Write a C++ extension for async scene loading
- **Pros**: Maximum control
- **Cons**: No C++ expertise on team; `ResourceLoader.load_threaded_*` already provides async loading natively
- **Estimated Effort**: 5–10x chosen approach
- **Rejection Reason**: No benefit over built-in threaded loader for this use case

## Consequences

### Positive

- HUD nodes persist across all scene transitions — no flicker, no state loss
- Background thread loading eliminates main-thread hitches during scene transitions on Android
- `SceneManager` provides a single, auditable chokepoint for all scene transitions
- Push/pop overlay stack handles pause and settings cleanly without scene destruction
- Transition effects (fade, instant) are centrally controlled

### Negative

- Slightly more boilerplate than vanilla `change_scene_to_file`
- `SceneManager._process()` polling adds a small per-frame cost during loads (negligible outside load windows)
- Developers must remember to never call `change_scene_to_file` — requires enforcement via code review

### Neutral

- `Main.tscn` is always the project's "main scene" — the entry point never changes
- Scene paths are strings — typos cause runtime errors rather than compile errors (mitigated by constant definitions in `SceneManager`)

## Risks

| Risk | Probability | Impact | Mitigation |
|------|------------|--------|-----------|
| Developer calls `change_scene_to_file` by mistake | Medium | High — breaks HUD persistence | Add forbidden API to `/story-done` checklist; lint grep in CI |
| Threaded load fails silently on Android | Low | High — black screen | Always check `THREAD_LOAD_FAILED` status and emit `scene_load_failed`; show error dialog |
| Memory leak if old scene not freed | Low | Medium — OOM on device | Confirm `queue_free()` called on old scene; scene_changed signal triggers memory check in debug builds |
| Scene stack grows unbounded (push without pop) | Low | Low | Cap stack depth at 5; assert in push_scene |

## Performance Implications

| Metric | Before | Expected After | Budget |
|--------|--------|---------------|--------|
| CPU (scene transition hitch) | 200–400ms (change_scene_to_file) | <16ms (async, background thread) | <16ms |
| Memory (double-loaded scene) | N/A | ~5–15MB peak during load window | <20MB peak overhead |
| Load Time (gameplay scene) | Blocking | Background; player sees transition overlay | <2s on mid-range Android |
| HUD reinit per transition | Every transition | Zero | Zero |

## Migration Plan

Pre-production project; no existing scene management code to migrate.

1. Create `res://scenes/Main.tscn` with `HUD`, `SceneContainer`, `TransitionLayer` nodes
2. Set `Main.tscn` as Project Settings main scene
3. Implement `SceneManager` autoload with `change_scene`, `push_scene`, `pop_scene`
4. Implement `FadeRect` transition in `TransitionLayer`
5. Add `SceneManager` as last entry in Project Settings autoload list (after all data autoloads)

**Rollback plan**: If threaded loading proves unreliable on target devices, revert to synchronous `ResourceLoader.load()` (blocking) inside the same `SceneManager` API — the public interface does not change, only the internal loading mechanism.

## Validation Criteria

- [ ] HUD nodes (`PressureMeter`, `EconomyDisplay`, `UltimateButton`) remain in scene tree across 10 consecutive scene transitions in device testing
- [ ] No frame hitch >16ms during scene transition on Samsung Galaxy A34 (mid-range Android baseline)
- [ ] `grep -r "change_scene_to_file" res://` returns zero results outside `boot` context after implementation
- [ ] Push/pop overlay stack correctly restores underlying scene after pop
- [ ] `scene_load_failed` signal fires and an error dialog appears when a non-existent path is passed to `change_scene`

## GDD Requirements Addressed

| GDD Document | System | Requirement | How This ADR Satisfies It |
|-------------|--------|-------------|--------------------------|
| `design/gdd/master-gdd.md` | SaveService | TR-save-001: SaveService serializes state into a single save | SceneManager triggers `SaveService.save_game()` on level-end transitions, ensuring save happens before scene swap |
| `design/gdd/master-gdd.md` | Platform | TR-plat-001/002: Portrait-locked layout; HUD survives transitions | Persistent HUD in `Main.tscn` is never destroyed; no portrait lock is broken by scene reload |

## Related

- ADR-002: Autoload initialization order (SceneManager is last autoload; depends on this root scene structure)
- ADR-003: Signal bus (HUD signal subscriptions assume persistent HUD node established by this ADR)
- `docs/architecture/architecture.md` § Initialization Order
- `docs/architecture/architecture.md` § Signal/Event Path

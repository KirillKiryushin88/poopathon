# Autoloads — Registration Order

Register these in **Project Settings → Autoload** in the exact order below.
Godot loads autoloads top-to-bottom; the order in `project.godot [autoload]` is authoritative (ADR-002).

| # | Name             | Path                                  | Notes                          |
|---|------------------|---------------------------------------|--------------------------------|
| 1 | GameSession      | res://src/autoloads/game_session.gd   | Session signals source of truth |
| 2 | MetaProgression  | res://src/autoloads/meta_progression.gd | M1 stub                      |
| 3 | EconomyService   | res://src/autoloads/economy_service.gd | Currency; restored by SaveService |
| 4 | SaveService      | res://src/autoloads/save_service.gd   | Loads via call_deferred        |
| 5 | SceneManager     | res://src/autoloads/scene_manager.gd  | Thread-based scene transitions |
| 6 | PlatformBridge   | res://src/autoloads/platform_bridge.gd | M1 stub                      |
| 7 | AudioRouter      | res://src/autoloads/audio_router.gd   | M1 stub                       |
| 8 | CombatEventBus   | res://src/autoloads/combat_event_bus.gd | Signal relay; last so all senders are ready |

## Rules (ADR-002)

- No autoload may **call methods** on another autoload during `_ready()`.
- Cross-autoload communication is **signals only**.
- SaveService uses `call_deferred("_load_game")` so EconomyService is fully initialized before data is restored.
- CombatEventBus is last — all combat senders (GameSession, towers, enemies) are already in the tree.

## Verification

Open **Debugger → Remote → Scene Tree** after launching the project. All 8 nodes must appear as direct children of `/root` in the listed order with zero errors in the Output panel.

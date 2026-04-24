# ADR-006: Mobile Renderer VFX Constraints

## Status

Accepted

## Date

2026-04-24

## Last Verified

2026-04-24

## Decision Makers

Technical Director

## Summary

Godot 4.6's Mobile renderer has specific capability differences from the Forward+ renderer that will silently break VFX if not designed against explicitly; glow changed to apply before tonemapping in Mobile renderer as of Godot 4.6, requiring device re-tuning. All VFX must use `GPUParticles2D`, observe a 200-particle hard budget enforced by `VFXSystem`, cap active decals at 20, limit fragment shaders to 4 texture samples per pass, and disable all unsupported features (screen-space reflections, SSAO).

## Engine Compatibility

| Field | Value |
|-------|-------|
| **Engine** | Godot 4.6 |
| **Domain** | Rendering / Core |
| **Knowledge Risk** | HIGH — Godot 4.6 Mobile renderer glow behaviour (applies before tonemapping) is post-cutoff; `GPUParticles2D` on Mobile renderer behaviour, Decal node support, and HDR 2D in Mobile renderer all require verification against 4.6 |
| **References Consulted** | `docs/engine-reference/godot/breaking-changes.md`, `docs/engine-reference/godot/modules/rendering.md` (if present), `docs/architecture/architecture.md` |
| **Post-Cutoff APIs Used** | Godot 4.6 Mobile renderer glow-before-tonemapping change; `VFXSystem.set_budget_cap(cap: int)` runtime degradation API; Shader Baker (Godot 4.5) for CI pipeline |
| **Verification Required** | On physical Android device (mid-range, Mali/Adreno GPU): (1) confirm glow visuals with `glow_intensity ≤ 0.4` baseline look correct; (2) confirm `GPUParticles2D` runs on GPU thread (not CPU fallback) in Mobile renderer; (3) confirm Decal nodes render correctly in 2D Mobile renderer; (4) confirm HDR 2D mode is active and UI glow accents render; (5) run Shader Baker in CI export and confirm startup time reduction on device |

> **Note**: Knowledge Risk is HIGH — this ADR must be re-validated if the project
> upgrades engine versions. Flag it as "Superseded" and write a new ADR.

## ADR Dependencies

| Field | Value |
|-------|-------|
| **Depends On** | ADR-003 (VFXSystem subscribes to CombatEventBus for all VFX trigger events — that signal model must be settled first) |
| **Enables** | All VFX implementation stories; all tower and enemy visual polish stories |
| **Blocks** | VFXSystem implementation, any tower/enemy/boss VFX authoring story |
| **Ordering Note** | Must be Accepted before any particle effect, shader, or glow effect is authored |

## Context

### Problem Statement

Godot's Mobile renderer is a distinct rendering pipeline from Forward+ (the desktop default). Several VFX features that work in the editor (which uses Forward+ by default) will not work or will look different on device. The most critical change in Godot 4.6 is that glow/bloom now applies before tonemapping on the Mobile renderer — meaning any glow effect tuned in the editor will look different on device. Additionally, the 200-particle hard cap and 150-draw-call budget for mid-range Android require a software enforcement system (`VFXSystem`) that can prioritize and drop low-priority effects when the budget is exceeded. Without this ADR, developers will unknowingly author effects that break silently on device.

### Current State

Pre-production; no VFX exist. The risk is that without explicit constraints, effects are authored against the wrong renderer.

### Constraints

- **Renderer**: Project uses Mobile renderer (configured in Project Settings → Rendering → Renderer). Editor may show effects differently — always test VFX on device.
- **Performance budget**: Max 200 active particles/frame; max 150 draw calls/frame; max 20 active decals/scene; max 40 active enemies simultaneously
- **Unsupported features**: Screen-space reflections (SSR), SSAO, SDFGI — all unsupported on Mobile renderer
- **Glow**: Godot 4.6 Mobile renderer applies glow before tonemapping (changed from 4.3 behaviour) — tuning done at author time in editor will look different on device
- **Shader complexity**: Fragment shaders with more than 4 texture samples per pass may fail to compile or run slowly on low-end mobile GPUs (Mali G52, Adreno 610 class)
- **Platform**: Android and iOS, portrait, mid-range GPU baseline

### Requirements

- All particle effects use `GPUParticles2D` (not `CPUParticles2D`)
- `VFXSystem` autoload maintains an active particle count and rejects emissions that would exceed 200
- Glow effects authored with `glow_intensity ≤ 0.4` as baseline; device re-tuning mandatory
- No screen-space reflections, SSAO, or SDFGI in any scene
- Decals limited to 20 active per scene
- Fragment shaders limited to 4 texture samples per pass; complex shaders split across passes
- HDR 2D enabled for UI glow accents and overdrive effects
- Shader Baker (Godot 4.5) runs in CI export pipeline to eliminate startup shader compilation hitching
- `VFXSystem` priority tiering: effects have a priority level; budget enforcement drops lowest-priority effects first

## Decision

All VFX are designed and tested against Godot 4.6 Mobile renderer exclusively. The `VFXSystem` autoload is the single gateway for all particle emissions and enforces the particle budget in real time. The rules below are hard constraints — they are not guidelines.

### Architecture

```
VFXSystem (Autoload — budget enforcer and effect registry)
─────────────────────────────────────────────────────────
    _active_particles: int = 0          ← running total
    _active_effects: Array[VFXHandle]   ← currently live effects
    _budget_cap: int = 200              ← runtime-adjustable for degradation
    _decal_count: int = 0

    play_vfx(vfx_id, position, priority) → VFXHandle
        ├── query registry for effect spec (particle count, duration)
        ├── if _active_particles + effect.count > _budget_cap:
        │       if priority < PRIORITY_MEDIUM: reject (drop effect)
        │       else: evict lowest-priority active effect
        ├── instantiate (pooled) GPUParticles2D node
        ├── add to SceneContainer (not HUD layer)
        └── _active_particles += effect.count

    on_effect_expired(handle):
        _active_particles -= handle.particle_count
        pool_recycle(handle.node)

    set_budget_cap(cap: int):    ← called by performance monitor for degradation
        _budget_cap = cap

Effect Priority Tiers (high → low):
    PRIORITY_CRITICAL  = 3   (ultimate activation, boss finisher)
    PRIORITY_HIGH      = 2   (enemy death, tower attack hit)
    PRIORITY_MEDIUM    = 1   (tower projectile trail)
    PRIORITY_LOW       = 0   (ambient, background sparks) ← dropped first

CombatEventBus subscriptions in VFXSystem._ready():
    enemy_died     → play_vfx(enemy.enemy_data.death_vfx_id, pos, PRIORITY_HIGH)
    tower_fired    → play_vfx(tower_projectile_vfx, pos, PRIORITY_MEDIUM)
    hit_landed     → play_vfx(hit_impact_vfx, pos, PRIORITY_HIGH)
    ultimate_activated → play_ultimate_vfx(id)  [PRIORITY_CRITICAL, uncapped]
    boss_died      → play_vfx(boss_data.finisher_vfx_id, pos, PRIORITY_CRITICAL)

Mobile Renderer VFX Rules:
─────────────────────────────────────────────────────────
✅ ALLOWED:
    GPUParticles2D (all particle effects)
    Decals (ground splats, slime puddles) — max 20 active
    HDR 2D (UI glow accents, overdrive effects)
    Custom shaders (≤4 texture samples per fragment pass)
    Glow/bloom (WorldEnvironment) — intensity ≤ 0.4 baseline, device-tuned

❌ FORBIDDEN:
    CPUParticles2D (use GPUParticles2D — CPU fallback defeats GPU budget)
    Screen-Space Reflections (SSR) — unsupported on Mobile renderer
    SSAO — unsupported on Mobile renderer
    SDFGI — unsupported on Mobile renderer
    Fragment shaders with >4 texture samples per pass
    Direct particle node instantiation outside VFXSystem
    Hardcoded particle counts in scene files (must reference VFX registry)
```

### Key Interfaces

```gdscript
# VFXSystem — autoload
class_name VFXSystem
extends Node

enum VFXPriority {
    LOW = 0,
    MEDIUM = 1,
    HIGH = 2,
    CRITICAL = 3
}

# Play an effect from the VFX registry
func play_vfx(vfx_id: StringName, position: Vector2,
              priority: VFXPriority = VFXPriority.MEDIUM,
              parent: Node = null) -> void: pass

# Play the full-screen ultimate VFX (always plays; CRITICAL priority; uncapped)
func play_ultimate_vfx(ultimate_id: StringName) -> void: pass

# Read current budget usage (for debug HUD)
func get_active_particle_count() -> int: pass

# Runtime budget adjustment — called by a performance monitor if FPS drops
func set_budget_cap(cap: int) -> void: pass

# VFX Registry entry (loaded from UltimateData / EnemyData vfx_id references)
class VFXSpec:
    var vfx_id: StringName
    var packed_scene: PackedScene    # GPUParticles2D scene
    var particle_count: int          # particles emitted per activation
    var duration: float              # seconds until auto-free
    var priority: VFXPriority        # default priority for this effect


# WorldEnvironment settings for Mobile renderer (in GameplayScene.tscn):
# Environment:
#   background_mode = SKY (or COLOR for simple levels)
#   glow_enabled = true
#   glow_intensity = 0.3          ← ≤0.4 baseline; re-tune on device
#   glow_bloom = 0.1
#   ssao_enabled = false           ← MUST be false
#   sdfgi_enabled = false          ← MUST be false
#   ssr_enabled = false            ← MUST be false
#   tonemap_mode = FILMIC


# Shader template — max 4 texture samples per fragment pass:
# shader_type canvas_item;
# uniform sampler2D main_tex : source_color;
# uniform sampler2D normal_tex;
# uniform sampler2D emission_tex;
# uniform sampler2D mask_tex;
# // ← 4 samples total. If more needed, split into two-pass shader.
# void fragment() {
#     COLOR = texture(main_tex, UV)
#             * texture(emission_tex, UV)
#             * texture(mask_tex, UV).r;
#     NORMAL_MAP = texture(normal_tex, UV).rgb;
# }
```

### Implementation Guidelines

1. **Renderer selection**: Confirm `Rendering → Renderer → Rendering Method` is set to `Mobile` in Project Settings. This must be set before any VFX is authored — it changes how the editor previews effects.
2. **Glow workflow**: Author glow at `glow_intensity = 0.3` in the editor. Always re-tune on a physical device (Samsung Galaxy A34 or equivalent) before marking any VFX story Done. The editor preview will look different from device — this is expected and documented in Godot 4.6.
3. **Particle count in registry**: Each VFX effect in the registry declares its maximum simultaneous particle count. `VFXSystem` uses this to pre-check budget. Authors must populate this field accurately when creating a new VFX.
4. **Pooling**: `VFXSystem` maintains a pool of pre-instantiated `GPUParticles2D` nodes per `vfx_id`. On `play_vfx`, it retrieves a pooled node, repositions it, and resets `emitting = true`. On expiry, it sets `emitting = false` and returns it to the pool. Pool sizes are defined in the VFX registry.
5. **Decal tracking**: `VFXSystem` tracks active `Decal` nodes. Any request to place a decal that would exceed 20 recycles the oldest active decal.
6. **HDR 2D**: Enabled in Project Settings → Rendering → 2D → HDR 2D. UI glow elements (ultimate button overdrive, pressure bar glow) use `CanvasItem.use_hdr_2d = true`. Do not enable on all UI elements — only those requiring bloom/glow.
7. **Shader Baker in CI**: The CI export job must run Godot's Shader Baker before packaging the APK/IPA. Command: `godot --headless --export-debug "Android" build.apk --shader-pack`. This eliminates per-device shader compilation stutters on first play.
8. **CRITICAL effects**: Ultimate activation VFX (e.g., Клизма Апокалипсиса) use `PRIORITY_CRITICAL` and bypass the particle cap check. These are one-at-a-time events where dropping the effect would damage player experience unacceptably.
9. **Draw call discipline**: `EnemyBase` and `TowerBase` scenes must use single `Sprite2D` or `AnimatedSprite2D` per entity — no nested `CanvasItem` sub-layers unless required. This keeps draw call count within the 150-call budget at 40 enemies.

## Alternatives Considered

### Alternative 1: CPUParticles2D for all effects

- **Description**: Use `CPUParticles2D` instead of `GPUParticles2D` for all particle effects
- **Pros**: CPU-side control; easier to debug per-particle state; no GPU shader compilation
- **Cons**: CPU-bound particle simulation at 200 particles with 40 enemies creates ~5–10ms per-frame CPU overhead; defeats the GPU budget; Godot recommendation for Mobile renderer is `GPUParticles2D`
- **Estimated Effort**: Same
- **Rejection Reason**: Performance budget. GPUParticles2D offloads simulation to GPU, keeping CPU free for gameplay logic.

### Alternative 2: No particle budget enforcement (author discipline only)

- **Description**: No `VFXSystem` budget tracking; authors manually ensure they stay under 200 particles
- **Pros**: Zero overhead from budget checking
- **Cons**: No runtime safety net; a single poorly-authored effect can push the game below 30fps on device; no graceful degradation under load
- **Estimated Effort**: Lower (no VFXSystem complexity)
- **Rejection Reason**: Mid-production, when the particle budget is exceeded by an edge case (boss encounter + full wave), there is no recovery mechanism. TR-perf-001 explicitly requires budget enforcement.

### Alternative 3: Forward+ renderer with reduced quality settings

- **Description**: Use Forward+ renderer with quality settings reduced to mobile levels
- **Pros**: More features available; easier to tune in editor (editor also runs Forward+)
- **Cons**: Higher GPU overhead than Mobile renderer on mid-range Android; 2D games do not benefit from Forward+'s 3D feature set; Mobile renderer is the correct choice for 2D portrait games
- **Estimated Effort**: Same setup; higher per-frame GPU cost
- **Rejection Reason**: Godot's Mobile renderer is purpose-built for mobile 2D; the performance difference is measurable on mid-range devices

## Consequences

### Positive

- `VFXSystem` provides a single auditable chokepoint for all particle emissions — easy to profile and debug
- Priority-based budget enforcement means critical gameplay effects (ultimate, boss death) always play; ambient effects degrade gracefully
- Glow re-tuning requirement documented explicitly prevents "looks different on device" surprises
- Shader Baker in CI prevents startup hitching on first player session
- Decal cap prevents slime puddle accumulation from degrading performance in long battles

### Negative

- All VFX must be device-tested — editor preview is unreliable for Mobile renderer glow tuning
- `VFXSystem` pooling adds implementation complexity
- CRITICAL effects (ultimates) bypass the budget cap — a poorly-authored ultimate could spike frame time; must be profiled per ultimate
- Fragment shader 4-sample limit constrains visual complexity; some desired effects require split-pass shaders

### Neutral

- `CPUParticles2D` is effectively banned from the project — all particle effect knowledge must target `GPUParticles2D` API
- Shader Baker adds a CI step but eliminates a class of player-reported "first-session lag" issues

## Risks

| Risk | Probability | Impact | Mitigation |
|------|------------|--------|-----------|
| Glow looks washed out on device vs editor | High | Low — visual only | Required: device sign-off on every VFX effect before story Done; glow_intensity ≤ 0.4 baseline |
| GPUParticles2D falls back to CPU on some devices | Low | Medium — frame spike | Test on Adreno 610 (low end target); if fallback detected, provide CPUParticles2D fallback path in VFXSystem |
| Ultimate VFX causes frame spike (uncapped) | Medium | High — gameplay disruption | Profile every ultimate VFX on device before Accepted; cap particle count at 150 per ultimate regardless of CRITICAL priority |
| Decal nodes unsupported on some Android GPUs | Low | Low — visual only | VFXSystem decal placement checks `RenderingServer.get_current_rendering_method()` and disables decals on unsupported configs |
| Shader Baker not run in CI, shipped without baked shaders | Medium | Medium — first-session lag for all players | CI job must fail the build if Shader Baker step is skipped; verified in `/story-done` export checklist |

## Performance Implications

| Metric | Before | Expected After | Budget |
|--------|--------|---------------|--------|
| CPU (frame time — VFXSystem budget check) | N/A | <0.2ms per frame | <0.5ms |
| GPU (200 active particles, peak wave) | N/A | ~2–4ms GPU time | <5ms GPU |
| Draw calls (40 enemies + towers + VFX) | N/A | ≤150 draw calls/frame | 150 max |
| Active decals | N/A | ≤20 | 20 max |
| Startup time (with Shader Baker) | N/A | <2s on mid-range Android (shaders pre-baked) | <3s |
| Startup time (without Shader Baker) | N/A | 4–8s on mid-range Android | Unacceptable |

## Migration Plan

Pre-production; no existing VFX to migrate.

1. Set Project Settings → Rendering → Renderer to `Mobile`
2. Enable HDR 2D in Project Settings → Rendering → 2D
3. Create `res://autoloads/VFXSystem.gd` with budget tracking and pooling
4. Create VFX registry resource (`res://data/vfx/vfx_registry.tres`) with `VFXSpec` entries
5. Register `VFXSystem` as autoload (after `CombatEventBus` in ADR-002 order — add to position 8, shift SceneManager to 9)
6. Implement pool for each VFX type needed in sprint 1
7. Add Shader Baker step to CI export pipeline (Godot 4.5 feature, available in 4.6)

**Rollback plan**: If `GPUParticles2D` performs worse than expected on a specific device tier, introduce a `VFXQuality` enum (`HIGH / MEDIUM / LOW`) and `VFXSystem.set_quality(level)` that switches between `GPUParticles2D` (HIGH) and `CPUParticles2D` (LOW) for non-critical effects at runtime.

## Validation Criteria

- [ ] `grep -r "CPUParticles2D" res://` returns zero results
- [ ] `grep -r "ssr_enabled\|ssao_enabled\|sdfgi_enabled" res://` returns all `= false`
- [ ] Frame profiler on Samsung Galaxy A34: ≤150 draw calls during peak wave (40 enemies)
- [ ] `VFXSystem.get_active_particle_count()` never exceeds 200 during a 5-minute play session stress test
- [ ] All glow effects device-tested and signed off (glow_intensity values in range [0.1, 0.4])
- [ ] CI export pipeline runs Shader Baker; APK startup time on device <3s cold start
- [ ] Ultimate VFX (Клизма Апокалипсиса) does not cause >5ms GPU spike during activation

## GDD Requirements Addressed

| GDD Document | System | Requirement | How This ADR Satisfies It |
|-------------|--------|-------------|--------------------------|
| `design/gdd/master-gdd.md` | VFXSystem | TR-perf-001: Max 200 active particles; VFXSystem tracks budget and applies tiered degradation | `VFXSystem` budget enforcement with priority tiers; `set_budget_cap()` for runtime degradation |
| `design/gdd/master-gdd.md` | VFXSystem | TR-perf-002: All VFX for Mobile renderer; glow re-tuned for Godot 4.6 glow-before-tonemapping | Mandatory Mobile renderer target; device re-tuning requirement documented; glow_intensity ≤ 0.4 baseline |
| `design/gdd/master-gdd.md` | VFXSystem | TR-vfx-001: Death VFX per enemy type played via VFXSystem; not inline in EnemyBase | `CombatEventBus.enemy_died → VFXSystem.play_vfx(enemy.death_vfx_id)` pattern defined here |
| `design/gdd/master-gdd.md` | EnemySystem | TR-enemy-002: Max 40 simultaneous active enemies; EnemySystem notifies VFXSystem for degradation | `VFXSystem.set_budget_cap()` called by EnemySystem when near cap (40 enemies × high-frequency events) |
| `design/gdd/master-gdd.md` | EnemySystem | TR-enemy-004: Death VFX id in EnemyData, played via VFXSystem | `EnemyData.death_vfx_id` (defined in ADR-004); VFXSystem subscribes to CombatEventBus.enemy_died |
| `design/gdd/master-gdd.md` | BossController | TR-boss-003: Boss intro VFX and finisher VFX referenced in BossData; VFXSystem plays on BossController signals | `BossData.intro_vfx_id` / `finisher_vfx_id` (ADR-004); VFXSystem subscribes to `CombatEventBus.boss_died` |

## Related

- ADR-003: Signal bus (VFXSystem subscribes to CombatEventBus for all trigger events — defined there)
- ADR-004: Data Resource structure (`EnemyData.death_vfx_id`, `BossData.intro_vfx_id` etc. defined there)
- `docs/engine-reference/godot/breaking-changes.md` — Godot 4.6 Mobile renderer glow change
- `docs/architecture/architecture.md` § High-Risk Post-Cutoff Changes

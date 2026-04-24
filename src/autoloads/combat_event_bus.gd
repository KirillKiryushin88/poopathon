extends Node
## CombatEventBus — stateless cross-system signal relay (ADR-003)
## Autoload order: 7th (last)
## No state here. Emit only. Subscribers connect in their own _ready().
## Max ~20 subscribers per signal for performance.

# Combat events
signal hit_landed(target: Node, damage: float, damage_type: String, is_crit: bool)
signal enemy_died(enemy: Node, position: Vector2)
signal pressure_gained(amount: float, source: String)

# Tower events
signal tower_placed(slot_id: int, tower: Node)
signal tower_upgraded(slot_id: int, new_tier: int)
signal tower_sold(slot_id: int, refund: int)

# Wave events
signal wave_break_started(duration: float)
signal ultimate_activated(ultimate_id: String)


func _ready() -> void:
	print("[CombatEventBus] ready")

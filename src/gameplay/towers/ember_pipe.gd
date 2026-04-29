class_name EmberPipe
extends TowerBase
## Red T1 — Ember Pipe: applies Burn DoT (3s) on hit
## Stats: dmg=18, interval=1.2s, range=140, burn_dps=6

@export var burn_dps: float = 6.0
@export var burn_duration: float = 3.0


func _ready() -> void:
	school = School.RED
	tier = 1
	super._ready()


func _apply_hit_effect(target: EnemyBase) -> void:
	target.apply_poison(burn_dps, burn_duration)

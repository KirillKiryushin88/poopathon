class_name ChillPipe
extends TowerBase
## Blue T1 — Chill Pipe: applies 35% slow for 2s
## Stats: dmg=10, interval=1.8s, range=120, slow_factor=0.65, slow_duration=2s

@export var slow_factor: float = 0.65
@export var slow_duration: float = 2.0


func _ready() -> void:
	school = School.BLUE
	tier = 1
	super._ready()


func _apply_hit_effect(target: EnemyBase) -> void:
	target.apply_slow(slow_factor, slow_duration)
	target.add_to_group("chilled")

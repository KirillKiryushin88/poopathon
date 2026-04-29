class_name ChlorineCannon
extends TowerBase
## Blue T2 — Chlorine Cannon: 35% slow + Corrode (−15% defense) + Toxic Steam combo
## Stats: dmg=14, interval=1.3s, range=140, slow_factor=0.65, corrode_armor_reduction=0.15

@export var slow_factor: float = 0.65
@export var slow_duration: float = 2.5
@export var corrode_armor_reduction: float = 0.15


func _ready() -> void:
	school = School.BLUE
	tier = 2
	add_to_group("tower_cold")
	super._ready()


func _apply_hit_effect(target: EnemyBase) -> void:
	target.apply_slow(slow_factor, slow_duration)
	target.add_to_group("chilled")
	# Corrode: reduce armor temporarily
	target.armor = maxf(target.armor - corrode_armor_reduction, 0.0)
	# Toxic Steam: if target also has HEAT tag
	if target.is_in_group("heated"):
		target.apply_stench(2.0)
		target.take_damage(damage * 0.5, EnemyBase.DamageType.POISON)

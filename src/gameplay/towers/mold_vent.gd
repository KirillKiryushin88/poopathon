class_name MoldVent
extends TowerBase
## Green T1 — Mold Vent: Poison DoT + Stench debuff. No chain effects in M1.
## Stats: dmg=8, interval=0.8s, range=160, mold_dps=8, mold_duration=4s

@export var mold_dps: float = 8.0
@export var mold_duration: float = 4.0


func _ready() -> void:
	school = School.GREEN
	tier = 1
	super._ready()


func _apply_hit_effect(target: EnemyBase) -> void:
	target.apply_poison(mold_dps, mold_duration)
	target.apply_stench(mold_duration)
	# Stench Ignition: if target also has HEAT tag
	if target.is_in_group("heated"):
		target.take_damage(damage * 2.0, EnemyBase.DamageType.FIRE)

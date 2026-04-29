class_name BoilerCannon
extends TowerBase
## Red T2 — Boiler Cannon: Burn DoT + HEAT tag for Toxic Steam combo
## Stats: dmg=28, interval=0.9s, range=155, burn_dps=10, burn_duration=3s

@export var burn_dps: float = 10.0
@export var burn_duration: float = 3.0


func _ready() -> void:
	school = School.RED
	tier = 2
	add_to_group("tower_heat")
	super._ready()


func _apply_hit_effect(target: EnemyBase) -> void:
	target.apply_poison(burn_dps, burn_duration)
	target.add_to_group("heated")
	# Toxic Steam: if target also has COLD tag → emit combo
	if target.is_in_group("chilled"):
		_trigger_toxic_steam(target)


func _trigger_toxic_steam(target: EnemyBase) -> void:
	# Stench debuff simulates toxic steam cloud
	target.apply_stench(2.0)
	target.take_damage(damage * 0.5, EnemyBase.DamageType.POISON)

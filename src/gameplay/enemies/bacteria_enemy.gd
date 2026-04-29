class_name BacteriaEnemy
extends EnemyBase
## Bacteria — heavily armored tank
## Stats: base_hp=155, base_armor=0.45, base_speed=26, throne_damage=20, soft_reward=25
## At 50% HP: armor breaks (-0.20), emits armor_broken signal

signal armor_broken()

var _armor_broken: bool = false


func take_damage(amount: float, damage_type: DamageType = DamageType.NORMAL) -> void:
	var modified_amount: float = amount
	# IMPACT (Chunk Burst) bypasses 50% of remaining armor
	if damage_type == DamageType.NORMAL and not _armor_broken:
		modified_amount = amount * 1.5

	super.take_damage(modified_amount, damage_type)

	if not _armor_broken and hp <= max_hp * 0.5:
		_armor_broken = true
		armor = maxf(armor - 0.20, 0.0)
		armor_broken.emit()

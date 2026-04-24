class_name WormEnemy
extends EnemyBase

var _has_burrowed: bool = false
var _burrow_hp_threshold: float = 0.5

func take_damage(amount: float, damage_type: DamageType = DamageType.NORMAL) -> void:
	super.take_damage(amount, damage_type)
	if not _has_burrowed and hp / max_hp <= _burrow_hp_threshold and not _is_dead:
		_burrow()

func _burrow() -> void:
	_has_burrowed = true
	# Brief invulnerability
	armor = 9999.0
	await get_tree().create_timer(0.5).timeout
	armor = enemy_data.base_armor if enemy_data else 0.0
	# Lane shift: just offset position slightly (full lane-swap needs WaveManager path index)
	global_position.x += 60.0

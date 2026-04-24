class_name LevelResult
extends Resource

@export var won: bool = false
@export var soft_earned: int = 0
@export var throne_hp_pct: float = 1.0
@export var stars: int = 0  # computed: 3=>hp>80%, 2=>hp>40%, 1=>hp>0%, 0=>lost


func compute_stars() -> void:
	if not won:
		stars = 0
	elif throne_hp_pct > 0.8:
		stars = 3
	elif throne_hp_pct > 0.4:
		stars = 2
	else:
		stars = 1

class_name MetaProgression
extends Node
## MetaProgression — level stars and lifetime currency
## Autoload order: 2nd

signal level_stars_updated(level_id: String, new_stars: int)

var level_stars: Dictionary = {}
var lifetime_slime: int = 0


func _ready() -> void:
	print("[MetaProgression] ready")


func record_level(level_id: String, result: LevelResult) -> void:
	result.compute_stars()
	var prev: int = level_stars.get(level_id, 0) as int
	if result.stars > prev:
		level_stars[level_id] = result.stars
		level_stars_updated.emit(level_id, result.stars)
	if result.won:
		lifetime_slime += result.soft_earned


func get_stars(level_id: String) -> int:
	return level_stars.get(level_id, 0) as int


func get_save_data() -> Dictionary:
	return {"level_stars": level_stars, "lifetime_slime": lifetime_slime}


func restore_from_save(data: Dictionary) -> void:
	level_stars = data.get("level_stars", {}) as Dictionary
	lifetime_slime = data.get("lifetime_slime", 0) as int

extends Node
## SaveService — ConfigFile-based persistence at user://save.cfg
## Autoload order: 4th
## Uses call_deferred for load to ensure all autoloads are ready

signal save_completed()
signal load_completed()
signal save_failed(error: String)

const SAVE_PATH: String = "user://save.cfg"
const CURRENT_VERSION: int = 1


func _ready() -> void:
	call_deferred("_load_game")


func save_game() -> void:
	var cfg: ConfigFile = ConfigFile.new()
	cfg.set_value("meta", "save_version", CURRENT_VERSION)

	# Ask each autoload for its save data via direct call (save is synchronous)
	var economy: Node = Engine.get_singleton("EconomyService")
	if economy:
		var econ_data: Dictionary = economy.get_save_data()
		for key: String in econ_data:
			cfg.set_value("economy", key, econ_data[key])

	var err: Error = cfg.save(SAVE_PATH)
	if err != OK:
		save_failed.emit("ConfigFile.save() returned error: %d" % err)
		return
	save_completed.emit()


func _load_game() -> void:
	if not FileAccess.file_exists(SAVE_PATH):
		load_completed.emit()
		return

	var cfg: ConfigFile = ConfigFile.new()
	var err: Error = cfg.load(SAVE_PATH)
	if err != OK:
		load_completed.emit()
		return

	var version: int = cfg.get_value("meta", "save_version", 0) as int
	if version < CURRENT_VERSION:
		_migrate(cfg, version, CURRENT_VERSION)

	# Restore economy
	var economy: Node = Engine.get_singleton("EconomyService")
	if economy:
		economy.restore_from_save({
			"soft": cfg.get_value("economy", "soft", 0) as int,
			"hard": cfg.get_value("economy", "hard", 0) as int
		})

	load_completed.emit()


func _migrate(cfg: ConfigFile, from_version: int, to_version: int) -> void:
	# Migration stub — add cases per version bump
	push_warning("SaveService: migrating save from v%d to v%d" % [from_version, to_version])

extends Node
## SaveService — ConfigFile-based persistence at user://save.cfg
## Autoload order: 4th

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

	var economy: EconomyService = Engine.get_singleton("EconomyService") as EconomyService
	if economy:
		var d: Dictionary = economy.get_save_data()
		for k: String in d:
			cfg.set_value("economy", k, d[k])

	var meta: MetaProgression = Engine.get_singleton("MetaProgression") as MetaProgression
	if meta:
		var d: Dictionary = meta.get_save_data()
		for k: String in d:
			cfg.set_value("meta_prog", k, d[k])

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
	if cfg.load(SAVE_PATH) != OK:
		load_completed.emit()
		return

	var version: int = cfg.get_value("meta", "save_version", 0) as int
	if version < CURRENT_VERSION:
		_migrate(cfg, version, CURRENT_VERSION)

	var economy: EconomyService = Engine.get_singleton("EconomyService") as EconomyService
	if economy:
		economy.restore_from_save({
			"soft": cfg.get_value("economy", "soft", 0) as int,
			"hard": cfg.get_value("economy", "hard", 0) as int,
		})

	var meta: MetaProgression = Engine.get_singleton("MetaProgression") as MetaProgression
	if meta:
		meta.restore_from_save({
			"level_stars":    cfg.get_value("meta_prog", "level_stars", {}) as Dictionary,
			"lifetime_slime": cfg.get_value("meta_prog", "lifetime_slime", 0) as int,
		})

	load_completed.emit()


func _migrate(_cfg: ConfigFile, from_version: int, to_version: int) -> void:
	push_warning("SaveService: migrating save v%d → v%d" % [from_version, to_version])

class_name GameSession
extends Node
## GameSession — tracks active play session state
## Autoload order: 1st
## All other autoloads may connect to these signals

signal level_started(config: LevelConfig)
signal level_ended(result: LevelResult)
signal pressure_changed(new_value: float)
signal wave_number_changed(wave: int)

var current_level: LevelConfig = null
var wave_number: int = 0
var pressure: float = 0.0
const MAX_PRESSURE: float = 100.0
const PRESSURE_PER_HIT: float = 2.0
const PRESSURE_PER_CRIT: float = 5.0
const PRESSURE_PER_KILL: float = 10.0


func _ready() -> void:
	# Connect to CombatEventBus once it's ready
	pass


func start_level(config: LevelConfig) -> void:
	current_level = config
	wave_number = 0
	pressure = 0.0
	level_started.emit(config)


func end_level(result: LevelResult) -> void:
	level_ended.emit(result)


func add_pressure(amount: float) -> void:
	pressure = clampf(pressure + amount, 0.0, MAX_PRESSURE)
	pressure_changed.emit(pressure)


func set_wave(wave: int) -> void:
	wave_number = wave
	wave_number_changed.emit(wave)

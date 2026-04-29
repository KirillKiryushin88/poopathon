class_name LevelController
extends Node2D
## LevelController — orchestrates a level run: start → waves → results
## Add as root of any level scene. Wire child nodes in inspector.

signal level_finished(result: LevelResult)

@export var level_config: LevelConfig
@export var wave_manager: WaveManager
@export var ultimate_system: UltimateSystem
@export var results_overlay: LevelResultsController

const MAX_THRONE_HP: float = 100.0
var _throne_hp: float = MAX_THRONE_HP
var _soft_earned: int = 0
var _started: bool = false


func _ready() -> void:
	_connect_signals()


func start_level() -> void:
	if _started:
		return
	_started = true
	_throne_hp = MAX_THRONE_HP
	_soft_earned = 0

	var session: GameSession = Engine.get_singleton("GameSession") as GameSession
	if session and level_config:
		session.start_level(level_config)

	if wave_manager and level_config:
		wave_manager.wave_configs = level_config.wave_configs
		wave_manager.start_wave(0)


func _connect_signals() -> void:
	var session: GameSession = Engine.get_singleton("GameSession") as GameSession
	if session:
		session.pressure_changed.connect(_on_pressure_changed)

	if wave_manager:
		wave_manager.all_waves_completed.connect(_on_all_waves_completed)
		wave_manager.wave_completed.connect(_on_wave_completed)

	var bus: CombatEventBus = Engine.get_singleton("CombatEventBus") as CombatEventBus
	if bus:
		bus.enemy_died.connect(_on_enemy_died)

	if results_overlay:
		results_overlay.retry_pressed.connect(_on_retry)
		results_overlay.menu_pressed.connect(_on_menu)


func _on_pressure_changed(new_value: float) -> void:
	# Throne damage = pressure overflow events tracked via GameSession
	if new_value >= GameSession.MAX_PRESSURE:
		_take_throne_damage(20.0)


func _take_throne_damage(amount: float) -> void:
	_throne_hp = maxf(_throne_hp - amount, 0.0)
	if _throne_hp <= 0.0:
		_end_level(false)


func _on_enemy_died(_enemy: Node, _pos: Vector2) -> void:
	_soft_earned += 5  # Flat reward; EnemyData-driven reward handled in EconomyService


func _on_wave_completed(wave_index: int) -> void:
	var config: LevelConfig = level_config
	if config and wave_index < config.wave_configs.size():
		_soft_earned += config.wave_configs[wave_index].soft_reward


func _on_all_waves_completed() -> void:
	_end_level(true)


func _end_level(won: bool) -> void:
	if wave_manager:
		wave_manager.abort()

	var result: LevelResult = LevelResult.new()
	result.won = won
	result.soft_earned = _soft_earned
	result.throne_hp_pct = _throne_hp / MAX_THRONE_HP
	result.compute_stars()

	var session: GameSession = Engine.get_singleton("GameSession") as GameSession
	if session:
		session.end_level(result)

	if results_overlay:
		results_overlay.show_results(result)

	level_finished.emit(result)


func _on_retry() -> void:
	get_tree().reload_current_scene()


func _on_menu() -> void:
	var scene_mgr: SceneManager = Engine.get_singleton("SceneManager") as SceneManager
	if scene_mgr:
		scene_mgr.transition_to("res://src/ui/main_menu.tscn")

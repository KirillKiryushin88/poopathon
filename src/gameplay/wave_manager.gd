class_name WaveManager
extends Node
## WaveManager — reads WaveConfig resources, spawns enemy groups, manages inter-wave breaks
## Attaches to the level scene. Set spawn_path in the inspector.

signal wave_started(wave_index: int)
signal wave_completed(wave_index: int)
signal all_waves_completed()
signal inter_wave_tick(remaining: float)

@export var spawn_path: Path2D
@export var wave_configs: Array[WaveConfig] = []

const INTER_WAVE_DURATION: float = 12.0

var current_wave_index: int = -1

var _active_enemy_count: int = 0
var _spawn_queues: Array[Dictionary] = []
var _state: StringName = &"idle"
var _break_timer: float = 0.0


func _ready() -> void:
	var bus: CombatEventBus = Engine.get_singleton("CombatEventBus") as CombatEventBus
	if bus:
		bus.enemy_died.connect(_on_bus_enemy_died)


func start_wave(index: int) -> void:
	if index >= wave_configs.size():
		all_waves_completed.emit()
		return

	current_wave_index = index
	_active_enemy_count = 0
	_spawn_queues.clear()

	for spawn: Dictionary in wave_configs[index].enemy_spawns:
		_spawn_queues.append({
			"scene":     spawn.get("enemy_scene") as PackedScene,
			"remaining": int(spawn.get("count", 1)),
			"interval":  float(spawn.get("interval", 1.0)),
			"timer":     0.0,
		})

	_state = &"spawning"
	wave_started.emit(index)

	var session: GameSession = Engine.get_singleton("GameSession") as GameSession
	if session:
		session.set_wave(index + 1)


func _process(delta: float) -> void:
	match _state:
		&"spawning": _tick_spawning(delta)
		&"break":    _tick_break(delta)


func _tick_spawning(delta: float) -> void:
	var all_queues_empty: bool = true
	for q: Dictionary in _spawn_queues:
		if int(q["remaining"]) <= 0:
			continue
		all_queues_empty = false
		q["timer"] = float(q["timer"]) + delta
		while float(q["timer"]) >= float(q["interval"]) and int(q["remaining"]) > 0:
			q["timer"] = float(q["timer"]) - float(q["interval"])
			q["remaining"] = int(q["remaining"]) - 1
			_spawn_enemy(q["scene"] as PackedScene)

	if all_queues_empty and _active_enemy_count == 0:
		_begin_break()


func _spawn_enemy(scene: PackedScene) -> void:
	if scene == null or spawn_path == null:
		push_warning("WaveManager: spawn_path or enemy scene is null — skipping spawn")
		return

	var follower: PathFollow2D = PathFollow2D.new()
	follower.rotates = false
	follower.loop = false
	spawn_path.add_child(follower)

	var enemy: EnemyBase = scene.instantiate() as EnemyBase
	follower.add_child(enemy)
	enemy.setup_path(follower)

	# Bind follower cleanup to enemy lifecycle
	enemy.died.connect(func(_e: EnemyBase, _p: Vector2) -> void: follower.queue_free())
	enemy.reached_throne.connect(func(_dmg: float) -> void: follower.queue_free())
	enemy.reached_throne.connect(_on_enemy_reached_throne)

	_active_enemy_count += 1


func _on_bus_enemy_died(_enemy: Node, _pos: Vector2) -> void:
	_active_enemy_count = maxi(_active_enemy_count - 1, 0)
	if _state == &"spawning":
		_check_wave_clear()


func _on_enemy_reached_throne(_damage: float) -> void:
	_active_enemy_count = maxi(_active_enemy_count - 1, 0)
	if _state == &"spawning":
		_check_wave_clear()


func _check_wave_clear() -> void:
	var queues_empty: bool = true
	for q: Dictionary in _spawn_queues:
		if int(q["remaining"]) > 0:
			queues_empty = false
			break
	if queues_empty and _active_enemy_count == 0:
		_begin_break()


func _begin_break() -> void:
	_state = &"break"
	_break_timer = INTER_WAVE_DURATION
	wave_completed.emit(current_wave_index)

	var bus: CombatEventBus = Engine.get_singleton("CombatEventBus") as CombatEventBus
	if bus:
		bus.wave_break_started.emit(INTER_WAVE_DURATION)


func _tick_break(delta: float) -> void:
	_break_timer -= delta
	inter_wave_tick.emit(_break_timer)
	if _break_timer <= 0.0:
		_state = &"idle"
		start_wave(current_wave_index + 1)


func abort() -> void:
	_state = &"idle"
	_spawn_queues.clear()
	_active_enemy_count = 0

class_name CentralTowerController
extends Node2D

# Signals
signal aim_updated(direction: Vector2)
signal fire_mode_changed(new_mode: FireMode)

# Fire modes
enum FireMode { CHUNK_BURST, AUTO_DIARRHEA, GAS_CONE }

# Exported stats (override with TowerData resource in scene)
@export var fire_mode: FireMode = FireMode.CHUNK_BURST
@export var aim_zone_start_x: float = 432.0

# Data resources — set these in the scene inspector
@export var chunk_burst_data: TowerFireModeData
@export var auto_diarrhea_data: TowerFireModeData
@export var gas_cone_data: TowerFireModeData

# Projectile scenes
@export var chunk_projectile_scene: PackedScene
@export var diarrhea_projectile_scene: PackedScene

var aim_direction: Vector2 = Vector2.DOWN
var _is_aiming: bool = false
var _auto_fire_timer: float = 0.0
var _chunk_cooldown_timer: float = 0.0

func _ready() -> void:
	# Connect pressure gain to CombatEventBus
	var bus: Node = Engine.get_singleton("CombatEventBus")
	if bus:
		bus.hit_landed.connect(_on_hit_landed)
		bus.enemy_died.connect(_on_enemy_died)

func _input(event: InputEvent) -> void:
	if event is InputEventScreenDrag:
		var drag: InputEventScreenDrag = event as InputEventScreenDrag
		if drag.position.x >= aim_zone_start_x:
			_update_aim(drag.position)
	elif event is InputEventScreenTouch:
		var touch: InputEventScreenTouch = event as InputEventScreenTouch
		if touch.position.x >= aim_zone_start_x:
			_is_aiming = touch.pressed
			if touch.pressed:
				_handle_tap_fire(touch.position)

func _process(delta: float) -> void:
	_chunk_cooldown_timer = maxf(_chunk_cooldown_timer - delta, 0.0)
	if fire_mode == FireMode.AUTO_DIARRHEA and _is_aiming:
		_auto_fire_timer += delta
		var interval: float = auto_diarrhea_data.fire_interval if auto_diarrhea_data else 0.08
		if _auto_fire_timer >= interval:
			_auto_fire_timer = 0.0
			_fire_auto_diarrhea()

func _update_aim(screen_pos: Vector2) -> void:
	var tower_screen_pos: Vector2 = get_global_transform_with_canvas().origin
	var raw_dir: Vector2 = (screen_pos - tower_screen_pos).normalized()
	if raw_dir.length_squared() > 0.01:
		aim_direction = raw_dir
		aim_updated.emit(aim_direction)

func _handle_tap_fire(screen_pos: Vector2) -> void:
	_update_aim(screen_pos)
	match fire_mode:
		FireMode.CHUNK_BURST:
			_fire_chunk_burst()
		FireMode.GAS_CONE:
			_fire_gas_cone()

func _fire_chunk_burst() -> void:
	if _chunk_cooldown_timer > 0.0 or chunk_projectile_scene == null:
		return
	var cooldown: float = chunk_burst_data.fire_interval if chunk_burst_data else 0.8
	_chunk_cooldown_timer = cooldown
	var proj: Node2D = chunk_projectile_scene.instantiate() as Node2D
	get_parent().add_child(proj)
	proj.global_position = global_position
	if proj.has_method("launch"):
		proj.launch(aim_direction, chunk_burst_data)

func _fire_auto_diarrhea() -> void:
	if diarrhea_projectile_scene == null:
		return
	var proj: Node2D = diarrhea_projectile_scene.instantiate() as Node2D
	get_parent().add_child(proj)
	proj.global_position = global_position
	if proj.has_method("launch"):
		proj.launch(aim_direction, auto_diarrhea_data)

func _fire_gas_cone() -> void:
	# Gas cone: fan-shaped overlap check using area detection
	var cone_area: Area2D = _create_cone_area()
	get_parent().add_child(cone_area)
	cone_area.global_position = global_position
	# Enemies in cone receive stench debuff via their own signal handler
	await get_tree().process_frame
	cone_area.queue_free()

func _create_cone_area() -> Area2D:
	var area: Area2D = Area2D.new()
	var shape: CollisionShape2D = CollisionShape2D.new()
	var cone_shape: CircleShape2D = CircleShape2D.new()
	var radius: float = gas_cone_data.range if gas_cone_data else 200.0
	cone_shape.radius = radius
	shape.shape = cone_shape
	area.add_child(shape)
	area.collision_layer = 0
	area.collision_mask = 2  # enemy layer
	return area

func switch_fire_mode(new_mode: FireMode) -> void:
	fire_mode = new_mode
	_auto_fire_timer = 0.0
	fire_mode_changed.emit(new_mode)

func _on_hit_landed(_target: Node, _damage: float, _damage_type: String, is_crit: bool) -> void:
	var session: Node = Engine.get_singleton("GameSession")
	if not session:
		return
	if is_crit:
		session.add_pressure(5.0)
	else:
		session.add_pressure(2.0)

func _on_enemy_died(_enemy: Node, _position: Vector2) -> void:
	var session: Node = Engine.get_singleton("GameSession")
	if session:
		session.add_pressure(10.0)

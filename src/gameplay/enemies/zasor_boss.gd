class_name ZasorBoss
extends EnemyBase
## Засор (Blockage) — Chapter 1 boss, 3-phase encounter
##
## Phase 1 (HP 100% → 70%): normal advance + Grease Spit (projectile) every 4s
## Phase 2 (HP 70% → 40%):  spawns 3 Mini-Clogs that advance independently
## Phase 3 (HP 40% →  0%):  reform animation (1.5s invulnerable) → punish window
##                           (×2 damage taken for 1.5s) → charge attack
##
## Set mini_clog_scene and grease_spit_scene in the inspector.

signal phase_changed(new_phase: int)
signal punish_window_opened()
signal punish_window_closed()

enum Phase { ONE, TWO, THREE, REFORMING, PUNISH, DEAD }

@export var mini_clog_scene: PackedScene
@export var grease_spit_scene: PackedScene
@export var grease_spit_interval: float = 4.0
@export var mini_clog_offset: float = 50.0
@export var charge_damage: float = 35.0

var current_phase: Phase = Phase.ONE
var _spit_timer: float = 0.0
var _reform_timer: float = 0.0
var _punish_timer: float = 0.0
var _mini_clogs_spawned: bool = false
var _punish_multiplier: float = 1.0

const REFORM_DURATION: float = 1.5
const PUNISH_DURATION: float = 1.5
const PHASE2_HP_PCT: float = 0.70
const PHASE3_HP_PCT: float = 0.40


func _ready() -> void:
	add_to_group("boss")
	super._ready()


func _process(delta: float) -> void:
	if current_phase == Phase.DEAD:
		return
	_process_debuffs(delta)
	_process_phase_logic(delta)
	_move(delta)


func _process_phase_logic(delta: float) -> void:
	var hp_pct: float = hp / max_hp
	match current_phase:
		Phase.ONE:
			if hp_pct <= PHASE2_HP_PCT:
				_enter_phase_two()
			else:
				_tick_grease_spit(delta)
		Phase.TWO:
			if hp_pct <= PHASE3_HP_PCT:
				_enter_phase_three()
			else:
				_tick_grease_spit(delta)
		Phase.THREE:
			_tick_grease_spit(delta)
		Phase.REFORMING:
			_reform_timer -= delta
			if _reform_timer <= 0.0:
				_enter_punish_window()
		Phase.PUNISH:
			_punish_timer -= delta
			if _punish_timer <= 0.0:
				_end_punish_window()


func take_damage(amount: float, damage_type: DamageType = DamageType.NORMAL) -> void:
	if current_phase == Phase.REFORMING:
		return  # Invulnerable during reform
	super.take_damage(amount * _punish_multiplier, damage_type)


func _enter_phase_two() -> void:
	current_phase = Phase.TWO
	phase_changed.emit(2)
	if not _mini_clogs_spawned:
		_mini_clogs_spawned = true
		_spawn_mini_clogs()


func _enter_phase_three() -> void:
	current_phase = Phase.REFORMING
	_reform_timer = REFORM_DURATION
	phase_changed.emit(3)
	# Brief invulnerability during reform animation


func _enter_punish_window() -> void:
	current_phase = Phase.PUNISH
	_punish_multiplier = 2.0
	_punish_timer = PUNISH_DURATION
	punish_window_opened.emit()


func _end_punish_window() -> void:
	current_phase = Phase.THREE
	_punish_multiplier = 1.0
	punish_window_closed.emit()
	# Charge attack — deal damage directly to throne
	var session: GameSession = Engine.get_singleton("GameSession") as GameSession
	if session:
		session.add_pressure(charge_damage)


func _tick_grease_spit(delta: float) -> void:
	_spit_timer += delta
	if _spit_timer >= grease_spit_interval:
		_spit_timer = 0.0
		_fire_grease_spit()


func _fire_grease_spit() -> void:
	if grease_spit_scene == null:
		return
	var proj: Node2D = grease_spit_scene.instantiate() as Node2D
	get_parent().add_child(proj)
	proj.global_position = global_position
	if proj.has_method("launch"):
		# Aim toward throne
		var throne: Node = get_tree().get_first_node_in_group("central_tower")
		var target_pos: Vector2 = get_viewport().get_visible_rect().get_center()
		if throne is Node2D:
			target_pos = (throne as Node2D).global_position
		var dir: Vector2 = (target_pos - global_position).normalized()
		proj.call("launch", dir, null)


func _spawn_mini_clogs() -> void:
	if mini_clog_scene == null:
		return
	var spawn_parent: Node = get_parent()
	if spawn_parent == null:
		return
	for i: int in range(3):
		var mini: EnemyBase = mini_clog_scene.instantiate() as EnemyBase
		mini.global_position = global_position + Vector2(float(i - 1) * mini_clog_offset * 2.0, 0.0)
		if _path_follower != null:
			var follower: PathFollow2D = PathFollow2D.new()
			follower.rotates = false
			follower.loop = false
			_path_follower.get_parent().add_child(follower)
			follower.progress = _path_follower.progress
			mini.setup_path(follower)
			mini.died.connect(func(_e: EnemyBase, _p: Vector2) -> void: follower.queue_free())
		spawn_parent.add_child(mini)


func _die() -> void:
	current_phase = Phase.DEAD
	super._die()

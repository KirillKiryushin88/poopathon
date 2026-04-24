class_name EnemyBase
extends Node2D

signal died(enemy: EnemyBase, position: Vector2)
signal reached_throne(damage: float)

enum DamageType { NORMAL, FIRE, ICE, POISON, ACID }

@export var enemy_data: EnemyData

var hp: float = 100.0
var max_hp: float = 100.0
var armor: float = 0.0
var move_speed: float = 60.0
var throne_damage: float = 10.0

var _is_dead: bool = false
var _path_follower: PathFollow2D = null
var _stench_timer: float = 0.0
var _freeze_timer: float = 0.0
var _poison_timer: float = 0.0
var _poison_dps: float = 0.0
var _slow_factor: float = 1.0

func _ready() -> void:
	add_to_group("enemies")
	if enemy_data:
		hp = enemy_data.base_hp
		max_hp = enemy_data.base_hp
		armor = enemy_data.base_armor
		move_speed = enemy_data.base_speed
		throne_damage = enemy_data.throne_damage

func setup_path(follower: PathFollow2D) -> void:
	_path_follower = follower

func _process(delta: float) -> void:
	if _is_dead:
		return
	_process_debuffs(delta)
	_move(delta)

func _move(delta: float) -> void:
	if _path_follower == null or _freeze_timer > 0.0:
		return
	var effective_speed: float = move_speed * _slow_factor
	_path_follower.progress += effective_speed * delta
	global_position = _path_follower.global_position
	if _path_follower.progress_ratio >= 1.0:
		_on_reached_end()

func _process_debuffs(delta: float) -> void:
	if _freeze_timer > 0.0:
		_freeze_timer = maxf(_freeze_timer - delta, 0.0)
	if _stench_timer > 0.0:
		_stench_timer = maxf(_stench_timer - delta, 0.0)
	if _poison_timer > 0.0:
		_poison_timer -= delta
		take_damage(_poison_dps * delta, DamageType.POISON)
		if _poison_timer <= 0.0:
			_poison_timer = 0.0
			_poison_dps = 0.0

func take_damage(amount: float, damage_type: DamageType = DamageType.NORMAL) -> void:
	if _is_dead:
		return
	var effective: float = maxf(amount - armor, 0.0)
	if damage_type == DamageType.POISON:
		effective = amount  # poison bypasses armor
	hp -= effective
	if hp <= 0.0:
		_die()

func apply_slow(factor: float, duration: float) -> void:
	_slow_factor = minf(_slow_factor, factor)
	await get_tree().create_timer(duration).timeout
	_slow_factor = 1.0

func apply_freeze(duration: float) -> void:
	_freeze_timer = maxf(_freeze_timer, duration)

func apply_poison(dps: float, duration: float) -> void:
	_poison_dps = maxf(_poison_dps, dps)
	_poison_timer = maxf(_poison_timer, duration)

func apply_stench(duration: float) -> void:
	_stench_timer = maxf(_stench_timer, duration)

func has_stench() -> bool:
	return _stench_timer > 0.0

func _die() -> void:
	if _is_dead:
		return
	_is_dead = true
	remove_from_group("enemies")
	var bus: Node = Engine.get_singleton("CombatEventBus")
	if bus:
		bus.enemy_died.emit(self, global_position)
	died.emit(self, global_position)
	queue_free()

func _on_reached_end() -> void:
	_is_dead = true
	remove_from_group("enemies")
	reached_throne.emit(throne_damage)
	queue_free()

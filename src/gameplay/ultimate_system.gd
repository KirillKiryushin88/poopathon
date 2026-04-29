class_name UltimateSystem
extends Node
## UltimateSystem — Смыв (Flush) and Пердеж (Fart) ultimates for M1
## Add as child of the level scene. Reads pressure from GameSession.
## Auto-releases weak Смыв after 30-second timeout at 100 pressure.

signal ultimate_fired(ultimate_id: String)

enum Ultimate { SMYV, PERDEЖ }

## How far enemies are pushed back by Смыв (in pixels)
@export var flush_pushback_distance: float = 200.0
## Damage dealt to all enemies during Смыв
@export var flush_damage: float = 40.0
## Radius of Пердеж AoE
@export var fart_radius: float = 250.0
## Duration of fear effect in seconds
@export var fart_fear_duration: float = 3.0
## Pердеж direct damage
@export var fart_damage: float = 25.0

const PRESSURE_TIMEOUT: float = 30.0

var _pressure_timer: float = 0.0
var _pressure_is_full: bool = false
var _active_ultimate: Ultimate = Ultimate.SMYV


func _ready() -> void:
	var session: GameSession = Engine.get_singleton("GameSession") as GameSession
	if session:
		session.pressure_changed.connect(_on_pressure_changed)

	var bus: CombatEventBus = Engine.get_singleton("CombatEventBus") as CombatEventBus
	if bus:
		bus.ultimate_activated.connect(_on_ultimate_activated)


func _process(delta: float) -> void:
	if not _pressure_is_full:
		return
	_pressure_timer += delta
	if _pressure_timer >= PRESSURE_TIMEOUT:
		_pressure_timer = 0.0
		_fire_weak_flush()


func select_ultimate(u: Ultimate) -> void:
	_active_ultimate = u


func try_activate() -> bool:
	var session: GameSession = Engine.get_singleton("GameSession") as GameSession
	if session == null or session.pressure < GameSession.MAX_PRESSURE:
		return false
	_activate_selected()
	return true


func _activate_selected() -> void:
	match _active_ultimate:
		Ultimate.SMYV:  _fire_flush(flush_damage)
		Ultimate.PERDEЖ: _fire_fart()
	_reset_pressure()


## Weak Flush — auto-release, reduced damage
func _fire_weak_flush() -> void:
	_fire_flush(flush_damage * 0.4)
	_reset_pressure()


func _fire_flush(dmg: float) -> void:
	var enemies: Array[Node] = get_tree().get_nodes_in_group("enemies")
	for node: Node in enemies:
		if node is EnemyBase:
			var enemy: EnemyBase = node as EnemyBase
			enemy.take_damage(dmg, EnemyBase.DamageType.NORMAL)
			# Push back along their path
			if enemy.get_parent() is PathFollow2D:
				var pf: PathFollow2D = enemy.get_parent() as PathFollow2D
				pf.progress = maxf(pf.progress - flush_pushback_distance, 0.0)
	_emit_activated("smyv")


func _fire_fart() -> void:
	var enemies: Array[Node] = get_tree().get_nodes_in_group("enemies")
	var origin: Vector2 = _get_throne_position()
	for node: Node in enemies:
		if node is EnemyBase:
			var enemy: EnemyBase = node as EnemyBase
			if enemy.global_position.distance_to(origin) <= fart_radius:
				enemy.take_damage(fart_damage, EnemyBase.DamageType.POISON)
				# Fear: briefly reverse path progress
				if enemy.get_parent() is PathFollow2D:
					var pf: PathFollow2D = enemy.get_parent() as PathFollow2D
					pf.progress = maxf(pf.progress - 80.0, 0.0)
				enemy.apply_slow(0.0, fart_fear_duration)  # full stop = fear
	_emit_activated("perdeж")


func _get_throne_position() -> Vector2:
	var throne: Node = get_tree().get_first_node_in_group("central_tower")
	if throne is Node2D:
		return (throne as Node2D).global_position
	return get_viewport().get_visible_rect().get_center()


func _reset_pressure() -> void:
	var session: GameSession = Engine.get_singleton("GameSession") as GameSession
	if session:
		session.pressure = 0.0
		session.pressure_changed.emit(0.0)
	_pressure_is_full = false
	_pressure_timer = 0.0


func _emit_activated(id: String) -> void:
	ultimate_fired.emit(id)
	var bus: CombatEventBus = Engine.get_singleton("CombatEventBus") as CombatEventBus
	if bus:
		bus.ultimate_activated.emit(id)


func _on_pressure_changed(new_value: float) -> void:
	_pressure_is_full = new_value >= GameSession.MAX_PRESSURE
	if not _pressure_is_full:
		_pressure_timer = 0.0


func _on_ultimate_activated(_id: String) -> void:
	pass  # Reserved for future cross-system hooks

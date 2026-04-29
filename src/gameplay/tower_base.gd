class_name TowerBase
extends Node2D
## TowerBase — base class for all altar towers
## Subclasses override _apply_hit_effect() for elemental behaviour.

signal target_acquired(enemy: EnemyBase)

enum School { RED, BLUE, GREEN }

@export var tower_name: String = "Tower"
@export var school: School = School.RED
@export var tier: int = 1
@export var attack_range: float = 140.0
@export var attack_interval: float = 1.0
@export var damage: float = 20.0
@export var projectile_scene: PackedScene

var slot_id: int = -1

var _fire_timer: float = 0.0
var _current_target: EnemyBase = null
var _detection_area: Area2D = null


func _ready() -> void:
	_setup_detection()


func _setup_detection() -> void:
	_detection_area = Area2D.new()
	_detection_area.collision_layer = 0
	_detection_area.collision_mask = 2  # enemy layer
	var shape: CollisionShape2D = CollisionShape2D.new()
	var circle: CircleShape2D = CircleShape2D.new()
	circle.radius = attack_range
	shape.shape = circle
	_detection_area.add_child(shape)
	add_child(_detection_area)
	_detection_area.body_entered.connect(_on_enemy_entered)
	_detection_area.body_exited.connect(_on_enemy_exited)


func _process(delta: float) -> void:
	_fire_timer = maxf(_fire_timer - delta, 0.0)
	_refresh_target()
	if _current_target != null and _fire_timer <= 0.0:
		_fire_timer = attack_interval
		_fire_at(_current_target)


func _refresh_target() -> void:
	if _current_target != null and is_instance_valid(_current_target) and not _current_target.is_queued_for_deletion():
		return
	_current_target = null
	# Pick nearest enemy in range
	var best_dist: float = attack_range + 1.0
	for body: Node2D in _detection_area.get_overlapping_bodies():
		if body is EnemyBase:
			var d: float = global_position.distance_to(body.global_position)
			if d < best_dist:
				best_dist = d
				_current_target = body as EnemyBase


func _fire_at(target: EnemyBase) -> void:
	if projectile_scene != null:
		var proj: Node2D = projectile_scene.instantiate() as Node2D
		get_parent().add_child(proj)
		proj.global_position = global_position
		if proj.has_method("launch"):
			var dir: Vector2 = (target.global_position - global_position).normalized()
			proj.call("launch", dir, null)
	else:
		# Direct-hit fallback (no projectile scene set)
		_apply_direct_hit(target)

	_apply_hit_effect(target)


func _apply_direct_hit(target: EnemyBase) -> void:
	target.take_damage(damage)
	var bus: CombatEventBus = Engine.get_singleton("CombatEventBus") as CombatEventBus
	if bus:
		bus.hit_landed.emit(target, damage, _damage_type_string(), false)


func _apply_hit_effect(_target: EnemyBase) -> void:
	# Override in subclasses for elemental effects (Burn, Slow, Mold)
	pass


func _damage_type_string() -> String:
	match school:
		School.RED:   return "fire"
		School.BLUE:  return "ice"
		School.GREEN: return "poison"
	return "normal"


func _on_enemy_entered(body: Node) -> void:
	if body is EnemyBase and _current_target == null:
		_current_target = body as EnemyBase


func _on_enemy_exited(body: Node) -> void:
	if body == _current_target:
		_current_target = null

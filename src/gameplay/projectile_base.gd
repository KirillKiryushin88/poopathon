class_name ProjectileBase
extends Area2D

var _direction: Vector2 = Vector2.DOWN
var _speed: float = 600.0
var _damage: float = 8.0
var _pierce_count: int = 0
var _stagger_force: float = 0.0
var _hits: int = 0
var _is_crit: bool = false

func launch(direction: Vector2, data: TowerFireModeData) -> void:
	_direction = direction
	if data:
		_damage = data.damage
		_pierce_count = data.pierce_count
		_stagger_force = data.stagger_force
	_is_crit = randf() < 0.15  # 15% base crit chance — TODO: move to TowerData
	set_process(true)
	body_entered.connect(_on_body_entered)

func _process(delta: float) -> void:
	global_position += _direction * _speed * delta
	# Despawn if off screen
	if global_position.y < -100.0 or global_position.y > 2000.0:
		queue_free()

func _on_body_entered(body: Node) -> void:
	if not body.is_in_group("enemies"):
		return
	if body.has_method("take_damage"):
		var dtype: String = "normal"
		body.take_damage(_damage, dtype)
	var bus: Node = Engine.get_singleton("CombatEventBus")
	if bus:
		bus.hit_landed.emit(body, _damage, "normal", _is_crit)
	_hits += 1
	if _pierce_count <= 0 or _hits > _pierce_count:
		queue_free()

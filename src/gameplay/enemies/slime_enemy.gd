class_name SlimeEnemy
extends EnemyBase
## Slime — splits into 2 Mini-Slimes on death
## Stats: base_hp=80, base_speed=35, throne_damage=12, soft_reward=12
## Set mini_slime_scene to the Mini-Slime packed scene in inspector.
## is_mini flag prevents infinite split recursion.

@export var mini_slime_scene: PackedScene
@export var is_mini: bool = false
@export var mini_offset: float = 28.0


func _die() -> void:
	if not is_mini and mini_slime_scene != null:
		_spawn_minis()
	super._die()


func _spawn_minis() -> void:
	var spawn_parent: Node = get_parent()
	if spawn_parent == null:
		return
	for i: int in range(2):
		var mini: SlimeEnemy = mini_slime_scene.instantiate() as SlimeEnemy
		mini.is_mini = true
		mini.global_position = global_position + Vector2(float(i * 2 - 1) * mini_offset, 0.0)
		# Mini inherits a path if this enemy had one
		if _path_follower != null:
			var mini_follower: PathFollow2D = PathFollow2D.new()
			mini_follower.rotates = false
			mini_follower.loop = false
			_path_follower.get_parent().add_child(mini_follower)
			mini_follower.progress = _path_follower.progress
			mini.setup_path(mini_follower)
			mini.died.connect(func(_e: SlimeEnemy, _p: Vector2) -> void: mini_follower.queue_free())
		spawn_parent.add_child(mini)

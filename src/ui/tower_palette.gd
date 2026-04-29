class_name TowerPalette
extends Control
## TowerPalette — left thumb zone swipe-up tower selection and drag-to-place (S12)
## Collapsed by default; swipe up from left zone to expand 3 tower cards.
## Drag a card onto a TowerSlot node to place the tower.

signal tower_drag_started(tower_scene: PackedScene, base_cost: int)
signal tower_drag_cancelled()

@export var tower_options: Array[Dictionary] = []
## [{name, scene (PackedScene), cost, icon_color}]

var _expanded: bool = false
var _drag_scene: PackedScene = null
var _drag_cost: int = 0
var _drag_ghost: Control = null

const EXPAND_SWIPE_THRESHOLD: float = 30.0


func _ready() -> void:
	visible = false
	# Default tower options — set PackedScene refs in editor
	if tower_options.is_empty():
		tower_options = [
			{"name": "Ember Pipe",        "cost": 40, "color": Color(1.0, 0.4, 0.0)},
			{"name": "Chill Pipe",        "cost": 35, "color": Color(0.3, 0.7, 1.0)},
			{"name": "Mold Vent",         "cost": 50, "color": Color(0.5, 0.9, 0.1)},
		]


func expand() -> void:
	_expanded = true
	visible = true


func collapse() -> void:
	_expanded = false
	visible = false
	_cancel_drag()


func toggle() -> void:
	if _expanded:
		collapse()
	else:
		expand()


## Called by the touch handler when a tower card is dragged.
func begin_drag(option_index: int, drag_origin: Vector2) -> void:
	if option_index >= tower_options.size():
		return
	var opt: Dictionary = tower_options[option_index]
	_drag_scene = opt.get("scene") as PackedScene
	_drag_cost = int(opt.get("cost", 0))
	tower_drag_started.emit(_drag_scene, _drag_cost)


## Call when the drag is released — LevelController checks for slot overlap.
func end_drag(release_position: Vector2) -> void:
	# Find slot under cursor
	var slots: Array[Node] = get_tree().get_nodes_in_group("tower_slots")
	for node: Node in slots:
		if node is TowerSlot:
			var slot: TowerSlot = node as TowerSlot
			var local_pos: Vector2 = slot.to_local(release_position)
			if Rect2(-32, -32, 64, 64).has_point(local_pos):
				var is_mid_wave: bool = _is_mid_wave()
				slot.try_place(_drag_scene, _drag_cost, is_mid_wave)
				break
	_cancel_drag()
	collapse()


func _cancel_drag() -> void:
	_drag_scene = null
	_drag_cost = 0
	if _drag_ghost:
		_drag_ghost.queue_free()
		_drag_ghost = null
	tower_drag_cancelled.emit()


func _is_mid_wave() -> bool:
	var session: GameSession = Engine.get_singleton("GameSession") as GameSession
	return session != null and session.wave_number > 0

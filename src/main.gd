extends Node
## Main — persistent root scene controller
## Children: HUD (CanvasLayer, persistent), ContentRoot (Node2D, swapped by SceneManager)

@onready var _content_root: Node2D = $ContentRoot


func _ready() -> void:
	# Main is NOT an autoload — calling register_content_root() here is the
	# deliberate bootstrap seam (ADR-001). Rule 3 (no inter-autoload direct calls)
	# applies between autoloads; Main is a scene node and this one call is required
	# to wire the content root before any scene transition can occur.
	var scene_manager: Node = Engine.get_singleton("SceneManager")
	if scene_manager and scene_manager.has_method("register_content_root"):
		scene_manager.register_content_root(_content_root)

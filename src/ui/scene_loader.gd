class_name SceneLoader
extends CanvasLayer
## SceneLoader — fullscreen transition overlay for scene changes
## Add as child of Main.tscn (layer 15, above game, below top HUD).
## Call SceneLoader.transition_to(path) instead of SceneManager.transition_to().
## Handles: fade-out → scene load → fade-in with optional loading bar.

signal transition_finished()

@export var fade_duration: float = 0.25
@export var show_loading_bar: bool = false

@onready var _overlay: ColorRect   = $Overlay
@onready var _bar: ProgressBar     = $Bar
@onready var _label: Label         = $Label

var _is_transitioning: bool = false


func _ready() -> void:
	layer = 15
	_overlay.color = Color(0.03, 0.01, 0.0, 0.0)
	if _bar:
		_bar.visible = false
	if _label:
		_label.visible = false


func transition_to(path: String, loading_text: String = "") -> void:
	if _is_transitioning:
		return
	_is_transitioning = true

	# Fade out
	var t_out: Tween = create_tween()
	t_out.tween_property(_overlay, "color:a", 1.0, fade_duration)
	await t_out.finished

	# Show loading indicator if requested
	if show_loading_bar and _bar:
		_bar.visible = true
		_bar.value = 0.0
	if loading_text != "" and _label:
		_label.text = loading_text
		_label.visible = true

	# Delegate actual load to SceneManager
	var mgr: SceneManager = Engine.get_singleton("SceneManager") as SceneManager
	if mgr:
		mgr.scene_load_completed.connect(_on_scene_loaded.bind(path), CONNECT_ONE_SHOT)
		mgr.transition_to(path)
	else:
		# Fallback: direct change
		get_tree().change_scene_to_file(path)
		_finish_transition()


func _on_scene_loaded(_path: String) -> void:
	if _bar:
		_bar.value = 100.0
	_finish_transition()


func _finish_transition() -> void:
	if _bar:
		_bar.visible = false
	if _label:
		_label.visible = false

	var t_in: Tween = create_tween()
	t_in.tween_property(_overlay, "color:a", 0.0, fade_duration)
	await t_in.finished
	_is_transitioning = false
	transition_finished.emit()

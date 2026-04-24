extends Node
## SceneManager — non-blocking scene loading via ResourceLoader threads
## Autoload order: between SaveService and PlatformBridge (inserted as needed)
## Never use get_tree().change_scene_to_file() for in-game transitions (ADR-001)

signal scene_load_started(path: String)
signal scene_load_completed(path: String)
signal scene_unloaded()

var _current_scene: Node = null
var _content_root: Node = null  # set by Main.tscn on ready
var _loading_path: String = ""


func _ready() -> void:
	set_process(false)


func register_content_root(root: Node) -> void:
	_content_root = root


func transition_to(path: String) -> void:
	assert(_content_root != null, "SceneManager: content_root not registered. Call register_content_root() from Main.tscn")
	scene_load_started.emit(path)
	_loading_path = path
	ResourceLoader.load_threaded_request(path)
	set_process(true)


func _process(_delta: float) -> void:
	if _loading_path.is_empty():
		return
	var status: ResourceLoader.ThreadLoadStatus = ResourceLoader.load_threaded_get_status(_loading_path)
	match status:
		ResourceLoader.THREAD_LOAD_LOADED:
			_finish_load()
		ResourceLoader.THREAD_LOAD_FAILED:
			push_error("SceneManager: failed to load %s" % _loading_path)
			_loading_path = ""
			set_process(false)


func _finish_load() -> void:
	var resource: Resource = ResourceLoader.load_threaded_get(_loading_path)
	_unload_current()
	_current_scene = (resource as PackedScene).instantiate()
	_content_root.add_child(_current_scene)
	scene_load_completed.emit(_loading_path)
	_loading_path = ""
	set_process(false)


func _unload_current() -> void:
	if _current_scene != null:
		_current_scene.queue_free()
		_current_scene = null
		scene_unloaded.emit()

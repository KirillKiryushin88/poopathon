class_name VfxManager
extends Node
## VfxManager — autoload for screen shake, hit flash, impact panels, burst rings
## Usage:
##   VfxManager.shake(8.0, 0.35)
##   VfxManager.hit_flash(enemy_sprite, Color(1,1,1), 0.08)
##   VfxManager.impact_panel("KA-SPLAT!", world_pos)
##   VfxManager.burst_ring(world_pos, Color(1,0.5,0), 80.0)

## Connect this autoload to Main's camera node via set_camera() after scene loads.

signal shake_started(intensity: float, duration: float)

# ── Camera shake ──────────────────────────────────────────────────────────────
var _camera: Camera2D = null
var _shake_intensity: float = 0.0
var _shake_timer: float = 0.0
var _shake_origin: Vector2 = Vector2.ZERO

# ── Impact panel pool ─────────────────────────────────────────────────────────
const PANEL_POOL_SIZE: int = 8
var _panel_pool: Array[Label] = []
var _panel_canvas: CanvasLayer = null

const IMPACT_TEXTS: Dictionary = {
	"chunk":   ["KA-SPLAT!", "BLORP!", "THWUMP!"],
	"auto":    ["RAT-A-TAT!", "SPLAT!", "PEW!"],
	"gas":     ["BWAAAP!", "TOXIC!", "РЫГНУЛО!"],
	"throne":  ["THRONE HIT!", "ДЕРЬМО!"],
	"ultimate":["FLUSH!!!", "PURGED!", "СБРОС!"],
}


func _ready() -> void:
	_build_panel_pool()
	var bus: CombatEventBus = Engine.get_singleton("CombatEventBus") as CombatEventBus
	if bus:
		bus.hit_landed.connect(_on_hit_landed)


func set_camera(cam: Camera2D) -> void:
	_camera = cam
	if cam:
		_shake_origin = cam.offset


# ── Public API ────────────────────────────────────────────────────────────────

func shake(intensity: float, duration: float) -> void:
	_shake_intensity = maxf(_shake_intensity, intensity)
	_shake_timer = maxf(_shake_timer, duration)
	shake_started.emit(intensity, duration)


func hit_flash(sprite: CanvasItem, color: Color, duration: float) -> void:
	if sprite == null or not is_instance_valid(sprite):
		return
	var original: Color = sprite.modulate
	sprite.modulate = color
	var t: Tween = create_tween()
	t.tween_property(sprite, "modulate", original, duration)


func impact_panel(category: String, world_pos: Vector2) -> void:
	var pool: Array[String] = IMPACT_TEXTS.get(category, IMPACT_TEXTS["chunk"]) as Array[String]
	var txt: String = pool[randi() % pool.size()]
	_spawn_panel(txt, world_pos)


func impact_panel_text(text: String, world_pos: Vector2) -> void:
	_spawn_panel(text, world_pos)


func burst_ring(world_pos: Vector2, color: Color, max_radius: float = 60.0, duration: float = 0.35) -> void:
	# Draw an expanding ring via a temporary Line2D
	var ring: Line2D = Line2D.new()
	ring.default_color = color
	ring.width = 3.0
	ring.closed = true
	_add_to_canvas(ring)
	ring.global_position = world_pos

	var points: PackedVector2Array = PackedVector2Array()
	for i: int in range(32):
		var angle: float = (float(i) / 32.0) * TAU
		points.append(Vector2(cos(angle), sin(angle)) * 4.0)
	ring.points = points

	var t: Tween = create_tween()
	t.set_parallel(true)
	t.tween_method(
		func(r: float) -> void: _update_ring(ring, r),
		4.0, max_radius, duration
	)
	t.tween_property(ring, "modulate:a", 0.0, duration)
	t.tween_callback(ring.queue_free).set_delay(duration)


# ── Process ───────────────────────────────────────────────────────────────────

func _process(delta: float) -> void:
	if _shake_timer > 0.0:
		_shake_timer -= delta
		if _shake_timer <= 0.0:
			_shake_intensity = 0.0
			if _camera:
				_camera.offset = _shake_origin
		elif _camera:
			var d: float = _shake_timer / maxf(_shake_timer + delta, 0.001)
			var off: Vector2 = Vector2(
				randf_range(-1.0, 1.0),
				randf_range(-1.0, 1.0)
			) * _shake_intensity * d
			_camera.offset = _shake_origin + off


# ── Internals ─────────────────────────────────────────────────────────────────

func _build_panel_pool() -> void:
	_panel_canvas = CanvasLayer.new()
	_panel_canvas.layer = 20
	add_child(_panel_canvas)
	for i: int in range(PANEL_POOL_SIZE):
		var lbl: Label = Label.new()
		lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		lbl.visible = false
		lbl.add_theme_font_size_override("font_size", 22)
		_panel_canvas.add_child(lbl)
		_panel_pool.append(lbl)


func _spawn_panel(text: String, world_pos: Vector2) -> void:
	if randf() > 0.6:
		return  # 60% spawn rate keeps screen clean
	var lbl: Label = _get_free_panel()
	if lbl == null:
		return

	# Convert world → screen position
	var vp: Viewport = get_viewport()
	if vp == null:
		return
	var screen_pos: Vector2 = world_pos
	if _camera:
		screen_pos = _camera.get_screen_center_position() + (world_pos - _camera.global_position)

	lbl.text = text
	lbl.position = screen_pos + Vector2(randf_range(-30, 30), 0)
	lbl.modulate = Color(1.0, 0.9, 0.1, 1.0)
	lbl.rotation = randf_range(-0.25, 0.25)
	lbl.scale = Vector2(0.3, 0.3)
	lbl.visible = true

	var t: Tween = create_tween()
	t.set_parallel(true)
	t.tween_property(lbl, "scale", Vector2(1.0, 1.0), 0.12).set_trans(Tween.TRANS_BACK)
	t.tween_property(lbl, "position:y", lbl.position.y - 50.0, 0.6)
	t.tween_property(lbl, "modulate:a", 0.0, 0.4).set_delay(0.25)
	t.tween_callback(func() -> void: lbl.visible = false).set_delay(0.65)


func _get_free_panel() -> Label:
	for lbl: Label in _panel_pool:
		if not lbl.visible:
			return lbl
	return null


func _add_to_canvas(node: Node) -> void:
	if _panel_canvas:
		_panel_canvas.add_child(node)
	else:
		add_child(node)


func _update_ring(ring: Line2D, radius: float) -> void:
	if not is_instance_valid(ring):
		return
	var pts: PackedVector2Array = PackedVector2Array()
	for i: int in range(32):
		var angle: float = (float(i) / 32.0) * TAU
		pts.append(Vector2(cos(angle), sin(angle)) * radius)
	ring.points = pts


func _on_hit_landed(_target: Node, _damage: float, _dtype: String, is_crit: bool) -> void:
	if is_crit:
		shake(5.0, 0.18)

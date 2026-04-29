class_name UIAnimator
extends RefCounted
## UIAnimator — static helpers for common mobile UI animations
## No node required — call on any Control node from anywhere.
## All methods return the Tween so callers can chain callbacks.
##
## Usage:
##   UIAnimator.pop(my_button)
##   UIAnimator.slide_in_bottom(hud_panel, 0.3)
##   UIAnimator.shake(label, 6.0)
##   await UIAnimator.pop(card).finished

static func pop(node: Control, duration: float = 0.18) -> Tween:
	var t: Tween = node.create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	node.scale = Vector2(0.0, 0.0)
	node.pivot_offset = node.size * 0.5
	t.tween_property(node, "scale", Vector2(1.0, 1.0), duration)
	return t


static func pop_from(node: Control, from_scale: float = 0.6, duration: float = 0.22) -> Tween:
	var t: Tween = node.create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	node.scale = Vector2(from_scale, from_scale)
	node.pivot_offset = node.size * 0.5
	t.tween_property(node, "scale", Vector2(1.0, 1.0), duration)
	return t


static func dismiss(node: Control, duration: float = 0.14) -> Tween:
	var t: Tween = node.create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
	node.pivot_offset = node.size * 0.5
	t.tween_property(node, "scale", Vector2(0.0, 0.0), duration)
	t.tween_callback(func() -> void: node.visible = false)
	return t


static func slide_in_bottom(node: Control, duration: float = 0.28) -> Tween:
	var vp_h: float = node.get_viewport_rect().size.y
	var target_y: float = node.position.y
	node.position.y = vp_h + node.size.y
	var t: Tween = node.create_tween().set_trans(Tween.TRANS_QUINT).set_ease(Tween.EASE_OUT)
	t.tween_property(node, "position:y", target_y, duration)
	return t


static func slide_out_bottom(node: Control, duration: float = 0.22) -> Tween:
	var vp_h: float = node.get_viewport_rect().size.y
	var t: Tween = node.create_tween().set_trans(Tween.TRANS_QUINT).set_ease(Tween.EASE_IN)
	t.tween_property(node, "position:y", vp_h + node.size.y, duration)
	t.tween_callback(func() -> void: node.visible = false)
	return t


static func slide_in_left(node: Control, duration: float = 0.25) -> Tween:
	var target_x: float = node.position.x
	node.position.x = -node.size.x - 20.0
	var t: Tween = node.create_tween().set_trans(Tween.TRANS_QUINT).set_ease(Tween.EASE_OUT)
	t.tween_property(node, "position:x", target_x, duration)
	return t


static func shake(node: Control, intensity: float = 8.0, duration: float = 0.3) -> Tween:
	var origin: Vector2 = node.position
	var t: Tween = node.create_tween()
	var steps: int = int(duration / 0.04)
	for i: int in range(steps):
		var decay: float = 1.0 - float(i) / float(steps)
		var off: Vector2 = Vector2(randf_range(-1, 1), randf_range(-1, 1)) * intensity * decay
		t.tween_property(node, "position", origin + off, 0.04)
	t.tween_property(node, "position", origin, 0.04)
	return t


static func pulse(node: Control, scale_to: float = 1.15, duration: float = 0.2) -> Tween:
	var t: Tween = node.create_tween()
	node.pivot_offset = node.size * 0.5
	t.tween_property(node, "scale", Vector2(scale_to, scale_to), duration * 0.5) \
		.set_trans(Tween.TRANS_SINE)
	t.tween_property(node, "scale", Vector2(1.0, 1.0), duration * 0.5) \
		.set_trans(Tween.TRANS_SINE)
	return t


static func fade_in(node: CanvasItem, duration: float = 0.2) -> Tween:
	node.modulate.a = 0.0
	var t: Tween = node.create_tween()
	t.tween_property(node, "modulate:a", 1.0, duration)
	return t


static func fade_out(node: CanvasItem, duration: float = 0.2, and_hide: bool = true) -> Tween:
	var t: Tween = node.create_tween()
	t.tween_property(node, "modulate:a", 0.0, duration)
	if and_hide:
		t.tween_callback(func() -> void: node.visible = false)
	return t

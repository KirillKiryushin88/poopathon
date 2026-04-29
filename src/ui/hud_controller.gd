class_name HudController
extends CanvasLayer
## HudController — in-game HUD: wave, lives, pressure bar, ult button, wave-break countdown
## Expected scene tree:
##   HudController (CanvasLayer)
##     TopBar (HBoxContainer)
##       WaveLabel (Label)
##       LivesLabel (Label)
##     PressureRow (HBoxContainer)
##       PressureLabel (Label)
##       PressureBar (ProgressBar)
##     UltButton (Button)
##     WaveBreakPanel (PanelContainer) [hidden during waves]
##       BreakTimerLabel (Label)

@onready var _wave_label: Label         = $TopBar/WaveLabel
@onready var _lives_label: Label        = $TopBar/LivesLabel
@onready var _pressure_bar: ProgressBar = $PressureRow/PressureBar
@onready var _pressure_label: Label     = $PressureRow/PressureLabel
@onready var _ult_button: Button        = $UltButton
@onready var _break_panel: Control      = $WaveBreakPanel
@onready var _break_timer_label: Label  = $WaveBreakPanel/BreakTimerLabel

const MAX_LIVES: int = 3


func _ready() -> void:
	_break_panel.visible = false
	_connect_signals()


func _connect_signals() -> void:
	var session: GameSession = Engine.get_singleton("GameSession") as GameSession
	if session:
		session.pressure_changed.connect(_on_pressure_changed)
		session.wave_number_changed.connect(_on_wave_changed)

	var bus: CombatEventBus = Engine.get_singleton("CombatEventBus") as CombatEventBus
	if bus:
		bus.wave_break_started.connect(_on_wave_break_started)


func set_lives(count: int) -> void:
	if _lives_label:
		_lives_label.text = "❤ %d / %d" % [count, MAX_LIVES]


func _on_pressure_changed(new_value: float) -> void:
	if _pressure_bar:
		_pressure_bar.value = new_value
	if _pressure_label:
		_pressure_label.text = "PRESSURE %d%%" % int(new_value)
	if _ult_button:
		var ready: bool = new_value >= GameSession.MAX_PRESSURE
		_ult_button.modulate = Color.CYAN if ready else Color.WHITE
		_ult_button.disabled = not ready


func _on_wave_changed(wave: int) -> void:
	if _wave_label:
		_wave_label.text = "WAVE %d" % wave


func _on_wave_break_started(duration: float) -> void:
	_break_panel.visible = true
	_update_break_timer(duration)
	# Countdown via a tween so we don't need _process
	var tween: Tween = create_tween()
	tween.tween_method(_update_break_timer, duration, 0.0, duration)
	tween.tween_callback(func() -> void: _break_panel.visible = false)


func _update_break_timer(remaining: float) -> void:
	if _break_timer_label:
		_break_timer_label.text = "NEXT WAVE IN %ds" % ceili(remaining)

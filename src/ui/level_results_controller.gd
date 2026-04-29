class_name LevelResultsController
extends CanvasLayer
## LevelResultsController — post-level results screen (S31)
## Displays stars (1-3), Slime earned, retry / menu buttons.
## Call show_results() from the level controller when level ends.

signal retry_pressed()
signal menu_pressed()

@onready var _stars_label: Label     = $Panel/StarsLabel
@onready var _slime_label: Label     = $Panel/SlimeLabel
@onready var _title_label: Label     = $Panel/TitleLabel
@onready var _retry_button: Button   = $Panel/RetryButton
@onready var _menu_button: Button    = $Panel/MenuButton


func _ready() -> void:
	visible = false
	if _retry_button:
		_retry_button.pressed.connect(func() -> void: retry_pressed.emit())
	if _menu_button:
		_menu_button.pressed.connect(func() -> void: menu_pressed.emit())


func show_results(result: LevelResult) -> void:
	visible = true
	_apply_result(result)
	_save_result(result)


func _apply_result(result: LevelResult) -> void:
	if _title_label:
		_title_label.text = "ПОБЕДА!" if result.won else "ТРОН ОСКВЕРНЁН"

	var star_str: String = "★".repeat(result.stars) + "☆".repeat(3 - result.stars)
	if _stars_label:
		_stars_label.text = star_str

	if _slime_label:
		_slime_label.text = "+%d 💩 SLIME" % result.soft_earned


func _save_result(result: LevelResult) -> void:
	var meta: MetaProgression = Engine.get_singleton("MetaProgression") as MetaProgression
	if meta:
		meta.record_level_result(result)

	var economy: EconomyService = Engine.get_singleton("EconomyService") as EconomyService
	if economy:
		economy.add_soft(result.soft_earned)

	var save_svc: Node = Engine.get_singleton("SaveService")
	if save_svc and save_svc.has_method("save_game"):
		save_svc.call("save_game")

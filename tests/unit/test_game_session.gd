extends GutTest

const GameSessionScript := preload("res://src/autoloads/game_session.gd")
var _session: GameSession


func before_each() -> void:
	_session = GameSessionScript.new() as GameSession
	add_child(_session)


func after_each() -> void:
	_session.queue_free()


func test_initial_pressure_is_zero() -> void:
	assert_eq(_session.pressure, 0.0)


func test_add_pressure_increases_value() -> void:
	_session.add_pressure(10.0)
	assert_eq(_session.pressure, 10.0)


func test_pressure_clamps_at_max() -> void:
	_session.add_pressure(200.0)
	assert_eq(_session.pressure, _session.MAX_PRESSURE)


func test_pressure_changed_signal_emitted() -> void:
	watch_signals(_session)
	_session.add_pressure(5.0)
	assert_signal_emitted(_session, "pressure_changed")


func test_set_wave_updates_wave_number() -> void:
	_session.set_wave(2)
	assert_eq(_session.wave_number, 2)


func test_wave_number_changed_signal_emitted() -> void:
	watch_signals(_session)
	_session.set_wave(3)
	assert_signal_emitted(_session, "wave_number_changed")

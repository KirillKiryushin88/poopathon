extends GutTest

const EconomyServiceScript := preload("res://src/autoloads/economy_service.gd")
var _economy: EconomyService


func before_each() -> void:
	_economy = EconomyServiceScript.new() as EconomyService
	add_child(_economy)


func after_each() -> void:
	_economy.queue_free()


func test_add_soft_increases_balance() -> void:
	_economy.add_soft(100)
	assert_eq(_economy.soft_currency, 100)


func test_spend_soft_decreases_balance() -> void:
	_economy.add_soft(100)
	var result: bool = _economy.spend_soft(60)
	assert_true(result)
	assert_eq(_economy.soft_currency, 40)


func test_spend_soft_returns_false_when_insufficient() -> void:
	var result: bool = _economy.spend_soft(100)
	assert_false(result)
	assert_eq(_economy.soft_currency, 0)


func test_balance_changed_signal_emitted_on_add() -> void:
	watch_signals(_economy)
	_economy.add_soft(50)
	assert_signal_emitted(_economy, "balance_changed")


func test_add_hard_increases_balance() -> void:
	_economy.add_hard(10)
	assert_eq(_economy.hard_currency, 10)


func test_spend_hard_returns_false_when_insufficient() -> void:
	var result: bool = _economy.spend_hard(5)
	assert_false(result)


func test_get_save_data_returns_correct_dict() -> void:
	_economy.add_soft(200)
	_economy.add_hard(5)
	var data: Dictionary = _economy.get_save_data()
	assert_eq(data["soft"], 200)
	assert_eq(data["hard"], 5)


func test_restore_from_save_sets_correct_values() -> void:
	_economy.restore_from_save({"soft": 150, "hard": 3})
	assert_eq(_economy.soft_currency, 150)
	assert_eq(_economy.hard_currency, 3)

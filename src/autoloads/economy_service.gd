class_name EconomyService
extends Node
## EconomyService — manages soft and hard currency
## Autoload order: 3rd
## Never call methods on other autoloads directly — emit signals only

signal balance_changed(soft: int, hard: int)
signal insufficient_funds(currency_type: String, required: int, available: int)

var soft_currency: int = 0
var hard_currency: int = 0


func _ready() -> void:
	pass  # SaveService will call restore_from_save() after load


func add_soft(amount: int) -> void:
	assert(amount >= 0, "add_soft: amount must be non-negative")
	soft_currency += amount
	balance_changed.emit(soft_currency, hard_currency)


func spend_soft(amount: int) -> bool:
	assert(amount >= 0, "spend_soft: amount must be non-negative")
	if soft_currency < amount:
		insufficient_funds.emit("soft", amount, soft_currency)
		return false
	soft_currency -= amount
	balance_changed.emit(soft_currency, hard_currency)
	return true


func add_hard(amount: int) -> void:
	assert(amount >= 0, "add_hard: amount must be non-negative")
	hard_currency += amount
	balance_changed.emit(soft_currency, hard_currency)


func spend_hard(amount: int) -> bool:
	assert(amount >= 0, "spend_hard: amount must be non-negative")
	if hard_currency < amount:
		insufficient_funds.emit("hard", amount, hard_currency)
		return false
	hard_currency -= amount
	balance_changed.emit(soft_currency, hard_currency)
	return true


func get_save_data() -> Dictionary:
	return {"soft": soft_currency, "hard": hard_currency}


func restore_from_save(data: Dictionary) -> void:
	soft_currency = data.get("soft", 0) as int
	hard_currency = data.get("hard", 0) as int
	balance_changed.emit(soft_currency, hard_currency)

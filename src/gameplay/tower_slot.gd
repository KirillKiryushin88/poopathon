class_name TowerSlot
extends Node2D
## TowerSlot — manages one altar slot: placement, sell, visual state
## Add to level scene at each altar position.

signal tower_placed_here(slot_id: int, tower: TowerBase)
signal tower_removed_here(slot_id: int)

@export var slot_id: int = 0
@export var mid_wave_cost_multiplier: float = 1.3

var occupied_tower: TowerBase = null
var _invested_cost: int = 0


func is_empty() -> bool:
	return occupied_tower == null


func try_place(tower_scene: PackedScene, base_cost: int, is_mid_wave: bool) -> bool:
	if not is_empty():
		return false
	var final_cost: int = int(float(base_cost) * (mid_wave_cost_multiplier if is_mid_wave else 1.0))
	var economy: EconomyService = Engine.get_singleton("EconomyService") as EconomyService
	if economy == null or not economy.spend_soft(final_cost):
		return false

	occupied_tower = tower_scene.instantiate() as TowerBase
	occupied_tower.slot_id = slot_id
	add_child(occupied_tower)
	_invested_cost = final_cost

	var bus: CombatEventBus = Engine.get_singleton("CombatEventBus") as CombatEventBus
	if bus:
		bus.tower_placed.emit(slot_id, occupied_tower)
	tower_placed_here.emit(slot_id, occupied_tower)
	return true


func sell() -> void:
	if occupied_tower == null:
		return
	var refund: int = int(float(_invested_cost) * 0.6)
	var economy: EconomyService = Engine.get_singleton("EconomyService") as EconomyService
	if economy:
		economy.add_soft(refund)

	var bus: CombatEventBus = Engine.get_singleton("CombatEventBus") as CombatEventBus
	if bus:
		bus.tower_sold.emit(slot_id, refund)

	occupied_tower.queue_free()
	occupied_tower = null
	_invested_cost = 0
	tower_removed_here.emit(slot_id)

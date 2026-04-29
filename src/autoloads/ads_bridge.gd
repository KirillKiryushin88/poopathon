extends Node
## AdsBridge — M1 stub. Returns mock success; no real SDK integrated.
## Autoload order: add after BillingBridge when registering.
## All signals mirror the contract the real SDK will fulfil.

signal ad_rewarded_complete(placement_id: String)
signal ad_interstitial_closed(placement_id: String)
signal ad_load_failed(placement_id: String, error_code: int)

var _no_ads_purchased: bool = false


func _ready() -> void:
	print("[AdsBridge] stub ready — all ads will mock success")


## Called by EconomyService when no_ads is purchased.
func set_no_ads(purchased: bool) -> void:
	_no_ads_purchased = purchased


func show_rewarded(placement_id: String) -> void:
	if _no_ads_purchased:
		ad_rewarded_complete.emit(placement_id)
		return
	# Stub: immediate success after one frame
	await get_tree().process_frame
	ad_rewarded_complete.emit(placement_id)


func show_interstitial(placement_id: String) -> void:
	if _no_ads_purchased:
		return
	await get_tree().process_frame
	ad_interstitial_closed.emit(placement_id)

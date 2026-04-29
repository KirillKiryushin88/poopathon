extends Node
## BillingBridge — M1 stub. Returns mock purchase success; no SDK integrated.
## All signals mirror the Apple IAP / Google Play Billing contract.

signal purchase_completed(product_id: String)
signal purchase_failed(product_id: String, error_code: int)
signal restore_completed(restored_ids: Array[String])


func _ready() -> void:
	print("[BillingBridge] stub ready — all purchases will mock success")


func purchase(product_id: String) -> void:
	await get_tree().process_frame
	purchase_completed.emit(product_id)


func restore_purchases() -> void:
	await get_tree().process_frame
	restore_completed.emit([])

class_name BusinessRegistry
## BizTown — the list of known business paths. Static lookup only, no
## autoload needed (same pattern as GrayboxKit.gd). GameState.active_business_id
## selects which one is current; Chapter 1 always plays "soap_shop" today.
##
## "construction_materials" is a placeholder proving the data shape
## generalizes to a different kind of shop — it is NOT wired into gameplay
## (no missions, no shop scene, no economy tuning). Making a second business
## path actually playable is future work, not part of this foundation.

const DEFAULT_ID: String = "soap_shop"


static func get_business(business_id: String) -> BusinessType:
	var all: Dictionary = _all()
	if all.has(business_id):
		return all[business_id]
	push_warning("BusinessRegistry: unknown business id '%s', falling back to default" % business_id)
	return all[DEFAULT_ID]


static func get_active() -> BusinessType:
	return get_business(String(GameState.active_business_id))


static func _all() -> Dictionary:
	return {
		"soap_shop": _soap_shop(),
		"construction_materials": _construction_materials(),
	}


static func _soap_shop() -> BusinessType:
	var b := BusinessType.new()
	b.id = "soap_shop"
	b.display_name = "Soap Shop"
	b.product_name = SimConfig.PRODUCT_NAME
	b.shop_sign_text = "SOAP SHOP"
	b.expanded_sign_text = "SOAP SHOP II"
	b.tagline = "One shop, one street, one chance to prove yourself."
	b.starting_cash = SimConfig.STARTING_CASH
	b.starting_inventory = SimConfig.STARTING_INVENTORY
	b.product_cost = SimConfig.PRODUCT_COST
	b.price_min = SimConfig.PRICE_MIN
	b.price_max = SimConfig.PRICE_MAX
	b.customer_names = SimConfig.CREDIT_NAMES
	return b


## Placeholder only — proves the data shape generalizes. Not playable.
static func _construction_materials() -> BusinessType:
	var b := BusinessType.new()
	b.id = "construction_materials"
	b.display_name = "Construction Materials Store"
	b.product_name = "Cement"
	b.shop_sign_text = "BUILDING SUPPLIES"
	b.expanded_sign_text = "BUILDING SUPPLIES II"
	b.tagline = "Bricks, cement, and steel - building the town that builds itself."
	b.starting_cash = 15000.0
	b.starting_inventory = 25
	b.product_cost = 180.0
	b.price_min = 220.0
	b.price_max = 420.0
	b.customer_names = ["Contractor Bikash", "Engineer Meena", "Panda Constructions", "Site Foreman Raju"]
	return b

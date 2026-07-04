extends Node
## BizTown — Living Business Build: mutable runtime state. Autoloaded as "GameState".
## Holds DATA only — all logic lives in Sim.gd / EventEngine.gd.

var rng: RandomNumberGenerator = RandomNumberGenerator.new()

# Business path (foundation for multiple business types — see HUMAN_DECISIONS.md
# and scripts/business/. Chapter 1 only ever plays "soap_shop" today.)
var active_business_id: String

var cash: float
var reputation: float
var day: int
var inventory: int
var current_price: float
var current_unit_cost: float     # drifts daily within [COST_MIN, COST_MAX] + event deltas
var daily_costs: float
var has_ravi: bool
var has_expanded_shop: bool
var customers_served: int
var customers_lost: int
var regular_count: int           # loyal customers built by clean days
var traits: Dictionary

# Uncertainty & events
var pending_event: Dictionary    # rolled at end of day N, applies on day N+1 ({} = none)
var active_effects: Array = []   # [{id, days_left, ...}] multi-day modifiers

# Living customers
var credit_ledger: Array = []    # [{name, qty, amount, due_day, reliability, resolved}]
var bulk_commitments: Array = [] # [{qty, unit_price, days_left}]
var pending_credit_request: Dictionary = {}  # awaiting player choice ({} = none)
var pending_bulk_offer: Dictionary = {}      # awaiting player choice ({} = none)
var customer_relationships: Dictionary = {}  # name -> {paid: int, defaulted: int, refused: int}

# Lender
var lender_debt: float           # 0 = no debt; repay due at next month-end
var lender_offer_pending: bool


func _ready() -> void:
	reset()


## Reset everything to the Chapter 1 starting state.
func reset(seed_value: int = -1) -> void:
	if seed_value >= 0:
		rng.seed = seed_value
	else:
		rng.randomize()
	# Always the default for now — there is no player-facing business-select
	# screen yet, so every reset starts Chapter 1's one playable business.
	active_business_id = BusinessRegistry.DEFAULT_ID
	cash = SimConfig.STARTING_CASH
	reputation = SimConfig.STARTING_REPUTATION
	day = 0
	inventory = SimConfig.STARTING_INVENTORY
	current_price = SimConfig.DEFAULT_PRICE
	current_unit_cost = SimConfig.PRODUCT_COST
	daily_costs = 0.0
	has_ravi = false
	has_expanded_shop = false
	customers_served = 0
	customers_lost = 0
	regular_count = 0
	traits = { "pricing": {}, "risk": {}, "people": {}, "integrity": {} }
	pending_event = {}
	active_effects = []
	credit_ledger = []
	bulk_commitments = []
	pending_credit_request = {}
	pending_bulk_offer = {}
	customer_relationships = {}
	lender_debt = 0.0
	lender_offer_pending = false


## Record an entrepreneurial-style choice. Pure data — surfaced later, NEVER as a label/score.
func add_trait(dimension: String, value: String) -> void:
	if not traits.has(dimension):
		traits[dimension] = {}
	traits[dimension][value] = int(traits[dimension].get(value, 0)) + 1


## Record a named customer's credit outcome ("paid"/"defaulted"). Pure
## bookkeeping — EventEngine.gd reads this back to nudge that customer's next
## reliability roll; the nudge math itself lives there, not here. (Refusals
## aren't tracked: refusing someone is a fact about the player's caution,
## not a signal about that customer's own trustworthiness.)
func record_customer_outcome(customer_name: String, outcome: String) -> void:
	if not customer_relationships.has(customer_name):
		customer_relationships[customer_name] = {"paid": 0, "defaulted": 0}
	var rec: Dictionary = customer_relationships[customer_name]
	rec[outcome] = int(rec.get(outcome, 0)) + 1


## Full serializable snapshot (used by SaveManager).
func to_dict() -> Dictionary:
	return {
		"version": 1,
		"active_business_id": active_business_id,
		"rng_seed": rng.seed,
		"rng_state": rng.state,
		"cash": cash, "reputation": reputation, "day": day,
		"inventory": inventory, "current_price": current_price,
		"current_unit_cost": current_unit_cost, "daily_costs": daily_costs,
		"has_ravi": has_ravi, "has_expanded_shop": has_expanded_shop,
		"customers_served": customers_served, "customers_lost": customers_lost,
		"regular_count": regular_count, "traits": traits,
		"pending_event": pending_event, "active_effects": active_effects,
		"credit_ledger": credit_ledger, "bulk_commitments": bulk_commitments,
		"pending_credit_request": pending_credit_request,
		"pending_bulk_offer": pending_bulk_offer,
		"customer_relationships": customer_relationships,
		"lender_debt": lender_debt, "lender_offer_pending": lender_offer_pending,
	}


## Restore from a snapshot produced by to_dict().
func from_dict(d: Dictionary) -> void:
	active_business_id = String(d.get("active_business_id", BusinessRegistry.DEFAULT_ID))
	rng.seed = int(d.get("rng_seed", 0))
	rng.state = int(d.get("rng_state", 0))
	cash = float(d.get("cash", SimConfig.STARTING_CASH))
	reputation = float(d.get("reputation", SimConfig.STARTING_REPUTATION))
	day = int(d.get("day", 0))
	inventory = int(d.get("inventory", 0))
	current_price = float(d.get("current_price", SimConfig.DEFAULT_PRICE))
	current_unit_cost = float(d.get("current_unit_cost", SimConfig.PRODUCT_COST))
	daily_costs = float(d.get("daily_costs", 0.0))
	has_ravi = bool(d.get("has_ravi", false))
	has_expanded_shop = bool(d.get("has_expanded_shop", false))
	customers_served = int(d.get("customers_served", 0))
	customers_lost = int(d.get("customers_lost", 0))
	regular_count = int(d.get("regular_count", 0))
	traits = d.get("traits", {})
	pending_event = d.get("pending_event", {})
	active_effects = d.get("active_effects", [])
	credit_ledger = d.get("credit_ledger", [])
	bulk_commitments = d.get("bulk_commitments", [])
	pending_credit_request = d.get("pending_credit_request", {})
	pending_bulk_offer = d.get("pending_bulk_offer", {})
	customer_relationships = d.get("customer_relationships", {})
	lender_debt = float(d.get("lender_debt", 0.0))
	lender_offer_pending = bool(d.get("lender_offer_pending", false))

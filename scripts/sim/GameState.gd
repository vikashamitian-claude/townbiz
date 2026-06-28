extends Node
## BizTown — Sprint 1: mutable runtime state for the Chapter 1 simulation.
## Autoloaded as "GameState". Holds data only — all logic lives in Sim.gd.

var cash: float
var reputation: float
var day: int
var inventory: int
var current_price: float
var daily_costs: float          # recurring per-day costs (e.g. Ravi's wage)
var has_ravi: bool
var has_expanded_shop: bool      # Chapter 1 expansion decision (Mission 5 placeholder)
var customers_served: int       # lifetime total
var customers_lost: int         # lifetime total
var traits: Dictionary          # entrepreneurial-style tallies (data only; see add_trait)


func _ready() -> void:
	reset()


## Reset everything to the Chapter 1 starting state (values come from SimConfig).
func reset() -> void:
	cash = SimConfig.STARTING_CASH
	reputation = SimConfig.STARTING_REPUTATION
	day = 0
	inventory = SimConfig.STARTING_INVENTORY
	current_price = SimConfig.DEFAULT_PRICE
	daily_costs = 0.0
	has_ravi = false
	has_expanded_shop = false
	customers_served = 0
	customers_lost = 0
	traits = { "pricing": {}, "risk": {}, "people": {}, "integrity": {} }


## Record an entrepreneurial-style choice. Pure data — surfaced later (mirror / identity),
## NEVER shown to the player as a label or score. Dimensions: pricing/risk/people/integrity.
func add_trait(dimension: String, value: String) -> void:
	if not traits.has(dimension):
		traits[dimension] = {}
	traits[dimension][value] = int(traits[dimension].get(value, 0)) + 1

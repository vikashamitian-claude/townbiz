extends Node
## BizTown — Sprint 1: Business Simulation Engine. Autoloaded as "Sim".
##
## Two kinds of functions:
##   * calculate_* are PURE — given inputs, return a number, touch no state. Safe to call
##     repeatedly (e.g. to drive a pricing dial).
##   * the action functions mutate GameState (run a day, buy stock, hire Ravi, charge costs).
##
## Built for Chapter 1's single retail shop. Deliberately NOT generalised to other business
## types yet — that comes only after Chapter 1 is proven (see FOUNDATION.md).

# --- Events for the Mission Engine (Sprint 2). Sim emits these; it never reads missions. ---
signal changed                        ## a state-changing action happened
signal day_ended(result: Dictionary)  ## a trading day finished (carries the day's result)
signal ravi_hired                     ## Ravi was hired

# ---------------------------------------------------------------------------
#  Pure calculations (no side effects)
# ---------------------------------------------------------------------------

## How many customers WANT to buy at this price & reputation, before capacity/stock limits.
## Reputation shifts the curve right: higher reputation => higher prices tolerated.
func calculate_demand(price: float, reputation: float) -> float:
	var rep_shift: float = SimConfig.REP_SHIFT_PER_POINT * (reputation - SimConfig.REP_BASELINE)
	var effective_price: float = price - rep_shift
	var demand: float = SimConfig.BASE_DEMAND - SimConfig.DEMAND_SLOPE * (effective_price - SimConfig.FLOOR_PRICE)
	return clampf(demand, 0.0, SimConfig.MAX_DEMAND)


## Projected gross profit for a day — a hint for the pricing dial.
## Capacity-aware: served is limited by demand, then current capacity, then stock on hand —
## so it never overstates profit at low prices you can't actually serve solo.
## Profit is revenue minus cost-of-goods only (recurring daily costs are not included).
func calculate_daily_profit(price: float, cost: float, reputation: float, inventory: int) -> float:
	var demand: float = calculate_demand(price, reputation)
	var served: float = minf(demand, float(get_capacity()))
	served = minf(served, float(inventory))
	return served * (price - cost)


# ---------------------------------------------------------------------------
#  Helpers
# ---------------------------------------------------------------------------

## Customers you can serve per day (depends on whether Ravi has been hired).
func get_capacity() -> int:
	return SimConfig.CAPACITY_WITH_RAVI if GameState.has_ravi else SimConfig.CAPACITY_SOLO


# ---------------------------------------------------------------------------
#  Actions (mutate GameState)
# ---------------------------------------------------------------------------

## Simulate one trading day at the current price. Returns a per-day result dictionary.
## Sales are limited by demand, then by capacity, then by inventory on hand.
func run_day() -> Dictionary:
	var price: float = GameState.current_price
	var demand: int = roundi(calculate_demand(price, GameState.reputation))
	var capacity: int = get_capacity()

	var served: int = mini(demand, capacity)
	served = mini(served, GameState.inventory)
	var lost: int = demand - served

	var revenue: float = served * price
	GameState.inventory -= served
	GameState.cash += revenue
	GameState.customers_served += served
	GameState.customers_lost += lost

	apply_daily_costs()
	_update_reputation_for_day(served, lost)

	GameState.day += 1

	var result: Dictionary = {
		"day": GameState.day,
		"price": price,
		"demand": demand,
		"served": served,
		"lost": lost,
		"revenue": revenue,
		"daily_costs": GameState.daily_costs,
		"inventory": GameState.inventory,
		"cash": GameState.cash,
		"reputation": GameState.reputation,
	}
	day_ended.emit(result)
	changed.emit()
	return result


## Buy stock. Cash may go negative — there is NO hard game-over; the mission layer
## (Sprint 2) decides what to do about a shortfall (e.g. offer a loan).
func buy_inventory(quantity: int, unit_cost: float = SimConfig.PRODUCT_COST) -> float:
	var spent: float = quantity * unit_cost
	GameState.cash -= spent
	GameState.inventory += quantity
	changed.emit()
	return spent


## Change reputation, clamped to [REP_MIN, REP_MAX].
func apply_reputation_change(amount: float) -> void:
	GameState.reputation = clampf(GameState.reputation + amount, SimConfig.REP_MIN, SimConfig.REP_MAX)
	changed.emit()


## Hire Ravi: doubles capacity, adds a recurring daily wage, records a "trust" choice.
func hire_ravi() -> void:
	if GameState.has_ravi:
		return
	GameState.has_ravi = true
	GameState.daily_costs += SimConfig.RAVI_WAGE
	GameState.add_trait("people", "trusting")
	ravi_hired.emit()
	changed.emit()


## Chapter 1 expansion decision (Mission 5). Minimal placeholder — sets a flag only.
## NOT an expansion system (no bigger shop / new capacity yet); that is a later sprint.
func expand_shop() -> void:
	if GameState.has_expanded_shop:
		return
	GameState.has_expanded_shop = true
	changed.emit()


## Deduct recurring daily costs (Ravi's wage). Called automatically by run_day().
func apply_daily_costs() -> void:
	GameState.cash -= GameState.daily_costs


## Month-End: rent comes due. Returns the amount charged. (No game-over if it can't be paid.)
func apply_monthly_costs() -> float:
	GameState.cash -= SimConfig.RENT
	changed.emit()
	return SimConfig.RENT


## Snapshot of current state for printing/HUD. Plain numbers — never an accounting screen.
func get_daily_summary() -> Dictionary:
	return {
		"day": GameState.day,
		"cash": GameState.cash,
		"reputation": GameState.reputation,
		"inventory": GameState.inventory,
		"price": GameState.current_price,
		"has_ravi": GameState.has_ravi,
		"daily_costs": GameState.daily_costs,
		"customers_served": GameState.customers_served,
		"customers_lost": GameState.customers_lost,
	}


# ---------------------------------------------------------------------------
#  Internal
# ---------------------------------------------------------------------------

## Reputation drifts up on a clean day, down when customers are turned away.
func _update_reputation_for_day(served: int, lost: int) -> void:
	if lost > 0:
		var drop: float = minf(SimConfig.REP_MAX_DAILY_DROP, lost * SimConfig.REP_LOSS_PER_LOST)
		apply_reputation_change(-drop)
	elif served > 0:
		apply_reputation_change(SimConfig.REP_GAIN_GOOD_DAY)

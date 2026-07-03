extends Node
## BizTown — Living Business Build: simulation core. Autoloaded as "Sim".
## Pure calculate_* functions + mutating player actions + run_day().
## NEVER reads missions. `changed` is HUD-only; mission logic hangs off the
## five explicit events below (Sprint 1 Task 3 redesign).

signal changed                                          # HUD refresh ONLY
signal day_ended(result: Dictionary)                    # state is FINAL when this fires
signal inventory_purchased(qty: int, unit_cost: float)
signal ravi_hired
signal shop_expanded
signal month_ended(rent_paid: float, cash_after: float)


# =========================================================================
# PURE CALCULATIONS (no state mutation, no RNG — used for HUD hints & tests)
# =========================================================================

## Expected demand at a price/reputation (deterministic center of the curve).
func calculate_demand(price: float, reputation: float) -> int:
	var rep_shift: float = (reputation - SimConfig.REP_BASELINE) * SimConfig.REP_SHIFT_PER_POINT
	var effective_floor: float = SimConfig.FLOOR_PRICE + rep_shift
	var d: float = SimConfig.BASE_DEMAND - (price - effective_floor) * SimConfig.DEMAND_SLOPE
	return clampi(int(round(d)), 0, int(SimConfig.MAX_DEMAND))


## Demand RANGE for the HUD hint ("18–30 customers likely"). Never fake precision.
func calculate_demand_range(price: float, reputation: float) -> Vector2i:
	var center: int = calculate_demand(price, reputation)
	return Vector2i(
		int(floor(center * SimConfig.NOISE_MIN)),
		int(ceil(center * SimConfig.NOISE_MAX))
	)


func calculate_capacity() -> int:
	var cap: int = SimConfig.CAPACITY_WITH_RAVI if GameState.has_ravi else SimConfig.CAPACITY_SOLO
	if GameState.has_expanded_shop:
		cap = int(round(cap * SimConfig.EXPANSION_CAPACITY_MULT))
	return cap


## Bargainer price ceiling shifts with reputation, same as the demand curve.
func calculate_bargain_ceiling(reputation: float) -> float:
	return SimConfig.BARGAIN_CEILING_BASE + (reputation - SimConfig.REP_BASELINE) * SimConfig.REP_SHIFT_PER_POINT


# =========================================================================
# PLAYER ACTIONS (mutate state, emit their explicit event + changed)
# =========================================================================

func set_price(price: float) -> void:
	GameState.current_price = clampf(price, SimConfig.PRICE_MIN, SimConfig.PRICE_MAX)
	changed.emit()


## Buy stock at TODAY'S drifting supplier cost (restock timing is a decision).
func buy_inventory(qty: int) -> bool:
	if qty <= 0:
		return false
	var unit_cost: float = get_current_unit_cost()
	var total: float = qty * unit_cost
	if GameState.cash < total:
		return false
	GameState.cash -= total
	GameState.inventory += qty
	inventory_purchased.emit(qty, unit_cost)
	changed.emit()
	return true


func hire_ravi() -> bool:
	if GameState.has_ravi:
		return false
	GameState.has_ravi = true
	GameState.daily_costs += SimConfig.RAVI_WAGE
	ravi_hired.emit()
	changed.emit()
	return true


## Expansion costs REAL money (₹8,000) and raises daily costs. A trade, not a flag.
func expand_shop() -> bool:
	if GameState.has_expanded_shop:
		return false
	if GameState.cash < SimConfig.EXPANSION_COST:
		return false
	GameState.cash -= SimConfig.EXPANSION_COST
	GameState.has_expanded_shop = true
	GameState.daily_costs += SimConfig.EXPANSION_EXTRA_DAILY
	GameState.add_trait("risk", "investor")
	shop_expanded.emit()
	changed.emit()
	return true


## --- Credit decisions (trust mechanic). Consequences only — never labels. ---

func grant_credit() -> bool:
	var req: Dictionary = GameState.pending_credit_request
	if req.is_empty() or GameState.inventory < int(req.qty):
		return false
	GameState.inventory -= int(req.qty)
	GameState.credit_ledger.append({
		"name": req.name,
		"qty": int(req.qty),
		"amount": int(req.qty) * GameState.current_price,
		"due_day": GameState.day + int(req.repay_in_days),
		"reliability": float(req.reliability),
		"resolved": false,
	})
	GameState.pending_credit_request = {}
	GameState.add_trait("people", "trusting")
	changed.emit()
	return true


func refuse_credit() -> bool:
	if GameState.pending_credit_request.is_empty():
		return false
	GameState.pending_credit_request = {}
	_apply_reputation_change(-SimConfig.CREDIT_REFUSE_REP_HIT, true)  # word gets around
	GameState.add_trait("people", "cautious")
	changed.emit()
	return true


## --- Bulk order decisions (volume vs margin; over-commitment risk). ---

func accept_bulk_offer() -> bool:
	var offer: Dictionary = GameState.pending_bulk_offer
	if offer.is_empty():
		return false
	GameState.bulk_commitments.append({
		"qty": int(offer.qty),
		"unit_price": float(offer.unit_price),
		"days_left": int(offer.deadline_days),
	})
	GameState.pending_bulk_offer = {}
	GameState.add_trait("risk", "bold")
	changed.emit()
	return true


func decline_bulk_offer() -> bool:
	if GameState.pending_bulk_offer.is_empty():
		return false
	GameState.pending_bulk_offer = {}
	GameState.add_trait("risk", "careful")
	changed.emit()
	return true


## --- Lender (broke = harder path, never game-over). ---

func accept_lender() -> bool:
	if not GameState.lender_offer_pending:
		return false
	GameState.cash += SimConfig.LENDER_PRINCIPAL
	GameState.lender_debt += SimConfig.LENDER_REPAY
	GameState.lender_offer_pending = false
	GameState.add_trait("risk", "leveraged")
	changed.emit()
	return true


func decline_lender() -> bool:
	if not GameState.lender_offer_pending:
		return false
	GameState.lender_offer_pending = false
	GameState.add_trait("risk", "self_reliant")
	changed.emit()
	return true


# =========================================================================
# RUN DAY — all mutation completes BEFORE any event is emitted (§2.3)
# =========================================================================

func run_day() -> Dictionary:
	# ---- 1. Apply the telegraphed event for today ----
	var todays_event: Dictionary = GameState.pending_event
	GameState.pending_event = {}
	var one_day_mult: float = Events.apply_pending(todays_event)

	# ---- 2. Supplier cost drift ----
	GameState.current_unit_cost = clampf(
		GameState.current_unit_cost + GameState.rng.randf_range(-SimConfig.COST_DRIFT, SimConfig.COST_DRIFT),
		SimConfig.COST_MIN, SimConfig.COST_MAX)

	# ---- 3. Maybe a credit request arrives (player answers before/after; sim doesn't block) ----
	Events.maybe_roll_credit_request()

	# ---- 4. Roll demand with noise, split into customer mix ----
	var price: float = GameState.current_price
	var rep: float = GameState.reputation
	var noise: float = GameState.rng.randf_range(SimConfig.NOISE_MIN, SimConfig.NOISE_MAX)
	var base: int = calculate_demand(price, rep)
	var rolled: int = int(round(base * noise * one_day_mult * Events.get_active_demand_mult()))

	var walk_ins: int = int(round(rolled * SimConfig.SHARE_WALK_INS))
	var bargainers: int = int(round(rolled * SimConfig.SHARE_BARGAINERS))
	if price > calculate_bargain_ceiling(rep):
		bargainers = 0  # they walk
	var regulars: int = GameState.regular_count  # buy at any price ≤ PRICE_MAX
	var want_to_buy: int = walk_ins + bargainers + regulars

	# ---- 5. Serve within capacity and stock ----
	var capacity: int = calculate_capacity()
	var served: int = mini(want_to_buy, mini(capacity, GameState.inventory))
	var lost: int = want_to_buy - served
	var revenue: float = served * price

	GameState.inventory -= served
	GameState.cash += revenue
	GameState.customers_served += served
	GameState.customers_lost += lost

	# ---- 6. Fulfill bulk commitments if stock allows; expire late ones ----
	var bulk_result: Dictionary = _process_bulk_commitments()

	# ---- 7. Credit ledger due-day resolution ----
	var credit_result: Dictionary = _process_credit_dues()

	# ---- 8. Regulars grow on clean days, shrink when people are turned away ----
	if lost == 0 and served > 0:
		GameState.regular_count = mini(GameState.regular_count + SimConfig.REGULAR_GAIN_CLEAN_DAY, SimConfig.REGULAR_CAP)
	elif lost > 0:
		GameState.regular_count = maxi(GameState.regular_count - SimConfig.REGULAR_LOSS_ON_TURNAWAY, 0)

	# ---- 9. Daily costs & reputation (SILENT — no signals mid-day) ----
	GameState.cash -= GameState.daily_costs
	if lost > 0:
		_apply_reputation_change(-minf(lost * SimConfig.REP_LOSS_PER_LOST, SimConfig.REP_MAX_DAILY_DROP), true)
	elif served > 0:
		_apply_reputation_change(SimConfig.REP_GAIN_GOOD_DAY, true)

	# ---- 10. Advance the day; month-end rent & lender debt ----
	GameState.day += 1
	var rent_paid: float = 0.0
	var is_month_end: bool = GameState.day % SimConfig.MONTH_LENGTH_DAYS == 0
	if is_month_end:
		rent_paid = SimConfig.RENT
		GameState.cash -= rent_paid
		if GameState.lender_debt > 0.0:
			if GameState.cash >= GameState.lender_debt:
				GameState.cash -= GameState.lender_debt
				GameState.lender_debt = 0.0
			else:
				GameState.lender_debt += SimConfig.LENDER_ROLL_PENALTY  # debt rolls
				_apply_reputation_change(-SimConfig.LENDER_REP_HIT, true)

	# ---- 11. Tick multi-day effects; roll & store TOMORROW'S event ----
	Events.tick_effects()
	GameState.pending_event = Events.roll_next_event()

	# ---- 12. ALL STATE FINAL. Emit in guaranteed order. ----
	var result: Dictionary = {
		"day": GameState.day, "served": served, "lost": lost,
		"revenue": revenue, "cash": GameState.cash,
		"inventory": GameState.inventory, "reputation": GameState.reputation,
		"regulars": GameState.regular_count, "event": todays_event,
		"bulk": bulk_result, "credit": credit_result,
		"rent_paid": rent_paid,
	}
	if is_month_end:
		month_ended.emit(rent_paid, GameState.cash)
		if GameState.cash < 0.0:
			Events.offer_lender()  # broke = harder path, never death
	day_ended.emit(result)
	Events.telegraph(GameState.pending_event)
	changed.emit()
	return result


# =========================================================================
# INTERNAL HELPERS
# =========================================================================

func get_current_unit_cost() -> float:
	return clampf(GameState.current_unit_cost + Events.get_active_cost_delta(),
		SimConfig.COST_MIN - 6.0, SimConfig.COST_MAX + 6.0)


## silent=true suppresses `changed` (used inside run_day to prevent re-entrancy).
func _apply_reputation_change(delta: float, silent: bool = false) -> void:
	GameState.reputation = clampf(GameState.reputation + delta, SimConfig.REP_MIN, SimConfig.REP_MAX)
	if not silent:
		changed.emit()


func _process_bulk_commitments() -> Dictionary:
	var fulfilled: int = 0
	var failed: int = 0
	var kept: Array = []
	for c in GameState.bulk_commitments:
		if GameState.inventory >= int(c.qty):
			GameState.inventory -= int(c.qty)
			GameState.cash += int(c.qty) * float(c.unit_price)
			fulfilled += 1
		else:
			c.days_left = int(c.days_left) - 1
			if int(c.days_left) <= 0:
				_apply_reputation_change(-SimConfig.BULK_REP_PENALTY, true)
				failed += 1
			else:
				kept.append(c)
	GameState.bulk_commitments = kept
	return { "fulfilled": fulfilled, "failed": failed }


func _process_credit_dues() -> Dictionary:
	var paid: int = 0
	var defaulted: int = 0
	for entry in GameState.credit_ledger:
		if bool(entry.resolved) or GameState.day < int(entry.due_day):
			continue
		entry.resolved = true
		if GameState.rng.randf() <= float(entry.reliability):
			GameState.cash += float(entry.amount)
			_apply_reputation_change(SimConfig.CREDIT_PAID_REP_GAIN, true)
			GameState.regular_count = mini(GameState.regular_count + 1, SimConfig.REGULAR_CAP)
			paid += 1
		else:
			GameState.cash += float(entry.amount) * SimConfig.CREDIT_DEFAULT_PAY_FRACTION
			defaulted += 1
	return { "paid": paid, "defaulted": defaulted }

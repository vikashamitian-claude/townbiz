extends Node
## BizTown — Living Business Build: Event Engine. Autoloaded as "Events".
## Rolls at most ONE event per day, TELEGRAPHED the evening before (Fairness law:
## the player always gets one decision between warning and impact).
## Sim calls into this; this never calls Sim actions or reads missions.

signal event_telegraphed(event: Dictionary)   # fired at end of day N for day N+1
signal event_applied(event: Dictionary)       # fired when the effect starts
signal credit_requested(request: Dictionary)  # player must choose grant/refuse
signal bulk_offered(offer: Dictionary)        # player must choose accept/decline
signal lender_offered(offer: Dictionary)      # after a broke month-end


## Roll tomorrow's event id using SimConfig.EVENT_WEIGHTS and the shared RNG.
func roll_next_event() -> Dictionary:
	var weights: Dictionary = SimConfig.EVENT_WEIGHTS
	var total: int = 0
	for k in weights:
		total += int(weights[k])
	var pick: int = GameState.rng.randi_range(1, total)
	var acc: int = 0
	for k in weights:
		acc += int(weights[k])
		if pick <= acc:
			return _make_event(String(k))
	return {}


## Build the event dictionary (telegraph text + effect parameters).
func _make_event(id: String) -> Dictionary:
	match id:
		"none":
			return {}
		"festival_rush":
			return { "id": id, "demand_mult": SimConfig.FESTIVAL_DEMAND_MULT, "duration": 1,
				"telegraph": "Festival tomorrow — the whole town will be out shopping." }
		"heavy_rain":
			return { "id": id, "demand_mult": SimConfig.RAIN_DEMAND_MULT, "duration": 1,
				"telegraph": "Dark clouds gathering. Tomorrow looks wet." }
		"supplier_hike":
			return { "id": id, "cost_delta": SimConfig.HIKE_COST_DELTA,
				"duration": SimConfig.HIKE_DURATION_DAYS,
				"telegraph": "Your supplier warns: soap prices are rising." }
		"supplier_deal":
			return { "id": id, "cost_delta": SimConfig.DEAL_COST_DELTA,
				"duration": SimConfig.DEAL_DURATION_DAYS,
				"telegraph": "A wholesaler is clearing stock cheap this week." }
		"competitor_discount":
			return { "id": id, "demand_mult": SimConfig.COMPETITOR_DEMAND_MULT,
				"duration": SimConfig.COMPETITOR_DURATION_DAYS,
				"telegraph": "The shop across the road put up a SALE board." }
		"bulk_order_offer":
			# Arrives as a CHOICE the next morning, not a passive effect.
			var qty: int = GameState.rng.randi_range(SimConfig.BULK_QTY_MIN, SimConfig.BULK_QTY_MAX)
			var margin: float = GameState.rng.randf_range(SimConfig.BULK_MARGIN_MIN, SimConfig.BULK_MARGIN_MAX)
			return { "id": id, "qty": qty, "margin": margin, "duration": 0,
				"telegraph": "A lodge manager asked about buying soap in bulk. He'll come tomorrow." }
		_:
			return {}


## Telegraph the pending event for tomorrow (called by Sim at end of run_day).
func telegraph(event: Dictionary) -> void:
	if not event.is_empty():
		event_telegraphed.emit(event)


## Apply the pending event at the START of a day. Choice-events populate a pending
## decision on GameState instead of an effect. Returns today's one-day demand mult.
func apply_pending(event: Dictionary) -> float:
	if event.is_empty():
		return 1.0
	event_applied.emit(event)
	var one_day_mult: float = 1.0
	match String(event.get("id", "")):
		"festival_rush", "heavy_rain":
			one_day_mult = float(event.get("demand_mult", 1.0))
		"supplier_hike", "supplier_deal", "competitor_discount":
			GameState.active_effects.append({
				"id": event.id,
				"days_left": int(event.get("duration", 1)),
				"cost_delta": float(event.get("cost_delta", 0.0)),
				"demand_mult": float(event.get("demand_mult", 1.0)),
			})
		"bulk_order_offer":
			var unit_price: float = snappedf(GameState.current_unit_cost + float(event.get("margin", 5.0)), 0.5)
			var offer: Dictionary = { "qty": int(event.get("qty", 30)), "unit_price": unit_price,
				"deadline_days": SimConfig.BULK_DEADLINE_DAYS }
			GameState.pending_bulk_offer = offer
			bulk_offered.emit(offer)
	return one_day_mult


## Aggregate multipliers/deltas from active multi-day effects.
func get_active_demand_mult() -> float:
	var m: float = 1.0
	for e in GameState.active_effects:
		m *= float(e.get("demand_mult", 1.0))
	return m


func get_active_cost_delta() -> float:
	var d: float = 0.0
	for e in GameState.active_effects:
		d += float(e.get("cost_delta", 0.0))
	return d


## Count down and expire multi-day effects (called by Sim inside run_day).
func tick_effects() -> void:
	var kept: Array = []
	for e in GameState.active_effects:
		e.days_left = int(e.days_left) - 1
		if int(e.days_left) > 0:
			kept.append(e)
	GameState.active_effects = kept


## Maybe generate today's credit request (called by Sim inside run_day, before sales).
func maybe_roll_credit_request() -> void:
	if not GameState.pending_credit_request.is_empty():
		return
	if GameState.rng.randf() >= SimConfig.CREDIT_REQUEST_CHANCE:
		return
	var names: Array = SimConfig.CREDIT_NAMES
	var request: Dictionary = {
		"name": names[GameState.rng.randi_range(0, names.size() - 1)],
		"qty": GameState.rng.randi_range(SimConfig.CREDIT_QTY_MIN, SimConfig.CREDIT_QTY_MAX),
		"repay_in_days": GameState.rng.randi_range(SimConfig.CREDIT_DUE_MIN_DAYS, SimConfig.CREDIT_DUE_MAX_DAYS),
		"reliability": GameState.rng.randf_range(SimConfig.CREDIT_RELIABILITY_MIN, SimConfig.CREDIT_RELIABILITY_MAX),
	}
	GameState.pending_credit_request = request
	credit_requested.emit(request)


## Offer the lender after a broke month-end (called by Sim).
func offer_lender() -> void:
	GameState.lender_offer_pending = true
	lender_offered.emit({
		"principal": SimConfig.LENDER_PRINCIPAL,
		"repay": SimConfig.LENDER_REPAY,
	})

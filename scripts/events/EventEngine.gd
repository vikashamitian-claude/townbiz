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
signal contract_offered(offer: Dictionary)    # a build contract; accept/decline


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
		"local_holiday":
			return { "id": id, "demand_mult": SimConfig.HOLIDAY_DEMAND_MULT, "duration": 1,
				"telegraph": "Tomorrow's a local holiday — most shutters will stay half-down." }
		"wedding_season":
			return { "id": id, "demand_mult": SimConfig.WEDDING_DEMAND_MULT,
				"duration": SimConfig.WEDDING_DURATION_DAYS,
				"telegraph": "Wedding season is starting — everyone's stocking up on soap." }
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
		"festival_rush", "heavy_rain", "local_holiday":
			one_day_mult = float(event.get("demand_mult", 1.0))
		"supplier_hike", "supplier_deal", "competitor_discount", "wedding_season":
			# Refresh rather than stack: re-rolling the same effect while a prior
			# instance is still active should reset its duration/magnitude, not
			# add a second copy on top (which would double the cost_delta/demand_mult).
			GameState.active_effects = GameState.active_effects.filter(
				func(e: Dictionary) -> bool: return String(e.get("id", "")) != String(event.id))
			GameState.active_effects.append({
				"id": event.id,
				"days_left": int(event.get("duration", 1)),
				"cost_delta": float(event.get("cost_delta", 0.0)),
				"demand_mult": float(event.get("demand_mult", 1.0)),
			})
		"bulk_order_offer":
			# Don't clobber an unresolved offer the player hasn't answered yet.
			if GameState.pending_bulk_offer.is_empty():
				var unit_price: float = snappedf(GameState.current_unit_cost + float(event.get("margin", 5.0)), 0.5)
				var offer: Dictionary = { "qty": int(event.get("qty", 30)), "unit_price": unit_price,
					"deadline_days": SimConfig.BULK_DEADLINE_DAYS }
				GameState.pending_bulk_offer = offer
				bulk_offered.emit(offer)
		_:
			# A telegraphed event with no matching effect branch here would
			# otherwise apply silently as a no-op — warn loudly instead, since
			# this only happens if a new SimConfig.EVENT_WEIGHTS id is added
			# without a matching case above (or one is typo'd).
			push_warning("EventEngine: telegraphed event has no apply_pending case: %s" % [event.get("id", "")])
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
	var picked_name: String = String(names[GameState.rng.randi_range(0, names.size() - 1)])
	var reliability: float = GameState.rng.randf_range(
		SimConfig.CREDIT_RELIABILITY_MIN, SimConfig.CREDIT_RELIABILITY_MAX)
	# Repeat customers nudge toward their own track record — trust (or wariness)
	# builds from real history with THIS person, not a fresh coin-flip every time.
	var history: Dictionary = GameState.customer_relationships.get(picked_name, {})
	reliability += float(history.get("paid", 0)) * SimConfig.CREDIT_HISTORY_PAID_BONUS
	reliability -= float(history.get("defaulted", 0)) * SimConfig.CREDIT_HISTORY_DEFAULT_PENALTY
	reliability = clampf(reliability,
		SimConfig.CREDIT_RELIABILITY_HARD_MIN, SimConfig.CREDIT_RELIABILITY_HARD_MAX)
	var request: Dictionary = {
		"name": picked_name,
		"qty": GameState.rng.randi_range(SimConfig.CREDIT_QTY_MIN, SimConfig.CREDIT_QTY_MAX),
		"repay_in_days": GameState.rng.randi_range(SimConfig.CREDIT_DUE_MIN_DAYS, SimConfig.CREDIT_DUE_MAX_DAYS),
		"reliability": reliability,
	}
	GameState.pending_credit_request = request
	credit_requested.emit(request)


## Maybe roll a build-contract offer (called by Sim inside run_day). Only one
## offer or active contract at a time, and only while empty plots remain.
## Data + signal only — accepting/declining and all mutation live in Sim.gd.
func maybe_roll_contract_offer() -> void:
	if not GameState.pending_contract_offer.is_empty() or not GameState.active_contract.is_empty():
		return
	if GameState.contracts_completed >= SimConfig.CONTRACT_PLOTS.size():
		return  # the street is full — Chapter 2 grows the map
	if GameState.rng.randf() >= SimConfig.CONTRACT_OFFER_CHANCE:
		return
	var names: Array = SimConfig.CREDIT_NAMES
	var project: Dictionary = SimConfig.CONTRACT_PROJECTS[
		GameState.rng.randi_range(0, SimConfig.CONTRACT_PROJECTS.size() - 1)]
	var mat_range: Array = project.materials
	var materials: float = snappedf(GameState.rng.randf_range(
		float(mat_range[0]), float(mat_range[1])), 10.0)
	var margin: float = GameState.rng.randf_range(
		SimConfig.CONTRACT_MARGIN_MIN, SimConfig.CONTRACT_MARGIN_MAX)
	var style: int = GameState.rng.randi_range(0, SimConfig.CONTRACT_WALL_COLORS.size() - 1)
	var plot: Array = SimConfig.CONTRACT_PLOTS[GameState.contracts_completed]
	var size: Array = project.size
	var offer: Dictionary = {
		"name": String(names[GameState.rng.randi_range(0, names.size() - 1)]),
		"label": String(project.label),
		"teach": String(project.teach),
		"materials_cost": materials,
		"payout": snappedf(materials * (1.0 + margin), 10.0),
		"build_days": GameState.rng.randi_range(
			SimConfig.CONTRACT_BUILD_DAYS_MIN, SimConfig.CONTRACT_BUILD_DAYS_MAX),
		"structure": {
			"type": String(project.structure_type),
			"label": String(project.label),
			"pos": [float(plot[0]), float(size[1]) * 0.5, float(plot[1])],
			"size": size.duplicate(),
			"wall": SimConfig.CONTRACT_WALL_COLORS[style].duplicate(),
			"roof": SimConfig.CONTRACT_ROOF_COLORS[style].duplicate(),
			"face": 1.0 if float(plot[1]) < 1.5 else -1.0,
		},
	}
	GameState.pending_contract_offer = offer
	contract_offered.emit(offer)


## Offer the lender after a broke month-end (called by Sim).
func offer_lender() -> void:
	GameState.lender_offer_pending = true
	lender_offered.emit({
		"principal": SimConfig.LENDER_PRINCIPAL,
		"repay": SimConfig.LENDER_REPAY,
	})

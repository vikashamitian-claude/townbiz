extends Node
## BizTown — Living Business Build: headless test runner.
## Run:  godot --headless --path . res://tests/TestRunner.tscn
## Running a SCENE (not -s) guarantees autoloads are initialized.
## Exits 0 on all-pass, 1 on any failure.

var failures: int = 0
var checks: int = 0


func _ready() -> void:
	# Detach save autosave & mission UI side effects don't matter headless.
	_suite("SIGNALS (Task 3)", _test_signals)
	_suite("ECONOMY 60-DAY", _test_economy)
	_suite("EVENTS SEED SWEEP", _test_events)
	_suite("CREDIT", _test_credit)
	_suite("SAVE/LOAD", _test_save)
	_suite("MISSION PLAYTHROUGH", _test_missions)
	print("\n==== %d checks, %d failures ====" % [checks, failures])
	get_tree().quit(1 if failures > 0 else 0)


func _suite(name: String, fn: Callable) -> void:
	print("\n--- %s ---" % name)
	fn.call()


func _assert(cond: bool, msg: String) -> void:
	checks += 1
	if cond:
		print("  PASS  %s" % msg)
	else:
		failures += 1
		printerr("  FAIL  %s" % msg)


func _fresh(seed_value: int) -> void:
	GameState.reset(seed_value)
	Missions.start_chapter()
	SaveManager.delete_save()


# ------------------------------------------------------------------
# 1. Signals: changed never completes missions; explicit events do;
#    no same-instant cascade; day_ended state is final.
# ------------------------------------------------------------------
func _test_signals() -> void:
	_fresh(42)
	var completed: Array = []
	var conn = func(m: Dictionary) -> void: completed.append(m.id)
	Missions.mission_completed.connect(conn)

	# Firing changed alone must never complete a mission.
	GameState.customers_served = 999
	Sim.changed.emit()
	_assert(completed.is_empty(), "generic `changed` completes no mission")

	# day_ended completes opening_day (served total already ≥ 20).
	Sim.run_day()
	_assert(completed.has("opening_day"), "day_ended drives mission completion")

	# State finality: cash inside day_ended handler equals cash after run_day.
	var seen_cash: Array = []
	var probe = func(result: Dictionary) -> void: seen_cash.append([result.cash, GameState.cash])
	Sim.day_ended.connect(probe)
	Sim.run_day()
	Sim.day_ended.disconnect(probe)
	_assert(seen_cash.size() == 1 and is_equal_approx(seen_cash[0][0], seen_cash[0][1]),
		"state is final when day_ended fires")

	# No cascade: completing restock must not also complete long_queue.
	Sim.buy_inventory(100)
	_assert(completed.has("restock") and not completed.has("long_queue"),
		"no same-instant mission cascade")
	Missions.mission_completed.disconnect(conn)


# ------------------------------------------------------------------
# 2. Economy: fixed seed, 60 days at default price with basic auto-play.
# ------------------------------------------------------------------
func _test_economy() -> void:
	_fresh(1234)
	var rent_days: Array = []
	var probe = func(_rent: float, _cash: float) -> void: rent_days.append(GameState.day)
	Sim.month_ended.connect(probe)
	var regulars_grew: bool = false
	for i in range(60):
		if GameState.inventory < 30 and GameState.cash > 2000.0:
			Sim.buy_inventory(60)
		if not GameState.has_ravi and GameState.cash > 4000.0 and GameState.day > 5:
			Sim.hire_ravi()
		if not GameState.pending_credit_request.is_empty():
			Sim.refuse_credit()
		if not GameState.pending_bulk_offer.is_empty():
			Sim.decline_bulk_offer()
		var before_regulars: int = GameState.regular_count
		Sim.run_day()
		if GameState.regular_count > before_regulars:
			regulars_grew = true
	Sim.month_ended.disconnect(probe)
	_assert(rent_days == [30, 60], "rent charged exactly on days 30 and 60 (got %s)" % [rent_days])
	_assert(GameState.cash < 60000.0 and GameState.cash > -10000.0,
		"60-day cash in sane band (got %.0f)" % GameState.cash)
	_assert(regulars_grew, "regulars grow on clean days")
	_assert(GameState.day == 60, "day counter advanced to 60")


# ------------------------------------------------------------------
# 3. Events: 100-seed sweep — frequencies near weights, effects expire,
#    telegraph precedes effect by exactly one day.
# ------------------------------------------------------------------
func _test_events() -> void:
	var counts: Dictionary = {}
	var telegraph_ok: bool = true
	var total_days: int = 0
	for s in range(100):
		_fresh(s)
		var telegraphed_id: String = ""
		for i in range(30):
			var expected: String = String(GameState.pending_event.get("id", "none")) \
				if not GameState.pending_event.is_empty() else "none"
			if telegraphed_id != "" and telegraphed_id != expected:
				telegraph_ok = false
			var result: Dictionary = Sim.run_day()
			var applied: String = String(result.event.get("id", "none")) \
				if not result.event.is_empty() else "none"
			if applied != expected:
				telegraph_ok = false
			counts[applied] = int(counts.get(applied, 0)) + 1
			telegraphed_id = String(GameState.pending_event.get("id", "none")) \
				if not GameState.pending_event.is_empty() else "none"
			total_days += 1
			if not GameState.pending_bulk_offer.is_empty():
				Sim.decline_bulk_offer()
			if not GameState.pending_credit_request.is_empty():
				Sim.refuse_credit()
		for e in GameState.active_effects:
			if int(e.days_left) <= 0:
				_assert(false, "expired effect still active: %s" % [e])
	_assert(telegraph_ok, "telegraph always matches next day's applied event")
	var weight_total: int = 0
	for k in SimConfig.EVENT_WEIGHTS:
		weight_total += int(SimConfig.EVENT_WEIGHTS[k])
	var freq_ok: bool = true
	for k in SimConfig.EVENT_WEIGHTS:
		var expected_frac: float = float(SimConfig.EVENT_WEIGHTS[k]) / weight_total
		var actual_frac: float = float(counts.get(k, 0)) / total_days
		if absf(actual_frac - expected_frac) > maxf(expected_frac * 0.35, 0.02):
			freq_ok = false
			printerr("    freq off: %s expected %.3f got %.3f" % [k, expected_frac, actual_frac])
	_assert(freq_ok, "event frequencies within tolerance of weights over 3000 days")


# ------------------------------------------------------------------
# 4. Credit: grant/refuse paths and due-day resolution.
# ------------------------------------------------------------------
func _test_credit() -> void:
	_fresh(7)
	# Forced request, reliability 1.0 → guaranteed repayment.
	GameState.pending_credit_request = { "name": "Sharma-ji", "qty": 10, "repay_in_days": 3, "reliability": 1.0 }
	var inv_before: int = GameState.inventory
	_assert(Sim.grant_credit(), "grant_credit succeeds with stock")
	_assert(GameState.inventory == inv_before - 10, "credit deducts inventory now")
	_assert(GameState.credit_ledger.size() == 1, "ledger entry created")
	var cash_track: float = GameState.cash
	var amount: float = float(GameState.credit_ledger[0].amount)
	for i in range(4):
		if not GameState.pending_credit_request.is_empty():
			Sim.refuse_credit()
		if not GameState.pending_bulk_offer.is_empty():
			Sim.decline_bulk_offer()
		Sim.run_day()
	_assert(bool(GameState.credit_ledger[0].resolved), "credit resolved on due day")
	_assert(GameState.cash > cash_track - 5000.0, "repayment credited (cash didn't collapse)")
	_assert(int(GameState.traits["people"].get("trusting", 0)) == 1, "trait recorded, no label shown")

	# Refuse path costs a little reputation.
	var rep_before: float = GameState.reputation
	GameState.pending_credit_request = { "name": "Raju bhai", "qty": 5, "repay_in_days": 5, "reliability": 0.9 }
	Sim.refuse_credit()
	_assert(GameState.reputation < rep_before, "refusal has a reputation cost")
	_assert(amount > 0.0, "credit amount positive")


# ------------------------------------------------------------------
# 5. Save/load round-trip.
# ------------------------------------------------------------------
func _test_save() -> void:
	_fresh(99)
	for i in range(10):
		if not GameState.pending_credit_request.is_empty():
			Sim.grant_credit()
		if not GameState.pending_bulk_offer.is_empty():
			Sim.accept_bulk_offer()
		Sim.run_day()
	var snapshot: Dictionary = GameState.to_dict()
	_assert(SaveManager.save_game(), "save_game writes")
	# Mutate wildly, then load.
	GameState.reset(1)
	Sim.run_day()
	_assert(SaveManager.load_game(), "load_game reads")
	var restored: Dictionary = GameState.to_dict()
	var same: bool = JSON.stringify(snapshot) == JSON.stringify(restored)
	_assert(same, "state round-trips identically through save/load")


# ------------------------------------------------------------------
# 6. Missions: scripted playthrough completes Chapter 1; expansion
#    refused while cash < cost.
# ------------------------------------------------------------------
func _test_missions() -> void:
	_fresh(2026)
	var completed: Array = []
	var done: Array = [false]
	var conn = func(m: Dictionary) -> void: completed.append(m.id)
	var conn2 = func() -> void: done[0] = true
	Missions.mission_completed.connect(conn)
	Missions.chapter_completed.connect(conn2)

	GameState.cash = 100.0
	_assert(not Sim.expand_shop(), "expansion refused when cash < %d" % int(SimConfig.EXPANSION_COST))
	GameState.cash = SimConfig.STARTING_CASH

	var guard: int = 0
	while not done[0] and guard < 200:
		guard += 1
		if GameState.inventory < 40 and GameState.cash > 3000.0:
			Sim.buy_inventory(80)
		if not GameState.has_ravi and completed.has("restock") and GameState.cash > 3500.0:
			Sim.hire_ravi()
		if completed.has("month_end") and not GameState.has_expanded_shop \
				and GameState.cash >= SimConfig.EXPANSION_COST + 2000.0:
			Sim.expand_shop()
		if not GameState.pending_credit_request.is_empty():
			Sim.refuse_credit()
		if not GameState.pending_bulk_offer.is_empty():
			Sim.decline_bulk_offer()
		if GameState.lender_offer_pending:
			Sim.accept_lender()
		Sim.run_day()
	Missions.mission_completed.disconnect(conn)
	Missions.chapter_completed.disconnect(conn2)
	_assert(completed == ["opening_day", "restock", "long_queue", "month_end", "shop_next_door"],
		"Chapter 1 completes in order (got %s)" % [completed])
	_assert(done[0], "chapter_completed emitted (in %d days)" % GameState.day)

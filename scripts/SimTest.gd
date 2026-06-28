extends Node
## BizTown — Sprint 1 console test for the Business Simulation Engine.
## No UI: run this scene with F6 (Run Current Scene) and read the Output panel.
## It walks the Chapter 1 beats: pricing, stock, the long queue + Ravi, month-end.

func _ready() -> void:
	GameState.reset()

	_header("STARTING STATE")
	_print_summary()

	_header("DEMAND & PROJECTED PROFIT AT DIFFERENT PRICES (reputation 50)")
	for p in [20, 25, 30, 35, 40, 45, 50, 55]:
		var d: float = Sim.calculate_demand(float(p), 50.0)
		var profit: float = Sim.calculate_daily_profit(float(p), SimConfig.PRODUCT_COST, 50.0, 9999)
		print("  Rs %2d  ->  %5.1f customers   | projected profit Rs %.0f" % [p, d, profit])

	_header("SAME PRICES AT HIGHER REPUTATION (80) — premium becomes viable")
	for p in [35, 45, 50, 55]:
		var d: float = Sim.calculate_demand(float(p), 80.0)
		print("  Rs %2d  ->  %5.1f customers" % [p, d])

	_header("BUY OPENING STOCK (120 units of Soap)")
	var spent: float = Sim.buy_inventory(120)
	print("  Bought 120 Soap for Rs %.0f. Inventory %d, cash Rs %.0f" % [spent, GameState.inventory, GameState.cash])

	_header("RUN 5 DAYS AT Rs 35 — the sweet spot, but a queue is already forming")
	GameState.current_price = 35.0
	for i in range(5):
		_print_day(Sim.run_day())

	_header("THE QUEUE AT THE SWEET SPOT (Rs 35) — success has outgrown one person")
	Sim.buy_inventory(150)  # plenty of stock, so capacity (not stock) is the limit
	print("  Solo capacity: %d customers/day." % SimConfig.CAPACITY_SOLO)
	print("  -- BEFORE Ravi --")
	var before: Dictionary = Sim.run_day()
	print("    demand %d, capacity %d  ->  served %d, TURNED AWAY %d  | rep %.1f"
		% [before.demand, SimConfig.CAPACITY_SOLO, before.served, before.lost, before.reputation])

	Sim.hire_ravi()
	print("  >> Hired Ravi (wage Rs %.0f/day). Capacity %d -> %d customers/day."
		% [SimConfig.RAVI_WAGE, SimConfig.CAPACITY_SOLO, Sim.get_capacity()])

	_header("AFTER RAVI — turned-away drops to 0; demand climbs as reputation recovers")
	for i in range(5):
		var r: Dictionary = Sim.run_day()
		print("    Day %d: demand %d, capacity %d  ->  served %d, turned away %d  | cash Rs %.0f | rep %.1f"
			% [r.day, r.demand, Sim.get_capacity(), r.served, r.lost, r.cash, r.reputation])

	_header("MONTH-END — rent is due every %d days" % SimConfig.MONTH_LENGTH_DAYS)
	var rent: float = Sim.apply_monthly_costs()
	print("  Paid rent Rs %.0f. Cash now Rs %.0f" % [rent, GameState.cash])

	_header("FINAL STATE")
	_print_summary()
	print("  Traits recorded (data only, never shown in-game): %s" % [GameState.traits])


func _print_day(r: Dictionary) -> void:
	print("    Day %2d @ Rs %.0f: %d/%d served (%d turned away) | revenue Rs %.0f | inv %d | cash Rs %.0f | rep %.1f"
		% [r.day, r.price, r.served, r.demand, r.lost, r.revenue, r.inventory, r.cash, r.reputation])


func _print_summary() -> void:
	var s: Dictionary = Sim.get_daily_summary()
	print("  Day %d | Cash Rs %.0f | Reputation %.1f | Inventory %d | Price Rs %.0f | Ravi: %s | Costs Rs %.0f/day"
		% [s.day, s.cash, s.reputation, s.inventory, s.price, str(s.has_ravi), s.daily_costs])
	print("  Lifetime customers: %d served, %d lost" % [s.customers_served, s.customers_lost])


func _header(title: String) -> void:
	print("\n=== %s ===" % title)

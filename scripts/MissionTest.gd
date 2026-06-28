extends Node
## BizTown — Sprint 2: Mission Engine test. Run with F6 (Run Current Scene); read the Output panel.
## Demonstrates: event-driven completion, force-complete, reset, and independent mission start.
## It drives the Simulation Engine to satisfy objectives — the Mission Engine reacts on its own.

func _ready() -> void:
	MissionManager.mission_started.connect(_log_started)
	MissionManager.mission_completed.connect(_log_completed)
	MissionManager.chapter_completed.connect(_log_chapter)

	_header("PART A - NORMAL CHAPTER 1 PLAYTHROUGH (event-driven completion)")
	MissionManager.start_chapter()
	_print_state()

	print("\n  -- Mission 1: trade until enough customers are served --")
	GameState.current_price = 35.0
	var safety: int = 0
	while MissionManager.get_current_mission().get("id", "") == "opening_day" and safety < 100:
		Sim.run_day()
		safety += 1
	_print_state()

	print("\n  -- Mission 2: restock to clear the objective --")
	Sim.buy_inventory(80)
	_print_state()

	print("\n  -- Mission 3: hire Ravi --")
	Sim.hire_ravi()
	_print_state()

	print("\n  -- Mission 4: force-complete (testing shortcut) --")
	MissionManager.force_complete_current()
	print("     After M4: M5 should be ACTIVE, NOT auto-completed (no cascade):")
	_print_state()

	print("\n  -- Mission 5 must NOT complete from cash alone --")
	print("     cash is Rs %.0f (above the old Rs 8000 threshold), and a normal day passes:" % GameState.cash)
	Sim.run_day()
	_print_state()

	print("\n  -- Trigger the expansion decision; only now should M5 complete and the chapter end --")
	Sim.expand_shop()
	_print_state()

	_header("PART B - TEST A MISSION INDEPENDENTLY")
	MissionManager.reset()
	print("  After reset:")
	_print_state()
	print("\n  -- Jump straight to 'The Long Queue', then force-complete it --")
	MissionManager.start_mission("the_long_queue")
	MissionManager.force_complete_current()
	_print_state()

	_header("RESET BACK TO START")
	MissionManager.reset()
	_print_state()


func _log_started(m: Dictionary) -> void:
	print("  >> STARTED:   %s  -  %s" % [m.title, m.objective])


func _log_completed(m: Dictionary) -> void:
	var msg: String = MissionManager.last_message
	if msg != "":
		print("  ** COMPLETED: %s   [%s]" % [m.title, msg])
	else:
		print("  ** COMPLETED: %s" % m.title)


func _log_chapter() -> void:
	print("  #####  CHAPTER 1 COMPLETE  #####")


func _print_state() -> void:
	var m: Dictionary = MissionManager.get_current_mission()
	var title: String = m.get("title", "(none)")
	print("     state: current=%s active=%s | cash Rs %.0f | rep %.1f | inv %d | day %d | served %d | ravi=%s | expanded=%s"
		% [title, str(MissionManager.is_active), GameState.cash, GameState.reputation,
			GameState.inventory, GameState.day, GameState.customers_served,
			str(GameState.has_ravi), str(GameState.has_expanded_shop)])


func _header(t: String) -> void:
	print("\n========== %s ==========" % t)

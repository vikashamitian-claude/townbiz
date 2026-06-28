extends Node
## BizTown — Sprint 2: Mission Engine. Autoloaded as "MissionManager".
##
## Sits ABOVE the Simulation Engine. It controls progression only:
##   * tracks the current mission,
##   * checks completion conditions by READING GameState,
##   * advances to the next mission and applies simple rewards.
##
## It contains NO business calculations. It re-checks the objective whenever the
## Simulation Engine reports that something changed (via Sim's signals).

signal mission_started(mission: Dictionary)
signal mission_completed(mission: Dictionary)
signal chapter_completed()

var missions: Array = []
var current_mission: Dictionary = {}
var is_active: bool = false
var unlocked: Array[String] = []
var last_message: String = ""


func _ready() -> void:
	missions = MissionData.chapter_1()
	# React to the business state changing — but never do business math here.
	Sim.changed.connect(_on_state_changed)
	Sim.day_ended.connect(_on_day_ended)
	Sim.ravi_hired.connect(_on_state_changed)


# ---------------------------------------------------------------------------
#  Public control
# ---------------------------------------------------------------------------

## Begin Chapter 1 from the first mission (also resets the simulation).
func start_chapter() -> void:
	GameState.reset()
	unlocked.clear()
	start_mission(missions[0].id)


## Start a specific mission by id (used by the chapter flow and for independent testing).
func start_mission(id: String) -> void:
	var m: Dictionary = find_mission(id)
	if m.is_empty():
		push_warning("MissionManager: mission not found: " + id)
		return
	current_mission = m
	is_active = true
	mission_started.emit(current_mission)
	# Arm-on-entry: do NOT check completion here. A mission completes only on a LATER
	# sim event, a force-complete (test), or an explicit action — never the instant it starts.
	# This prevents same-instant completion cascades (e.g. M4 -> M5 -> chapter end).


## Force the current mission to complete — testing/debug only.
func force_complete_current() -> void:
	if is_active:
		_complete_current()


## Reset the whole chapter and the simulation back to the start.
func reset() -> void:
	is_active = false
	current_mission = {}
	start_chapter()


# ---------------------------------------------------------------------------
#  Lookup
# ---------------------------------------------------------------------------

func find_mission(id: String) -> Dictionary:
	for m in missions:
		if m.id == id:
			return m
	return {}


func get_current_mission() -> Dictionary:
	return current_mission


# ---------------------------------------------------------------------------
#  Event handlers (from the Simulation Engine)
# ---------------------------------------------------------------------------

func _on_state_changed() -> void:
	_check_completion()


func _on_day_ended(_result: Dictionary) -> void:
	_check_completion()


# ---------------------------------------------------------------------------
#  Internal
# ---------------------------------------------------------------------------

func _check_completion() -> void:
	if not is_active or current_mission.is_empty():
		return
	if _is_condition_met(current_mission.condition):
		_complete_current()


func _complete_current() -> void:
	is_active = false
	var finished: Dictionary = current_mission
	_apply_reward(finished.get("reward", {}))
	mission_completed.emit(finished)

	var next_id: String = finished.get("next", "")
	if next_id == "":
		current_mission = {}
		chapter_completed.emit()
	else:
		start_mission(next_id)


## Maps a condition type to a simple GameState comparison. No business math here.
func _is_condition_met(c: Dictionary) -> bool:
	match c.get("type", ""):
		"cash_at_least": return GameState.cash >= c.value
		"inventory_at_most": return GameState.inventory <= c.value
		"inventory_at_least": return GameState.inventory >= c.value
		"reputation_at_least": return GameState.reputation >= c.value
		"ravi_hired": return GameState.has_ravi
		"shop_expanded": return GameState.has_expanded_shop
		"day_at_least": return GameState.day >= c.value
		"customers_served_at_least": return GameState.customers_served >= c.value
		_:
			push_warning("MissionManager: unknown condition type: " + str(c.get("type", "")))
			return false


func _apply_reward(r: Dictionary) -> void:
	if r.has("cash"):
		GameState.cash += r.cash
	if r.has("reputation"):
		Sim.apply_reputation_change(r.reputation)
	if r.has("unlock") and r.unlock != "":
		if not unlocked.has(r.unlock):
			unlocked.append(r.unlock)
	last_message = r.get("message", "")

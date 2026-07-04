extends Node
## BizTown — Living Business Build: mission progression. Autoloaded as "Missions".
## EVENT-DRIVEN ONLY: connects to the five explicit Sim events, NEVER to Sim.changed.
## Reads GameState; never does business math.

signal mission_started(mission: Dictionary)
signal mission_completed(mission: Dictionary)
signal chapter_completed

var missions: Array = []
var current_index: int = -1


func _ready() -> void:
	# The five explicit events — and ONLY these — drive mission checks.
	Sim.day_ended.connect(_on_sim_event.bind("day_ended"))
	Sim.inventory_purchased.connect(_on_inventory_purchased)
	Sim.ravi_hired.connect(_on_sim_event.bind("ravi_hired"))
	Sim.shop_expanded.connect(_on_sim_event.bind("shop_expanded"))
	Sim.month_ended.connect(_on_month_ended)
	start_chapter()


func start_chapter() -> void:
	missions = MissionData.chapter_1()
	current_index = -1
	_advance()


func get_current_mission() -> Dictionary:
	if current_index >= 0 and current_index < missions.size():
		return missions[current_index]
	return {}


## For SaveManager.
func to_dict() -> Dictionary:
	return { "current_index": current_index }


func from_dict(d: Dictionary) -> void:
	current_index = int(d.get("current_index", 0))
	if current_index >= 0 and current_index < missions.size():
		mission_started.emit(missions[current_index])
	elif current_index >= missions.size():
		# Saved after Chapter 1 was already finished — tell the UI so a
		# reload doesn't silently drop back into a blank/no-mission state.
		chapter_completed.emit()


# --- signal adapters (Godot connects need matching arities) ---

func _on_inventory_purchased(_qty: int, _unit_cost: float) -> void:
	_on_sim_event("inventory_purchased")


func _on_month_ended(_rent: float, _cash: float) -> void:
	_on_sim_event("month_ended")


func _on_sim_event(_result = null, event_name: String = "") -> void:
	# bind() appends the event name as the LAST argument; signals with one payload
	# arg pass it first. Normalize:
	var evt: String = event_name if event_name != "" else String(_result)
	_check_current(evt)


func _check_current(event_name: String) -> void:
	var m: Dictionary = get_current_mission()
	if m.is_empty():
		return
	var check_on: Array = m.get("check_on", [])
	if not check_on.has(event_name):
		return
	if _conditions_met(m):
		var completed: Dictionary = m
		mission_completed.emit(completed)
		_advance()


func _conditions_met(m: Dictionary) -> bool:
	for c in m.get("conditions", []):
		match String(c.get("type", "")):
			"customers_served_total":
				if GameState.customers_served < int(c.value):
					return false
			"inventory_at_least":
				if GameState.inventory < int(c.value):
					return false
			"ravi_hired":
				if not GameState.has_ravi:
					return false
			"cash_at_least_on_day":
				if GameState.day < int(c.day):
					return false
				if GameState.cash < float(c.value):
					return false
			"shop_expanded":
				if not GameState.has_expanded_shop:
					return false
			_:
				push_warning("Unknown mission condition type: %s" % [c])
				return false
	return true


func _advance() -> void:
	current_index += 1
	if current_index < missions.size():
		mission_started.emit(missions[current_index])
	else:
		chapter_completed.emit()

extends Node
## BizTown — Living Business Build: balance sweep (Sprint L4).
## Headless (CI):  godot --headless --path . res://tests/BalanceSweep.tscn
## On-device (e.g. the Godot Android editor): open this scene and Run Current
##   Scene — the numbers are drawn on screen instead of quitting.
## Runs a naive default-price auto-player across 100 seeds x 60 days and reports:
##   - % of seeds that reach every month-end (day 30, day 60) with cash >= 0
##     WITHOUT ever being offered the lender (i.e. never went broke).
##   - the day on which expansion (cash >= SimConfig.EXPANSION_COST) first
##     becomes affordable, median across seeds that reach it within 60 days.
## Tune ONLY SimConfig.gd values against these numbers (spec success test, §9):
##   ~70% survive Month-End without the lender; expansion reachable day 40-55.
## This script never edits Sim.gd; it only reads/plays against the public API.

const SEED_COUNT: int = 100
const DAYS: int = 60

var went_broke: bool = false
var report_lines: PackedStringArray = []


func _ready() -> void:
	var survived_count: int = 0
	var expansion_days: Array[int] = []
	var never_expanded: int = 0
	var broke_seeds: Array[int] = []

	for s in range(SEED_COUNT):
		var result: Dictionary = _run_one_seed(s)
		if not result.went_broke:
			survived_count += 1
		else:
			broke_seeds.append(s)
		if result.expansion_day >= 0:
			expansion_days.append(result.expansion_day)
		else:
			never_expanded += 1

	var survive_pct: float = 100.0 * float(survived_count) / float(SEED_COUNT)
	expansion_days.sort()
	var median_expansion: String = "n/a"
	if expansion_days.size() > 0:
		var mid: int = expansion_days.size() / 2
		if expansion_days.size() % 2 == 0 and expansion_days.size() > 1:
			median_expansion = str((expansion_days[mid - 1] + expansion_days[mid]) / 2.0)
		else:
			median_expansion = str(expansion_days[mid])

	_out("\n==== BALANCE SWEEP: %d seeds x %d days ====" % [SEED_COUNT, DAYS])
	_out("Survived Month-End without lender: %d/%d (%.1f%%)  [target ~70%%]" % [survived_count, SEED_COUNT, survive_pct])
	_out("Went broke (offered lender) on seeds: %s" % [broke_seeds])
	_out("Expansion affordable (cash >= Rs %d): %d/%d seeds reached it within %d days" % [
		int(SimConfig.EXPANSION_COST), expansion_days.size(), SEED_COUNT, DAYS])
	_out("  never affordable within window: %d" % never_expanded)
	_out("  median day expansion became affordable: %s  [target 40-55]" % median_expansion)
	_out("==== END BALANCE SWEEP ====\n")
	# Don't leave a sweep-state autosave behind for the real game to "Continue" into.
	SaveManager.delete_save()
	if DisplayServer.get_name() == "headless":
		get_tree().quit(0)
	else:
		_show_report_on_screen()


func _out(line: String) -> void:
	print(line)
	report_lines.append(line)


## Windowed mode (phone/editor): draw the report instead of quitting.
func _show_report_on_screen() -> void:
	var canvas := CanvasLayer.new()
	add_child(canvas)
	var bg := ColorRect.new()
	bg.color = Color(0.09, 0.11, 0.16)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	canvas.add_child(bg)
	var scroll := ScrollContainer.new()
	scroll.set_anchors_preset(Control.PRESET_FULL_RECT)
	canvas.add_child(scroll)
	var vbox := VBoxContainer.new()
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.add_theme_constant_override("separation", 10)
	scroll.add_child(vbox)

	var head := Label.new()
	head.text = "BALANCE SWEEP RESULTS"
	head.add_theme_font_size_override("font_size", 30)
	head.add_theme_color_override("font_color", Color(0.4, 0.86, 0.52))
	vbox.add_child(head)

	var body := Label.new()
	body.text = "\n".join(report_lines)
	body.add_theme_font_size_override("font_size", 16)
	body.add_theme_color_override("font_color", Color(0.90, 0.93, 0.98))
	body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vbox.add_child(body)


## Naive default-price bot: keeps stock topped up, hires Ravi once affordable,
## always declines credit/bulk/lender (so "survived without lender" is a clean signal).
func _run_one_seed(seed_value: int) -> Dictionary:
	GameState.reset(seed_value)
	Missions.start_chapter()
	went_broke = false
	var expansion_day: int = -1

	var probe := func(_rent: float, cash_after: float) -> void:
		if cash_after < 0.0:
			went_broke = true
	Sim.month_ended.connect(probe)

	for i in range(DAYS):
		if GameState.inventory < 30 and GameState.cash > 2000.0:
			Sim.buy_inventory(60)
		if not GameState.has_ravi and GameState.cash > 4000.0 and GameState.day > 5:
			Sim.hire_ravi()
		if not GameState.pending_credit_request.is_empty():
			Sim.refuse_credit()
		if not GameState.pending_bulk_offer.is_empty():
			Sim.decline_bulk_offer()
		if GameState.lender_offer_pending:
			Sim.decline_lender()
		if expansion_day < 0 and GameState.cash >= SimConfig.EXPANSION_COST:
			expansion_day = GameState.day
		Sim.run_day()

	Sim.month_ended.disconnect(probe)
	return { "went_broke": went_broke, "expansion_day": expansion_day }

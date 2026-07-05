extends Control
## BizTown — Chapter 1 "Living Business" Build: gameplay UI (functional, not pretty).
##
## Everything here is presentation built from Godot Controls + code styles — NO art assets.
## Wires the UI to the Living Business engine (Sim / Events / Missions / SaveManager).

const DAY_DURATION: float = 2.7
const MAX_CUSTOMER_DOTS: int = 10
const LOG_MAX: int = 6

# --- Palette ---
const BG := Color(0.09, 0.11, 0.16)
const PANEL := Color(0.16, 0.19, 0.27)
const PANEL_HI := Color(0.22, 0.27, 0.38)
const TEXT := Color(0.90, 0.93, 0.98)
const MUTED := Color(0.62, 0.68, 0.80)
const CASH_COL := Color(1.0, 0.82, 0.34)
const REP_COL := Color(0.48, 0.72, 1.0)
const STOCK_COL := Color(1.0, 0.62, 0.34)
const DAY_COL := Color(0.82, 0.88, 1.0)
const REGULARS_COL := Color(0.66, 0.86, 0.56)
const GOOD := Color(0.40, 0.86, 0.52)
const BAD := Color(0.92, 0.42, 0.42)
const WARN := Color(0.96, 0.80, 0.36)
const SKIN := Color(0.88, 0.74, 0.58)
const ACCENT := Color(0.45, 0.85, 0.6)

var day_timer: float = 0.0
var running: bool = false
var chapter_done: bool = false
var counter_pos: Vector2 = Vector2(360, 225)
var world_home: Vector2 = Vector2.ZERO
var log_lines: Array[String] = []

# Reflection tracking (world-layer only — engine untouched)
var total_revenue: float = 0.0
var stock_ordered: int = 0
var price_changes: int = 0
var ravi_hire_day: int = -1
var regulars_prev: int = 0
var reflection_nodes: Array[Node] = []
var submit_button: Button
var q1_edit: LineEdit
var q2_edit: LineEdit
var q3_edit: LineEdit

# Supplier cost — today's vs yesterday's (Buy screen must show both).
var cost_today: float = SimConfig.PRODUCT_COST
var cost_yesterday: float = SimConfig.PRODUCT_COST

# Decision modal queue (credit / bulk / lender choices).
var decision_queue: Array = []
var decision_active: bool = false
var current_decision: Dictionary = {}
var decision_overlay: Control
var decision_title: Label
var decision_body: Label
var decision_yes: Button
var decision_no: Button

var telegraph_banner: PanelContainer
var telegraph_label: Label

# HUD value labels (built in code)
var day_value: Label
var cash_value: Label
var rep_value: Label
var stock_value: Label
var regulars_value: Label

@onready var hud: HBoxContainer = $HUD
@onready var mission_card: PanelContainer = $MissionCard
@onready var mission_title: Label = $MissionCard/MC/MVBox/MissionTitle
@onready var mission_objective: Label = $MissionCard/MC/MVBox/MissionObjective
@onready var mission_status: Label = $MissionCard/MC/MVBox/MissionStatus
@onready var world_area: Control = $WorldArea
@onready var shop: Panel = $WorldArea/Shop
@onready var counter: Panel = $WorldArea/Counter
@onready var ravi: Control = $WorldArea/Ravi
@onready var diary_card: PanelContainer = $DiaryCard
@onready var diary_title: Label = $DiaryCard/DMargin/DVBox/DiaryTitle
@onready var diary_log: Label = $DiaryCard/DMargin/DVBox/DiaryLog
@onready var price_card: PanelContainer = $Controls/PriceCard
@onready var price_label: Label = $Controls/PriceCard/PMargin/PVBox/PriceLabel
@onready var price_slider: HSlider = $Controls/PriceCard/PMargin/PVBox/PriceSlider
@onready var buy_button: Button = $Controls/ActionRow/BuyButton
@onready var ravi_button: Button = $Controls/ActionRow/RaviButton
@onready var expand_button: Button = $Controls/ActionRow/ExpandButton
@onready var flow_button: Button = $Controls/FlowRow/FlowButton
@onready var reset_button: Button = $Controls/FlowRow/ResetButton
@onready var overlay: Control = $Overlay
@onready var reflection_box: VBoxContainer = $Overlay/Center/CompletePanel/CMargin/CVBox


func _ready() -> void:
	_style_everything()
	_build_hud()
	_build_telegraph_banner()
	_build_decision_overlay()

	Missions.mission_started.connect(_on_mission_started)
	Missions.mission_completed.connect(_on_mission_completed)
	Missions.chapter_completed.connect(_on_chapter_completed)
	Sim.month_ended.connect(_on_month_ended)
	Events.event_telegraphed.connect(_on_event_telegraphed)
	Events.credit_requested.connect(_on_credit_requested)
	Events.bulk_offered.connect(_on_bulk_offered)
	Events.lender_offered.connect(_on_lender_offered)
	Events.contract_offered.connect(_on_contract_offered)

	price_slider.min_value = SimConfig.PRICE_MIN
	price_slider.max_value = SimConfig.PRICE_MAX
	price_slider.step = 1.0
	price_slider.value = SimConfig.DEFAULT_PRICE
	price_slider.value_changed.connect(_on_price_changed)
	price_slider.drag_ended.connect(_on_price_drag_ended)

	buy_button.pressed.connect(_on_buy)
	ravi_button.pressed.connect(_on_hire_ravi)
	expand_button.pressed.connect(_on_expand)
	flow_button.pressed.connect(_on_flow_pressed)
	reset_button.pressed.connect(_on_reset_pressed)

	ravi.visible = false
	overlay.visible = false
	overlay.z_index = 100   # always above floating feedback (z 50)
	_clear_log()
	world_home = world_area.position

	if SaveManager.has_save():
		_show_boot_choice()
	else:
		_begin_new_game()


func _process(delta: float) -> void:
	if not running or chapter_done:
		return
	day_timer += delta
	if day_timer >= DAY_DURATION:
		day_timer = 0.0
		_advance_day()


# ===========================================================================
#  BOOT — Continue / New Game (Sprint L3)
# ===========================================================================

func _begin_new_game() -> void:
	Missions.start_chapter()
	GameState.current_price = price_slider.value
	cost_today = Sim.get_current_unit_cost()
	cost_yesterday = cost_today
	regulars_prev = GameState.regular_count
	_on_price_changed(price_slider.value)
	_refresh_hud()
	_update_buttons()


func _sync_after_load() -> void:
	price_slider.value = GameState.current_price
	cost_today = Sim.get_current_unit_cost()
	cost_yesterday = cost_today
	regulars_prev = GameState.regular_count
	_on_price_changed(GameState.current_price)
	_refresh_hud()
	_update_buttons()


func _show_boot_choice() -> void:
	var boot := Control.new()
	boot.set_anchors_preset(Control.PRESET_FULL_RECT)
	boot.z_index = 200
	add_child(boot)

	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.75)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	boot.add_child(dim)

	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	boot.add_child(center)

	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(560, 0)
	panel.add_theme_stylebox_override("panel", _sb(PANEL, 18, 2, ACCENT))
	center.add_child(panel)

	var margin := MarginContainer.new()
	for side in ["left", "top", "right", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 28)
	panel.add_child(margin)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 14)
	margin.add_child(vbox)

	var title := Label.new()
	title.text = "Welcome back"
	title.add_theme_font_size_override("font_size", 30)
	title.add_theme_color_override("font_color", TEXT)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(title)

	var sub := Label.new()
	sub.text = "You have a shop in progress."
	sub.add_theme_color_override("font_color", MUTED)
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(sub)

	var continue_btn := Button.new()
	continue_btn.text = "Continue"
	continue_btn.custom_minimum_size = Vector2(0, 50)
	_style_button(continue_btn, ACCENT.darkened(0.1))
	vbox.add_child(continue_btn)

	var new_btn := Button.new()
	new_btn.text = "New Game"
	new_btn.custom_minimum_size = Vector2(0, 50)
	_style_button(new_btn, PANEL_HI)
	vbox.add_child(new_btn)

	continue_btn.pressed.connect(func() -> void:
		boot.queue_free()
		SaveManager.load_game()
		_sync_after_load()
	)
	new_btn.pressed.connect(func() -> void:
		boot.queue_free()
		SaveManager.delete_save()
		_begin_new_game()
	)


# ===========================================================================
#  STYLING (looks like a studio prototype, no art)
# ===========================================================================

func _style_everything() -> void:
	$Bg.color = BG
	for p in [mission_card, diary_card, price_card]:
		p.add_theme_stylebox_override("panel", _sb(PANEL, 14, 1, PANEL_HI))
	$Overlay/Center/CompletePanel.add_theme_stylebox_override("panel", _sb(PANEL, 18, 2, ACCENT))
	shop.add_theme_stylebox_override("panel", _sb(Color(0.78, 0.55, 0.38), 10, 3, Color(0.5, 0.34, 0.22)))
	counter.add_theme_stylebox_override("panel", _sb(Color(0.42, 0.32, 0.24), 6))
	$WorldArea/ShopSign.add_theme_color_override("font_color", Color(1, 0.95, 0.8))
	$WorldArea/Ravi/RaviLabel.add_theme_color_override("font_color", REP_COL)

	mission_title.add_theme_color_override("font_color", TEXT)
	mission_objective.add_theme_color_override("font_color", ACCENT)
	mission_status.add_theme_color_override("font_color", MUTED)
	diary_title.add_theme_color_override("font_color", MUTED)
	diary_log.add_theme_color_override("font_color", TEXT)
	price_label.add_theme_color_override("font_color", TEXT)

	# Ravi (blue helper figure)
	$WorldArea/Ravi/RaviBody.add_theme_stylebox_override("panel", _sb(REP_COL.darkened(0.1), 8))
	$WorldArea/Ravi/RaviHead.add_theme_stylebox_override("panel", _sb(SKIN, 10))

	# Buttons (subtle hover/pressed)
	for b in [buy_button, ravi_button, expand_button, reset_button]:
		_style_button(b, PANEL_HI)
	_style_button(flow_button, ACCENT.darkened(0.1))


func _sb(bg: Color, radius: int = 10, border: int = 0, border_col: Color = Color.TRANSPARENT) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = bg
	s.set_corner_radius_all(radius)
	if border > 0:
		s.set_border_width_all(border)
		s.border_color = border_col
	s.content_margin_left = 12.0
	s.content_margin_right = 12.0
	s.content_margin_top = 8.0
	s.content_margin_bottom = 8.0
	return s


func _style_button(b: Button, base: Color) -> void:
	b.add_theme_stylebox_override("normal", _sb(base, 10))
	b.add_theme_stylebox_override("hover", _sb(base.lightened(0.12), 10))
	b.add_theme_stylebox_override("pressed", _sb(base.darkened(0.18), 10))
	b.add_theme_stylebox_override("disabled", _sb(PANEL.darkened(0.1), 10))
	b.add_theme_color_override("font_color", TEXT)
	b.add_theme_color_override("font_disabled_color", MUTED.darkened(0.2))


func _build_hud() -> void:
	day_value = _add_chip("DAY", "0", DAY_COL)
	cash_value = _add_chip("CASH", "Rs 0", CASH_COL)
	rep_value = _add_chip("REPUTATION", "0", REP_COL)
	stock_value = _add_chip("STOCK", "0", STOCK_COL)
	regulars_value = _add_chip("REGULARS", "0", REGULARS_COL)


func _add_chip(caption: String, value: String, accent: Color) -> Label:
	var p := PanelContainer.new()
	p.add_theme_stylebox_override("panel", _sb(PANEL, 12, 2, accent.darkened(0.25)))
	p.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 2)
	p.add_child(v)
	var cap := Label.new()
	cap.text = caption
	cap.add_theme_font_size_override("font_size", 13)
	cap.add_theme_color_override("font_color", MUTED)
	cap.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var val := Label.new()
	val.text = value
	val.add_theme_font_size_override("font_size", 26)
	val.add_theme_color_override("font_color", accent)
	val.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(cap)
	v.add_child(val)
	hud.add_child(p)
	return val


## Evening-news-style banner for Events.event_telegraphed (Fairness law: warn a day ahead).
func _build_telegraph_banner() -> void:
	telegraph_banner = PanelContainer.new()
	telegraph_banner.visible = false
	telegraph_banner.set_anchors_preset(Control.PRESET_TOP_WIDE)
	telegraph_banner.offset_left = 16.0
	telegraph_banner.offset_right = -16.0
	telegraph_banner.offset_top = 258.0
	telegraph_banner.offset_bottom = 300.0
	telegraph_banner.z_index = 60
	telegraph_banner.add_theme_stylebox_override("panel", _sb(WARN.darkened(0.55), 10, 2, WARN))
	add_child(telegraph_banner)
	var m := MarginContainer.new()
	m.add_theme_constant_override("margin_left", 14)
	m.add_theme_constant_override("margin_top", 6)
	m.add_theme_constant_override("margin_right", 14)
	m.add_theme_constant_override("margin_bottom", 6)
	telegraph_banner.add_child(m)
	telegraph_label = Label.new()
	telegraph_label.add_theme_color_override("font_color", WARN)
	telegraph_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	m.add_child(telegraph_label)


## One reusable modal for credit / bulk / lender choices (Sprint L3).
func _build_decision_overlay() -> void:
	decision_overlay = Control.new()
	decision_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	decision_overlay.z_index = 150
	decision_overlay.visible = false
	add_child(decision_overlay)

	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.65)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	decision_overlay.add_child(dim)

	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	decision_overlay.add_child(center)

	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(600, 0)
	panel.add_theme_stylebox_override("panel", _sb(PANEL, 18, 2, PANEL_HI))
	center.add_child(panel)

	var margin := MarginContainer.new()
	for side in ["left", "top", "right", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 26)
	panel.add_child(margin)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 14)
	margin.add_child(vbox)

	decision_title = Label.new()
	decision_title.add_theme_font_size_override("font_size", 26)
	decision_title.add_theme_color_override("font_color", TEXT)
	vbox.add_child(decision_title)

	decision_body = Label.new()
	decision_body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	decision_body.add_theme_color_override("font_color", MUTED)
	vbox.add_child(decision_body)

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	vbox.add_child(row)

	decision_yes = Button.new()
	decision_yes.custom_minimum_size = Vector2(0, 50)
	decision_yes.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_style_button(decision_yes, ACCENT.darkened(0.1))
	row.add_child(decision_yes)

	decision_no = Button.new()
	decision_no.custom_minimum_size = Vector2(0, 50)
	decision_no.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_style_button(decision_no, PANEL_HI)
	row.add_child(decision_no)

	decision_yes.pressed.connect(_on_decision_yes_pressed)
	decision_no.pressed.connect(_on_decision_no_pressed)


# ===========================================================================
#  TIME / WORLD
# ===========================================================================

func _advance_day() -> void:
	telegraph_banner.visible = false
	cost_yesterday = cost_today

	var rep_before: float = GameState.reputation
	var r: Dictionary = Sim.run_day()
	cost_today = Sim.get_current_unit_cost()
	var drep: int = int(round(GameState.reputation - rep_before))
	total_revenue += r.revenue

	_diary_day(r)
	_note_regulars_trend(int(r.regulars))
	var day_contract: Dictionary = r.get("contract", {})
	if not day_contract.is_empty():
		_diary("%s's %s is finished - paid Rs %d. It stands as long as the town does." % [
			String(day_contract.name), String(day_contract.get("label", "house")).to_lower(),
			int(day_contract.payout)])
		if String(day_contract.get("teach", "")) != "":
			_diary(String(day_contract.teach))

	if drep > 0:
		_float("Reputation +%d" % drep, REP_COL, rep_value.global_position + Vector2(0, 30))
	elif drep < 0:
		_float("Reputation %d" % drep, BAD, rep_value.global_position + Vector2(0, 30))

	if GameState.inventory <= SimConfig.LOW_STOCK and not chapter_done:
		_float("Low stock!", WARN, stock_value.global_position + Vector2(0, 30))

	_spawn_customers(r)
	_refresh_hud()
	_update_buttons()


func _spawn_customers(result: Dictionary) -> void:
	var demand: int = int(result.served) + int(result.lost)
	if demand <= 0:
		return
	var total: int = mini(demand, MAX_CUSTOMER_DOTS)
	var served_dots: int = clampi(int(round(float(result.served) / float(demand) * total)), 0, total)
	for i in range(total):
		_spawn_customer(i < served_dots, i)


## A little grey-box person: green/blue = served, becomes red if turned away.
func _spawn_customer(served: bool, idx: int) -> void:
	var person := Control.new()
	person.size = Vector2(26, 44)
	var body := Panel.new()
	body.add_theme_stylebox_override("panel", _sb(Color(0.55, 0.62, 0.78), 8))
	body.position = Vector2(4, 16)
	body.size = Vector2(18, 26)
	var head := Panel.new()
	head.add_theme_stylebox_override("panel", _sb(SKIN, 10))
	head.position = Vector2(5, 0)
	head.size = Vector2(16, 16)
	person.add_child(body)
	person.add_child(head)

	var start := Vector2(140.0 + idx * 44.0, 430.0)
	person.position = start
	world_area.add_child(person)

	var t := create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	if served:
		t.tween_property(person, "position", counter_pos + Vector2(randf_range(-30, 30), 0), DAY_DURATION * 0.45)
		t.tween_callback(_customer_buy.bind(person))
		t.tween_property(person, "position", Vector2(person.position.x, -70), DAY_DURATION * 0.5)
	else:
		var queue := Vector2(360 + randf_range(-70, 70), 300)
		t.tween_property(person, "position", queue, DAY_DURATION * 0.4)
		t.tween_callback(_customer_leave.bind(person))
		var exit_x := -60.0 if start.x < 360.0 else 780.0
		t.tween_property(person, "position", Vector2(exit_x, 470), DAY_DURATION * 0.5)
	t.tween_callback(person.queue_free)


func _customer_buy(person: Control) -> void:
	_float("+Rs %d" % int(GameState.current_price), GOOD, person.global_position + Vector2(-6, -12))


func _customer_leave(person: Control) -> void:
	(person.get_child(0) as Panel).add_theme_stylebox_override("panel", _sb(BAD, 8))
	(person.get_child(1) as Panel).add_theme_stylebox_override("panel", _sb(BAD.lightened(0.2), 10))
	_float("left!", BAD, person.global_position + Vector2(-4, -12))


# ===========================================================================
#  FLOATING FEEDBACK + SHAKE / CONFETTI
# ===========================================================================

func _float(text: String, color: Color, pos: Vector2) -> void:
	var l := Label.new()
	l.text = text
	l.add_theme_color_override("font_color", color)
	l.add_theme_font_size_override("font_size", 22)
	l.position = pos
	l.z_index = 50
	add_child(l)
	var t := create_tween()
	t.set_parallel(true)
	t.tween_property(l, "position:y", pos.y - 48, 0.9).set_ease(Tween.EASE_OUT)
	t.tween_property(l, "modulate:a", 0.0, 0.9)
	t.set_parallel(false)
	t.tween_callback(l.queue_free)


func _shake(amount: float) -> void:
	var t := create_tween()
	for i in range(6):
		var off := Vector2(randf_range(-amount, amount), randf_range(-amount, amount))
		t.tween_property(world_area, "position", world_home + off, 0.04)
	t.tween_property(world_area, "position", world_home, 0.05)


func _confetti() -> void:
	var cols := [Color(1, 0.45, 0.45), Color(0.45, 0.8, 1), Color(1, 0.85, 0.35), GOOD]
	for i in range(28):
		var p := ColorRect.new()
		p.size = Vector2(10, 14)
		p.color = cols[i % cols.size()]
		p.position = Vector2(360, 120)
		p.z_index = 40
		world_area.add_child(p)
		var dir := Vector2(randf_range(-1, 1), randf_range(-1.2, -0.3)).normalized()
		var target := p.position + dir * randf_range(160, 320) + Vector2(0, 280)
		var t := create_tween()
		t.set_parallel(true)
		t.tween_property(p, "position", target, 1.3).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		t.tween_property(p, "rotation", randf_range(-6, 6), 1.3)
		t.tween_property(p, "modulate:a", 0.0, 1.3)
		t.set_parallel(false)
		t.tween_callback(p.queue_free)


# ===========================================================================
#  PLAYER INPUT
# ===========================================================================

func _on_price_changed(value: float) -> void:
	GameState.current_price = value
	var demand_range: Vector2i = Sim.calculate_demand_range(value, GameState.reputation)
	price_label.text = "Price Rs %d     %d-%d customers likely" % [int(value), demand_range.x, demand_range.y]


func _on_buy() -> void:
	var unit_cost: float = Sim.get_current_unit_cost()
	if not Sim.buy_inventory(SimConfig.BUY_QUANTITY):
		_float("Not enough cash", BAD, stock_value.global_position + Vector2(0, 30))
		return
	var cost: int = int(round(SimConfig.BUY_QUANTITY * unit_cost))
	stock_ordered += SimConfig.BUY_QUANTITY
	_diary("Ordered %d units of soap at Rs %d/unit (Rs %d). Shelves are full again." % [SimConfig.BUY_QUANTITY, int(round(unit_cost)), cost])
	_float("+%d stock" % SimConfig.BUY_QUANTITY, STOCK_COL, stock_value.global_position + Vector2(0, 30))
	_refresh_hud()
	_update_buttons()


func _on_hire_ravi() -> void:
	if not Sim.hire_ravi():
		return
	ravi_hire_day = GameState.day
	ravi.visible = true
	var target := ravi.position
	ravi.position = target + Vector2(320, 0)
	var t := create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	t.tween_property(ravi, "position", target, 0.6)
	_float("Ravi joined!", GOOD, Vector2(360, 300))
	_float("Capacity 25 -> 50", REP_COL, Vector2(360, 340))
	_diary("Ravi started work today. The shop can now serve twice as many customers.")
	_shake(5.0)
	_refresh_hud()
	_update_buttons()


func _on_expand() -> void:
	if not Sim.expand_shop():
		_float("Need Rs %d to expand" % int(SimConfig.EXPANSION_COST), BAD, Vector2(360, 300))
		return
	_diary("Opened the bigger shop next door. Twice the space!")
	var t := create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	t.set_parallel(true)
	t.tween_property(shop, "size", Vector2(360, 200), 0.6)
	t.tween_property(shop, "position", Vector2(180, 30), 0.6)
	_shake(12.0)
	_confetti()
	_refresh_hud()
	_update_buttons()


# ===========================================================================
#  FLOW CONTROL
# ===========================================================================

func _on_flow_pressed() -> void:
	if chapter_done or decision_active:
		return
	running = not running
	day_timer = 0.0
	_update_buttons()


func _on_reset_pressed() -> void:
	chapter_done = false
	running = false
	day_timer = 0.0
	ravi.visible = false
	overlay.visible = false
	overlay.modulate.a = 1.0
	shop.position = Vector2(230, 40)
	shop.size = Vector2(260, 170)
	world_area.position = world_home
	total_revenue = 0.0
	stock_ordered = 0
	price_changes = 0
	regulars_prev = 0
	ravi_hire_day = -1
	decision_queue.clear()
	decision_active = false
	decision_overlay.visible = false
	telegraph_banner.visible = false
	_clear_reflection()
	_clear_log()
	SaveManager.delete_save()
	GameState.reset()
	Missions.start_chapter()
	cost_today = Sim.get_current_unit_cost()
	cost_yesterday = cost_today
	_refresh_hud()
	_update_buttons()


# ===========================================================================
#  DAILY EVENTS — telegraph banner + credit/bulk/lender decision modals
# ===========================================================================

func _on_event_telegraphed(event: Dictionary) -> void:
	telegraph_label.text = "TOMORROW: " + String(event.get("telegraph", ""))
	telegraph_banner.visible = true


func _on_credit_requested(request: Dictionary) -> void:
	_queue_decision("credit", request)


func _on_bulk_offered(offer: Dictionary) -> void:
	_queue_decision("bulk", offer)


func _on_lender_offered(offer: Dictionary) -> void:
	_queue_decision("lender", offer)


func _on_contract_offered(offer: Dictionary) -> void:
	_queue_decision("contract", offer)


func _queue_decision(kind: String, data: Dictionary) -> void:
	decision_queue.append({"kind": kind, "data": data})
	if not decision_active:
		_show_next_decision()


func _show_next_decision() -> void:
	if decision_queue.is_empty():
		decision_active = false
		decision_overlay.visible = false
		_update_buttons()
		return
	decision_active = true
	running = false
	current_decision = decision_queue.pop_front()
	var data: Dictionary = current_decision.data
	match String(current_decision.kind):
		"credit":
			decision_title.text = "Credit request"
			if not GameState.customer_relationships.get(String(data.name), {}).is_empty():
				decision_body.text = "%s is back, wanting %d units of soap on credit, repaying in %d days." % [
					String(data.name), int(data.qty), int(data.repay_in_days)]
			else:
				decision_body.text = "A new face, %s, wants %d units of soap on credit, repaying in %d days." % [
					String(data.name), int(data.qty), int(data.repay_in_days)]
			decision_yes.text = "Grant credit"
			decision_no.text = "Refuse"
		"bulk":
			decision_title.text = "Bulk order offer"
			decision_body.text = "A lodge wants %d soaps at Rs %d each, delivered in %d days." % [
				int(data.qty), int(round(float(data.unit_price))), int(data.deadline_days)]
			decision_yes.text = "Accept"
			decision_no.text = "Decline"
		"lender":
			decision_title.text = "The Mahajan's offer"
			decision_body.text = "Cash is short. Mahajan offers Rs %d now, repay Rs %d by next month-end." % [
				int(data.principal), int(data.repay)]
			decision_yes.text = "Accept loan"
			decision_no.text = "Decline"
		"contract":
			decision_title.text = "Build contract: %s" % String(data.get("label", "House"))
			decision_body.text = "%s wants a %s built. Materials Rs %d now; pays Rs %d in %d days. Profit: Rs %d." % [
				String(data.name), String(data.get("label", "house")).to_lower(),
				int(data.materials_cost), int(data.payout),
				int(data.build_days), int(data.payout) - int(data.materials_cost)]
			decision_yes.text = "Take the contract"
			decision_no.text = "Pass"
	decision_overlay.visible = true
	_refresh_hud()


func _on_decision_yes_pressed() -> void:
	var data: Dictionary = current_decision.get("data", {})
	match String(current_decision.get("kind", "")):
		"credit":
			if Sim.grant_credit():
				_diary("Granted %s credit for %d units." % [String(data.name), int(data.qty)])
			else:
				_diary("Couldn't grant %s credit - not enough stock." % String(data.name))
		"bulk":
			Sim.accept_bulk_offer()
			_diary("Accepted a bulk order for %d units." % int(data.qty))
		"lender":
			Sim.accept_lender()
			_diary("Took a Rs %d loan from the Mahajan." % int(data.principal))
		"contract":
			if Sim.accept_contract():
				_diary("Took %s's build contract - materials cost Rs %d." % [
					String(data.name), int(data.materials_cost)])
			else:
				_diary("Couldn't take the contract - not enough cash for materials.")
	_show_next_decision()


func _on_decision_no_pressed() -> void:
	var data: Dictionary = current_decision.get("data", {})
	match String(current_decision.get("kind", "")):
		"credit":
			Sim.refuse_credit()
			_diary("Refused %s's credit request." % String(data.name))
		"bulk":
			Sim.decline_bulk_offer()
			_diary("Declined the bulk order.")
		"lender":
			Sim.decline_lender()
			_diary("Declined the Mahajan's loan.")
		"contract":
			Sim.decline_contract()
			_diary("Passed on %s's build contract." % String(data.name))
	_show_next_decision()


func _on_month_ended(rent_paid: float, _cash_after: float) -> void:
	_diary("Month-end. Paid Rs %d in rent." % int(rent_paid))
	if GameState.lender_debt > 0.0:
		_diary("   Loan outstanding: Rs %d." % int(GameState.lender_debt))
	_float("Rent -Rs %d" % int(rent_paid), BAD, Vector2(360, 330))
	_shake(7.0)


# ===========================================================================
#  MISSION ENGINE -> UI
# ===========================================================================

func _on_mission_started(m: Dictionary) -> void:
	running = false
	day_timer = 0.0
	mission_title.text = m.title
	mission_objective.text = String(m.get("intro", ""))
	mission_status.text = ""
	_diary("New chapter beat: " + m.title)
	_pulse(mission_card)
	_update_buttons()


func _on_mission_completed(m: Dictionary) -> void:
	var msg: String = String(m.get("debrief", ""))
	mission_status.text = "Done! " + (msg if msg != "" else m.title)
	_float("Mission complete!", GOOD, Vector2(360, 200))


func _on_chapter_completed() -> void:
	chapter_done = true
	running = false
	_build_reflection()
	overlay.visible = true
	overlay.modulate.a = 0.0
	var t := create_tween()
	t.tween_interval(0.6)
	t.tween_property(overlay, "modulate:a", 1.0, 0.6)
	_update_buttons()


# ===========================================================================
#  DISPLAY HELPERS
# ===========================================================================

func _refresh_hud() -> void:
	day_value.text = str(GameState.day)
	cash_value.text = "Rs %d" % int(GameState.cash)
	rep_value.text = str(int(round(GameState.reputation)))
	stock_value.text = str(GameState.inventory)
	stock_value.add_theme_color_override("font_color", WARN if GameState.inventory <= SimConfig.LOW_STOCK else STOCK_COL)
	regulars_value.text = str(GameState.regular_count)


func _update_buttons() -> void:
	var cur: Dictionary = Missions.get_current_mission()
	var cur_id: String = cur.get("id", "")

	var can_hire_ravi: bool = (cur_id == "long_queue") and not GameState.has_ravi
	ravi_button.disabled = not can_hire_ravi
	ravi_button.text = "Ravi hired" if GameState.has_ravi else "Hire Ravi (Rs %d/day)" % int(SimConfig.RAVI_WAGE)

	expand_button.disabled = not ((cur_id == "shop_next_door") and not GameState.has_expanded_shop)

	buy_button.text = "Buy %d stock - Rs%d today (Rs%d yest.)" % [SimConfig.BUY_QUANTITY, int(round(cost_today)), int(round(cost_yesterday))]
	buy_button.disabled = chapter_done

	flow_button.disabled = chapter_done or decision_active
	flow_button.text = "Pause" if running else "Start / Continue"

	_update_emphasis(cur_id)


## Brighten the button the player should press now; subdue the rest.
func _update_emphasis(cur_id: String) -> void:
	var focus: Button = null
	if cur_id == "restock":
		focus = buy_button
	elif cur_id == "long_queue":
		focus = ravi_button
	elif cur_id == "shop_next_door":
		focus = expand_button
	else:
		focus = flow_button   # Opening Day & Month-End: keep trading

	for b in [buy_button, ravi_button, expand_button, flow_button]:
		if b.disabled or b == focus:
			b.modulate = Color(1, 1, 1, 1)
		else:
			b.modulate = Color(1, 1, 1, 0.72)


func _pulse(node: Control) -> void:
	node.scale = Vector2(1, 1)
	node.pivot_offset = node.size * 0.5
	var t := create_tween().set_trans(Tween.TRANS_SINE)
	t.tween_property(node, "scale", Vector2(1.04, 1.04), 0.15)
	t.tween_property(node, "scale", Vector2(1, 1), 0.15)


func _diary_day(r: Dictionary) -> void:
	_diary("Day %d  -  %d customers bought soap (Rs %d)." % [r.day, r.served, int(r.revenue)])
	if r.lost > 0:
		_diary("   %d people left without buying - the wait was too long." % r.lost)
	if r.inventory <= SimConfig.LOW_STOCK:
		_diary("   Stock is running low. Better order more soon.")


## Surface the existing regulars feedback loop as a felt pattern, not just a
## number ticking on the HUD — first regular, every +5 milestone, or a drop.
func _note_regulars_trend(new_count: int) -> void:
	if new_count > regulars_prev:
		if regulars_prev == 0 and new_count > 0:
			_diary("   Word is spreading - your first regular customer.")
		elif new_count / 5 > regulars_prev / 5:
			_diary("   Word is spreading - %d regulars now count on your shop." % new_count)
	elif new_count < regulars_prev:
		_diary("   A regular gave up waiting today - that trust doesn't come back easily.")
	regulars_prev = new_count


func _diary(line: String) -> void:
	log_lines.append(line)
	while log_lines.size() > LOG_MAX:
		log_lines.pop_front()
	diary_log.text = "\n".join(PackedStringArray(log_lines))


func _clear_log() -> void:
	log_lines.clear()
	diary_log.text = ""


# ===========================================================================
#  REFLECTION SCREEN (the Mirror) + "Your Opinion Matters"
# ===========================================================================

func _on_price_drag_ended(value_changed: bool) -> void:
	if value_changed:
		price_changes += 1


func _build_reflection() -> void:
	_clear_reflection()

	_ref_label("YOUR BUSINESS", MUTED, 16)
	_ref_label("Days survived: %d\nCustomers served: %d\nCustomers turned away: %d\nTotal earned: Rs %d\nStock ordered: %d units\nRegulars built: %d\nMoney left: Rs %d" % [
		GameState.day, GameState.customers_served, GameState.customers_lost,
		int(total_revenue), stock_ordered, GameState.regular_count, int(GameState.cash)], TEXT, 18)

	_ref_label("YOUR DECISIONS", MUTED, 16)
	var ravi_txt: String = ("day %d" % ravi_hire_day) if ravi_hire_day >= 0 else "not hired"
	_ref_label("Final price: Rs %d\nPrice changes: %d\nRavi hired: %s\nReputation: %d" % [
		int(GameState.current_price), price_changes, ravi_txt, int(round(GameState.reputation))], TEXT, 18)

	_ref_label("YOUR STORY", MUTED, 16)
	var story: Label = _ref_label(_make_story(), ACCENT, 19)
	story.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART

	_ref_label("YOUR OPINION MATTERS", MUTED, 16)
	q1_edit = _ref_question("What confused you?")
	q2_edit = _ref_question("What did you enjoy the most?")
	q3_edit = _ref_question("Would you continue building your business?")

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	submit_button = Button.new()
	submit_button.text = "Submit"
	submit_button.custom_minimum_size = Vector2(0, 50)
	submit_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_style_button(submit_button, ACCENT.darkened(0.1))
	submit_button.pressed.connect(_on_submit_feedback)
	var again := Button.new()
	again.text = "Play Again"
	again.custom_minimum_size = Vector2(160, 50)
	_style_button(again, PANEL_HI)
	again.pressed.connect(_on_reset_pressed)
	row.add_child(submit_button)
	row.add_child(again)
	_ref_add(row)


func _make_story() -> String:
	var parts: Array[String] = []
	if ravi_hire_day >= 0 and ravi_hire_day <= 6:
		parts.append("You trusted Ravi early - and customers stopped leaving your shop.")
	elif ravi_hire_day >= 0:
		parts.append("You waited before hiring Ravi, but help arrived in time.")
	else:
		parts.append("You ran the whole shop on your own.")
	if GameState.cash >= 9000:
		parts.append("You kept healthy cash reserves instead of spending everything.")
	elif GameState.cash >= 4000:
		parts.append("You balanced spending and saving to keep the shop steady.")
	else:
		parts.append("You spent aggressively to grow - a bolder, riskier path.")
	if GameState.customers_served > 0 and GameState.customers_lost > GameState.customers_served * 0.25:
		parts.append("Many customers left unserved - capacity and stock were tight.")
	else:
		parts.append("You served most customers who came - a smooth operation.")
	if GameState.regular_count >= 15:
		parts.append("A loyal circle of regulars grew around your shop.")
	if GameState.has_expanded_shop:
		parts.append("And you took the leap to expand next door.")
	return " ".join(PackedStringArray(parts))


func _on_submit_feedback() -> void:
	if q1_edit == null:
		return
	var entry := "Q1 confused: %s\nQ2 enjoyed: %s\nQ3 continue: %s\n---\n" % [q1_edit.text, q2_edit.text, q3_edit.text]
	var existing := ""
	if FileAccess.file_exists("user://biztown_feedback.txt"):
		existing = FileAccess.get_file_as_string("user://biztown_feedback.txt")
	var f := FileAccess.open("user://biztown_feedback.txt", FileAccess.WRITE)
	if f != null:
		f.store_string(existing + entry)
		f.close()
	submit_button.text = "Thank you, founder!"
	submit_button.disabled = true


func _ref_add(n: Control) -> void:
	reflection_box.add_child(n)
	reflection_nodes.append(n)


func _ref_label(text: String, color: Color, size: int) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_color_override("font_color", color)
	l.add_theme_font_size_override("font_size", size)
	_ref_add(l)
	return l


func _ref_question(q: String) -> LineEdit:
	_ref_label(q, TEXT, 16)
	var e := LineEdit.new()
	e.placeholder_text = "type here..."
	_ref_add(e)
	return e


func _clear_reflection() -> void:
	for n in reflection_nodes:
		if is_instance_valid(n):
			n.queue_free()
	reflection_nodes.clear()
	submit_button = null
	q1_edit = null
	q2_edit = null
	q3_edit = null

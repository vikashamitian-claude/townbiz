extends Node3D
## BizTown 3D — Phase 3D-1 graybox walkable town (see HUMAN_DECISIONS.md).
## A new PRESENTATION layer only: talks to the same Sim/Events/Missions/
## SaveManager autoloads as the old 2D Game.gd. NO business logic here.
##
## The founder walks a small street: manage the shop at the counter, meet
## Ravi in person to hire him, walk to the empty shop next door to expand.
## Customers arrive as 3D figures each day; turned-away ones leave red.

enum Ctx { NONE, MANAGE, HIRE, EXPAND }

const DAY_DURATION: float = 6.0
const MAX_CUSTOMER_DOTS: int = 10
const LOG_MAX: int = 4
const INTERACT_DIST: float = 3.0

# --- Palette (UI) ---
const PANEL := Color(0.16, 0.19, 0.27, 0.92)
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
const ACCENT := Color(0.45, 0.85, 0.6)

# Cosmetic clothing palette for spawned customers (UI-only variety)
const CUSTOMER_COLORS: Array = [
	Color(0.55, 0.62, 0.78), Color(0.75, 0.55, 0.45), Color(0.55, 0.70, 0.52),
	Color(0.72, 0.62, 0.42), Color(0.62, 0.52, 0.70), Color(0.48, 0.65, 0.68),
]

# --- World points ---
const COUNTER_POS := Vector3(0, 0, -2.5)     # in front of the shop door
const RAVI_WAIT_POS := Vector3(-4.5, 0, -1.5)
const RAVI_HIRED_POS := Vector3(-1.6, 0, -3.2)
const NEIGHBOR_POS := Vector3(8, 0, -3.0)    # in front of the empty shop
const DOOR_POS := Vector3(1.2, 0, -3.6)
const SPAWN_LEFT := Vector3(-19, 0, 1.5)
const SPAWN_RIGHT := Vector3(19, 0, 1.5)

const PlayerScene := preload("res://scripts/world3d/Player3D.gd")

var day_timer: float = 0.0
var running: bool = false
var chapter_done: bool = false
var log_lines: Array[String] = []

# Reflection tracking (presentation only)
var total_revenue: float = 0.0
var stock_ordered: int = 0
var ravi_hire_day: int = -1
var price_changes: int = 0
var regulars_prev: int = 0
var submit_button: Button
var q1_edit: LineEdit
var q2_edit: LineEdit
var q3_edit: LineEdit

# Supplier cost display (today vs yesterday)
var cost_today: float = SimConfig.PRODUCT_COST
var cost_yesterday: float = SimConfig.PRODUCT_COST

# Decision modal queue (credit / bulk / lender)
var decision_queue: Array = []
var decision_active: bool = false
var current_decision: Dictionary = {}

# 3D nodes
var player: CharacterBody3D
var cam: Camera3D
var structures_root: Node3D   # everything built from GameState.built_structures
var shop_body: Node3D
var neighbor_body: Node3D
var neighbor_sign: Label3D
var ravi_npc: Node3D
var ravi_label: Label3D
var npc_root: Node3D

# UI nodes (all built in code on one CanvasLayer)
var ui: CanvasLayer
var day_value: Label
var cash_value: Label
var rep_value: Label
var stock_value: Label
var regulars_value: Label
var mission_label: Label
var telegraph_panel: PanelContainer
var telegraph_label: Label
var log_label: Label
var context_button: Button
var flow_button: Button
var manage_panel: PanelContainer
var price_label: Label
var price_slider: HSlider
var buy_button: Button
var decision_overlay: Control
var decision_title: Label
var decision_body: Label
var decision_yes: Button
var decision_no: Button
var complete_overlay: Control
var hint_label: Label
var context_action: int = Ctx.NONE


func _ready() -> void:
	_build_world()
	_build_ui()

	Missions.mission_started.connect(_on_mission_started)
	Missions.mission_completed.connect(_on_mission_completed)
	Missions.chapter_completed.connect(_on_chapter_completed)
	Sim.month_ended.connect(_on_month_ended)
	Events.event_telegraphed.connect(_on_event_telegraphed)
	Events.credit_requested.connect(func(r: Dictionary) -> void: _queue_decision("credit", r))
	Events.bulk_offered.connect(func(o: Dictionary) -> void: _queue_decision("bulk", o))
	Events.lender_offered.connect(func(o: Dictionary) -> void: _queue_decision("lender", o))

	if SaveManager.has_save():
		_show_boot_choice()
	else:
		_begin_new_game()


func _process(delta: float) -> void:
	# Follow camera (fixed angle, smooth)
	var target: Vector3 = player.global_position + Vector3(0, 13, 15)
	cam.global_position = cam.global_position.lerp(target, minf(6.0 * delta, 1.0))
	cam.look_at(player.global_position + Vector3(0, 1, 0))

	_update_context_button()

	if not running or chapter_done or decision_active or manage_panel.visible:
		return
	day_timer += delta
	if day_timer >= DAY_DURATION:
		day_timer = 0.0
		_advance_day()


# ===========================================================================
#  WORLD (graybox — Phase 3D-2 swaps these boxes for real low-poly assets)
# ===========================================================================

func _build_world() -> void:
	var business: BusinessType = BusinessRegistry.get_active()
	var env := WorldEnvironment.new()
	var e := Environment.new()
	e.background_mode = Environment.BG_SKY
	var sky := Sky.new()
	var sky_mat := ProceduralSkyMaterial.new()
	sky_mat.sky_top_color = Color(0.35, 0.55, 0.85)
	sky_mat.sky_horizon_color = Color(0.78, 0.82, 0.88)
	sky_mat.ground_bottom_color = Color(0.40, 0.56, 0.35)
	sky_mat.ground_horizon_color = Color(0.60, 0.72, 0.58)
	sky.sky_material = sky_mat
	e.sky = sky
	e.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
	e.ambient_light_energy = 1.0
	env.environment = e
	add_child(env)

	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-52, -30, 0)
	sun.shadow_enabled = true
	sun.light_energy = 1.1
	add_child(sun)

	cam = Camera3D.new()
	cam.position = Vector3(0, 13, 15)
	cam.fov = 60.0
	add_child(cam)

	# Ground (oversized well past the walkable BOUND so its edge is never in frame)
	GrayboxKit.static_box(self, Vector3(0, -0.25, 0), Vector3(200, 0.5, 200), Color(0.45, 0.62, 0.38))
	# Road with sidewalks and center dashes (visual, no colliders)
	GrayboxKit.visual_box(self, Vector3(0, 0.02, 1.5), Vector3(40, 0.04, 3.2), Color(0.32, 0.33, 0.36))
	var sidewalk_col := Color(0.62, 0.60, 0.56)
	GrayboxKit.visual_box(self, Vector3(0, 0.03, -0.4), Vector3(40, 0.06, 0.6), sidewalk_col)
	GrayboxKit.visual_box(self, Vector3(0, 0.03, 3.4), Vector3(40, 0.06, 0.6), sidewalk_col)
	for dash_x in range(-18, 19, 4):
		GrayboxKit.visual_box(
			self, Vector3(dash_x, 0.045, 1.5), Vector3(1.2, 0.02, 0.16), Color(0.85, 0.85, 0.80))

	# All registry-driven structures (shop, neighbor, houses, trees, lamps)
	# live under one root so a loaded save can rebuild the physical town from
	# its own data (keystone law — DESIGN_CONSTRUCTION_ECONOMY.md §7).
	structures_root = Node3D.new()
	add_child(structures_root)
	_rebuild_structures()

	# --- Storefront dressing (tied to the shop's default spot, kept in code) ---
	GrayboxKit.visual_box(  # door
		self, Vector3(1.2, 1.0, -3.95), Vector3(1.1, 2.0, 0.12), Color(0.30, 0.22, 0.16))
	GrayboxKit.visual_box(  # window
		self, Vector3(-1.2, 1.7, -3.95), Vector3(1.4, 1.0, 0.12), Color(0.55, 0.78, 0.95))
	GrayboxKit.label3d(self, business.shop_sign_text, Vector3(0, 4.4, -4), 96, Color(1, 0.95, 0.8))
	# Counter with a sloped awning and stock crates beside it
	GrayboxKit.visual_box(self, Vector3(0, 0.5, -2.6), Vector3(2.6, 1.0, 0.7), Color(0.42, 0.32, 0.24))
	var awning := GrayboxKit.visual_box(
		self, Vector3(0, 2.35, -3.0), Vector3(3.2, 0.08, 1.6), Color(0.85, 0.45, 0.35))
	awning.rotation.x = -0.22
	GrayboxKit.crate(self, Vector3(-2.1, 0, -3.0), 0.6, Color(0.62, 0.47, 0.30))
	GrayboxKit.crate(self, Vector3(-2.1, 0.6, -3.0), 0.45, Color(0.68, 0.52, 0.34))
	GrayboxKit.crate(self, Vector3(-2.7, 0, -2.7), 0.5, Color(0.58, 0.44, 0.28))
	neighbor_sign = GrayboxKit.label3d(
		self, "FOR RENT", Vector3(8, 3.6, -4), 72, Color(0.85, 0.85, 0.85))

	# Ravi (idle NPC; shown when relevant)
	ravi_npc = GrayboxKit.person(Color(0.35, 0.48, 0.78))
	ravi_npc.position = RAVI_WAIT_POS
	ravi_npc.visible = false
	add_child(ravi_npc)
	ravi_label = GrayboxKit.label3d(ravi_npc, "Ravi", Vector3(0, 2.1, 0), 48, REP_COL)

	npc_root = Node3D.new()
	add_child(npc_root)

	player = PlayerScene.new()
	player.position = Vector3(0, 0.1, 4)
	add_child(player)


## Rebuild every registry-driven structure from GameState.built_structures.
## Called at scene start, after Continue loads a save (the loaded registry is
## the truth, not what _ready() seeded), and after Reset. Re-applies the
## expansion repaint since the neighbor mesh is recreated fresh.
func _rebuild_structures() -> void:
	for c in structures_root.get_children():
		c.queue_free()
	shop_body = null
	neighbor_body = null
	for s in GameState.built_structures:
		var node := StructureCatalog.build(structures_root, s)
		match String(s.get("id", "")):
			"shop":
				shop_body = node
			"neighbor":
				neighbor_body = node
	if GameState.has_expanded_shop:
		_apply_expansion_visual()


# ===========================================================================
#  UI (CanvasLayer, all code — same style family as the old 2D HUD)
# ===========================================================================

func _build_ui() -> void:
	ui = CanvasLayer.new()
	add_child(ui)

	# HUD chips
	var chips := HBoxContainer.new()
	chips.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	chips.offset_left = 10
	chips.offset_right = -10
	chips.offset_top = 10
	chips.add_theme_constant_override("separation", 8)
	ui.add_child(chips)
	day_value = _add_chip(chips, "DAY", "0", DAY_COL)
	cash_value = _add_chip(chips, "CASH", "Rs 0", CASH_COL)
	rep_value = _add_chip(chips, "REP", "0", REP_COL)
	stock_value = _add_chip(chips, "STOCK", "0", STOCK_COL)
	regulars_value = _add_chip(chips, "REGULARS", "0", REGULARS_COL)

	# Mission line
	var mission_panel := PanelContainer.new()
	mission_panel.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	mission_panel.offset_left = 10
	mission_panel.offset_right = -10
	mission_panel.offset_top = 96
	mission_panel.add_theme_stylebox_override("panel", _sb(PANEL, 12, 1, PANEL_HI))
	ui.add_child(mission_panel)
	mission_label = Label.new()
	mission_label.add_theme_font_size_override("font_size", 17)
	mission_label.add_theme_color_override("font_color", ACCENT)
	mission_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	mission_panel.add_child(mission_label)

	# Telegraph banner
	telegraph_panel = PanelContainer.new()
	telegraph_panel.visible = false
	telegraph_panel.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	telegraph_panel.offset_left = 10
	telegraph_panel.offset_right = -10
	telegraph_panel.offset_top = 190
	telegraph_panel.add_theme_stylebox_override("panel", _sb(WARN.darkened(0.55), 10, 2, WARN))
	ui.add_child(telegraph_panel)
	telegraph_label = Label.new()
	telegraph_label.add_theme_color_override("font_color", WARN)
	telegraph_label.add_theme_font_size_override("font_size", 16)
	telegraph_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	telegraph_panel.add_child(telegraph_label)

	# Mini diary (bottom-left)
	log_label = Label.new()
	log_label.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_LEFT)
	log_label.offset_left = 12
	log_label.offset_top = -210
	log_label.offset_right = 560
	log_label.offset_bottom = -110
	log_label.add_theme_font_size_override("font_size", 15)
	log_label.add_theme_color_override("font_color", MUTED)
	log_label.vertical_alignment = VERTICAL_ALIGNMENT_BOTTOM
	ui.add_child(log_label)

	# Contextual action button (bottom-center) — appears near things
	context_button = Button.new()
	context_button.visible = false
	context_button.custom_minimum_size = Vector2(360, 64)
	context_button.set_anchors_and_offsets_preset(Control.PRESET_CENTER_BOTTOM)
	context_button.offset_top = -100
	context_button.offset_bottom = -36
	context_button.offset_left = -180
	context_button.offset_right = 180
	_style_button(context_button, ACCENT.darkened(0.1))
	context_button.pressed.connect(_on_context_pressed)
	ui.add_child(context_button)

	# Day flow button (bottom-right)
	flow_button = Button.new()
	flow_button.custom_minimum_size = Vector2(190, 58)
	flow_button.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_RIGHT)
	flow_button.offset_left = -204
	flow_button.offset_right = -14
	flow_button.offset_top = -78
	flow_button.offset_bottom = -20
	_style_button(flow_button, PANEL_HI)
	flow_button.pressed.connect(_on_flow_pressed)
	ui.add_child(flow_button)

	# Walk hint (fades after a while)
	hint_label = Label.new()
	hint_label.text = "Drag on the left side of the screen to walk"
	hint_label.add_theme_font_size_override("font_size", 16)
	hint_label.add_theme_color_override("font_color", TEXT)
	hint_label.set_anchors_and_offsets_preset(Control.PRESET_CENTER_BOTTOM)
	hint_label.offset_top = -170
	hint_label.offset_bottom = -140
	hint_label.offset_left = -220
	hint_label.offset_right = 220
	hint_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	ui.add_child(hint_label)
	_start_hint_fade()

	_build_manage_panel()
	_build_decision_overlay()


## Fades hint_label out after a delay; replayable so a reset shows it again.
func _start_hint_fade() -> void:
	hint_label.modulate.a = 1.0
	var ht := create_tween()
	ht.tween_interval(8.0)
	ht.tween_property(hint_label, "modulate:a", 0.0, 1.5)


func _add_chip(parent: Control, caption: String, value: String, accent: Color) -> Label:
	var p := PanelContainer.new()
	p.add_theme_stylebox_override("panel", _sb(PANEL, 10, 2, accent.darkened(0.25)))
	p.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 0)
	p.add_child(v)
	var cap := Label.new()
	cap.text = caption
	cap.add_theme_font_size_override("font_size", 11)
	cap.add_theme_color_override("font_color", MUTED)
	cap.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var val := Label.new()
	val.text = value
	val.add_theme_font_size_override("font_size", 21)
	val.add_theme_color_override("font_color", accent)
	val.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(cap)
	v.add_child(val)
	parent.add_child(p)
	return val


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


func _build_manage_panel() -> void:
	manage_panel = PanelContainer.new()
	manage_panel.visible = false
	manage_panel.set_anchors_and_offsets_preset(Control.PRESET_CENTER_BOTTOM)
	manage_panel.offset_left = -330
	manage_panel.offset_right = 330
	manage_panel.offset_top = -420
	manage_panel.offset_bottom = -110
	manage_panel.add_theme_stylebox_override("panel", _sb(PANEL, 16, 2, PANEL_HI))
	ui.add_child(manage_panel)

	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 12)
	manage_panel.add_child(v)

	var title := Label.new()
	title.text = "%s — Counter" % BusinessRegistry.get_active().shop_sign_text
	title.add_theme_font_size_override("font_size", 22)
	title.add_theme_color_override("font_color", TEXT)
	v.add_child(title)

	price_label = Label.new()
	price_label.add_theme_font_size_override("font_size", 17)
	price_label.add_theme_color_override("font_color", TEXT)
	v.add_child(price_label)

	price_slider = HSlider.new()
	price_slider.custom_minimum_size = Vector2(0, 40)
	price_slider.min_value = SimConfig.PRICE_MIN
	price_slider.max_value = SimConfig.PRICE_MAX
	price_slider.step = 1.0
	price_slider.value = SimConfig.DEFAULT_PRICE
	price_slider.value_changed.connect(_on_price_changed)
	price_slider.drag_ended.connect(_on_price_drag_ended)
	v.add_child(price_slider)

	buy_button = Button.new()
	buy_button.custom_minimum_size = Vector2(0, 54)
	_style_button(buy_button, PANEL_HI)
	buy_button.pressed.connect(_on_buy)
	v.add_child(buy_button)

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	v.add_child(row)
	var close := Button.new()
	close.text = "Close"
	close.custom_minimum_size = Vector2(0, 48)
	close.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_style_button(close, ACCENT.darkened(0.1))
	close.pressed.connect(func() -> void: manage_panel.visible = false)
	row.add_child(close)
	var reset := Button.new()
	reset.text = "Reset game"
	reset.custom_minimum_size = Vector2(170, 48)
	_style_button(reset, BAD.darkened(0.35))
	reset.pressed.connect(_on_reset_pressed)
	row.add_child(reset)


## Shared full-screen dim + centered bordered-panel scaffold used by the
## decision modal, boot choice, and chapter-complete screens. The caller
## populates the returned vbox and owns the returned overlay's visibility
## and lifecycle (each of the three has different show/hide/free timing).
func _build_modal_shell(min_width: float, border_color: Color, dim_alpha: float) -> Dictionary:
	var overlay := Control.new()
	overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	ui.add_child(overlay)

	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, dim_alpha)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay.add_child(dim)

	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay.add_child(center)

	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(min_width, 0)
	panel.add_theme_stylebox_override("panel", _sb(PANEL, 18, 2, border_color))
	center.add_child(panel)

	var margin := MarginContainer.new()
	for side in ["left", "top", "right", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 26)
	panel.add_child(margin)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 14)
	margin.add_child(vbox)

	return {"overlay": overlay, "vbox": vbox}


func _build_decision_overlay() -> void:
	var shell := _build_modal_shell(600, PANEL_HI, 0.65)
	decision_overlay = shell.overlay
	decision_overlay.visible = false
	var vbox: VBoxContainer = shell.vbox

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
	decision_yes.pressed.connect(_on_decision_yes_pressed)
	row.add_child(decision_yes)

	decision_no = Button.new()
	decision_no.custom_minimum_size = Vector2(0, 50)
	decision_no.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_style_button(decision_no, PANEL_HI)
	decision_no.pressed.connect(_on_decision_no_pressed)
	row.add_child(decision_no)


# ===========================================================================
#  BOOT — Continue / New Game
# ===========================================================================

func _begin_new_game() -> void:
	_log(BusinessRegistry.get_active().tagline)
	Missions.start_chapter()
	GameState.current_price = price_slider.value
	cost_today = Sim.get_current_unit_cost()
	cost_yesterday = cost_today
	regulars_prev = GameState.regular_count
	_on_price_changed(price_slider.value)
	_refresh_all()


func _show_boot_choice() -> void:
	var shell := _build_modal_shell(520, ACCENT, 0.75)
	var boot: Control = shell.overlay
	var v: VBoxContainer = shell.vbox
	var t := Label.new()
	t.text = "Welcome back to your shop"
	t.add_theme_font_size_override("font_size", 26)
	t.add_theme_color_override("font_color", TEXT)
	t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(t)
	var cont := Button.new()
	cont.text = "Continue"
	cont.custom_minimum_size = Vector2(0, 52)
	_style_button(cont, ACCENT.darkened(0.1))
	v.add_child(cont)
	var newg := Button.new()
	newg.text = "New Game"
	newg.custom_minimum_size = Vector2(0, 52)
	_style_button(newg, PANEL_HI)
	v.add_child(newg)
	cont.pressed.connect(func() -> void:
		boot.queue_free()
		if not SaveManager.load_game():
			# Corrupt or incompatible save file — fall back to a fresh game
			# instead of leaving default state with no mission ever shown.
			_begin_new_game()
			return
		# The loaded save's registry is the truth for what stands in the town
		# (also re-applies the expansion repaint if the save had expanded).
		_rebuild_structures()
		price_slider.value = GameState.current_price
		cost_today = Sim.get_current_unit_cost()
		cost_yesterday = cost_today
		regulars_prev = GameState.regular_count
		_on_price_changed(GameState.current_price)
		_refresh_all()
	)
	newg.pressed.connect(func() -> void:
		boot.queue_free()
		SaveManager.delete_save()
		GameState.reset()
		_begin_new_game()
	)


# ===========================================================================
#  DAY FLOW
# ===========================================================================

func _advance_day() -> void:
	telegraph_panel.visible = false
	cost_yesterday = cost_today
	var rep_before: float = GameState.reputation
	var r: Dictionary = Sim.run_day()
	cost_today = Sim.get_current_unit_cost()
	total_revenue += r.revenue

	_log("Day %d: %d bought soap (Rs %d)%s" % [r.day, r.served, int(r.revenue),
		(", %d walked away" % r.lost) if int(r.lost) > 0 else ""])
	_note_regulars_trend(int(r.regulars))

	var drep: int = int(round(GameState.reputation - rep_before))
	if drep != 0:
		_float(("Reputation +%d" if drep > 0 else "Reputation %d") % drep,
			REP_COL if drep > 0 else BAD, Vector2(360, 150))
	if GameState.inventory <= SimConfig.LOW_STOCK and not chapter_done:
		_float("Low stock!", WARN, Vector2(560, 90))

	_spawn_customers_3d(r)
	_refresh_all()


func _spawn_customers_3d(result: Dictionary) -> void:
	var demand: int = int(result.served) + int(result.lost)
	if demand <= 0:
		return
	var total: int = mini(demand, MAX_CUSTOMER_DOTS)
	var served_dots: int = clampi(int(round(float(result.served) / float(demand) * total)), 0, total)
	for i in range(total):
		_spawn_customer_3d(i < served_dots, i)


func _spawn_customer_3d(served: bool, idx: int) -> void:
	# Cosmetic-only randomness (allowed outside GameState.rng per biztown-rules)
	var npc := GrayboxKit.person(CUSTOMER_COLORS[randi() % CUSTOMER_COLORS.size()])
	var from_left: bool = (idx % 2) == 0
	npc.position = SPAWN_LEFT if from_left else SPAWN_RIGHT
	npc_root.add_child(npc)

	# Bound to npc (not self) so Godot auto-kills this tween if npc is freed early
	# (e.g. Reset game mid-animation) instead of it running on afterward and
	# touching a freed instance.
	var t := npc.create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	t.tween_interval(idx * (DAY_DURATION * 0.06))
	var front := Vector3(DOOR_POS.x + randf_range(-0.6, 0.6), 0, 1.2)
	t.tween_property(npc, "position", front, DAY_DURATION * 0.32)
	if served:
		t.tween_property(npc, "position", DOOR_POS, DAY_DURATION * 0.18)
		t.tween_callback(func() -> void:
			_float("+Rs %d" % int(GameState.current_price), GOOD, _screen_pos(npc.position)))
		t.tween_property(npc, "scale", Vector3(0.05, 0.05, 0.05), 0.25)
	else:
		t.tween_callback(func() -> void:
			GrayboxKit.tint_person(npc, BAD)
			_float("left!", BAD, _screen_pos(npc.position)))
		var exit := SPAWN_LEFT if not from_left else SPAWN_RIGHT
		t.tween_property(npc, "position", exit, DAY_DURATION * 0.4)
	t.tween_callback(npc.queue_free)


func _screen_pos(world: Vector3) -> Vector2:
	if cam == null:
		return Vector2(360, 400)
	return cam.unproject_position(world + Vector3(0, 1.8, 0))


# ===========================================================================
#  CONTEXT INTERACTIONS (walk up to things)
# ===========================================================================

func _update_context_button() -> void:
	if chapter_done or decision_active or manage_panel.visible:
		context_button.visible = false
		return
	var pp: Vector3 = player.global_position
	var m: Dictionary = Missions.get_current_mission()
	var mid: String = m.get("id", "")

	# Ravi appears on the street while The Long Queue is active; moves in when hired.
	ravi_npc.visible = GameState.has_ravi or mid == "long_queue"
	ravi_npc.position = RAVI_HIRED_POS if GameState.has_ravi else RAVI_WAIT_POS
	ravi_label.text = "Ravi" if GameState.has_ravi else "Ravi — looking for work"

	context_action = Ctx.NONE
	if mid == "long_queue" and not GameState.has_ravi \
			and pp.distance_to(RAVI_WAIT_POS) < INTERACT_DIST:
		context_action = Ctx.HIRE
		context_button.text = "Hire Ravi (Rs %d/day)" % int(SimConfig.RAVI_WAGE)
	elif mid == "shop_next_door" and not GameState.has_expanded_shop \
			and pp.distance_to(NEIGHBOR_POS) < INTERACT_DIST:
		context_action = Ctx.EXPAND
		context_button.text = "Take the shop next door (Rs %d)" % int(SimConfig.EXPANSION_COST)
	elif pp.distance_to(COUNTER_POS) < INTERACT_DIST:
		context_action = Ctx.MANAGE
		context_button.text = "Manage shop"
	context_button.visible = context_action != Ctx.NONE


func _on_context_pressed() -> void:
	match context_action:
		Ctx.MANAGE:
			_refresh_manage_panel()
			manage_panel.visible = true
			player.stop_moving()
		Ctx.HIRE:
			if Sim.hire_ravi():
				ravi_hire_day = GameState.day
				_log("Ravi joined the shop. Capacity %d -> %d." % [SimConfig.CAPACITY_SOLO, SimConfig.CAPACITY_WITH_RAVI])
				_float("Ravi joined!", GOOD, Vector2(360, 400))
				_refresh_all()
		Ctx.EXPAND:
			if Sim.expand_shop():
				_log("You took the shop next door. Bigger space, bigger bills.")
				_float("EXPANDED!", GOOD, Vector2(360, 380))
				_apply_expansion_visual()
				_refresh_all()
			else:
				_float("Need Rs %d in cash" % int(SimConfig.EXPANSION_COST), BAD, Vector2(360, 380))


func _apply_expansion_visual() -> void:
	_paint_neighbor(BusinessRegistry.get_active().expanded_sign_text, Color(1, 0.95, 0.8), Color(0.78, 0.55, 0.38))


## Repaint the neighbor shop's sign and wall color (expanded vs FOR RENT).
func _paint_neighbor(sign_text: String, sign_col: Color, wall_col: Color) -> void:
	if neighbor_body == null or neighbor_sign == null:
		return
	neighbor_sign.text = sign_text
	neighbor_sign.modulate = sign_col
	var mesh := neighbor_body.get_node_or_null("Wall") as MeshInstance3D
	if mesh != null and mesh.mesh is BoxMesh:
		var box := mesh.mesh as BoxMesh
		var mat := box.material as StandardMaterial3D
		if mat == null:
			mat = StandardMaterial3D.new()
			box.material = mat
		mat.albedo_color = wall_col


# ===========================================================================
#  MANAGE PANEL (price + stock)
# ===========================================================================

func _refresh_manage_panel() -> void:
	price_slider.value = GameState.current_price
	_on_price_changed(GameState.current_price)


func _on_price_changed(value: float) -> void:
	GameState.current_price = value
	var demand_range: Vector2i = Sim.calculate_demand_range(value, GameState.reputation)
	price_label.text = "Price Rs %d     %d-%d customers likely" % [int(value), demand_range.x, demand_range.y]
	_refresh_buy_button()


func _on_price_drag_ended(value_changed: bool) -> void:
	if value_changed:
		price_changes += 1


func _refresh_buy_button() -> void:
	buy_button.text = "Buy %d stock - Rs%d/unit today (Rs%d yest.)" % [
		SimConfig.BUY_QUANTITY, int(round(cost_today)), int(round(cost_yesterday))]


func _on_buy() -> void:
	var unit_cost: float = Sim.get_current_unit_cost()
	if not Sim.buy_inventory(SimConfig.BUY_QUANTITY):
		_float("Not enough cash", BAD, Vector2(360, 500))
		return
	stock_ordered += SimConfig.BUY_QUANTITY
	_log("Bought %d soap at Rs %d/unit." % [SimConfig.BUY_QUANTITY, int(round(unit_cost))])
	_float("+%d stock" % SimConfig.BUY_QUANTITY, STOCK_COL, Vector2(560, 90))
	_refresh_all()


# ===========================================================================
#  FLOW / EVENTS / DECISIONS (same contracts as the 2D UI)
# ===========================================================================

func _on_flow_pressed() -> void:
	if chapter_done or decision_active:
		return
	running = not running
	day_timer = 0.0
	_refresh_all()


func _on_event_telegraphed(event: Dictionary) -> void:
	telegraph_label.text = "TOMORROW: " + String(event.get("telegraph", ""))
	telegraph_panel.visible = true


func _queue_decision(kind: String, data: Dictionary) -> void:
	decision_queue.append({"kind": kind, "data": data})
	if not decision_active:
		_show_next_decision()


func _show_next_decision() -> void:
	if decision_queue.is_empty():
		decision_active = false
		decision_overlay.visible = false
		_refresh_all()   # re-enables flow_button (disabled while decision_active)
		return
	decision_active = true
	running = false
	player.stop_moving()
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
	decision_overlay.visible = true
	_refresh_all()


func _on_decision_yes_pressed() -> void:
	var data: Dictionary = current_decision.get("data", {})
	match String(current_decision.get("kind", "")):
		"credit":
			if Sim.grant_credit():
				_log("Gave %s credit for %d units." % [String(data.name), int(data.qty)])
			else:
				_log("Couldn't give %s credit - not enough stock." % String(data.name))
		"bulk":
			Sim.accept_bulk_offer()
			_log("Accepted a bulk order for %d units." % int(data.qty))
		"lender":
			Sim.accept_lender()
			_log("Took a Rs %d loan from the Mahajan." % int(data.principal))
	_show_next_decision()


func _on_decision_no_pressed() -> void:
	var data: Dictionary = current_decision.get("data", {})
	match String(current_decision.get("kind", "")):
		"credit":
			Sim.refuse_credit()
			_log("Refused %s's credit request." % String(data.name))
		"bulk":
			Sim.decline_bulk_offer()
			_log("Declined the bulk order.")
		"lender":
			Sim.decline_lender()
			_log("Declined the Mahajan's loan.")
	_show_next_decision()


func _on_month_ended(rent_paid: float, _cash_after: float) -> void:
	_log("Month-end: paid Rs %d rent." % int(rent_paid))
	if GameState.lender_debt > 0.0:
		_log("Loan outstanding: Rs %d." % int(GameState.lender_debt))
	_float("Rent -Rs %d" % int(rent_paid), BAD, Vector2(360, 200))


# ===========================================================================
#  MISSIONS -> UI
# ===========================================================================

func _on_mission_started(m: Dictionary) -> void:
	running = false
	day_timer = 0.0
	mission_label.text = "%s — %s" % [m.title, String(m.get("intro", ""))]
	_log("New chapter beat: " + m.title)
	_refresh_all()


func _on_mission_completed(m: Dictionary) -> void:
	_float("Mission complete!", GOOD, Vector2(360, 250))
	var msg: String = String(m.get("debrief", ""))
	if msg != "":
		_log(msg)


func _on_chapter_completed() -> void:
	chapter_done = true
	running = false
	_build_complete_overlay()


func _build_complete_overlay() -> void:
	var shell := _build_modal_shell(620, ACCENT, 0.7)
	complete_overlay = shell.overlay
	var v: VBoxContainer = shell.vbox

	var title := Label.new()
	title.text = "CHAPTER 1 COMPLETE"
	title.add_theme_font_size_override("font_size", 32)
	title.add_theme_color_override("font_color", ACCENT)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(title)

	var stats := Label.new()
	stats.text = "Days: %d   Served: %d   Turned away: %d\nEarned: Rs %d   Regulars: %d   Cash: Rs %d" % [
		GameState.day, GameState.customers_served, GameState.customers_lost,
		int(total_revenue), GameState.regular_count, int(GameState.cash)]
	stats.add_theme_font_size_override("font_size", 17)
	stats.add_theme_color_override("font_color", TEXT)
	stats.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(stats)

	var ravi_txt: String = ("day %d" % ravi_hire_day) if ravi_hire_day >= 0 else "not hired"
	var decisions := Label.new()
	decisions.text = "Final price: Rs %d   Price changes: %d\nRavi hired: %s   Reputation: %d" % [
		int(GameState.current_price), price_changes, ravi_txt, int(round(GameState.reputation))]
	decisions.add_theme_font_size_override("font_size", 15)
	decisions.add_theme_color_override("font_color", MUTED)
	decisions.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(decisions)

	var story := Label.new()
	story.text = _make_story()
	story.add_theme_font_size_override("font_size", 18)
	story.add_theme_color_override("font_color", ACCENT)
	story.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	v.add_child(story)

	var feedback_title := Label.new()
	feedback_title.text = "YOUR OPINION MATTERS"
	feedback_title.add_theme_font_size_override("font_size", 14)
	feedback_title.add_theme_color_override("font_color", MUTED)
	v.add_child(feedback_title)
	q1_edit = _add_feedback_question(v, "What confused you?")
	q2_edit = _add_feedback_question(v, "What did you enjoy the most?")
	q3_edit = _add_feedback_question(v, "Would you continue building your business?")

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	v.add_child(row)
	submit_button = Button.new()
	submit_button.text = "Submit"
	submit_button.custom_minimum_size = Vector2(0, 50)
	submit_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_style_button(submit_button, ACCENT.darkened(0.1))
	submit_button.pressed.connect(_on_submit_feedback)
	row.add_child(submit_button)
	var again := Button.new()
	again.text = "Play Again"
	again.custom_minimum_size = Vector2(160, 50)
	_style_button(again, PANEL_HI)
	again.pressed.connect(func() -> void:
		complete_overlay.queue_free()
		complete_overlay = null
		_on_reset_pressed())
	row.add_child(again)


func _add_feedback_question(parent: VBoxContainer, question: String) -> LineEdit:
	var q := Label.new()
	q.text = question
	q.add_theme_font_size_override("font_size", 15)
	q.add_theme_color_override("font_color", TEXT)
	parent.add_child(q)
	var e := LineEdit.new()
	e.placeholder_text = "type here..."
	parent.add_child(e)
	return e


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
	if GameState.regular_count >= 15:
		parts.append("A loyal circle of regulars grew around your counter.")
	if GameState.has_expanded_shop:
		parts.append("And you took the leap to expand next door.")
	return " ".join(PackedStringArray(parts))


# ===========================================================================
#  RESET / DISPLAY HELPERS
# ===========================================================================

func _on_reset_pressed() -> void:
	chapter_done = false
	running = false
	day_timer = 0.0
	_start_hint_fade()
	total_revenue = 0.0
	stock_ordered = 0
	ravi_hire_day = -1
	price_changes = 0
	regulars_prev = 0
	decision_queue.clear()
	decision_active = false
	decision_overlay.visible = false
	manage_panel.visible = false
	telegraph_panel.visible = false
	log_lines.clear()
	log_label.text = ""
	for c in npc_root.get_children():
		c.queue_free()
	_paint_neighbor("FOR RENT", Color(0.85, 0.85, 0.85), Color(0.52, 0.53, 0.58))
	SaveManager.delete_save()
	GameState.reset()
	Missions.start_chapter()
	_rebuild_structures()   # fresh registry -> fresh (default) town
	cost_today = Sim.get_current_unit_cost()
	cost_yesterday = cost_today
	price_slider.value = SimConfig.DEFAULT_PRICE
	_refresh_all()


func _refresh_all() -> void:
	day_value.text = str(GameState.day)
	cash_value.text = "Rs %d" % int(GameState.cash)
	rep_value.text = str(int(round(GameState.reputation)))
	stock_value.text = str(GameState.inventory)
	stock_value.add_theme_color_override("font_color",
		WARN if GameState.inventory <= SimConfig.LOW_STOCK else STOCK_COL)
	regulars_value.text = str(GameState.regular_count)
	flow_button.text = "Pause days" if running else "Start days"
	flow_button.disabled = chapter_done or decision_active
	_refresh_buy_button()


func _log(line: String) -> void:
	log_lines.append(line)
	while log_lines.size() > LOG_MAX:
		log_lines.pop_front()
	log_label.text = "\n".join(PackedStringArray(log_lines))


## Surface the existing regulars feedback loop as a felt pattern, not just a
## number ticking on the HUD — first regular, every +5 milestone, or a drop.
func _note_regulars_trend(new_count: int) -> void:
	if new_count > regulars_prev:
		if regulars_prev == 0 and new_count > 0:
			_log("Word is spreading - your first regular customer.")
		elif new_count / 5 > regulars_prev / 5:
			_log("Word is spreading - %d regulars now count on your shop." % new_count)
	elif new_count < regulars_prev:
		_log("A regular gave up waiting today - that trust doesn't come back easily.")
	regulars_prev = new_count


func _float(text: String, color: Color, pos: Vector2) -> void:
	var l := Label.new()
	l.text = text
	l.add_theme_color_override("font_color", color)
	l.add_theme_font_size_override("font_size", 22)
	l.position = pos
	ui.add_child(l)
	var t := create_tween()
	t.set_parallel(true)
	t.tween_property(l, "position:y", pos.y - 48, 0.9).set_ease(Tween.EASE_OUT)
	t.tween_property(l, "modulate:a", 0.0, 0.9)
	t.set_parallel(false)
	t.tween_callback(l.queue_free)

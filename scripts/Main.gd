extends Node2D
## BizTown: Build Your Empire — Stage 1 prototype.
## Core loop: earn money -> upgrade your business through 4 stages.
## Small Shop -> Big Shop -> Warehouse -> Factory.
##
## Everything (world rendering + UI) is built in code so the project stays
## to two text files. World coordinates == screen coordinates (no camera),
## matching the 720x1280 base viewport defined in project.godot.

const BASE := Vector2(720, 1280)
const BUILDING_CENTER := Vector2(360, 740)
const CUSTOMER_INTERVAL := 1.4   # seconds between auto-customers
const CUSTOMER_SPEED := 220.0    # pixels / second

# --- Each business stage. cost = -1 means already at the top tier. ---
const STAGES := [
	{
		"name": "Small Shop", "tagline": "Where every empire begins",
		"income": 4, "cost": 150,
		"a": 70.0, "b": 35.0, "h": 70.0,
		"wall": Color(0.86, 0.47, 0.30), "roof": Color(0.80, 0.24, 0.22),
	},
	{
		"name": "Big Shop", "tagline": "More shelves, more customers",
		"income": 22, "cost": 1200,
		"a": 110.0, "b": 55.0, "h": 120.0,
		"wall": Color(0.31, 0.56, 0.86), "roof": Color(0.17, 0.33, 0.63),
	},
	{
		"name": "Warehouse", "tagline": "Buy wholesale, sell big",
		"income": 110, "cost": 7500,
		"a": 150.0, "b": 75.0, "h": 150.0,
		"wall": Color(0.63, 0.65, 0.69), "roof": Color(0.40, 0.42, 0.47),
	},
	{
		"name": "Factory", "tagline": "Your own brand. Empire built!",
		"income": 520, "cost": -1,
		"a": 180.0, "b": 90.0, "h": 195.0,
		"wall": Color(0.47, 0.52, 0.57), "roof": Color(0.30, 0.34, 0.41),
	},
]

# --- Runtime state ---
var cash: float = 25.0
var invested: float = 0.0   # money sunk into upgrades (feeds net worth)
var stage: int = 0
var customers: Array = []    # each: {pos:Vector2, target:Vector2}
var _spawn_timer: float = 0.0

# --- UI nodes (built in _ready) ---
var cash_label: Label
var networth_label: Label
var stage_label: Label
var tagline_label: Label
var progress: ProgressBar
var progress_label: Label
var sell_button: Button
var upgrade_button: Button


func _ready() -> void:
	_build_ui()
	_refresh_ui()
	queue_redraw()


# --------------------------------------------------------------------------
#  Game logic
# --------------------------------------------------------------------------
func _process(delta: float) -> void:
	# Spawn auto-customers that walk in and buy.
	_spawn_timer -= delta
	if _spawn_timer <= 0.0:
		_spawn_timer = CUSTOMER_INTERVAL
		_spawn_customer()

	# Move customers toward the shop door; sell on arrival.
	var door := BUILDING_CENTER + Vector2(0, STAGES[stage].b + 6)
	for c in customers.duplicate():
		c.pos = c.pos.move_toward(door, CUSTOMER_SPEED * delta)
		if c.pos.distance_to(door) < 8.0:
			customers.erase(c)
			earn(STAGES[stage].income)
	queue_redraw()


func _unhandled_input(event: InputEvent) -> void:
	# A tap anywhere in the play area (above the bottom controls) is a manual sale.
	var pressed := false
	var pos := Vector2.ZERO
	if event is InputEventScreenTouch and event.pressed:
		pressed = true
		pos = event.position
	elif event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		pressed = true
		pos = event.position
	if pressed and pos.y < BASE.y - 240.0 and pos.y > 200.0:
		earn(STAGES[stage].income)


func earn(amount: float) -> void:
	cash += amount
	_spawn_floating_text("+" + _money(amount))
	_refresh_ui()


func try_upgrade() -> void:
	if stage >= STAGES.size() - 1:
		return
	var cost: float = STAGES[stage].cost
	if cash < cost:
		return
	cash -= cost
	invested += cost
	stage += 1
	_flash_building()
	_refresh_ui()
	queue_redraw()


# --------------------------------------------------------------------------
#  Customers
# --------------------------------------------------------------------------
func _spawn_customer() -> void:
	# Walk in from either the left or right edge of the platform.
	var from_left := randf() < 0.5
	var start := Vector2(80.0 if from_left else BASE.x - 80.0, BUILDING_CENTER.y + 150.0)
	customers.append({"pos": start, "target": BUILDING_CENTER})


# --------------------------------------------------------------------------
#  Rendering (isometric, cartoon placeholder art)
# --------------------------------------------------------------------------
func _draw() -> void:
	_draw_sky()
	_draw_platform()
	_draw_building(BUILDING_CENTER, STAGES[stage])
	_draw_customers()


func _draw_sky() -> void:
	# Soft vertical gradient backdrop behind the play area.
	draw_rect(Rect2(0, 0, BASE.x, BASE.y), Color(0.55, 0.78, 0.95))
	draw_rect(Rect2(0, 360, BASE.x, BASE.y - 360), Color(0.78, 0.90, 0.78))


func _draw_platform() -> void:
	var c := BUILDING_CENTER + Vector2(0, 30)
	var a := 300.0
	var b := 150.0
	var grass := PackedVector2Array([
		c + Vector2(0, -b), c + Vector2(a, 0), c + Vector2(0, b), c + Vector2(-a, 0)
	])
	# A little 3D lip so the ground reads as a raised plate.
	var lip := PackedVector2Array([
		c + Vector2(-a, 0), c + Vector2(0, b), c + Vector2(a, 0),
		c + Vector2(a, 22), c + Vector2(0, b + 22), c + Vector2(-a, 22)
	])
	draw_colored_polygon(lip, Color(0.36, 0.55, 0.30))
	draw_colored_polygon(grass, Color(0.50, 0.74, 0.40))
	_outline(grass, Color(0.30, 0.45, 0.25, 0.6), 2.0)


func _draw_building(center: Vector2, data: Dictionary) -> void:
	var a: float = data.a
	var b: float = data.b
	var h: float = data.h
	var up := Vector2(0, -h)

	# Ground-level diamond corners.
	var g_top := center + Vector2(0, -b)
	var g_right := center + Vector2(a, 0)
	var g_bottom := center + Vector2(0, b)
	var g_left := center + Vector2(-a, 0)
	# Top (roof-level) corners.
	var t_top := g_top + up
	var t_right := g_right + up
	var t_bottom := g_bottom + up
	var t_left := g_left + up

	# Drop shadow on the platform.
	var shadow := PackedVector2Array([
		g_top + Vector2(20, 14), g_right + Vector2(20, 14),
		g_bottom + Vector2(20, 14), g_left + Vector2(20, 14)
	])
	draw_colored_polygon(shadow, Color(0, 0, 0, 0.18))

	var wall: Color = data.wall
	var roof: Color = data.roof

	# Two visible wall faces meeting at the front corner (g_bottom).
	var left_face := PackedVector2Array([g_left, g_bottom, t_bottom, t_left])
	var right_face := PackedVector2Array([g_bottom, g_right, t_right, t_bottom])
	var top_face := PackedVector2Array([t_top, t_right, t_bottom, t_left])

	draw_colored_polygon(left_face, wall.darkened(0.28))
	draw_colored_polygon(right_face, wall)
	draw_colored_polygon(top_face, roof)

	_outline(left_face, Color(0, 0, 0, 0.35), 2.0)
	_outline(right_face, Color(0, 0, 0, 0.35), 2.0)
	_outline(top_face, Color(0, 0, 0, 0.35), 2.0)

	# Door on the right-hand (sunny) face.
	var dw := a * 0.34
	var dh := h * 0.5
	var door_base := g_bottom.lerp(g_right, 0.5)
	var door := PackedVector2Array([
		door_base + Vector2(-dw * 0.5, 6),
		door_base + Vector2(dw * 0.5, -6),
		door_base + Vector2(dw * 0.5, -6) + Vector2(0, -dh),
		door_base + Vector2(-dw * 0.5, 6) + Vector2(0, -dh),
	])
	draw_colored_polygon(door, Color(0.18, 0.12, 0.10))

	# A couple of windows on the same face for character.
	if h >= 110.0:
		var win_base := g_bottom.lerp(g_right, 0.82)
		var ww := a * 0.16
		var wh := h * 0.22
		var win := PackedVector2Array([
			win_base + Vector2(-ww * 0.5, 3),
			win_base + Vector2(ww * 0.5, -3),
			win_base + Vector2(ww * 0.5, -3) + Vector2(0, -wh) + Vector2(0, -dh * 0.4),
			win_base + Vector2(-ww * 0.5, 3) + Vector2(0, -wh) + Vector2(0, -dh * 0.4),
		])
		draw_colored_polygon(win, Color(0.75, 0.90, 1.0, 0.9))

	# Factory chimney with a puff of smoke.
	if stage == STAGES.size() - 1:
		var chim_base := t_left.lerp(t_top, 0.45)
		var cw := 22.0
		var ch := 70.0
		var chimney := PackedVector2Array([
			chim_base + Vector2(-cw, 0), chim_base + Vector2(cw, 0),
			chim_base + Vector2(cw, -ch), chim_base + Vector2(-cw, -ch),
		])
		draw_colored_polygon(chimney, Color(0.36, 0.30, 0.28))
		draw_circle(chim_base + Vector2(0, -ch - 14), 16, Color(0.92, 0.92, 0.92, 0.8))
		draw_circle(chim_base + Vector2(14, -ch - 36), 22, Color(0.92, 0.92, 0.92, 0.6))


func _draw_customers() -> void:
	for c in customers:
		var p: Vector2 = c.pos
		draw_circle(p + Vector2(0, 4), 9, Color(0, 0, 0, 0.15))      # shadow
		draw_circle(p, 11, Color(0.95, 0.78, 0.55))                 # head
		var body := PackedVector2Array([
			p + Vector2(-9, 6), p + Vector2(9, 6),
			p + Vector2(7, 30), p + Vector2(-7, 30)
		])
		draw_colored_polygon(body, Color(0.85, 0.30, 0.35))


func _outline(points: PackedVector2Array, color: Color, width: float) -> void:
	var closed := points.duplicate()
	closed.append(points[0])
	draw_polyline(closed, color, width)


# --------------------------------------------------------------------------
#  UI
# --------------------------------------------------------------------------
func _build_ui() -> void:
	var layer := CanvasLayer.new()
	add_child(layer)

	# ---- Top status panel ----
	var top := ColorRect.new()
	top.color = Color(0.10, 0.13, 0.20, 0.85)
	top.position = Vector2(16, 24)
	top.size = Vector2(BASE.x - 32, 150)
	layer.add_child(top)

	cash_label = _make_label(layer, Vector2(36, 36), 52, Color(1, 0.86, 0.30))
	stage_label = _make_label(layer, Vector2(38, 100), 30, Color(0.85, 0.95, 1.0))
	networth_label = _make_label(layer, Vector2(38, 138), 22, Color(0.70, 0.78, 0.88))
	tagline_label = _make_label(layer, Vector2(BASE.x - 360, 138), 22, Color(0.70, 0.78, 0.88))
	tagline_label.size.x = 330
	tagline_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT

	# ---- Upgrade progress bar ----
	progress = ProgressBar.new()
	progress.position = Vector2(36, 200)
	progress.size = Vector2(BASE.x - 72, 26)
	progress.min_value = 0
	progress.max_value = 100
	progress.show_percentage = false
	layer.add_child(progress)

	progress_label = _make_label(layer, Vector2(36, 196), 20, Color(1, 1, 1))
	progress_label.size = Vector2(BASE.x - 72, 26)
	progress_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	progress_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER

	# ---- Bottom action buttons ----
	sell_button = Button.new()
	sell_button.text = "SELL"
	sell_button.position = Vector2(36, BASE.y - 210)
	sell_button.size = Vector2((BASE.x - 90) * 0.5, 150)
	sell_button.add_theme_font_size_override("font_size", 40)
	sell_button.pressed.connect(func(): earn(STAGES[stage].income))
	layer.add_child(sell_button)

	upgrade_button = Button.new()
	upgrade_button.position = Vector2(54 + (BASE.x - 90) * 0.5, BASE.y - 210)
	upgrade_button.size = Vector2((BASE.x - 90) * 0.5, 150)
	upgrade_button.add_theme_font_size_override("font_size", 32)
	upgrade_button.pressed.connect(try_upgrade)
	layer.add_child(upgrade_button)

	var hint := _make_label(layer, Vector2(36, BASE.y - 248), 22, Color(0.2, 0.2, 0.25))
	hint.text = "Tap the shop to sell. Earn enough to UPGRADE."
	hint.size = Vector2(BASE.x - 72, 24)
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER


func _make_label(parent: Node, pos: Vector2, font_size: int, color: Color) -> Label:
	var l := Label.new()
	l.position = pos
	l.add_theme_font_size_override("font_size", font_size)
	l.add_theme_color_override("font_color", color)
	parent.add_child(l)
	return l


func _refresh_ui() -> void:
	cash_label.text = _money(cash)
	stage_label.text = STAGES[stage].name
	networth_label.text = "Net worth: " + _money(cash + invested)
	tagline_label.text = STAGES[stage].tagline
	sell_button.text = "SELL\n+" + _money(STAGES[stage].income)

	if stage >= STAGES.size() - 1:
		progress.value = 100
		progress_label.text = "EMPIRE COMPLETE"
		upgrade_button.text = "MAX\nLEVEL"
		upgrade_button.disabled = true
	else:
		var cost: float = STAGES[stage].cost
		var next_name: String = STAGES[stage + 1].name
		progress.value = clampf(cash / cost * 100.0, 0.0, 100.0)
		progress_label.text = "%s  /  %s  to  %s" % [_money(cash), _money(cost), next_name]
		upgrade_button.text = "UPGRADE\n%s" % _money(cost)
		upgrade_button.disabled = cash < cost


## Format a number as Indian rupees with comma grouping, e.g. 1234567 -> "₹12,34,567".
func _money(value: float) -> String:
	var n := int(round(value))
	var neg := n < 0
	n = abs(n)
	var s := str(n)
	if s.length() > 3:
		var head := s.substr(0, s.length() - 3)
		var tail := s.substr(s.length() - 3)
		var grouped := ""
		while head.length() > 2:
			grouped = "," + head.substr(head.length() - 2) + grouped
			head = head.substr(0, head.length() - 2)
		s = head + grouped + "," + tail
	return ("-" if neg else "") + "₹" + s


# --------------------------------------------------------------------------
#  Juice: floating "+₹" text and an upgrade flash
# --------------------------------------------------------------------------
func _spawn_floating_text(text: String) -> void:
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", 34)
	l.add_theme_color_override("font_color", Color(1, 0.95, 0.4))
	l.position = BUILDING_CENTER + Vector2(randf_range(-40, 40), -STAGES[stage].h - 40)
	add_child(l)
	var t := create_tween()
	t.set_parallel(true)
	t.tween_property(l, "position", l.position + Vector2(0, -80), 0.9)
	t.tween_property(l, "modulate:a", 0.0, 0.9)
	t.set_parallel(false)
	t.tween_callback(l.queue_free)


func _flash_building() -> void:
	var flash := ColorRect.new()
	flash.color = Color(1, 1, 1, 0.6)
	flash.size = BASE
	flash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var layer := CanvasLayer.new()
	layer.add_child(flash)
	add_child(layer)
	var t := create_tween()
	t.tween_property(flash, "modulate:a", 0.0, 0.5)
	t.tween_callback(layer.queue_free)

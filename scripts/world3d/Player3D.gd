extends CharacterBody3D
## BizTown 3D — the founder. Touch-driven: drag anywhere on the left ~60% of
## the screen to walk (floating joystick, no visual). Mouse drag works on
## desktop editors. Builds its own graybox visual, no scene file needed.

const SPEED: float = 5.0
const TURN_SPEED: float = 10.0
const GRAVITY: float = 20.0
const DRAG_RADIUS: float = 80.0
const BOUND: float = 20.0

var visual: Node3D

var _drag_index: int = -1
var _drag_origin: Vector2 = Vector2.ZERO
var _mouse_down: bool = false
var _move_input: Vector2 = Vector2.ZERO   # x = screen right, y = screen down


func _ready() -> void:
	var col := CollisionShape3D.new()
	var cap := CapsuleShape3D.new()
	cap.radius = 0.4
	cap.height = 1.6
	col.shape = cap
	col.position.y = 0.8
	add_child(col)

	visual = Node3D.new()
	add_child(visual)

	var body := MeshInstance3D.new()
	var body_mesh := CapsuleMesh.new()
	body_mesh.radius = 0.38
	body_mesh.height = 1.1
	body.mesh = body_mesh
	body.position.y = 0.65
	var body_mat := StandardMaterial3D.new()
	body_mat.albedo_color = Color(0.30, 0.55, 0.85)
	body_mesh.material = body_mat
	visual.add_child(body)

	var head := MeshInstance3D.new()
	var head_mesh := SphereMesh.new()
	head_mesh.radius = 0.24
	head_mesh.height = 0.48
	head.mesh = head_mesh
	head.position.y = 1.42
	var head_mat := StandardMaterial3D.new()
	head_mat.albedo_color = Color(0.88, 0.74, 0.58)
	head_mesh.material = head_mat
	visual.add_child(head)

	var nose := MeshInstance3D.new()
	var nose_mesh := BoxMesh.new()
	nose_mesh.size = Vector3(0.08, 0.08, 0.14)
	nose.mesh = nose_mesh
	nose.position = Vector3(0, 1.42, 0.24)
	var nose_mat := StandardMaterial3D.new()
	nose_mat.albedo_color = Color(0.80, 0.62, 0.46)
	nose_mesh.material = nose_mat
	visual.add_child(nose)


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		if event.pressed and _drag_index == -1 \
				and event.position.x < get_viewport().get_visible_rect().size.x * 0.6:
			_drag_index = event.index
			_drag_origin = event.position
			_move_input = Vector2.ZERO
		elif not event.pressed and event.index == _drag_index:
			_drag_index = -1
			_move_input = Vector2.ZERO
	elif event is InputEventScreenDrag:
		if event.index == _drag_index:
			_move_input = (event.position - _drag_origin).limit_length(DRAG_RADIUS) / DRAG_RADIUS
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT \
			and not DisplayServer.is_touchscreen_available():
		_mouse_down = event.pressed
		if event.pressed:
			_drag_origin = event.position
		else:
			_move_input = Vector2.ZERO
	elif event is InputEventMouseMotion and _mouse_down \
			and not DisplayServer.is_touchscreen_available():
		_move_input = (event.position - _drag_origin).limit_length(DRAG_RADIUS) / DRAG_RADIUS


func _physics_process(delta: float) -> void:
	# Screen up = away from the fixed follow-camera = -Z in world space.
	var dir := Vector3(_move_input.x, 0.0, _move_input.y)
	velocity.x = dir.x * SPEED
	velocity.z = dir.z * SPEED
	if is_on_floor():
		velocity.y = 0.0
	else:
		velocity.y -= GRAVITY * delta
	move_and_slide()
	global_position.x = clampf(global_position.x, -BOUND, BOUND)
	global_position.z = clampf(global_position.z, -BOUND, BOUND)
	if dir.length() > 0.1 and visual != null:
		visual.rotation.y = lerp_angle(visual.rotation.y, atan2(dir.x, dir.z), TURN_SPEED * delta)


func stop_moving() -> void:
	_drag_index = -1
	_mouse_down = false
	_move_input = Vector2.ZERO

class_name GrayboxKit
## BizTown 3D — procedural low-poly builders for the walkable town (Phase 3D-2).
## Name kept from the graybox phase for call-site stability; this is now the
## stylized low-poly kit: gabled roofs, doors/windows, people with arms,
## two tree types, glowing street lamps, crates. Still pure builders: no game
## state, no autoload references, no signals. Godot built-in meshes only
## (Box/Prism/Capsule/Sphere/Cylinder) — no imported binary assets, so the
## whole town stays text-diffable and works identically on Android GL
## Compatibility. External CC0 packs (Kenney-style) can still replace these
## later; this file remains the single swap point (HUMAN_DECISIONS.md).

const SKIN := Color(0.88, 0.74, 0.58)


static func _mat(color: Color, emissive: bool = false) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = color
	if emissive:
		m.emission_enabled = true
		m.emission = color
		m.emission_energy_multiplier = 1.4
	return m


## A solid box with collision, parented under `parent`.
static func static_box(parent: Node3D, pos: Vector3, size: Vector3, color: Color) -> Node3D:
	var body := StaticBody3D.new()
	body.position = pos
	var col := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = size
	col.shape = shape
	body.add_child(col)
	var mesh := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = size
	box.material = _mat(color)
	mesh.mesh = box
	body.add_child(mesh)
	parent.add_child(body)
	return body


## A visual-only box (no collision), parented under `parent`.
static func visual_box(parent: Node3D, pos: Vector3, size: Vector3, color: Color) -> MeshInstance3D:
	var mesh := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = size
	box.material = _mat(color)
	mesh.mesh = box
	mesh.position = pos
	parent.add_child(mesh)
	return mesh


## A billboarded 3D text label, parented under `parent`.
static func label3d(parent: Node3D, text: String, pos: Vector3, size: int, color: Color) -> Label3D:
	var l := Label3D.new()
	l.text = text
	l.font_size = size
	l.modulate = color
	l.position = pos
	l.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	l.outline_size = 8
	parent.add_child(l)
	return l


## A low-poly building: colliding walls, gabled prism roof, door and window
## on the road-facing side. `face` is the z-sign of the front (+1 faces +Z).
## The wall mesh is named "Wall" — Town3D repaints it on expansion; keep the
## name stable.
static func building(
	parent: Node3D, pos: Vector3, size: Vector3,
	wall_color: Color, roof_color: Color, face: float = 1.0, with_front: bool = true
) -> Node3D:
	var body := StaticBody3D.new()
	body.position = pos
	var col := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = size
	col.shape = shape
	body.add_child(col)

	var wall := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = size
	box.material = _mat(wall_color)
	wall.mesh = box
	wall.name = "Wall"
	body.add_child(wall)

	var roof := MeshInstance3D.new()
	var prism := PrismMesh.new()
	prism.size = Vector3(size.x * 1.15, size.y * 0.45, size.z * 1.15)
	prism.left_to_right = 0.5
	prism.material = _mat(roof_color)
	roof.mesh = prism
	roof.name = "Roof"
	roof.position = Vector3(0, size.y * 0.5 + prism.size.y * 0.5, 0)
	body.add_child(roof)

	if with_front:
		var zf: float = face * (size.z * 0.5 + 0.06)
		var door := MeshInstance3D.new()
		var dbox := BoxMesh.new()
		dbox.size = Vector3(size.x * 0.22, size.y * 0.55, 0.12)
		dbox.material = _mat(Color(0.30, 0.22, 0.16))
		door.mesh = dbox
		door.position = Vector3(size.x * 0.22, -size.y * 0.5 + dbox.size.y * 0.5, zf)
		body.add_child(door)
		var window := MeshInstance3D.new()
		var wbox := BoxMesh.new()
		wbox.size = Vector3(size.x * 0.26, size.y * 0.28, 0.12)
		wbox.material = _mat(Color(0.62, 0.82, 0.95))
		window.mesh = wbox
		window.position = Vector3(-size.x * 0.22, size.y * 0.08, zf)
		body.add_child(window)

	parent.add_child(body)
	return body


## A flat-roofed warehouse: colliding walls, roof slab with a lip, and a wide
## loading door on the road-facing side. Wall mesh named "Wall".
static func warehouse(
	parent: Node3D, pos: Vector3, size: Vector3,
	wall_color: Color, roof_color: Color, face: float = 1.0
) -> Node3D:
	var body := _walled_box(pos, size, wall_color)
	var roof := MeshInstance3D.new()
	var slab := BoxMesh.new()
	slab.size = Vector3(size.x * 1.08, 0.25, size.z * 1.08)
	slab.material = _mat(roof_color)
	roof.mesh = slab
	roof.name = "Roof"
	roof.position = Vector3(0, size.y * 0.5 + 0.125, 0)
	body.add_child(roof)
	var door := MeshInstance3D.new()
	var dbox := BoxMesh.new()
	dbox.size = Vector3(size.x * 0.45, size.y * 0.7, 0.12)
	dbox.material = _mat(Color(0.36, 0.38, 0.42))
	door.mesh = dbox
	door.position = Vector3(0, -size.y * 0.5 + dbox.size.y * 0.5, face * (size.z * 0.5 + 0.06))
	body.add_child(door)
	parent.add_child(body)
	return body


## A taller flat-roofed office block with a grid of windows on the front.
## Wall mesh named "Wall".
static func office(
	parent: Node3D, pos: Vector3, size: Vector3,
	wall_color: Color, roof_color: Color, face: float = 1.0
) -> Node3D:
	var body := _walled_box(pos, size, wall_color)
	var roof := MeshInstance3D.new()
	var slab := BoxMesh.new()
	slab.size = Vector3(size.x * 1.05, 0.22, size.z * 1.05)
	slab.material = _mat(roof_color)
	roof.mesh = slab
	roof.name = "Roof"
	roof.position = Vector3(0, size.y * 0.5 + 0.11, 0)
	body.add_child(roof)
	var zf: float = face * (size.z * 0.5 + 0.06)
	var rows: int = maxi(2, int(size.y / 1.5))
	var win_mat := _mat(Color(0.62, 0.82, 0.95))
	for row in range(rows):
		for col_x in [-size.x * 0.22, size.x * 0.22]:
			var w := MeshInstance3D.new()
			var wbox := BoxMesh.new()
			wbox.size = Vector3(size.x * 0.26, 0.6, 0.12)
			wbox.material = win_mat
			w.mesh = wbox
			w.position = Vector3(col_x, -size.y * 0.5 + 1.1 + row * 1.4, zf)
			body.add_child(w)
	parent.add_child(body)
	return body


## Shared: a colliding box body with its wall mesh named "Wall" (not parented).
static func _walled_box(pos: Vector3, size: Vector3, wall_color: Color) -> StaticBody3D:
	var body := StaticBody3D.new()
	body.position = pos
	var col := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = size
	col.shape = shape
	body.add_child(col)
	var wall := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = size
	box.material = _mat(wall_color)
	wall.mesh = box
	wall.name = "Wall"
	body.add_child(wall)
	return body


## A round leafy tree (trunk + two-sphere crown).
static func tree(parent: Node3D, pos: Vector3) -> void:
	var trunk := MeshInstance3D.new()
	var cyl := CylinderMesh.new()
	cyl.top_radius = 0.14
	cyl.bottom_radius = 0.2
	cyl.height = 1.2
	cyl.material = _mat(Color(0.45, 0.32, 0.22))
	trunk.mesh = cyl
	trunk.position = pos + Vector3(0, 0.6, 0)
	parent.add_child(trunk)
	for crown_data in [[Vector3(0, 1.9, 0), 0.9], [Vector3(0.35, 2.35, 0.2), 0.55]]:
		var crown := MeshInstance3D.new()
		var s := SphereMesh.new()
		s.radius = crown_data[1]
		s.height = crown_data[1] * 2.0
		s.material = _mat(Color(0.30, 0.55, 0.30))
		crown.mesh = s
		crown.position = pos + crown_data[0]
		parent.add_child(crown)


## A pine tree (trunk + stacked cones).
static func pine_tree(parent: Node3D, pos: Vector3) -> void:
	var trunk := MeshInstance3D.new()
	var cyl := CylinderMesh.new()
	cyl.top_radius = 0.12
	cyl.bottom_radius = 0.16
	cyl.height = 0.9
	cyl.material = _mat(Color(0.40, 0.28, 0.20))
	trunk.mesh = cyl
	trunk.position = pos + Vector3(0, 0.45, 0)
	parent.add_child(trunk)
	var tiers: Array = [[1.2, 1.0, 1.0], [2.0, 0.75, 0.9], [2.7, 0.5, 0.8]]
	for tier in tiers:
		var cone := MeshInstance3D.new()
		var c := CylinderMesh.new()
		c.top_radius = 0.0
		c.bottom_radius = tier[1]
		c.height = tier[2]
		c.material = _mat(Color(0.22, 0.45, 0.28))
		cone.mesh = c
		cone.position = pos + Vector3(0, tier[0], 0)
		parent.add_child(cone)


## A street lamp with a softly glowing head.
static func lamp_post(parent: Node3D, pos: Vector3) -> void:
	var pole := MeshInstance3D.new()
	var cyl := CylinderMesh.new()
	cyl.top_radius = 0.06
	cyl.bottom_radius = 0.08
	cyl.height = 2.6
	cyl.material = _mat(Color(0.25, 0.27, 0.30))
	pole.mesh = cyl
	pole.position = pos + Vector3(0, 1.3, 0)
	parent.add_child(pole)
	var lamp := MeshInstance3D.new()
	var s := SphereMesh.new()
	s.radius = 0.17
	s.height = 0.34
	s.material = _mat(Color(1.0, 0.92, 0.70), true)
	lamp.mesh = s
	lamp.position = pos + Vector3(0, 2.7, 0)
	parent.add_child(lamp)


## A small stock crate (visual only).
static func crate(parent: Node3D, pos: Vector3, side: float, color: Color) -> void:
	visual_box(parent, pos + Vector3(0, side * 0.5, 0), Vector3(side, side, side), color)


## A low-poly person: capsule body, sphere head, two arms. Children named
## "Body"/"Head"/"ArmL"/"ArmR" for tint_person(). NOT parented — the caller
## decides where it goes (a fixed NPC slot vs. the customer-spawn root).
static func person(body_color: Color) -> Node3D:
	var root := Node3D.new()
	var body := MeshInstance3D.new()
	var cap := CapsuleMesh.new()
	cap.radius = 0.30
	cap.height = 1.0
	cap.material = _mat(body_color)
	body.mesh = cap
	body.position.y = 0.6
	body.name = "Body"
	root.add_child(body)
	for arm_data in [["ArmL", -0.36, 0.22], ["ArmR", 0.36, -0.22]]:
		var arm := MeshInstance3D.new()
		var acap := CapsuleMesh.new()
		acap.radius = 0.09
		acap.height = 0.55
		acap.material = _mat(body_color.darkened(0.12))
		arm.mesh = acap
		arm.name = arm_data[0]
		arm.position = Vector3(arm_data[1], 0.72, 0)
		arm.rotation.z = arm_data[2]
		root.add_child(arm)
	var head := MeshInstance3D.new()
	var sph := SphereMesh.new()
	sph.radius = 0.2
	sph.height = 0.4
	sph.material = _mat(SKIN)
	head.mesh = sph
	head.position.y = 1.3
	head.name = "Head"
	root.add_child(head)
	return root


## Recolor a person's body and arms (e.g. to flag a turned-away customer).
static func tint_person(p: Node3D, color: Color) -> void:
	for part in [["Body", color], ["ArmL", color.darkened(0.12)], ["ArmR", color.darkened(0.12)]]:
		var mesh := p.get_node_or_null(part[0]) as MeshInstance3D
		if mesh != null and mesh.mesh is CapsuleMesh:
			(mesh.mesh as CapsuleMesh).material = _mat(part[1])

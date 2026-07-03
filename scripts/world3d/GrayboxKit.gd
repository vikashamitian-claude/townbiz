class_name GrayboxKit
## BizTown 3D — shared graybox mesh builders for the walkable town.
## Pure builders: no game state, no autoload references, no signals. This is
## the single swap point for Phase 3D-2 (replacing boxes/capsules with real
## low-poly assets) — see HUMAN_DECISIONS.md. Godot registers `class_name`
## scripts globally, so callers use `GrayboxKit.foo(...)` with no preload,
## the same way the rest of the codebase uses SimConfig/MissionData.

const SKIN := Color(0.88, 0.74, 0.58)


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
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	box.material = mat
	mesh.mesh = box
	body.add_child(mesh)
	parent.add_child(body)
	return body


## A visual-only box (no collision), parented under `parent`.
static func visual_box(parent: Node3D, pos: Vector3, size: Vector3, color: Color) -> MeshInstance3D:
	var mesh := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = size
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	box.material = mat
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


## A trunk + sphere-crown tree, parented under `parent`.
static func tree(parent: Node3D, pos: Vector3) -> void:
	visual_box(parent, pos + Vector3(0, 0.6, 0), Vector3(0.35, 1.2, 0.35), Color(0.45, 0.32, 0.22))
	var crown := MeshInstance3D.new()
	var s := SphereMesh.new()
	s.radius = 0.9
	s.height = 1.8
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.30, 0.55, 0.30)
	s.material = mat
	crown.mesh = s
	crown.position = pos + Vector3(0, 1.9, 0)
	parent.add_child(crown)


## A simple graybox person (capsule body + sphere head), named "Body"/"Head"
## for tint_person(). NOT parented — the caller decides where it goes
## (a fixed NPC slot vs. a pooled customer-spawn root).
static func person(body_color: Color) -> Node3D:
	var root := Node3D.new()
	var body := MeshInstance3D.new()
	var cap := CapsuleMesh.new()
	cap.radius = 0.32
	cap.height = 1.0
	var bmat := StandardMaterial3D.new()
	bmat.albedo_color = body_color
	cap.material = bmat
	body.mesh = cap
	body.position.y = 0.6
	body.name = "Body"
	root.add_child(body)
	var head := MeshInstance3D.new()
	var sph := SphereMesh.new()
	sph.radius = 0.2
	sph.height = 0.4
	var hmat := StandardMaterial3D.new()
	hmat.albedo_color = SKIN
	sph.material = hmat
	head.mesh = sph
	head.position.y = 1.3
	head.name = "Head"
	root.add_child(head)
	return root


## Recolor a person's body (e.g. to flag a turned-away customer).
static func tint_person(p: Node3D, color: Color) -> void:
	var body := p.get_node_or_null("Body") as MeshInstance3D
	if body != null and body.mesh is CapsuleMesh:
		var mat := StandardMaterial3D.new()
		mat.albedo_color = color
		(body.mesh as CapsuleMesh).material = mat

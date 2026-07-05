class_name StructureCatalog
## BizTown — builds one world structure from a serializable data entry.
## The bridge between the built-world registry (GameState.built_structures,
## pure JSON-safe data) and GrayboxKit's mesh builders. This is what makes the
## keystone law ("what is built stays in the game") mechanically possible:
## the town is data the save file owns, and this file turns that data back
## into a physical town on load (DESIGN_CONSTRUCTION_ECONOMY.md §7).
##
## Entry shape (all values JSON-safe — arrays, not Vector3/Color, because the
## save round-trips through JSON.stringify/parse_string):
##   { "id": "shop",             # optional; lets Town3D keep a reference
##     "type": "building",       # building | tree | pine | lamp | crate
##     "pos": [x, y, z],
##     ... type-specific fields, see build() }


static func build(parent: Node3D, s: Dictionary) -> Node3D:
	var pos := _v3(s.get("pos", []))
	var node: Node3D = null
	match String(s.get("type", "")):
		"building":
			node = GrayboxKit.building(
				parent, pos, _v3(s.get("size", [4, 2.5, 3])),
				_col(s.get("wall", [0.6, 0.6, 0.6])), _col(s.get("roof", [0.4, 0.35, 0.3])),
				float(s.get("face", 1.0)), bool(s.get("front", true)))
		"warehouse":
			node = GrayboxKit.warehouse(
				parent, pos, _v3(s.get("size", [5, 3, 4])),
				_col(s.get("wall", [0.6, 0.6, 0.6])), _col(s.get("roof", [0.4, 0.4, 0.45])),
				float(s.get("face", 1.0)))
		"office":
			node = GrayboxKit.office(
				parent, pos, _v3(s.get("size", [4, 5, 3.5])),
				_col(s.get("wall", [0.6, 0.6, 0.6])), _col(s.get("roof", [0.4, 0.4, 0.45])),
				float(s.get("face", 1.0)))
		"tree":
			GrayboxKit.tree(parent, pos)
		"pine":
			GrayboxKit.pine_tree(parent, pos)
		"lamp":
			GrayboxKit.lamp_post(parent, pos)
		"crate":
			GrayboxKit.crate(parent, pos, float(s.get("side", 0.5)), _col(s.get("color", [0.6, 0.45, 0.3])))
		_:
			# A saved structure this catalog doesn't know would silently vanish
			# from the rebuilt town — warn loudly instead (same discipline as
			# EventEngine's unmatched-event guard).
			push_warning("StructureCatalog: unknown structure type: %s" % [s.get("type", "")])
	# Contracted structures carry a label — part of the town-planning
	# curriculum (design doc §12): the town reads as WHAT each thing is.
	if node != null and s.has("label"):
		var size := _v3(s.get("size", [4, 2.5, 3]))
		GrayboxKit.label3d(node, String(s.label), Vector3(0, size.y + 0.7, 0), 48,
			Color(0.95, 0.92, 0.80))
	return node


static func _v3(a: Array) -> Vector3:
	if a.size() != 3:
		return Vector3.ZERO
	return Vector3(float(a[0]), float(a[1]), float(a[2]))


static func _col(a: Array) -> Color:
	if a.size() < 3:
		return Color.MAGENTA  # loud "data was wrong" color, never used by valid data
	return Color(float(a[0]), float(a[1]), float(a[2]))

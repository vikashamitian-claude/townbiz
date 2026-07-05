class_name DefaultTown
## BizTown — the starting town as DATA (the layout Town3D used to hardcode).
## GameState.reset() seeds GameState.built_structures from this, the save
## persists it, and Town3D rebuilds the world from whatever the save says —
## so anything added to the registry later genuinely stays across sessions
## (keystone law, DESIGN_CONSTRUCTION_ECONOMY.md §1/§7).
## Pure data, JSON-safe values only (arrays, not Vector3/Color).


static func layout() -> Array:
	return [
		{"id": "shop", "type": "building", "pos": [0.0, 1.5, -6.0], "size": [6.0, 3.0, 4.0],
			"wall": [0.78, 0.55, 0.38], "roof": [0.62, 0.30, 0.24], "face": 1.0, "front": false},
		{"id": "neighbor", "type": "building", "pos": [8.0, 1.3, -6.0], "size": [5.0, 2.6, 4.0],
			"wall": [0.52, 0.53, 0.58], "roof": [0.38, 0.40, 0.45], "face": 1.0, "front": false},
		{"type": "building", "pos": [-9.0, 1.4, -7.0], "size": [4.0, 2.8, 3.5],
			"wall": [0.62, 0.50, 0.60], "roof": [0.45, 0.30, 0.35], "face": 1.0},
		{"type": "building", "pos": [-15.0, 1.2, -5.0], "size": [3.5, 2.4, 3.0],
			"wall": [0.50, 0.60, 0.68], "roof": [0.32, 0.38, 0.48], "face": 1.0},
		{"type": "building", "pos": [14.0, 1.3, -6.5], "size": [4.0, 2.6, 3.5],
			"wall": [0.68, 0.60, 0.45], "roof": [0.50, 0.38, 0.26], "face": 1.0},
		{"type": "building", "pos": [-12.0, 1.2, 6.5], "size": [4.0, 2.4, 3.0],
			"wall": [0.58, 0.55, 0.50], "roof": [0.40, 0.34, 0.30], "face": -1.0},
		{"type": "building", "pos": [11.0, 1.3, 7.0], "size": [4.5, 2.6, 3.2],
			"wall": [0.52, 0.62, 0.55], "roof": [0.34, 0.44, 0.38], "face": -1.0},
		{"type": "tree", "pos": [-5.0, 0.0, 5.0]},
		{"type": "tree", "pos": [5.0, 0.0, 6.0]},
		{"type": "tree", "pos": [16.0, 0.0, 2.8]},
		{"type": "pine", "pos": [-17.0, 0.0, 3.2]},
		{"type": "pine", "pos": [-6.5, 0.0, -3.5]},
		{"type": "pine", "pos": [17.5, 0.0, -4.0]},
		{"type": "lamp", "pos": [-13.0, 0.0, -0.7]},
		{"type": "lamp", "pos": [-4.0, 0.0, -0.7]},
		{"type": "lamp", "pos": [4.5, 0.0, -0.7]},
		{"type": "lamp", "pos": [13.0, 0.0, -0.7]},
	]

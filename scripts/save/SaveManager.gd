extends Node
## BizTown — Living Business Build: save system. Autoloaded as "SaveManager".
## Autosaves after every day_ended. Versioned JSON at user://save_v1.json.

signal saved
signal loaded

const SAVE_PATH: String = "user://save_v1.json"


func _ready() -> void:
	Sim.day_ended.connect(_on_day_ended)


func _on_day_ended(_result: Dictionary) -> void:
	save_game()


func has_save() -> bool:
	return FileAccess.file_exists(SAVE_PATH)


func save_game() -> bool:
	var payload: Dictionary = {
		"version": 1,
		"state": GameState.to_dict(),
		"missions": Missions.to_dict(),
	}
	var f: FileAccess = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if f == null:
		push_error("SaveManager: cannot open save file for writing")
		return false
	f.store_string(JSON.stringify(payload))
	f.close()
	saved.emit()
	return true


func load_game() -> bool:
	if not has_save():
		return false
	var f: FileAccess = FileAccess.open(SAVE_PATH, FileAccess.READ)
	if f == null:
		return false
	var parsed = JSON.parse_string(f.get_as_text())
	f.close()
	if typeof(parsed) != TYPE_DICTIONARY or int(parsed.get("version", 0)) != 1:
		push_warning("SaveManager: incompatible or corrupt save; starting fresh")
		return false
	GameState.from_dict(parsed.get("state", {}))
	Missions.from_dict(parsed.get("missions", {}))
	loaded.emit()
	Sim.changed.emit()  # refresh HUD
	if not GameState.pending_event.is_empty():
		# Re-announce a telegraph the player may not have seen this session
		# (e.g. they quit right after it fired) — the effect still applies
		# on schedule either way; this only concerns the warning itself.
		Events.telegraph(GameState.pending_event)
	return true


func delete_save() -> void:
	if has_save():
		DirAccess.remove_absolute(ProjectSettings.globalize_path(SAVE_PATH))

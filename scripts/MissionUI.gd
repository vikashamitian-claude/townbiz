extends Control
## BizTown — Sprint 2: minimal PLACEHOLDER UI. Displays the current mission only.
## No polish, no art, no animation — just text reflecting the Mission Engine.

@onready var title_label: Label = $VBox/Title
@onready var desc_label: Label = $VBox/Description
@onready var objective_label: Label = $VBox/Objective
@onready var status_label: Label = $VBox/Status


func _ready() -> void:
	MissionManager.mission_started.connect(_on_mission_started)
	MissionManager.mission_completed.connect(_on_mission_completed)
	MissionManager.chapter_completed.connect(_on_chapter_completed)
	MissionManager.start_chapter()


func _on_mission_started(m: Dictionary) -> void:
	title_label.text = m.title
	desc_label.text = m.description
	objective_label.text = "Objective: " + m.objective
	status_label.text = "In progress..."


func _on_mission_completed(m: Dictionary) -> void:
	status_label.text = "Mission Complete: " + m.title


func _on_chapter_completed() -> void:
	title_label.text = "Chapter 1 Complete"
	desc_label.text = "You built your first successful business."
	objective_label.text = ""
	status_label.text = ""

extends Control

@onready var map_panel = $MapPanel/VBoxContainer
var chart_scene = load("res://objects/chart_set.tscn")
func _ready() -> void:
	CM.connect("chart_loaded", Callable(self, "_addchart"))
	await get_tree().process_frame
	DisplayServer.window_set_drop_files_callback(Callable(self, "_on_files_dropped"))
	#$Edit/AddDifficulty.connect("pressed",_add_new_difficulty)
	if Game.scene == Game.Scene.Edit:
		$Edit.visible = true
var save_selected_beatmap_uuid
func _addchart(c) -> void:
	$MapPanel.addchild(chart_scene.i)
func _on_files_dropped(files: Array[String]) -> void:
	CM._new_chart_set(files)

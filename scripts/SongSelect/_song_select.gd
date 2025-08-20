extends Control

@onready var map_panel = $MapPanel/VBoxContainer
var chart_scene = load("res://objects/chart_set.tscn")

func _ready() -> void:
	CM.connect("chartset_loaded", Callable(self, "_addchart"))
	CM.connect("loading_finished",Callable(self, "_refresh"))
	DisplayServer.window_set_drop_files_callback(Callable(self, "_on_files_dropped"))
	await get_tree().process_frame
	#$Edit/AddDifficulty.connect("pressed",_add_new_difficulty)
	if Game.scene == Game.Scene.Edit:
		$Edit.visible = true
	for chart in CM.charts:
		var new_chart = chart_scene.instantiate()
		new_chart.chart_set = chart
		map_panel.add_child(new_chart)

func _addchart(c) -> void:
	var new_chart = chart_scene.instantiate()
	new_chart.chart_set = c
	map_panel.add_child(new_chart)
func _on_files_dropped(files: Array[String]) -> void:
	CM._new_chart_set(files)

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
	# Support dropping .dansu archives as well as raw audio files
	var audio_files: Array[String] = []
	for f in files:
		var lower := f.to_lower()
		if lower.ends_with(".dansu"):
			CM.import_dansu(f)
		else:
			audio_files.append(f)
	if audio_files.size() > 0:
		CM._new_chart_set(audio_files)

func _process(_delta: float) -> void:
	for child in map_panel.get_children():
		var childpos = child.position.y + map_panel.position.y
		var bgable:bool = childpos > -300 and childpos < 1300
		if not child.has_BG and bgable:
			print("load")
			child.load_background()
		if child.has_BG and not bgable:
			print("unload")
			child.BG.texture = null
			child.has_BG = false

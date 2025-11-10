extends Button
func _ready() -> void:
	connect("pressed", _on_pressed)
func _on_pressed():
	if CM.sc:
		if Game.scene == Game.Scene.Play:
			get_tree().change_scene_to_file("res://scene/play_scene.tscn")
		else:
			get_tree().change_scene_to_file("res://scene/map_editor.tscn")

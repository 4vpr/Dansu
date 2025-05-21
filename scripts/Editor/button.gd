extends Button
func _ready() -> void:
	connect("pressed", _on_pressed)
func _on_pressed():
	if Game.select_map:
		get_tree().change_scene_to_file("res://Scene/PlayScene.tscn")

extends Button
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pressed.connect(_press)
	pass
func _press() -> void:
	var sprite_path = $"../..".chart.folder_path.path_join("sprite")
	var absolute_path = ProjectSettings.globalize_path(sprite_path)
	OS.shell_open(absolute_path)

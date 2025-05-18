extends Button

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pressed.connect(_press)
	pass
func _press() -> void:
	OS.shell_open($"../..".beatmap.folder_path.path_join("sprite"))

extends Button

func _ready():
	connect("pressed", _on_button_pressed)

func _on_button_pressed():
	var user_dir := "user://"
	var dir := DirAccess.open(user_dir)
	if dir == null:
		DirAccess.make_dir_absolute(ProjectSettings.globalize_path(user_dir))
	var absolute_path := ProjectSettings.globalize_path("user://Songs")
	OS.shell_open(absolute_path)

extends Button

func _ready() -> void:
	pressed.connect(_on_pressed)

func _on_pressed() -> void:
	if Engine.has_singleton("CM"):
		CM.export_selected_chartset()
	else:
		CM.export_selected_chartset()
	# Optional: provide simple user feedback in output
	print("Export triggered from Map Editor")

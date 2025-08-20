extends Button
func _ready() -> void:
	pressed.connect(_on_button_pressed)
	pass
func _on_button_pressed():
	$"../Song Setup".visible = true
	pass

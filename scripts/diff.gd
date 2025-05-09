extends Button
var map
var difficulty = "?"
func _ready() -> void:
	pressed.connect(_button_press)
	text = map.substr(0, map.length() - 5)
func _button_press() -> void:
	Game.select_map = map
	pass

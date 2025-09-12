extends HSlider


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	value = Game.settings["gameplay"]["velocity"]
	$Label.text = "note speed : " + str(value)
	pass # Replace with function body.


func _value_changed(new_value: float) -> void:
	Game.setVelocity(new_value)
	$Label.text = "note speed : " + str(new_value)

extends HSlider


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	value = Game.velocity
	pass # Replace with function body.


func _value_changed(new_value: float) -> void:
	Game.setVelocity(new_value)
	$Label.text = str(new_value)

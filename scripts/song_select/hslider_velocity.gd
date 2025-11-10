extends HSlider

func _ready() -> void:
	value = Settings.note_speed
	$Label.text = "note speed : " + str(value)
	pass # Replace with function body.

func _value_changed(new_value: float) -> void:
	Settings.note_speed = new_value
	Settings.apply_note_speed()
	$Label.text = "note speed : " + str(new_value)

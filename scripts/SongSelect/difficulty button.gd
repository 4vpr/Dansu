extends Button

var beatmap: Beatmap

func _ready() -> void:
	pressed.connect(_button_press)
	if beatmap:
		text = beatmap.diff_name
		#text = difficulty + " (" + str(beatmap.diff_value) + ")"

func _button_press() -> void:
	Game.select_map = beatmap
	pass

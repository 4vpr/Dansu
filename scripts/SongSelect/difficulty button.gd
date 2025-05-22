extends Button

var beatmap: Beatmap

func _ready() -> void:
	pressed.connect(_press)
	mouse_entered.connect(_enter)
	if beatmap:
		text = beatmap.diff_name
func _process(delta: float) -> void:
	if is_hovered:
		if Game.select_map == beatmap:
			custom_minimum_size.y = 45
		else:
			custom_minimum_size.y = 35
func _press() -> void:
	Game.select_map = beatmap

func _enter() -> void:
	custom_minimum_size.y = 50

extends Control

var is_key_assign_mode: bool = false
var key_assign_action: String = ""  # 현재 할당 중인 액션

func _ready() -> void:
	$Master.value_changed.connect(_master)
	$Master.value = Game.settings["audio"]["volume_master"] * 100
	$Music.value_changed.connect(_music)
	$Music.value = Game.settings["audio"]["volume_song"] * 100
	$SFX.value_changed.connect(_sfx)
	$SFX.value = Game.settings["audio"]["volume_sfx"] * 100
	$Left.pressed.connect(_left)
	$Left.text = Game.settings["key"]["move_left"]
	$Right.pressed.connect(_right)
	$Right.text = Game.settings["key"]["move_right"]
	$A1.pressed.connect(_a1)
	$A1.text = Game.settings["key"]["action_1"]
	$A2.pressed.connect(_a2)
	$A2.text = Game.settings["key"]["action_2"]

func _master(value):
	Game.settings["audio"]["volume_master"] = value / 100
	var db = linear_to_db(Game.settings["audio"]["volume_master"])
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Master"), db)

func _music(value):
	Game.settings["audio"]["volume_song"] = value / 100
	var db = linear_to_db(Game.settings["audio"]["volume_song"])
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Music"), db)

func _sfx(value):
	Game.settings["audio"]["volume_sfx"] = value / 100
	var db = linear_to_db(Game.settings["audio"]["volume_sfx"])
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("SFX"), db)
var selected_button
func _left() -> void:
	is_key_assign_mode = true
	key_assign_action = "move_left"
	selected_button = $Left

func _right() -> void:
	is_key_assign_mode = true
	key_assign_action = "move_right"
	selected_button = $Right
func _a1() -> void:
	is_key_assign_mode = true
	key_assign_action = "action_1"
	selected_button = $A1
func _a2() -> void:
	is_key_assign_mode = true
	key_assign_action = "action_2"
	selected_button = $A2

func _input(event: InputEvent) -> void:
	if is_key_assign_mode and event is InputEventKey and event.pressed:

		if event.keycode == KEY_ESCAPE:
			is_key_assign_mode = false

			return

		var key_string := OS.get_keycode_string(event.keycode)
		Game.settings["key"][key_assign_action] = key_string
		selected_button.text = key_string

		# InputMap에 반영
		InputMap.action_erase_events(key_assign_action)
		var new_event := InputEventKey.new()
		new_event.physical_keycode = event.keycode
		InputMap.action_add_event(key_assign_action, new_event)

		is_key_assign_mode = false

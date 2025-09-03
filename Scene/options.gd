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

	_setup_window_mode_and_resolution()
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

func _setup_window_mode_and_resolution() -> void:
	var mode_button: OptionButton = $WindowMode if has_node("WindowMode") else null
	var res_button: OptionButton = $Res if has_node("Res") else null
	var primary := DisplayServer.get_primary_screen()
	var screen_size: Vector2i = DisplayServer.screen_get_size(primary)

	# Window mode options
	if mode_button:
		mode_button.clear()
		mode_button.add_item("Windowed", 0)
		mode_button.add_item("Fullscreen", 1)
		mode_button.add_item("Borderless", 2)
		var mode: String = Game.settings["graphics"].get("window_mode", "windowed")
		var idx := 0
		match mode:
			"fullscreen": idx = 1
			"borderless": idx = 2
			_:
				idx = 0
		mode_button.select(idx)
		mode_button.item_selected.connect(func(i):
			var m := "windowed"
			if i == 1:
				m = "fullscreen"
			elif i == 2:
				m = "borderless"
			Game.settings["graphics"]["window_mode"] = m
			if res_button:
				if m == "borderless":
					var s = str(screen_size.x) + "x" + str(screen_size.y)
					Game.settings["graphics"]["resolution"] = s
					res_button.disabled = true
					_select_or_insert_resolution(res_button, screen_size)
				else:
					res_button.disabled = false
			Game.save_settings()
			Game.apply_settings()
		)

	# Resolution options (<= screen size)
	if res_button:
		var presets := [
			Vector2i(1280, 720), Vector2i(1366, 768), Vector2i(1440, 810),
			Vector2i(1600, 900), Vector2i(1920, 1080), Vector2i(2560, 1440),
			Vector2i(3440, 1440), Vector2i(3840, 2160)
		]
		res_button.clear()
		var allowed: Array = []
		for p in presets:
			if p.x <= screen_size.x and p.y <= screen_size.y:
				allowed.append(p)
		# Ensure current and screen resolution are present
		var cur = Game.settings["graphics"].get("resolution", "1920x1080")
		var parts = cur.split("x")
		var cur_v := Vector2i(1920,1080)
		if parts.size() == 2:
			cur_v = Vector2i(int(parts[0]), int(parts[1]))
		if not allowed.has(cur_v):
			allowed.append(cur_v)
		if not allowed.has(screen_size):
			allowed.append(screen_size)
		# Populate and select
		var sel_idx := 0
		for i in allowed.size():
			var p: Vector2i = allowed[i]
			res_button.add_item(str(p.x) + "x" + str(p.y), i)
			if p == cur_v:
				sel_idx = i
		res_button.select(sel_idx)
		# Disable if current mode is borderless
		res_button.disabled = Game.settings["graphics"].get("window_mode", "windowed") == "borderless"
		res_button.item_selected.connect(func(i):
			if res_button.disabled:
				return
			var p: Vector2i = allowed[i]
			var s = str(p.x) + "x" + str(p.y)
			Game.settings["graphics"]["resolution"] = s
			Game.save_settings()
			Game.apply_settings()
		)

func _select_or_insert_resolution(btn: OptionButton, size: Vector2i) -> void:
	var text := str(size.x) + "x" + str(size.y)
	var found := -1
	for i in btn.item_count:
		if btn.get_item_text(i) == text:
			found = i
			break
	if found == -1:
		btn.add_item(text, btn.item_count)
		found = btn.item_count - 1
	btn.select(found)

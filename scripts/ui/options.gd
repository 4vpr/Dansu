extends Control

var is_key_assign_mode: bool = false
var key_assign_action: String = ""  # 현재 할당 중인 액션

func _ready() -> void:
	$Master.value_changed.connect(_master)
	$Master.value = Settings.volume_master * 100
	$Music.value_changed.connect(_music)
	$Music.value = Settings.volume_music * 100
	$SFX.value_changed.connect(_sfx)
	$SFX.value = Settings.volume_sfx * 100
	$FPS.value_changed.connect(_fps)
	$FPS.value = Settings.game_fps
	$FPS/value.text = "FPS: "+ str(Settings.game_fps)
	$Left.pressed.connect(_left)
	$Left.text = Settings.keys["move_left"]
	$Right.pressed.connect(_right)
	$Right.text = Settings.keys["move_right"]
	$A1.pressed.connect(_a1)
	$A1.text = Settings.keys["action_1"]
	$A2.pressed.connect(_a2)
	$A2.text = Settings.keys["action_2"]
	$ShowFps.toggled.connect(_show_fps)
	$ShowFps.button_pressed = Settings.show_fps
	
	$FullScreen.button_pressed = Settings.fullscreen
	$FullScreen.toggled.connect(_fullscreen)
	
	_setup_resolution()
func _master(value):
	Settings.volume_master = value / 100
	var db = linear_to_db(Settings.volume_master)
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Master"), db)

func _music(value):
	Settings.volume_music = value / 100
	var db = linear_to_db(Settings.volume_music)
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Music"), db)

func _sfx(value):
	Settings.volume_sfx = value / 100
	var db = linear_to_db(Settings.volume_sfx)
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

func _setup_resolution() -> void:
	var res_button: OptionButton = $Res if has_node("Res") else null
	var primary := DisplayServer.get_primary_screen()
	var screen_size: Vector2i = DisplayServer.screen_get_size(primary)

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
		var cur_v = Vector2i(Settings.resolution_x , Settings.resolution_y)
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
		res_button.item_selected.connect(func(i):
			var p: Vector2i = allowed[i]
			Settings.resolution_x = p.x
			Settings.resolution_y = p.y
			Settings.apply_display()
		)

func _fps(value):
	Settings.game_fps = value
	if value != 0:
		$FPS/value.text = "FPS: "+ str(Settings.game_fps)
	else:
		$FPS/value.text = "FPS: infinite"

func _show_fps():
	Settings.show_fps = not Settings.show_fps

func _fullscreen(b: bool):
	print(b)
	Settings.fullscreen = b
	Settings.apply_display()

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

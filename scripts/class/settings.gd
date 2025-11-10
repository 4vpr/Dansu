extends Node

# runtime values
var config_file_path = "user://settings.cfg"
var primary_screen_index = DisplayServer.get_primary_screen()
var screen_position = DisplayServer.screen_get_position(primary_screen_index)
var screen_size = DisplayServer.screen_get_size(primary_screen_index)
var window_size = DisplayServer.window_get_size_with_decorations()
var travel_time = 1
const panel_size = 11.3

# Graphics
var fullscreen: bool = true
var resolution_x = 1920
var resolution_y = 1080

var game_fps: int = 0
var menu_fps: int = 60
var show_fps: bool = false
var vsync: bool = true

# Audio
var volume_master: float = 0.5
var volume_sfx: float = 1.0
var volume_music: float = 1.0
var audio_delay: int = 0

# Visual
var use_default_skin: bool = false
var player_size: int = 450
var skin_folder: String = ""

# Gameplay
var note_speed: float = 7.0
var move_speed: float = 10.0
var tick_rate: int = 1000

var keys = {
	"move_left" : "LEFT",
	"move_right" : "RIGHT",
	"action_1" : "Z",
	"action_2" : "X"
}

const PERSIST_LAYOUT := {
	"graphics": ["fullscreen", "resolution_x", "resolution_y", "game_fps", "menu_fps", "show_fps", "vsync"],
	"audio": ["volume_master", "volume_sfx", "volume_music", "audio_delay"],
	"visual": ["use_default_skin", "player_size", "skin_folder"],
	"gameplay": ["note_speed", "move_speed", "tick_rate"],
	"input": ["keys"]
}

func center_window():
	primary_screen_index = DisplayServer.get_primary_screen()
	screen_position = DisplayServer.screen_get_position(primary_screen_index)
	screen_size = DisplayServer.screen_get_size(primary_screen_index)
	window_size = DisplayServer.window_get_size_with_decorations()
	var centered_position = screen_position + (screen_size - window_size) / 2
	DisplayServer.window_set_position(centered_position)

func apply_all():
	apply_display()
	apply_audio()
	apply_keys()
	apply_note_speed()

func apply_display():
	if resolution_x > screen_size.x or resolution_y > screen_size.y:
			resolution_x = screen_size.x; resolution_y = screen_size.y
	if fullscreen:
		DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_BORDERLESS, false)
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN)
		DisplayServer.window_set_size(Vector2i(resolution_x, resolution_y))
	# borderless
	elif resolution_x == screen_size.x and resolution_y == screen_size.y:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
		DisplayServer.window_set_size(Vector2i(resolution_x, resolution_y))
	# windowed
	else:
		DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_BORDERLESS, false)
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
		DisplayServer.window_set_size(Vector2i(resolution_x, resolution_y))
		center_window()
func apply_keys() -> void:
	for action in keys.keys():
		var key_str = keys[action]
		var key_code = OS.find_keycode_from_string(key_str)
		if key_code != 0:
			InputMap.action_erase_events(action)
			var new_event := InputEventKey.new()
			new_event.physical_keycode = key_code
			InputMap.action_add_event(action, new_event)
		else:
			print("wrong key")
			print(OS.find_keycode_from_string(key_str))


func apply_audio() -> void:
	var master_db = linear_to_db(volume_master)
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Master"), master_db)
	var music_db = linear_to_db(volume_music)
	var music_bus_index = AudioServer.get_bus_index("Music")
	if music_bus_index != -1:
		AudioServer.set_bus_volume_db(music_bus_index, music_db)
	var sfx_db = linear_to_db(volume_sfx)
	var sfx_bus_index = AudioServer.get_bus_index("SFX")
	if sfx_bus_index != -1:
		AudioServer.set_bus_volume_db(sfx_bus_index, sfx_db)


func default_skin() -> PlayerSkin:
	var ds = PlayerSkin.new()
	ds.folder_path = "res://default/skin/"
	ds.json_path = "res://default/skin/skin.json"
	ds.parse_objects()
	return ds
var editor_velocity: float = 1
var offset_recom = AudioServer.get_output_latency()
var currentTime: float = 0.0

func apply_note_speed() -> void:
	travel_time = panel_size * 1000 / note_speed


func _coerce_type(value: Variant, default: Variant) -> Variant:
	match typeof(default):
		TYPE_BOOL: return bool(value)
		TYPE_INT: return int(value)
		TYPE_FLOAT: return float(value)
		TYPE_STRING: return str(value)
		TYPE_DICTIONARY:
			return value if typeof(value) == TYPE_DICTIONARY else default
		_:
			return value

func save_cfg() -> void:
	var cfg := ConfigFile.new()
	for section in PERSIST_LAYOUT.keys():
		for prop_name in PERSIST_LAYOUT[section]:
			var v = get(prop_name)
			cfg.set_value(section, prop_name, v)
	var err := cfg.save(config_file_path)
	if err != OK:
		push_error("Failed to save config: %s" % err)

func load_cfg() -> void:
	var cfg := ConfigFile.new()
	var err := cfg.load(config_file_path)
	if err != OK:
		return

	for section in PERSIST_LAYOUT.keys():
		for prop_name in PERSIST_LAYOUT[section]:
			var default_v = get(prop_name)
			var loaded_v = cfg.get_value(section, prop_name, default_v)
			set(prop_name, _coerce_type(loaded_v, default_v))

extends Node
const SAVE_PATH := "user://save.json"
var travelTime
const panelSize = 11.3
var score = Score.new()
var isTouchScreen = false
enum Scene {
	Play,
	Edit,
	Result,
	Main
}
var scene = Scene.Main
func _init():
	var primary_screen_index = DisplayServer.get_primary_screen()
	DisplayServer.window_set_current_screen(primary_screen_index)
	check_folders()
	load_settings()
	apply_settings()
	center_window()

func check_folders():
	var required_dirs = ["Songs", "Skins"]
	var base_path = "user://"
	for dir_name in required_dirs:
		var full_path = base_path + dir_name
		var dir = DirAccess.open(full_path)
		if !dir:
			# 경로가 없으면 생성
			var parent_dir = DirAccess.open(base_path)
			if parent_dir:
				var result = parent_dir.make_dir(dir_name)
				if result == OK:
					print(dir_name + " new folder at :", full_path)
				else:
					print(dir_name + " failed to create :", full_path)
			else:
				print(" failed to open :", base_path)


#------------------------------------------------------
"                      [Settings]                    "
#------------------------------------------------------


var config_file_path = "user://settings.cfg"
var monitor_res = str(DisplayServer.screen_get_size()[0]) + "x" + str(DisplayServer.screen_get_size()[1])
var settings = {
	"graphics": {
		"resolution": monitor_res,
		"window_mode": "fullscreen", # windowed | fullscreen | borderless
		"fullscreen": true, # legacy toggle for migration
		"MaxFPS": DisplayServer.screen_get_refresh_rate(),
		"VSync": true,
	},
	"audio": {
		"volume_master": 0.5,
		"volume_song": 0.5,
		"volume_sfx": 0.5,
		"offset": 0,
	},
	"gameplay": {
		"velocity": 7.5,
		"playerheight": 450,
		"pollingRate": 1000,
		"playerSpeed": 10,
		"showFPS": false
	},
	"key": {
		"move_left": "LEFT",
		"move_right": "RIGHT",
		"action_1": "Z",
		"action_2": "X"
	}
}


func load_settings():
	print(monitor_res)
	var config = ConfigFile.new()
	if config.load(config_file_path) == OK:
		for section in settings.keys():
			var section_data = settings[section]
			for key in section_data.keys():
				var default_value = section_data[key]
				section_data[key] = config.get_value(section, key, default_value)
		# Migrate legacy fullscreen -> window_mode if missing
		if !settings["graphics"].has("window_mode"):
			var legacy_full = bool(settings["graphics"].get("fullscreen", false))
			settings["graphics"]["window_mode"] = "fullscreen" if legacy_full else "windowed"
	save_settings()


func center_window():
	# 주 모니터 인덱스
	var primary_screen_index = DisplayServer.get_primary_screen()
	# 주 모니터의 글로벌 좌표
	var screen_position = DisplayServer.screen_get_position(primary_screen_index)
	# 주 모니터 크기
	var screen_size = DisplayServer.screen_get_size(primary_screen_index)
	# 창 크기
	var window_size = DisplayServer.window_get_size_with_decorations()
	# 중앙 좌표
	var centered_position = screen_position + (screen_size - window_size) / 2
	# 위치 설정
	DisplayServer.window_set_position(centered_position)


func _apply_display_settings() -> void:
	
	var primary_screen_index = DisplayServer.get_primary_screen()
	var screen_position = DisplayServer.screen_get_position(primary_screen_index)
	var screen_size = DisplayServer.screen_get_size(primary_screen_index)
	
	var mode: String = settings["graphics"].get("window_mode", "windowed")
	var res_parts = settings["graphics"]["resolution"].split("x")
	var req_size := Vector2i(1920, 1080)
	
	if res_parts.size() == 2:
		req_size = Vector2i(int(res_parts[0]), int(res_parts[1]))
	var final_size := req_size
	
	if mode != "fullscreen":
		final_size.x = min(final_size.x, screen_size.x)
		final_size.y = min(final_size.y, screen_size.y)
	
	match mode:
		"fullscreen":
			settings["graphics"]["fullscreen"] = true
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
			DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_BORDERLESS, false)
		"borderless":
			settings["graphics"]["fullscreen"] = false
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
			DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_BORDERLESS, true)
			settings["graphics"]["resolution"] = str(screen_size.x) + "x" + str(screen_size.y)
			DisplayServer.window_set_position(screen_position)
		_:
			settings["graphics"]["fullscreen"] = false
			DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_BORDERLESS, false)
			settings["graphics"]["resolution"] = str(final_size.x) + "x" + str(final_size.y)


func save_setting(section: String, key: String, value):
	var config = ConfigFile.new()
	# 키 설정 저장;
	for action in InputMap.get_actions():
		var events = InputMap.action_get_events(action)
		if events.size() > 0:
			# 첫 번째 InputEventKey만 저장 (확장 가능)
			var ev = events[0]
			if ev is InputEventKey:
				var key_name = OS.get_keycode_string(ev.physical_keycode)
				settings["key"][action] = key_name
	config.load(config_file_path)  # 기존 값 유지
	config.set_value(section, key, value)
	config.save(config_file_path)


func apply_settings():
	print("apply_setting")
	_apply_display_settings()
	# 해상도 적용
	var res_parts = settings["graphics"]["resolution"].split("x")
	if res_parts.size() == 2:
		var width = int(res_parts[0])
		var height = int(res_parts[1])
		DisplayServer.window_set_size(Vector2i(width, height))
	# 전체화면 적용
	DisplayServer.window_set_mode(
	DisplayServer.WINDOW_MODE_FULLSCREEN if settings["graphics"]["fullscreen"]
	else DisplayServer.WINDOW_MODE_WINDOWED)
	# Enforce specific handling for selected window_mode
	var __mode: String = settings["graphics"].get("window_mode", "windowed")
	var __parts = settings["graphics"]["resolution"].split("x")
	var __size := Vector2i(1920, 1080)
	if __parts.size() == 2:
		__size = Vector2i(int(__parts[0]), int(__parts[1]))
	var __primary = DisplayServer.get_primary_screen()
	var __screen_pos = DisplayServer.screen_get_position(__primary)
	var __screen_size = DisplayServer.screen_get_size(__primary)
	if __mode == "fullscreen":
		# Use exclusive fullscreen to actually switch to selected resolution
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN)
		DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_BORDERLESS, false)
		DisplayServer.window_set_size(__size)
	elif __mode == "borderless":
		# Borderless should cover the entire screen and be visible
		DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_BORDERLESS, true)
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	else:
		# Windowed
		DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_BORDERLESS, false)
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
		DisplayServer.window_set_size(__size)

	# Center window after resolution change in windowed mode
	var ____mode = settings["graphics"].get("window_mode", "windowed")
	if ____mode == "windowed":
		center_window()
	#키설정 적용
	for action in settings["key"].keys():
		var key_str = settings["key"][action]
		var key_code = OS.find_keycode_from_string(key_str)
		if key_code != 0:
			# 기존 이벤트 제거
			InputMap.action_erase_events(action)
			# 새로운 이벤트 추가
			var new_event := InputEventKey.new()
			new_event.physical_keycode = key_code
			InputMap.action_add_event(action, new_event)
		else:
			print("wrong key")
			print(OS.find_keycode_from_string(key_str))
	var master_vol = settings["audio"]["volume_master"]
	var master_db = linear_to_db(master_vol)
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Master"), master_db)

	# Song 볼륨 (예: Music 버스로)
	var music_vol = settings["audio"]["volume_song"]
	var music_db = linear_to_db(music_vol)
	var music_bus_index = AudioServer.get_bus_index("Music")
	if music_bus_index != -1:
		AudioServer.set_bus_volume_db(music_bus_index, music_db)

	# SFX 볼륨
	var sfx_vol = settings["audio"]["volume_sfx"]
	var sfx_db = linear_to_db(sfx_vol)
	var sfx_bus_index = AudioServer.get_bus_index("SFX")
	if sfx_bus_index != -1:
		AudioServer.set_bus_volume_db(sfx_bus_index, sfx_db)

func save_settings():
	var config = ConfigFile.new()
	for section in settings.keys():
		var section_data = settings[section]
		for key in section_data.keys():
			var value = section_data[key]
			config.set_value(section, key, value)
	config.save(config_file_path)

func _use_default_skin() -> PlayerSkin:
	var ds = PlayerSkin.new()
	ds.folder_path = "res://default/skin/"
	ds.json_path = "res://default/skin/skin.json"
	ds.parse_objects()
	return ds
var editor_velocity: float = 1
var offset_recom = AudioServer.get_output_latency()
var currentTime: float = 0.0

func setVelocity(v:float) -> void:
	settings["gameplay"]["velocity"] = v
	travelTime = panelSize * 1000 / settings["gameplay"]["velocity"]
	save_settings()

var SongSlider
var lastSelectDiff = 0

func getRank(a:float):
	if a >= 101:
		return "X"
	elif a >= 100.9:
		return "SS+"
	elif a >= 100:
		return "SS"
	elif a >= 99:
		return "S+"
	elif a >= 95:
		return "S"
	elif a >= 90:
		return "A"
	elif a >= 80:
		return "B"
	elif a >= 70:
		return "C"
	return "D"

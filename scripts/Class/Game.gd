extends Node
const SAVE_PATH := "user://save.json"
const F11_KEYCODE := 16777265

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_toggle_fullscreen"):
		settings["graphics"]["fullscreen"] = !settings["graphics"]["fullscreen"]
		save_settings()
		center_window()
		apply_settings()
	if event is InputEventScreenTouch:
		isTouchScreen = true

const FIELD_NAMES = [
	"score", "note", "perfect_plus", "perfect", "good",
	"ok", "bad", "miss", "high_combo", "hash"
]

var save_data: Dictionary = {}

func load_data():
	var file = FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file:
		var text = file.get_as_text()
		var parsed = JSON.parse_string(text)
		file.close()
		if typeof(parsed) == TYPE_DICTIONARY:
			for uuid in parsed.keys():
				var new_entries: Array = []
				for entry in parsed[uuid]:
					match typeof(entry):
						TYPE_DICTIONARY:
							var compact_entry: Array = [
								snappedf(entry.get("score", 0.0), 0.0001),
								entry.get("note", 0),
								entry.get("perfect_plus", 0),
								entry.get("perfect", 0),
								entry.get("good", 0),
								entry.get("ok", 0),
								entry.get("bad", 0),
								entry.get("miss", 0),
								entry.get("high_combo", 0),
								entry.get("hash", "")
							]
							new_entries.append(compact_entry)
						TYPE_ARRAY:
							var restored_entry := {}
							for i in entry.size():
								if i < FIELD_NAMES.size():
									restored_entry[FIELD_NAMES[i]] = entry[i]
							new_entries.append(restored_entry)
				parsed[uuid] = new_entries
		save_data = parsed
		save_data_to_file()
	else:
		save_data = {}
		save_data_to_file()

func save_data_to_file():
	var data_to_save: Dictionary = {}
	for uuid in save_data.keys():
		var new_entries: Array = []
		for entry in save_data[uuid]:
			match typeof(entry):
				TYPE_DICTIONARY:
					# Dictionary → 압축 Array 변환
					var compact_entry: Array = [
						snappedf(entry.get("score", 0.0), 0.0001),
						entry.get("note", 0),
						entry.get("perfect_plus", 0),
						entry.get("perfect", 0),
						entry.get("good", 0),
						entry.get("ok", 0),
						entry.get("bad", 0),
						entry.get("miss", 0),
						entry.get("high_combo", 0),
						entry.get("hash", "")
					]
					new_entries.append(compact_entry)
				TYPE_ARRAY:
					# 이미 압축된 경우 그대로
					new_entries.append(entry)
		data_to_save[uuid] = new_entries
	var file = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file:
		var json_string = JSON.stringify(data_to_save)  # 압축 저장
		file.store_string(json_string)
		file.close()

func get_scores_for_uuid(uuid_to_load: String) -> Array:
	if save_data.has(uuid_to_load):
		return save_data[uuid_to_load]
	else:
		return []
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
	load_data()
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
var config_file_path = "user://settings.cfg"
var settings = {
	"graphics": {
		"resolution": "1920x1080",
		"fullscreen": true,
		"MaxFPS": 1000,
		"VSync": true,
	},
	"audio": {
		"volume_master": 0.5,
		"volume_song": 0.25,
		"volume_sfx": 0.5,
		"offset": 0.0
	},
	"gameplay": {
		"velocity": 8.0,
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
	var config = ConfigFile.new()
	if config.load(config_file_path) == OK:
		for section in settings.keys():
			var section_data = settings[section]
			for key in section_data.keys():
				var default_value = section_data[key]
				section_data[key] = config.get_value(section, key, default_value)
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
	# 해상도 적용
	var res_parts = settings["graphics"]["resolution"].split("x")
	if res_parts.size() == 2:
		var width = int(res_parts[0])
		var height = int(res_parts[1])
		DisplayServer.window_set_size(Vector2i(width, height))
	# 전체화면 적용
	DisplayServer.window_set_mode(
	DisplayServer.WINDOW_MODE_FULLSCREEN if settings["graphics"]["fullscreen"] else DisplayServer.WINDOW_MODE_WINDOWED
)
	#fps 적용
	Engine.max_fps = settings["graphics"]["MaxFPS"]
	Engine.physics_ticks_per_second = settings["gameplay"]["pollingRate"]
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
	pass
var SongSlider
var lastSelectDiff = 0
#비트맵 로딩관련
var loaded_beatmaps = []
var selected_beatmap
var selected_beatmap_set
var prev_mapcard
var prev_diffcard




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

func get_sorted_scores_for_uuid(uuid: String) -> Array:
	if not save_data.has(uuid):
		return []
	var records = save_data[uuid]
	if typeof(records) != TYPE_ARRAY:
		records = [records]
	records.sort_custom(func(a, b): return b["score"] < a["score"])
	return records
var travelTime

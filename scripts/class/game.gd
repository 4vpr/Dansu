extends Node
const SAVE_PATH := "user://save.json"

const FIELD_NAMES = [
	"score", "note", "perfect_plus", "perfect", "good",
	"ok", "bad", "miss", "high_combo", "hash"
]
var save_data: Dictionary = {}

#------------------------------------------------------
"                      [SAVE]                         "
#------------------------------------------------------

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
func _ready():
	var primary_screen_index = DisplayServer.get_primary_screen()
	DisplayServer.window_set_current_screen(primary_screen_index)
	check_folders()
	Settings.load_cfg()
	load_data()
	Settings.apply_all()
	Settings.center_window()

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


func _use_default_skin() -> PlayerSkin:
	var ds = PlayerSkin.new()
	ds.folder_path = "res://default/skin/"
	ds.json_path = "res://default/skin/skin.json"
	ds.parse_objects()
	return ds
var editor_velocity: float = 1
var offset_recom = AudioServer.get_output_latency()
var currentTime: float = 0.0
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

func get_sorted_scores_for_uuid(uuid: String) -> Array:
	if not save_data.has(uuid):
		return []
	var records = save_data[uuid]
	if typeof(records) != TYPE_ARRAY:
		records = [records]
	records.sort_custom(func(a, b): return b["score"] < a["score"])
	return records
var travelTime

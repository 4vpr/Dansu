extends Control

@onready var map_panel = $MapPanel/VBoxContainer
var map_scene = load("res://objects/song.tscn")

func _ready() -> void:
	if Game.loaded_beatmaps.size() < 1:
		_load()
	_refresh()

func _load() -> void:

	# 외부 맵 로드
	var folders = get_folders_in_path(OS.get_user_data_dir().path_join("Songs"))
	for folder in folders:
		_add_beatmap_set(folder)
	# 내장 맵 로드
	_load_built_in_maps()

func _add_beatmap_set(folder: String):
	var i = 0
	var beatmap_set = BeatmapSet.new()
	beatmap_set.load_from_folder(folder)
	if beatmap_set.beatmaps.size() > 0:
		if Game.select_folder == null:
			Game.select_folder = beatmap_set
			Game.select_map = beatmap_set.beatmaps[0]
		Game.loaded_beatmaps.append(beatmap_set)
func _refresh():
	for beatmap in Game.loaded_beatmaps:
		var i = 1
		while i > 0:
			i -= 1
			var new_map = map_scene.instantiate()
			new_map.beatmap_set = beatmap
			map_panel.add_child(new_map)

func _load_built_in_maps():
	var list_path = "res://song/map_list.json"
	if not FileAccess.file_exists(list_path):
		print("내장 맵 목록 파일 없음: ", list_path)
		return

	var file = FileAccess.open(list_path, FileAccess.READ)
	var json = JSON.parse_string(file.get_as_text())
	if json.has("maps"):
		var loaded_folders = {}
		for map_path in json["maps"]:
			var folder = map_path.get_base_dir()
			if not loaded_folders.has(folder):
				_add_beatmap_set(folder)
				loaded_folders[folder] = true

func get_folders_in_path(path: String) -> Array:
	var folders = []
	var dir = DirAccess.open(path)
	if dir:
		dir.list_dir_begin()
		var file_name = dir.get_next()
		while file_name != "":
			if dir.current_is_dir() and file_name != "." and file_name != "..":
				folders.append(path.path_join(file_name))
			file_name = dir.get_next()
		dir.list_dir_end()
	else:
		print("폴더 탐색 실패: ", path)
	return folders

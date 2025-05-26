extends Control

@onready var map_panel = $MapPanel/VBoxContainer
var map_scene = load("res://objects/song.tscn")

func _ready() -> void:
	if Game.loaded_beatmaps.size() < 1:
		_load()
	_refresh()
	await get_tree().process_frame
	DisplayServer.window_set_drop_files_callback(Callable(self, "_on_files_dropped"))
	$Edit/AddDifficulty.connect("pressed",_add_new_difficulty)
	if Game.scene == Game.Scene.Edit:
		$Edit.visible = true
	
func _load() -> void:
	# 외부 맵 로드
	var folders = get_folders_in_path(OS.get_user_data_dir().path_join("Songs"))
	for folder in folders:
		_add_beatmap_set(folder)
	# 내장 맵 로드
	_load_built_in_maps()

func _add_beatmap_set(folder: String) -> BeatmapSet:
	var beatmap_set = BeatmapSet.new()
	beatmap_set.load_from_folder(folder)
	if beatmap_set.beatmaps.size() > 0:
		var i = 0
		Game.loaded_beatmaps.append(beatmap_set)
	return beatmap_set
func _refresh():
	$MapPanel/VBoxContainer.get_children().map(func(c): c.queue_free())
	for beatmap in Game.loaded_beatmaps:
		beatmap._clear()
		var i = 1
		while i > 0:
			i -= 1
			var new_map = map_scene.instantiate()
			new_map.beatmap_set = beatmap
			map_panel.add_child(new_map)
			if Game.selected_beatmap == null:
				Game.select_beatmap_set(beatmap,new_map)
				Game.selected_beatmap = beatmap.beatmaps[0]
			if beatmap == Game.selected_beatmap_set:
				Game.select_beatmap_set(beatmap,new_map)
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
func _on_files_dropped(files: Array[String]) -> void:
	if Game.scene == Game.Scene.Edit:
		for file_path in files:
			var file = file_path.get_file()
			var supported_extensions = [".mp3", ".wav_FIX", ".ogg_FIX"]
			for ext in supported_extensions:
				if file_path.to_lower().ends_with(ext):
					var song_file_name = file.get_basename()
					var _dir = OS.get_user_data_dir().path_join("Songs")
					var dir = DirAccess.open(_dir)
					var random_number = str(randi_range(100000, 999999)) + " "
					dir.make_dir(random_number + song_file_name)
					var folder_path = _dir.path_join(random_number + song_file_name)
					dir = DirAccess.open(folder_path)
					dir.make_dir(folder_path.path_join("sprite"))
					var new_json = str(randi_range(100000, 999999)) + ".json"
					var src_file = FileAccess.open(file_path, FileAccess.READ)
					if src_file:
						var mp3_data = src_file.get_buffer(src_file.get_length())
						src_file.close()
						var dst_file = FileAccess.open(folder_path.path_join(file), FileAccess.WRITE)
						if dst_file:
							dst_file.store_buffer(mp3_data)
							dst_file.close()
					var json_data = {}
					json_data["file_audio"] = file
					json_data["title"] = file.get_basename()
					var json = FileAccess.open(folder_path.path_join(new_json), FileAccess.WRITE)
					if json:
						json.store_string(JSON.stringify(json_data, "\t"))
						json.close()
					var new_map = map_scene.instantiate()
					new_map.beatmap_set = _add_beatmap_set(folder_path)
					map_panel.add_child(new_map)
					Game.select_beatmap_set(new_map.beatmap_set,new_map)
func _add_new_difficulty():
	var path = Game.selected_beatmap.json_path
	var file = FileAccess.open(path, FileAccess.READ)
	if file:
		var content = file.get_as_text()
		var json_data = JSON.parse_string(content)
		file.close()
		json_data.erase("rails")
		json_data.erase("notes")
		if json_data.has("difficulty_name"):
			json_data["difficulty_name"] = "New"
			json_data["uuid"] = "0"
			json_data["difficulty_value"] = 0
		var json_name = str(randi_range(100000, 999999)) + ".json"
		var target_file = FileAccess.open(Game.selected_beatmap.folder_path.path_join(json_name) , FileAccess.WRITE)
		if target_file:
			var json_string = JSON.stringify(json_data, "\t")
			target_file.store_string(json_string)
			target_file.close()
		var new_beatmap = Beatmap.new()
		new_beatmap.load_from_json(Game.selected_beatmap.folder_path.path_join(json_name))
		new_beatmap.folder_path = Game.selected_beatmap_set.folder_path
		for child in $MapPanel/VBoxContainer.get_children():
			if child.beatmap_set == Game.selected_beatmap_set:
				child.beatmap_set.beatmaps.append(new_beatmap)
				Game.selected_beatmap = new_beatmap
				child.reload_beatmap()

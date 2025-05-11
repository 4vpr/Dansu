extends Control

@onready var map_panel = $MapPanel/VBoxContainer
var map_scene = load("res://objects/song.tscn")

func _ready() -> void:
	_load()

func _load() -> void:
	var folders = get_folders_in_path(OS.get_user_data_dir().path_join("Songs"))
	folders += get_folders_in_path("res://song/")
	for folder in folders:
		var set = BeatmapSet.new()
		set.load_from_folder(folder)
		if set.beatmaps.size() > 0:
			var new_map = map_scene.instantiate()
			new_map.beatmap_set = set
			map_panel.add_child(new_map)

func get_folders_in_path(path: String) -> Array:
	var dir = DirAccess.open(path)
	var folders = []
	if dir:
		dir.list_dir_begin()
		var file_name = dir.get_next()
		while file_name != "":
			if dir.current_is_dir() and file_name != "." and file_name != "..":
				var sub_path = path.path_join(file_name)
				var sub_dir = DirAccess.open(sub_path)
				if sub_dir and sub_dir.file_exists("song.mp3"):
					folders.append(path + "/" + file_name)
			file_name = dir.get_next()
		dir.list_dir_end()
	else:
		print("something wrong: ", path)
	return folders

	

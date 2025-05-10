extends Control
@onready var map_panel = $MapPanel/VBoxContainer
var map_scene = load("res://objects/song.tscn")
var diff_scene = load("res://objects/diff.tscn")
var old_texture
var new_texture
var shader_mat
func _ready() -> void:
	shader_mat = $Image.material
	shader_mat.set_shader_parameter("previous_tex", old_texture)
	shader_mat.set_shader_parameter("current_tex", new_texture)
	_load()
func _load() -> void:
	var folders = get_folders_in_path(OS.get_user_data_dir().path_join("Songs"))
	folders += get_folders_in_path("res://song/")
	for folder in folders:
		var new_map = map_scene.instantiate()
		new_map.folder = folder
		var json_files = get_json_files_in_path(folder)
		new_map.map = json_files
		if Game.select_map == null:
			Game.select_folder = new_map.folder
			Game.select_map = new_map.map[0]
			pass

		if json_files.size() > 0:
			var json_path = folder.path_join(json_files[0])
			var file = FileAccess.open(json_path, FileAccess.READ)
			if file:
				var content = file.get_as_text()
				var json = JSON.parse_string(content)
				if typeof(json) == TYPE_DICTIONARY and json.has("title"):
					new_map.title = json["title"]
				else:
					new_map.title = "?"
			else:
				new_map.title = "?"

		var image_extensions = [".jpg", ".jpeg", ".png"]
		var dir = DirAccess.open(folder)
		var image_path := ""
		if dir:
			dir.list_dir_begin()
			var file_name = dir.get_next()
			while file_name != "":
				for ext in image_extensions:
					if file_name.to_lower().ends_with(ext):
						image_path = folder.path_join(file_name)
						break
				if image_path != "":
					break
				file_name = dir.get_next()
			dir.list_dir_end()
		if image_path != "":
			var bg_node = new_map.get_node("BG")
			if image_path.contains("res://song/"):
				bg_node.texture = load(image_path)
			else:
				bg_node.texture = ImageTexture.create_from_image(Image.load_from_file(image_path))
		map_panel.add_child(new_map)
func update_bg(i):
	$Image.texture = i
	shader_mat.set_shader_parameter("previous_tex", old_texture)
	shader_mat.set_shader_parameter("current_tex", new_texture)
	shader_mat.set_shader_parameter("mix_amount", 0.0)
	pass
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

func get_json_files_in_path(path: String) -> Array:
	var result = []
	var dir = DirAccess.open(path)
	if dir:
		dir.list_dir_begin()
		var file_name = dir.get_next()
		while file_name != "":
			if not dir.current_is_dir():
				if file_name.ends_with(".json"):
					#result.append(path.path_join(file_name))
					result.append(file_name)
			file_name = dir.get_next()
		dir.list_dir_end()
	return result

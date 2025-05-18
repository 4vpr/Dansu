extends RefCounted
class_name BeatmapSet

var folder_path: String = ""
var meta_title: String = "?"
var cover_image: Texture2D = null
var beatmaps: Array[Beatmap] = []

func load_from_folder(path: String):
	folder_path = path
	var json_files = get_json_files_in_path(path)
	for json_file in json_files:
		var beatmap = Beatmap.new()
		beatmap.folder_path = path
		if beatmap.load_from_json(path.path_join(json_file)):
			beatmaps.append(beatmap)
	if beatmaps.size() > 0:
		meta_title = beatmaps[0].meta_title
		_load_cover_image()

func _load_cover_image():
	var bg_candidates = ["bg.jpg", "bg.jpeg", "bg.png"]
	var image_path = ""

	if folder_path.begins_with("res://"):
		for bg_file in bg_candidates:
			var try_path = folder_path.path_join(bg_file)
			if ResourceLoader.exists(try_path):
				image_path = try_path
				break
	else:
		image_path = _get_bg_path()

	if image_path == "":
		return

	if image_path.begins_with("res://"):
		var texture = load(image_path)
		if texture:
			cover_image = texture
	else:
		if FileAccess.file_exists(folder_path.path_join(image_path)):
			var image = Image.new()
			if image.load(folder_path.path_join(image_path)) == OK:
				cover_image = ImageTexture.create_from_image(image)

func _get_bg_path() -> String:
	var image_extensions = [".jpg", ".jpeg", ".png"]
	var dir = DirAccess.open(folder_path)
	if not dir:
		return ""
	dir.list_dir_begin()
	var file_name = dir.get_next()
	while file_name != "":
		for ext in image_extensions:
			if file_name.to_lower().ends_with(ext):
				dir.list_dir_end()
				return file_name
		file_name = dir.get_next()
	dir.list_dir_end()
	return ""

func get_json_files_in_path(path: String) -> Array:
	var result = []
	var dir = DirAccess.open(path)
	if not dir:
		return result

	dir.list_dir_begin()
	var file_name = dir.get_next()
	while file_name != "":
		if not dir.current_is_dir() and file_name.ends_with(".json"):
			result.append(file_name)
		file_name = dir.get_next()
	dir.list_dir_end()
	return result

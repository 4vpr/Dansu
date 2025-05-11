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
	var image_path = folder_path.path_join("bg.jpg")
	if FileAccess.file_exists(image_path):
		var image = Image.new()
		if image.load(image_path) == OK:
			cover_image = ImageTexture.create_from_image(image)

func get_json_files_in_path(path: String) -> Array:
	var result = []
	var dir = DirAccess.open(path)
	if dir:
		dir.list_dir_begin()
		var file_name = dir.get_next()
		while file_name != "":
			if not dir.current_is_dir() and file_name.ends_with(".json"):
				result.append(file_name)
			file_name = dir.get_next()
		dir.list_dir_end()
	return result

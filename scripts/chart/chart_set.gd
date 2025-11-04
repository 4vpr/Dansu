extends RefCounted
class_name ChartSet

var folder_path: String = ""
var image_path: String = ""
var charts: Array[Chart] = []

func _clear():
	for chart in charts:
		chart._clear()

func _load_cover_image() -> Texture2D:
	var cover_image: Texture2D = null
	var bg_candidates = ["bg.jpg", "bg.jpeg", "bg.png"]
	# 내장맵 불러오기
	if folder_path.begins_with("res://"):
		for bg_file in bg_candidates:
			var try_path = folder_path.path_join(bg_file)
			if ResourceLoader.exists(try_path):
				image_path = try_path
				break
	# 유저맵 불러오기
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
	return cover_image

func _get_bg_path() -> String:
	var image_extensions = [".jpg", ".jpeg", ".png" , ".webp"]
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

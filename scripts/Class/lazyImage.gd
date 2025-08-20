extends TextureRect
class_name LazyImage

@export_file("*.png", "*.jpg", "*.jpeg") var image_path: String
var _loaded := false

func ensure_loaded() -> void:
	if _loaded:
		return
	if image_path.is_empty():
		return
	texture = load(image_path) as Texture2D
	_loaded = texture != null

func ensure_unloaded() -> void:
	if not _loaded:
		return
	texture = null
	_loaded = false

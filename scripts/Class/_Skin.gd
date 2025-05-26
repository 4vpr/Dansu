extends RefCounted
class_name PlayerSkin

var player_animation = {}
var animations = []

var name: String = "none"
var is_built_in: bool = false

var folder_path: String = ""
var json_path: String = ""

var texture_cache = {}

func load_from_json(path: String) -> bool:
	var file = FileAccess.open(path, FileAccess.READ)
	if not file:
		return false

	var json = JSON.parse_string(file.get_as_text())
	if typeof(json) != TYPE_DICTIONARY:
		return false

	var fields = {
		"name": ["name", "?"],
	}
	for var_name in fields:
		var json_key = fields[var_name][0]
		var default_value = fields[var_name][1]
		set(var_name, json.get(json_key, default_value))

	json_path = path
	return true

func parse_objects():
	var file = FileAccess.open(json_path, FileAccess.READ)
	if not file:
		print("not found")
		print(json_path)
		return
	var json = JSON.parse_string(file.get_as_text())
	animations.clear()
	player_animation.clear()
	if "animations" in json:
		for animation in json["animations"]:
			var frames = animation.get("frames", [])
			var texture_frames = []
			#var texture_filenames = []
			for frame in frames:
				var texture = _load_texture(frame)
				if texture:
					texture_frames.append(texture)
			var anim_data = {
				"id": animation.get("id", -1),
				"frames": texture_frames,
				"fps": animation.get("fps", 10),
				"effect": animation.get("effect", "none")
			}
			animations.append(anim_data)

	if "player" in json:
		player_animation = json["player"]

func _load_texture(file_name: String) -> Texture2D:
	if texture_cache.has(file_name):
		return texture_cache[file_name]

	var texture_path = folder_path.path_join("sprite/" + file_name)
	var texture: Texture2D = null

	if texture_path.begins_with("res://"):
		texture = load(texture_path)
		if texture == null:
			texture = load("res://Textures/no texture.png")
	elif FileAccess.file_exists(texture_path):
		var image = Image.new()
		if image.load(texture_path) == OK:
			texture = ImageTexture.create_from_image(image)
		else:
			texture = load("res://Textures/no texture.png")

	if texture:
		texture_cache[file_name] = texture

	return texture

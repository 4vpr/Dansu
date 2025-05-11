extends RefCounted
class_name Beatmap

var notes = []
var rails = []
var animations = []
var player_animation = {}

var meta_title: String = "?"
var meta_artist: String = "unknown"
var meta_creator: String = "unknown"

var file_song: String = "song.mp3"
var file_bg: String = "bg.jpg"

var diff_name: String = "?"
var diff_value: float = 0
var song_bpmstart: float = 0
var song_lerp: float = 0
var song_bpm: float = 100
var is_built_in: bool = false

var folder_path: String = ""
var json_path: String = ""

var rail_scene = load("res://objects/rail.tscn")
var note_scene = load("res://objects/note.tscn")
var rail_scene_editor = load("res://objects/editor/rail.tscn")
var note_scene_editor = load("res://objects/editor/note.tscn")


func load_from_json(path: String) -> bool:
	var file = FileAccess.open(path, FileAccess.READ)
	if file:
		var json = JSON.parse_string(file.get_as_text())
		if typeof(json) == TYPE_DICTIONARY:
			meta_title = json.get("title", "?")
			meta_artist = json.get("artist", "unknown")
			meta_creator = json.get("creator", "unknown")
			song_bpm = json.get("bpm", 100)
			diff_name = json.get("difficulty_name", "?")
			diff_value = json.get("difficulty_value", 0)
			json_path = path
			return true
	return false

func parse_objects():
	var file = FileAccess.open(json_path, FileAccess.READ)
	var json
	if file:
		json = JSON.parse_string(file.get_as_text())
	rails.clear()
	notes.clear()
	if "rails" in json:
		for rail_data in json["rails"]:
			var new_rail = rail_scene.instantiate()
			new_rail.id = rail_data.get("id", -1)
			new_rail.start = rail_data.get("start", -1)
			new_rail.end = rail_data.get("end", -1)
			new_rail.moves = rail_data.get("move", [])
			new_rail.position.x = rail_data.get("position", 0.0)
			rails.append(new_rail)

	rails.sort_custom(func(a, b): return a.start < b.start)

	if "notes" in json:
		for note_data in json["notes"]:
			var new_note = note_scene.instantiate()
			new_note.type = note_data.get("type", 0)
			new_note.time = note_data.get("time", 0)
			new_note.rail = note_data.get("rail", 0)
			new_note.dir = note_data.get("dir", 0)
			new_note.animation = note_data.get("animation", 0)
			notes.append(new_note)
	notes.sort_custom(func(a, b): return a.time < b.time)
	load_player_resources(json)

func parse_objects_editor():
	var file = FileAccess.open(json_path, FileAccess.READ)
	var json
	if file:
		json = JSON.parse_string(file.get_as_text())
	rails.clear()
	notes.clear()
	if "rails" in json:
		for rail_data in json["rails"]:
			var new_rail = rail_scene_editor.instantiate()
			new_rail.id = rail_data.get("id", -1)
			new_rail.start = rail_data.get("start", -1)
			new_rail.end = rail_data.get("end", -1)
			new_rail.moves = rail_data.get("move", [])
			new_rail.pos = rail_data.get("position", 0.0)
			rails.append(new_rail)
	rails.sort_custom(func(a, b): return a.start < b.start)
	if "notes" in json:
		for note_data in json["notes"]:
			var new_note = note_scene_editor.instantiate()
			new_note.type = note_data.get("type", 0)
			new_note.time = note_data.get("time", 0)
			new_note.rail = note_data.get("rail", 0)
			new_note.dir = note_data.get("dir", 0)
			new_note.animation = note_data.get("animation", 0)
			notes.append(new_note)
	notes.sort_custom(func(a, b): return a.time < b.time)
	load_player_resources(json,true)

func load_song(player: AudioStreamPlayer) -> bool:
	var song_path = folder_path.path_join(file_song)
	print(song_path)
	if FileAccess.file_exists(song_path):
		var song_file = FileAccess.open(song_path, FileAccess.READ)
		var song_stream = AudioStreamMP3.new()
		song_stream.data = song_file.get_buffer(song_file.get_length())
		player.stream = song_stream
		return true
	return false

var texture_cache = {}  # 파일명 -> Texture2D 캐시

func load_player_resources(json, save_filenames := false):
	animations.clear()
	player_animation.clear()

	if "animations" in json:
		for animation in json["animations"]:
			var frames = animation.get("frames", [])
			var texture_frames = []
			var texture_filenames = []

			for frame in frames:
				var texture = _load_texture(frame)
				if texture:
					texture_frames.append(texture)
					if save_filenames:
						texture_filenames.append(frame)

			var anim_data = {
				"id": animation.get("id", -1),
				"frames": texture_frames,
				"fps": animation.get("fps", 1),
				"effect": animation.get("effect", "none")
			}

			if save_filenames:
				anim_data["frame_filenames"] = texture_filenames
				anim_data["name"] = animation.get("name", "none")

			animations.append(anim_data)

	if "player" in json:
		player_animation = json["player"]

func _load_texture(file_name: String) -> Texture2D:
	if texture_cache.has(file_name):
		return texture_cache[file_name]

	var texture_path = folder_path.path_join("sprite/" + file_name)
	if texture_path.contains("res://"):
		var res_texture = load(texture_path)
		if res_texture:
			texture_cache[file_name] = res_texture
			return res_texture

	var image = Image.new()
	if image.load(texture_path) == OK:
		var texture = ImageTexture.create_from_image(image)
		texture_cache[file_name] = texture
		return texture

	return null

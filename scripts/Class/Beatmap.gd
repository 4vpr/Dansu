extends RefCounted
class_name Beatmap

var notes = []
var rails = []
var animations = []
var player_animation = {}

var map_uuid: String = "0"
var meta_title: String = "?"
var meta_artist: String = "unknown"
var meta_creator: String = "unknown"
var file_audio: String = "song.mp3"

var diff_name: String = "?"
var diff_value: float = 0
var song_bpmstart: float = 0
var song_lerp: float = 0
var song_bpm: float = 100
var is_built_in: bool = false
var use_default_skin: bool = true

var folder_path: String = ""
var json_path: String = ""
var json_file

var rail_scene = load("res://objects/rail.tscn")
var note_scene = load("res://objects/note.tscn")
var rail_scene_editor = load("res://objects/editor/rail.tscn")
var note_scene_editor = load("res://objects/editor/note.tscn")

var texture_cache = {}

func get_json():
	var path = folder_path.path_join(json_path)
	var file = FileAccess.open(path, FileAccess.READ)
	if not file:
		return false
	var json = JSON.parse_string(file.get_as_text())
	return json
func parse_meta():
	var fields = {
		"map_uuid": ["uuid", map_uuid],
		"meta_title": ["title", "?"],
		"meta_artist": ["artist", "unknown"],
		"meta_creator": ["creator", "unknown"],
		"song_bpm": ["bpm", 100],
		"song_bpmstart": ["bpmstart", 0],
		"diff_name": ["difficulty_name", "New"],
		"diff_value": ["difficulty_value", 0],
		"use_default_skin": ["use_default_skin", true],
		"file_audio": ["file_audio","song.mp3"]
	}
	for var_name in fields:
		var json_key = fields[var_name][0]
		var default_value = fields[var_name][1]
		set(var_name, json_file.get(json_key, default_value))
	return true
func parse_notes(is_editor: bool = false):
	var _notes = []
	var note_scene_to_use = note_scene_editor if is_editor else note_scene
	if "notes" in json_file:
		for note_data in json_file["notes"]:
			var new_note = note_scene_to_use.instantiate()
			new_note.type = note_data.get("type", 0)
			new_note.time = note_data.get("time", 0)
			new_note.rail = note_data.get("rail", 0)
			new_note.dir = note_data.get("dir", 0)
			new_note.animation = note_data.get("animation", 0)
			notes.append(new_note)
	notes.sort_custom(func(a, b): return a.time < b.time)
	return _notes
func parse_rails(is_editor: bool = false):
	var _rails = []
	rails.clear()
	var rail_scene_to_use = rail_scene_editor if is_editor else rail_scene
	if "rails" in json_file:
		for rail_data in json_file["rails"]:
			var new_rail = rail_scene_to_use.instantiate()
			new_rail.id = rail_data.get("id", -1)
			new_rail.start = rail_data.get("start", -1)
			new_rail.end = rail_data.get("end", -1)
			new_rail.moves = rail_data.get("move", [])
			if is_editor:
				new_rail.pos = rail_data.get("position", 0.0)
			else:
				new_rail.position.x = rail_data.get("position", 0.0)
			rails.append(new_rail)
	rails.sort_custom(func(a, b): return a.start < b.start)
	return _rails



func load_from_json(path: String) -> bool:
	var file = FileAccess.open(path, FileAccess.READ)
	if not file:
		return false
	var json = JSON.parse_string(file.get_as_text())
	if typeof(json) != TYPE_DICTIONARY:
		return false
	if map_uuid == "0":
		pass
	var fields = {
		"map_uuid": ["uuid", "0"],
		"meta_title": ["title", "?"],
		"meta_artist": ["artist", "unknown"],
		"meta_creator": ["creator", "unknown"],
		"song_bpm": ["bpm", 100],
		"song_bpmstart": ["bpmstart", 0],
		"diff_name": ["difficulty_name", "New"],
		"diff_value": ["difficulty_value", 0],
		"use_default_skin": ["use_default_skin", true],
		"file_audio": ["file_audio","song.mp3"]
	}
	for var_name in fields:
		var json_key = fields[var_name][0]
		var default_value = fields[var_name][1]
		set(var_name, json.get(json_key, default_value))

	json_path = path
	return true

func parse_objects(is_editor: bool = false):
	var file = FileAccess.open(json_path, FileAccess.READ)
	if not file:
		return

	var json = JSON.parse_string(file.get_as_text())
	rails.clear()
	notes.clear()

	var rail_scene_to_use = rail_scene_editor if is_editor else rail_scene
	var note_scene_to_use = note_scene_editor if is_editor else note_scene

	if "rails" in json:
		for rail_data in json["rails"]:
			var new_rail = rail_scene_to_use.instantiate()
			new_rail.id = rail_data.get("id", -1)
			new_rail.start = rail_data.get("start", -1)
			new_rail.end = rail_data.get("end", -1)
			new_rail.moves = rail_data.get("move", [])
			if is_editor:
				new_rail.pos = rail_data.get("position", 0.0)
			else:
				new_rail.position.x = rail_data.get("position", 0.0)
			rails.append(new_rail)
	rails.sort_custom(func(a, b): return a.start < b.start)

	if "notes" in json:
		for note_data in json["notes"]:
			var new_note = note_scene_to_use.instantiate()
			new_note.type = note_data.get("type", 0)
			new_note.time = note_data.get("time", 0)
			new_note.rail = note_data.get("rail", 0)
			new_note.dir = note_data.get("dir", 0)
			new_note.animation = note_data.get("animation", 0)
			notes.append(new_note)
	notes.sort_custom(func(a, b): return a.time < b.time)

	load_player_resources(json, is_editor)
func _clear() -> void:
	notes.clear()
	rails.clear()
	animations.clear()
	player_animation.clear()
	texture_cache.clear()

func load_song(player: AudioStreamPlayer) -> bool:
	var _path = folder_path.path_join(file_audio)
	var stream: AudioStream = null

	# 리소스 경로일 경우
	if _path.begins_with("res://"):
		stream = load(_path)
	else:
		# 외부 파일일 경우 확장자 확인
		if !FileAccess.file_exists(_path):
			return false

		var ext = _path.get_extension().to_lower()
		var file = FileAccess.open(_path, FileAccess.READ)
		if file:
			var data = file.get_buffer(file.get_length())
			match ext:
				"ogg_FIX":
					var parts = folder_path.split("Songs/")
					if parts.size() > 1:
						var relative_path = "Songs/" + parts[1]
						#var ogg = AudioStreamOggVorbis.new()
						var user_folder = "user://" + relative_path
						print("user://: ", ProjectSettings.globalize_path("user://"))
						print(user_folder.path_join(file_audio))
						stream = load(user_folder.path_join(file_audio))
				"wav_FIX":
					var wav = AudioStreamWAV.new()
					wav.data = data
					stream = wav
				"mp3":
					var mp3 = AudioStreamMP3.new()
					mp3.data = data
					stream = mp3
				_:
					return false

	if stream == null:
		return false

	# mp3가 아닌 경우만 Interactive로 래핑
	if not (stream is AudioStreamMP3):
		var interactive := AudioStreamInteractive.new()
		interactive.stream = stream
		player.stream = interactive
	else:
		player.stream = stream

	return true

func load_player_resources(json, save_filenames := false):
	animations.clear()
	player_animation.clear()

	if "animations" in json:
		for animation in json["animations"]:
			var frames = animation.get("frames", [])
			var texture_frames = []
			var texture_filenames = []
			#frame = 파일명 (sprite1.png)
			for frame in frames:
				var texture = _load_texture(frame)
				if texture:
					texture_frames.append(texture)
					if save_filenames:
						texture_filenames.append(frame)
			var anim_data = {
				"id": animation.get("id", -1),
				"frames": texture_frames,
				"fps": animation.get("fps", 10),
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
	
func get_hash() -> String:
	var hash_data = ""
	for rail in rails:
		hash_data += str(rail.id)
		hash_data += str(rail.start)
		hash_data += str(rail.end)
	for note in notes:
		hash_data += str(note.type)
		hash_data += str(note.time)
		hash_data += str(note.dir)
		hash_data += str(note.rail)

	var context = HashingContext.new()
	context.start(HashingContext.HASH_MD5)
	context.update(hash_data.to_utf8_buffer())
	var hash_result = context.finish()
	var hex_str = hash_result.hex_encode()

	var integrity_id = hex_str.substr(0, 8)
	#print("[integrity_id] " + integrity_id)

	return integrity_id
	

func generate_uuid() -> String:
	var hex_chars = "0123456789abcdef"
	var uuid = ""
	for i in range(32):
		uuid += hex_chars[randi() % 16]
		if i in [7, 11, 15, 19]:
			uuid += "-"
	return uuid

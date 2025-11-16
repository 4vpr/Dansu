extends RefCounted
class_name Chart

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

var folder_name: String = ""
var json_name: String = ""

var rail_scene = load("res://Scene/Entity/rail.tscn")
var note_scene = load("res://Scene/Entity/note.tscn")
var rail_scene_editor = load("res://Scene/Entity/Editor/rail.tscn")
var note_scene_editor = load("res://Scene/Entity/Editor/note.tscn")

func get_json():
	var path = Game.SONG_PATH.path_join(folder_name).path_join(json_name)
	var file = FileAccess.open(path, FileAccess.READ)
	if not file:
		return false
	var json = JSON.parse_string(file.get_as_text())
	return json

func get_difficulty(json = get_json()) -> float:
	return Rating.calculate_difficulty(json)

func parse_notes(json = get_json(), is_editor: bool = false):
	var _notes = []
	var note_scene_to_use = note_scene_editor if is_editor else note_scene
	if "notes" in json:
		for note_data in json["notes"]:
			var new_note = note_scene_to_use.instantiate()
			new_note.type = note_data.get("type", 0)
			new_note.time = note_data.get("time", 0)
			new_note.rail = note_data.get("rail", 0)
			new_note.dir = note_data.get("dir", 0)
			new_note.animation = note_data.get("animation", 0)
			_notes.append(new_note)
	_notes.sort_custom(func(a, b): return a.time < b.time)
	return _notes

func parse_rails(json = get_json(), is_editor: bool = false):
	var _rails = []
	var rail_scene_to_use = rail_scene_editor if is_editor else rail_scene
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
				new_rail.pos = rail_data.get("position", 0.0)
				new_rail.position.x = rail_data.get("position", 0.0)
			_rails.append(new_rail)
	_rails.sort_custom(func(a, b): return a.start < b.start)
	return _rails

func load_song(player: AudioStreamPlayer) -> bool:
	var _path = Game.SONG_PATH.path_join(folder_name).path_join(file_audio)
	var stream: AudioStream = null

	if _path.begins_with("res://"):
		stream = load(_path)
	
	else:
		if !FileAccess.file_exists(_path):
			return false

		var ext = _path.get_extension().to_lower()
		var file = FileAccess.open(_path, FileAccess.READ)
		if file:
			var data = file.get_buffer(file.get_length())
			match ext:
				"ogg_FIX":
					#var parts = folder_path.split("Songs/")
					#if parts.size() > 1:
						#var relative_path = "Songs/" + parts[1]
						##var ogg = AudioStreamOggVorbis.new()
						#var user_folder = "user://" + relative_path
						#print("user://: ", ProjectSettings.globalize_path("user://"))
						#print(user_folder.path_join(file_audio))
						#stream = load(user_folder.path_join(file_audio))
						pass
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

	if not (stream is AudioStreamMP3):
		var interactive := AudioStreamInteractive.new()
		interactive.stream = stream
		player.stream = interactive
	else:
		player.stream = stream

	return true

func load_animation(save_filenames := false):
	var json = get_json()
	var animations = []
	if "animations" in json:
		for animation in json["animations"]:
			var frames = animation.get("frames", [])
			var loaded_frames = []
			var frame_filenames = []
			for frame in frames:
				var texture = _load_texture(frame)
				if texture:
					loaded_frames.append(texture)
					if save_filenames:
						frame_filenames.append(frame)
			var anim_data = {
				"id": animation.get("id", -1),
				"frames": loaded_frames,
				"fps": animation.get("fps", 10),
				"effect": animation.get("effect", "none")
			}
			if save_filenames:
				anim_data["frame_filenames"] = frame_filenames
				anim_data["name"] = animation.get("name", "none")
			animations.append(anim_data)

func _load_texture(file_name: String) -> Texture2D:

	var texture_path = Game.SONG_PATH.path_join(folder_name).path_join("sprite").path_join(file_name)
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
	return texture
	
func get_hash(rails,notes) -> String:
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
	return integrity_id

func compute_hash_from_json() -> String:
	var json = get_json()
	var hash_data := ""
	var rails_arr: Array = json.get("rails", [])
	var notes_arr: Array = json.get("notes", [])

	# Sort deterministically like parse_rails/notes would do
	rails_arr.sort_custom(func(a, b):
		return (a.get("start", -1) < b.get("start", -1))
	)
	notes_arr.sort_custom(func(a, b):
		return (a.get("time", 0) < b.get("time", 0))
	)

	for rail in rails_arr:
		hash_data += str(rail.get("id", -1))
		hash_data += str(rail.get("start", -1))
		hash_data += str(rail.get("end", -1))

	for note in notes_arr:
		hash_data += str(note.get("type", 0))
		hash_data += str(note.get("time", 0))
		hash_data += str(note.get("dir", 0))
		hash_data += str(note.get("rail", 0))

	var context := HashingContext.new()
	context.start(HashingContext.HASH_MD5)
	context.update(hash_data.to_utf8_buffer())
	var hash_result := context.finish()
	var hex_str := hash_result.hex_encode()
	return hex_str.substr(0, 8)

func generate_uuid() -> String:
	var hex_chars = "0123456789abcdef"
	var uuid = ""
	for i in range(32):
		uuid += hex_chars[randi() % 16]
		if i in [7, 11, 15, 19]:
			uuid += "-"
	return uuid

func parse_meta(json):
	var fields = {
		"map_uuid": ["uuid", map_uuid],
		"meta_title": ["title", ""],
		"meta_artist": ["artist", "unknown"],
		"meta_creator": ["creator", "unknown"],
		"song_bpm": ["bpm", 100],
		"song_bpmstart": ["bpmstart", 0],
		"diff_name": ["difficulty_name", "new"],
		"diff_value": ["difficulty_value", 0],
		"use_default_skin": ["use_default_skin", true],
		"file_audio": ["file_audio","song.mp3"]
	}
	for var_name in fields:
		var json_key = fields[var_name][0]
		var default_value = fields[var_name][1]
		set(var_name, json.get(json_key, default_value))
	diff_value = get_difficulty()
	return true

func save_to_json(notes,rails,player_animation,animations):
	var json_data = {}
	json_data["file_audio"] = file_audio
	json_data["title"] = meta_title
	json_data["artist"] = meta_artist
	json_data["creator"] = meta_creator
	json_data["bpm"] = song_bpm
	json_data["bpmstart"] = song_bpmstart
	if map_uuid == "0":
		map_uuid = generate_uuid()
	json_data["uuid"] = map_uuid
	json_data["difficulty_name"] = diff_name
	json_data["difficulty_value"] = diff_value
	if !player_animation.is_empty() && animations.size() > 0:
		json_data["player"] = {
			"idle": player_animation["idle"],
			"left": player_animation["left"],
			"right": player_animation["right"],
			"jump": player_animation["jump"],
			"land": player_animation["land"],
			"defaultdance": player_animation["defaultdance"]
			}
		json_data["use_default_skin"] = false
	else:
		json_data["use_default_skin"] = true
	json_data["animations"] = []
	for animation in animations:
		json_data["animations"].append({
		"id": animation["id"],
		"frames": animation["frame_filenames"],
		"fps": animation["fps"],
		"name": animation["name"],
		"effect": animation["effect"]
		})
	json_data["rails"] = []
	for rail in rails:
		if rail.visible == true:
			json_data["rails"].append({
				"id": rail.id,
				"end": rail.end,
				"move": rail.moves,
				"start": rail.start,
				"position": rail.pos
				})
	json_data["notes"] = []
	for note in notes:
		if note.visible && note.hasrail:
			json_data["notes"].append({
				"type": int(note.type),
				"time": int(note.time),
				"rail": int(note.rail),
				"dir": int(note.dir),
				"animation": note.animation
				})
	var path = Game.SONG_PATH.path_join(folder_name).path_join(json_name)
	var file = FileAccess.open(path, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(json_data, "\t"))
		file.close()
		print("JSON Saved!:", path)
	else:
		print("JSON failed to save")

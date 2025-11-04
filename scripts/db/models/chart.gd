extends Model
class_name Chart

# SCENES
var rail_scene = load("res://scene/entity/rail.tscn")
var note_scene = load("res://scene/entity/note.tscn")
var rail_scene_editor = load("res://scene/entity/editor/rail.tscn")
var note_scene_editor = load("res://scene/entity/editor/note.tscn")

# KEYS
var id_local: int = 0
var id_online: int = 0
var chartset_id: int = 0
var hash: String = ""

# OBJECTS
var notes: Array[Node3D] = []
var rails: Array[Node3D] = []
var animations = []
var player_animation = {}

# META
var title: String = "?"
var artist: String = "unknown"
var creator: String = "unknown"
var name: String = "unkown"
var audio_file: String = "song.mp3"
var tags: String
var rating: float = 0

# SONG
var song_preview: float = 0
var song_start: float = 0
var song_bpms: Array[Dictionary] = [{
	"bpm" : 100,
	"time" : 0
}]

# FILE
var is_built_in: bool = false # res:// for true
var use_default_skin: bool = true

var folder_name: String = ""
var json_name: String = ""

# JSON MAP
var map = {
	"title": ["title", "?"],
	"artist": ["artist", "?"],
	"creator": ["creator", "?"],
	"name": ["name", "?"],
	"use_default_skin": ["use_default_skin", true],
	"file_audio": ["file_audio","song.mp3"]
}
# DB FIELDS
static func fields() -> Dictionary:
	return {
		"username": Field.Text("", false, true),
	}
var texture_cache = {}

func get_json():
	var json_path = Consts.song_folder.path_join(folder_name).path_join(json_name)
	var file = FileAccess.open(json_path, FileAccess.READ)
	if not file:
		return false
	var json = JSON.parse_string(file.get_as_text())
	return json

func parse_meta(json_file):
	for var_name in map:
		var key = map[var_name][0]
		var value = map[var_name][1]
		set(var_name, json_file.get(key, value))
	rating = Rating.calculate(get_json())

func parse_notes(json_file, is_editor: bool = false):
	var json = get_json()
	var _notes = []
	var note_scene_to_use = note_scene_editor if is_editor else note_scene
	if "notes" in json:
		for note_data in json_file["notes"]:
			var new_note = note_scene_to_use.instantiate()
			new_note.type = note_data.get("type", 0)
			new_note.time = note_data.get("time", 0)
			new_note.rail = note_data.get("rail", 0)
			new_note.dir = note_data.get("dir", 0)
			new_note.animation = note_data.get("animation", 0)
			notes.append(new_note)
	notes.sort_custom(func(a, b): return a.time < b.time)
	notes = _notes

func parse_rails(json_file, is_editor: bool = false):
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
				new_rail.pos = rail_data.get("position", 0.0)
				new_rail.position.x = rail_data.get("position", 0.0)
			rails.append(new_rail)
	rails.sort_custom(func(a, b): return a.start < b.start)
	rails = _rails
	return _rails

func _clear() -> void:
	notes.clear()
	rails.clear()
	animations.clear()
	player_animation.clear()
	texture_cache.clear()

func load_song(player: AudioStreamPlayer) -> bool:
	var _path = Consts.song_folder.path_join(folder_name).path_join(audio_file)
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
				"ogg":
						stream = load(_path)
				"wav":
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

	var texture_path = Consts.song_folder.path_join(folder_name).path_join("sprite").path_join(file_name)
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

func create_hash():
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
	var integrity_id = hex_str.substr(0, 255)
	hash = integrity_id

func generate_uuid() -> String:
	var hex_chars = "0123456789abcdef"
	var uuid = ""
	for i in range(32):
		uuid += hex_chars[randi() % 16]
		if i in [7, 11, 15, 19]:
			uuid += "-"
	return uuid

static func table() -> String: return "charts"

func _init() -> void:
	_defaults()

static func objects_for(db: DansuDB) -> QuerySet:
	return Model.objects(db, User)

static func ensure_table_for(db: DansuDB) -> void:
	Model.ensure_table(db, User)

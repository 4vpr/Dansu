extends Control
var paused_position = 0.0
var is_dragging = false
var was_playing = false
var player_animation = {}
var animations = []
var beatsdiv = 2
var sfx_pool = SfxPool.new()
var beatmap = Beatmap.new()
@onready var B_Pause = $SongControl/B_Pause;@onready var SongSlider = $SongSlider
@onready var B_Remove = $NoteControl/B_Remove;@onready var B_Save = $NoteControl/B_Save
@onready var B_AddNote = $NoteControl/B_Note;@onready var B_AddRight = $NoteControl/B_Right
@onready var B_AddLeft = $NoteControl/B_Left;@onready var B_AddRail = $NoteControl/B_Rail
@onready var Inspecter = $Inspecter;@onready var Song = $AudioStreamPlayer
@onready var RailContainer = $Preview/RailContainer;@onready var B_Animation = $animation
@onready var Win_Animation = $Animation
var user_dir = OS.get_user_data_dir()
var SongIsPlaying = false
var map_data = {}
var exe_dir = OS.get_executable_path().get_base_dir()
var map_path = Game.select_folder.path_join(Game.select_map)
var song_path = Game.select_folder.path_join("song.mp3")
var rail_scene = load("res://objects/editor/rail.tscn")
var note_scene = load("res://objects/editor/note.tscn")
var selected = null
var everything = {}; var undoredo = {}; var undoredo_i = 0
var rails = []; var notes = []
var rail_scope = null
func scope_rail():
	if selected != null:
		if selected.get("rail") != null:
			for rail in rails:
				if rail.id == selected.get("rail"):
					rail_scope = rail
		else:
			rail_scope = selected
func rail_check():
	for rail in rails:
		if not rail.get_parent() == RailContainer:
			if rail.start < Game.currentTime + 1000 && rail.end > Game.currentTime + 200:
				RailContainer.add_child(rail)
				for note in notes:
					if rail.id == note.rail && not note.get_parent():
						rail.notes.add_child(note)
				rail._update()
			else:
				if rail.get_parent() == RailContainer:
					RailContainer.remove_child(rail)
	for rail in RailContainer.get_children():
		rail.position.y = (Game.currentTime - rail.start) * Game.editor_velocity - rail.size.y - 100
func save_files():
	pass
func undo():
	pass
func redo():
	pass
func check_drag():
	if selected != null:
		var offset
		if selected.dragging:
			offset = get_global_mouse_position() - selected.offset
			if selected.get("time") != null:
				selected.time = selected.time_offset - (offset.y / Game.editor_velocity)
				selected.time = snap_to_bpm(selected.time)
				pass
			if selected.get("start") != null:
				pass
			selected._update()
			#Inspecter._update(selected)
func save_everything():
	pass
func create_note(type,dir = 0):
	var new_note = note_scene.instantiate()
	var time = snap_to_bpm(Game.currentTime)
	for note in notes:
		if round(note.time) == round(time):
			notes.erase(note)
			note.queue_free()
	if selected != null:
		print("works")
		new_note.type = type
		new_note.time = time
		print(Game.currentTime)
		new_note.rail = rail_scope.id
		new_note.dir = dir
		new_note.animation = 0
		notes.push_back(new_note)
		rail_scope.notes.add_child(new_note)
		rail_scope._update()
		selected = new_note
func create_rail():
	var new_rail = rail_scene.instantiate()
	new_rail.start = Game.currentTime - 50
	var used_ids := {}
	for rail in rails:
		used_ids[rail.id] = true
	var i = 1
	while used_ids.has(i):
		i += 1
	new_rail.id = i
	new_rail.end = Game.currentTime + 500
	new_rail.pos = 0
	selected = new_rail
	rails.push_back(new_rail)
	pass

func snap_to_bpm(timing: float,division: int = beatsdiv) -> float:
	var beat_interval = 60000 / beatmap.song_bpm
	var snap_interval = beat_interval / division
	print(beat_interval)
	var relative_timing = timing - beatmap.song_bpmstart
	
	var snapped_timing = round(relative_timing / snap_interval) * snap_interval + beatmap.song_bpmstart
	return snapped_timing


func load_files() -> Dictionary:
	var song_stream = AudioStreamMP3.new()
	var song_file = FileAccess.open(song_path, FileAccess.READ)
	if song_file:
		print("song loaded")
		song_stream.data = song_file.get_buffer(song_file.get_length())
		SongSlider.max_value = song_stream.get_length()
		Song.stream = song_stream
		Song.finished.connect(_on_song_finished)
	else:
		print("no song found")
	if not FileAccess.file_exists(map_path):
		print("theres no map.json:", map_path)
		return {}
	var map_file = FileAccess.open(map_path, FileAccess.READ)
	var content = map_file.get_as_text()
	var json_result = JSON.parse_string(content)
	if json_result is Dictionary:
		return json_result
	else:
		print("reading json failed")
		return {}


var clipboard
func copy() -> void:
	clipboard = selected.duplicate()
	print(clipboard.id)

func paste() -> void:
	if clipboard != null:
		if clipboard.get("id") != null:
				var new_rail = rail_scene.instantiate()
				new_rail.start = Game.currentTime
				var i = 1
				for rail in rails:
					if rail.id == i:
						i += 1
					else:
						break
				new_rail.id = i
				new_rail.end = clipboard.end - clipboard.start + Game.currentTime
				new_rail.pos = clipboard.pos
				selected = new_rail
				RailContainer.add_child(new_rail)
				for note in clipboard.notes.get_children():
					var new_note = note_scene.instantiate()
					new_note.type = note.type
					new_note.time = Game.currentTime - clipboard.start + note.time
					new_note.dir = note.dir
					new_note.id = i
					new_note.animation = note.animation
					notes.push_back(new_note)
func _ready() -> void:
	Game.currentTime = 0
	Song.volume_db = linear_to_db(Game.volume)
	add_child(sfx_pool)
	for button in get_tree().get_nodes_in_group("ui_buttons"):
		button.focus_mode = Control.FOCUS_NONE
	parse_data(load_files())
	var fields = {
		"meta_title": TYPE_STRING,
		"meta_artist": TYPE_STRING,
		"song_bpm": TYPE_FLOAT,
		"song_bpmstart": TYPE_FLOAT
		}
	for name in fields:
		var field = find_child(name, true, false)
		if field is LineEdit:
			field.text = str(get(name))
			field.text_changed.connect(func(new_text): set(name, new_text))
			
			
	B_Pause.pressed.connect(_on_pause_pressed)
	B_AddNote.pressed.connect(create_note.bind(1))
	B_AddLeft.pressed.connect(create_note.bind(2,2))
	B_AddRight.pressed.connect(create_note.bind(2,4))
	B_Save.pressed.connect(save_to_json)
	B_AddRail.pressed.connect(create_rail)
	B_Remove.pressed.connect(_on_remove_pressed)
	SongSlider.value_changed.connect(_on_slider_changed)
	
var nextHitSound = -INF
func _process(delta: float) -> void:
	if Input.is_action_just_pressed("ui_cancel"):
		save_files()
		get_tree().change_scene_to_file("res://Scene/SongSelect.tscn")
		print("exit")
	rail_check()
	check_drag()
	scope_rail()
	if Input.is_action_just_pressed("ui_copy"):
		copy()
	if Input.is_action_just_pressed("ui_paste"):
		paste()
	if SongIsPlaying and not is_dragging:
		SongSlider.value = Song.get_playback_position()
		Game.currentTime = Song.get_playback_position() * 1000
		var h = INF
		if Game.currentTime > nextHitSound:
			if nextHitSound > 0:
				sfx_pool.play_sound(preload("res://Resources/normal-hitnormal.wav"))
				nextHitSound = INF
			for note in notes:
				if note.time > Game.currentTime &&  note.time < h:
					nextHitSound = note.time
					h = note.time
			if Game.currentTime > h:
				nextHitSound = INF
	else:
		Game.currentTime = SongSlider.value * 1000
		nextHitSound = -INF
func snap_notes():
	for note in notes:
		note.time = snap_to_bpm(note.time)
		
func save_to_json():
	var json_data = {}
	json_data["title"] = beatmap.meta_title
	json_data["artist"] = beatmap.meta_artist
	json_data["creator"] = beatmap.meta_creator
	json_data["difficulty"] = beatmap.diff_value
	json_data["bpm"] = beatmap.song_bpm
	json_data["bpmstart"] = beatmap.song_bpmstart
	json_data["player"] = {
		"idle": player_animation["idle"],
		"left": player_animation["left"],
		"right": player_animation["right"],
		"jump": player_animation["jump"],
		"land": player_animation["land"],
		"defaultdance": player_animation["defaultdance"]
		}
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
		json_data["rails"].append({
			"id": rail.id,
			"end": rail.end,
			"move": rail.moves,
			"start": rail.start,
			"position": rail.pos
			})
	json_data["notes"] = []
	for note in notes:
		json_data["notes"].append({
			"type": note.type,
			"time": note.time,
			"rail": note.rail,
			"dir": note.dir,
			"animation": note.animation
			})
	var file = FileAccess.open(map_path, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(json_data, "\t"))  # JSON 변환 후 저장
		file.close()
		print("JSON 파일 저장 완료:", map_path)
	else:
		print("JSON 파일 저장 실패")

var texture_cache = {} # 파일명을 키로, Texture2D를 값으로 저장
func get_texture(file_name):
	if file_name in texture_cache:
		return texture_cache[file_name] # 캐싱된 텍스처 반환
	var texture_path = Game.select_folder.path_join("/sprite/" + file_name)
	var image = Image.new()
	if image.load(texture_path) == OK:
		var texture = ImageTexture.create_from_image(image)
		texture_cache[file_name] = texture
		return texture
func parse_data(json_data):
	beatmap.meta_title = json_data.get("title", "?")
	beatmap.meta_artist = json_data.get("artist", "?")
	beatmap.meta_creator = json_data.get("creator", "test")
	beatmap.diff_value = json_data.get("difficulty", 5)
	if "animations" in json_data:
		for animation in json_data["animations"]:
			var frames = animation.get("frames", [])
			var texture_frames = []
			var texture_filenames = []
			# 캐싱된 Texture2D 가져오기
			for frame in frames:
				var texture = get_texture(frame)
				if texture:
					texture_filenames.append(frame)
					texture_frames.append(texture)
			animations.append({
				"id": animation.get("id", -1),
				"frames": texture_frames,
				"fps": animation.get("fps", 1),
				"effect": animation.get("effect", "none"),
				"name": animation.get("name","none"),
				"frame_filenames": texture_filenames
				})
	if "player" in json_data:
		var animation = json_data["player"]
		player_animation = {
			"idle": animation.get("idle", 0),
			"left": animation.get("left", 0),
			"right": animation.get("right", 0),
			"jump": animation.get("jump", 0),
			"land": animation.get("land", 0),
			"defaultdance": animation.get("defaultdance", [])
		}
	beatmap.song_bpm = json_data.get("bpm", 100)
	beatmap.song_bpmstart = json_data.get("bpmstart", 100)
	if "rails" in json_data:
		for rail in json_data["rails"]:
			var new_rail = rail_scene.instantiate()
			new_rail.id = rail.get("id", -1)
			new_rail.start = rail.get("start", -1)
			new_rail.end = rail.get("end",-1)
			new_rail.moves = rail.get("move", [])
			new_rail.pos = rail.get("position", 0.0)
			rails.push_back(new_rail)
	rails.sort_custom(func(a, b): return a.start < b.start)
	if "notes" in json_data:
		for note in json_data["notes"]:
			var new_note = note_scene.instantiate()
			new_note.type = note.get("type", 0)
			new_note.time = note.get("time", 0)
			new_note.rail = note.get("rail", 0)
			new_note.dir = note.get("dir", 0)
			new_note.animation = note.get("animation",0)
			notes.push_back(new_note)
	notes.sort_custom(func(a, b): return a.time < b.time)

func _input(event):
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP and event.pressed:
			SongSlider.value = snap_to_bpm(SongSlider.value * 1000) / 1000
			SongSlider.value += 60 / beatmap.song_bpm / beatmap.beatsdiv
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN and event.pressed:
			SongSlider.value = snap_to_bpm(SongSlider.value * 1000) / 1000
			SongSlider.value -= 60 / beatmap.song_bpm / beatmap.beatsdiv
func _on_pause_pressed() -> void:
	if SongIsPlaying:
		paused_position = Song.get_playback_position()
		Song.stop()
		SongIsPlaying = false
	elif Song.stream:
		Song.play(paused_position)
		SongIsPlaying = true
func _on_slider_changed(value: float) -> void:
	if Song.stream:
		if !SongIsPlaying:
			paused_position = value
func _on_song_finished() -> void:
	SongIsPlaying = false
	SongSlider.value = 0
func _on_remove_pressed():
	if selected != null:
		if selected in rails:
			for note in selected.notes.get_children():
				notes.erase(note)
				note.queue_free()
			rails.erase(selected)
		if selected in notes:
			notes.erase(selected)
		selected.queue_free()

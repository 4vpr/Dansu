extends Control
var paused_position = 0.0
var is_dragging = false
var was_playing = false
var player_animation = {}
var animations = []
var sprites = []
var beatsdiv = 2
var sfx_pool = SfxPool.new()
var beatmap = Beatmap.new()
@onready var SongSlider = $SongSlider
@onready var Inspecter = $Inspecter;@onready var Song = $AudioStreamPlayer
@onready var RailContainer = $Preview/RailContainer;
@onready var Win_Animation = $Animation
@onready var option_button = $Animation/Panel/OptionButton
var SongIsPlaying = false
var map_data = {}
var rail_scene = load("res://objects/editor/rail.tscn")
var note_scene = load("res://objects/editor/note.tscn")
var animation_scene = load("res://objects/editor/animation.tscn")
var selected = null
var rails = []; var notes = []
var rail_scope = null
var selected_animation
var selected_frame

#레일 선택
func scope_rail():
	if selected != null:
		if selected.get("rail") != null:
			for rail in rails:
				if rail.id == selected.get("rail"):
					rail_scope = rail
		else:
			rail_scope = selected
			
#레일 스폰 확인
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
func undo():
	pass
func redo():
	pass
	
#노트 드래그로 옮기는 기능
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
			
#노트 생성
func create_note(type,dir = 0):
	var new_note = note_scene.instantiate()
	var time = int(snap_to_bpm(Game.currentTime))
	for note in notes:
		if note.time == time:
			notes.erase(note)
			note.queue_free()
			print("sametime")
		print(note.time)
	print(time)
	if selected != null:
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
#레일 생성
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
func load_pngs() -> void:
	var dir = DirAccess.open(beatmap.folder_path + "/sprite")
	if dir == null:
		print("폴더가 없습니다 : ", beatmap.folder_path)
		return
	dir.list_dir_begin()
	var file_name = dir.get_next()
	sprites.clear()
	option_button.clear()
	while file_name != "":
		if not dir.current_is_dir() and file_name.ends_with(".png"):
			var new_sprite = {
			"texture" : beatmap._load_texture(file_name),
			"filename" : file_name
			}
			sprites.append(new_sprite)
			print(file_name)
		file_name = dir.get_next()
	dir.list_dir_end()
	var i = 0
	for sprite in sprites:
		option_button.add_item(sprite["filename"], i)
		i += 1
# BPM 보간
func snap_to_bpm(timing: float, division: int = beatsdiv) -> float:
	var beat_interval = 60000.0 / beatmap.song_bpm  # ms per beat
	var snap_interval = beat_interval / division
	
	print("Beat Interval: ", beat_interval)
	
	var relative_timing = timing - beatmap.song_bpmstart
	var snapped_steps = round(relative_timing / snap_interval)
	var snapped_timing = snapped_steps * snap_interval + beatmap.song_bpmstart
	print(snapped_timing)
	return snapped_timing

var clipboard
#클립보드 구현부
#func copy() -> void:
	#clipboard = selected.duplicate()
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
					
var last_hash := ""
func _on_check_folder():
	var current_hash = calculate_folder_hash(beatmap.folder_path.path_join("sprite"))
	print(beatmap.folder_path.path_join("sprite"))
	if current_hash != last_hash:
		last_hash = current_hash
		load_pngs()
func calculate_folder_hash(path: String) -> String:
	var dir = DirAccess.open(path)
	if dir == null:
		return ""
	dir.list_dir_begin()
	var hash_input := ""
	var file_name = dir.get_next()
	while file_name != "":
		if !dir.current_is_dir():
			hash_input += file_name
		file_name = dir.get_next()
	dir.list_dir_end()
	return hash_input.md5_text()
func _ready() -> void:
	beatmap = Game.select_map
	Game.currentTime = 0
	Song.volume_db = linear_to_db(Game.settings.volume_song * Game.settings.volume_master)
	add_child(sfx_pool)
	parse_data()
	load_pngs()

	last_hash = calculate_folder_hash(beatmap.folder_path.path_join("sprite"))
	var timer = Timer.new()
	timer.wait_time = 1.0
	timer.autostart = true
	timer.timeout.connect(_on_check_folder)
	add_child(timer)

	for button in get_tree().get_nodes_in_group("ui_buttons"):
		button.focus_mode = Control.FOCUS_NONE
	if beatmap:
		beatmap.load_song(Song)
	var fields = {
		"meta_title": TYPE_STRING,
		"meta_artist": TYPE_STRING,
		"song_bpm": TYPE_FLOAT,
		"song_bpmstart": TYPE_FLOAT,
		"diff_value": TYPE_FLOAT,
		"diff_name": TYPE_STRING
	}
	for name in fields:
		var field = find_child(name, true, false)
		if field is LineEdit:
			field.text = str(beatmap.get(name))
			field.text_changed.connect(
				func(new_text, field_name = name, field_type = fields[name]):
					match field_type:
						TYPE_STRING:
							beatmap.set(field_name, new_text)
						TYPE_FLOAT:
							beatmap.set(field_name, new_text.to_float())
		)	
	$SongControl/B_Pause.pressed.connect(_on_pause_pressed)
	$NoteControl/B_Note.pressed.connect(create_note.bind(1))
	$NoteControl/B_Note2.pressed.connect(create_note.bind(3))
	$NoteControl/B_Note3.pressed.connect(create_note.bind(4))
	$NoteControl/B_Left.pressed.connect(create_note.bind(2,2))
	$NoteControl/B_Right.pressed.connect(create_note.bind(2,4))
	$NoteControl/B_Save.pressed.connect(save_to_json)
	$NoteControl/B_Rail.pressed.connect(create_rail)
	$NoteControl/B_Remove.pressed.connect(_on_remove_pressed)
	SongSlider.value_changed.connect(_on_slider_changed)
	SongSlider.max_value = Song.stream.get_length()


var nextHitSound = -INF
func _process(_delta: float) -> void:
	if Input.is_action_just_pressed("ui_cancel"):
		get_tree().change_scene_to_file("res://Scene/main_menu.tscn")
		print("exit")
	rail_check()
	check_drag()
	scope_rail()
	if Input.is_action_just_pressed("ui_copy"):
		#copy()
		pass
	if Input.is_action_just_pressed("ui_paste"):
		#paste()
		pass
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


#모든노트 스냅
func snap_notes():
	for note in notes:
		note.time = snap_to_bpm(note.time)


#저장
func save_to_json():
	var json_data = {}
	json_data["title"] = beatmap.meta_title
	json_data["artist"] = beatmap.meta_artist
	json_data["creator"] = beatmap.meta_creator
	json_data["bpm"] = beatmap.song_bpm
	json_data["bpmstart"] = beatmap.song_bpmstart
	json_data["uuid"] = beatmap.map_uuid
	json_data["difficulty_name"] = beatmap.diff_name
	json_data["difficulty_value"] = beatmap.diff_value
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
			"type": int(note.type),
			"time": int(note.time),
			"rail": int(note.rail),
			"dir": int(note.dir),
			"animation": note.animation
			})
	var file = FileAccess.open(beatmap.json_path, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(json_data, "\t"))  # JSON 변환 후 저장
		file.close()
		print("JSON 파일 저장 완료:", beatmap.json_path)
	else:
		print("JSON 파일 저장 실패")
		
		
#데이터 파싱
func parse_data():
	beatmap.parse_objects(true)
	notes = beatmap.notes
	rails = beatmap.rails
	player_animation = beatmap.player_animation
	animations = beatmap.animations
	for animation in animations:
		var new_anim = animation_scene.instantiate()
		new_anim.animation = animation
		$Animation/VBoxContainer.add_child(new_anim)

func _input(event):
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP and event.pressed:
			SongSlider.value = snap_to_bpm(SongSlider.value * 1000) / 1000
			SongSlider.value += 60 / beatmap.song_bpm / beatsdiv
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN and event.pressed:
			SongSlider.value = snap_to_bpm(SongSlider.value * 1000) / 1000
			SongSlider.value -= 60 / beatmap.song_bpm / beatsdiv
func _on_pause_pressed() -> void:
	if SongIsPlaying:
		paused_position = Song.get_playback_position()
		Song.stop()
		SongIsPlaying = false
	elif Song:
		if paused_position < 0:
			paused_position = 0
		Song.play(paused_position)
		SongIsPlaying = true
func _on_slider_changed(value: float) -> void:
	if Song:
		if !SongIsPlaying:
			paused_position = value
func _on_song_finished() -> void:
	SongIsPlaying = false
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

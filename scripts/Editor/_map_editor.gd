extends Control
var paused_position = 0.0
var is_dragging = false
var was_playing = false
var player_animation = {}
var animations = []
var sprites = []
var beatsdiv = 2
var sfx_pool = SfxPool.new()
var chart = Chart.new()
var shortcut = [0,0,0,0,0,0,0,0,0,0]
@onready var SongSlider = $SongSlider
@onready var Inspector = $Inspector;@onready var Song = $AudioStreamPlayer
@onready var RailContainer = $Preview/RailContainer;
@onready var Win_Animation = $Animation
@onready var option_button = $Animation/Panel/OptionButton
@onready var file_dialog: FileDialog = $FileDialog
@onready var chartsaver = load("res://scripts/Editor/chart/chart_save.gd")
var SongIsPlaying = false
var map_data = {}
var rail_scene = load("res://Scene/Entity/Editor/rail.tscn")
var note_scene = load("res://Scene/Entity/Editor/note.tscn")
var animation_scene = load("res://Scene/Entity/Editor/animation.tscn")
var selected = null
var rails = []; var notes = []
var rail_scope = null
var selected_animation
var selected_frame
var selected_prev
func select_object(object):
	if selected_prev != null:
		selected_prev._unselect()
	selected = object
	selected_prev = object
	object._select()
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
func create_note(type,dir = 0):
	var new_note = note_scene.instantiate()
	var time = int(snap_to_bpm(Game.currentTime))
	if selected != null:
		for note in notes:
			if note.visible && note.hasrail:
				if note.time == time:
					if note.type != 4 && type != 4:
						note.visible = false
						undo_objects.append(note)
						check_undo_size()
					elif note.rail == rail_scope.id:
						note.visible = false
						undo_objects.append(note)
						check_undo_size()

		new_note.type = type
		new_note.time = time
		new_note.rail = rail_scope.id
		new_note.dir = dir
		new_note.animation = 0
		
		notes.push_back(new_note)
		undo_objects.append(new_note)
		check_undo_size()
		rail_scope.notes.add_child(new_note)
		rail_scope._update()
		select_object(new_note)
func create_rail():
	var new_rail = rail_scene.instantiate()
	new_rail.start = Game.currentTime - 85
	var used_ids := {}
	for rail in rails:
		used_ids[rail.id] = true
	var i = 1
	while used_ids.has(i):
		i += 1
	new_rail.id = i
	new_rail.end = Game.currentTime + 1085
	new_rail.pos = 0
	select_object(new_rail)
	undo_objects.append(new_rail)
	check_undo_size()
	rails.push_back(new_rail)
	pass
func load_pngs() -> void:
	var dir = DirAccess.open(chart.folder_path + "/sprite")
	if dir == null:
		print("no folder exist! : ", chart.folder_path)
		return
	dir.list_dir_begin()
	var file_name = dir.get_next()
	sprites.clear()
	option_button.clear()
	while file_name != "":
		if not dir.current_is_dir() and file_name.ends_with(".png"):
			var new_sprite = {
			"texture" : chart._load_texture(file_name),
			"filename" : file_name
			}
			sprites.append(new_sprite)
		file_name = dir.get_next()
	dir.list_dir_end()
	var i = 0
	for sprite in sprites:
		option_button.add_item(sprite["filename"], i)
		i += 1
# BPM 보간
func snap_to_bpm(timing: float, division: int = beatsdiv) -> float:
	var beat_interval = 60000.0 / chart.song_bpm  # ms per beat
	var snap_interval = beat_interval / division
	
	
	var relative_timing = timing - chart.song_bpmstart
	var snapped_steps = round(relative_timing / snap_interval)
	var snapped_timing = snapped_steps * snap_interval + chart.song_bpmstart
	return snapped_timing

var last_hash := ""
func _on_check_folder():
	var current_hash = calculate_folder_hash(chart.folder_path.path_join("sprite"))
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
func _open_file_dialog():
	file_dialog.popup_centered()
func _on_file_selected(file_path: String):
	var file = file_path.get_file()
	var src_file = FileAccess.open(file_path, FileAccess.READ)
	if src_file:
		var _data = src_file.get_buffer(src_file.get_length())
		src_file.close()
		var dst_file = FileAccess.open(chart.folder_path.path_join(file), FileAccess.WRITE)
		if dst_file:
			dst_file.store_buffer(_data)
			dst_file.close()

func _ready() -> void:
	chart = CM.sc
	Game.currentTime = 0
	add_child(sfx_pool)
	file_dialog.use_native_dialog = true
	file_dialog.file_selected.connect(_on_file_selected)
	file_dialog.add_filter("*.png, *.jpg, *jpeg ; images")
	parse_data()
	load_pngs()

	last_hash = calculate_folder_hash(chart.folder_path.path_join("sprite"))
	var timer = Timer.new()
	timer.wait_time = 1.0
	timer.autostart = true
	timer.timeout.connect(_on_check_folder)
	add_child(timer)

	for button in get_tree().get_nodes_in_group("ui_buttons"):
		button.focus_mode = Control.FOCUS_NONE
	if chart:
		chart.load_song(Song)
	var fields = {
		"meta_title": TYPE_STRING,
		"meta_artist": TYPE_STRING,
		"song_bpm": TYPE_FLOAT,
		"song_bpmstart": TYPE_FLOAT,
		"diff_name": TYPE_STRING
	}
	for name in fields:
		var field = find_child(name, true, false)
		if field is LineEdit:
			field.text = str(chart.get(name))
			field.text_changed.connect(
				func(new_text, field_name = name, field_type = fields[name]):
					match field_type:
						TYPE_STRING:
							chart.set(field_name, new_text)
						TYPE_FLOAT:
							chart.set(field_name, new_text.to_float())
		)
	$SongControl/B_Pause.pressed.connect(_on_pause_pressed)
	$NoteControl/B_Note.pressed.connect(create_note.bind(1))
	$NoteControl/B_Note2.pressed.connect(create_note.bind(3))
	$NoteControl/B_Note3.pressed.connect(create_note.bind(4))
	$NoteControl/B_Left.pressed.connect(create_note.bind(2,2))
	$NoteControl/B_Right.pressed.connect(create_note.bind(2,4))
	$NoteControl/B_Rail.pressed.connect(create_rail)
	$ObjectControl/B_Remove.pressed.connect(_on_remove_pressed)
	$ObjectControl/B_Undo.pressed.connect(undo)
	%"ExploreImage".pressed.connect(_open_file_dialog)
	%B_Exit.pressed.connect(_quit)
	%SaveS.pressed.connect(_save)
	%SaveQ.pressed.connect(_save_exit)
	SongSlider.value_changed.connect(_on_slider_changed)
	SongSlider.max_value = Song.stream.get_length()

var nextHitSound = -INF
func _save() -> void:
	$Menu.visible = false
	save_to_json()
	CM.sc.load_from_json(chart.json_path)
func _save_exit() -> void:
	save_to_json()
	CM.sc.load_from_json(chart.json_path)
	_quit()
func _quit() -> void:
	get_tree().change_scene_to_file("res://Scene/main_menu.tscn")
func _process(_delta: float) -> void:
	if Input.is_action_just_pressed("ui_cancel"):
		$Menu.visible = !$Menu.visible
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
				if note.time > Game.currentTime &&  note.time < h && note.visible && note.hasrail:
					nextHitSound = note.time
					h = note.time
			if Game.currentTime > h:
				nextHitSound = INF
	else:
		Game.currentTime = SongSlider.value * 1000
		nextHitSound = -INF


#모든노트를 새로 갱신된 bpm에 맞게 가장 가까운 곳으로 스넵함.
func snap_notes():
	for note in notes:
		note.time = snap_to_bpm(note.time)

#저장
func save_to_json():
	var json_data = {}
	json_data["file_audio"] = chart.file_audio
	json_data["title"] = chart.meta_title
	json_data["artist"] = chart.meta_artist
	json_data["creator"] = chart.meta_creator
	json_data["bpm"] = chart.song_bpm
	json_data["bpmstart"] =chart.song_bpmstart
	if chart.map_uuid == "0":
		chart.map_uuid = chart.generate_uuid()
	json_data["uuid"] = chart.map_uuid
	json_data["difficulty_name"] = chart.diff_name
	json_data["difficulty_value"] = chart.diff_value
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
	var file = FileAccess.open(chart.json_path, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(json_data, "\t"))  # JSON 변환 후 저장
		file.close()
		print("JSON Saved!:", chart.json_path)
	else:
		print("JSON failed to save")
#데이터 파싱
func parse_data():
	chart.parse_objects(true)
	notes = chart.notes
	rails = chart.rails
	player_animation = chart.player_animation
	animations = chart.animations
	for animation in animations:
		var new_anim = animation_scene.instantiate()
		new_anim.animation = animation
		$Animation/ScrollContainer/VBoxContainer.add_child(new_anim)

func _input(event):
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP and event.pressed:
			SongSlider.value = snap_to_bpm(SongSlider.value * 1000) / 1000
			SongSlider.value += 60 / chart.song_bpm / beatsdiv
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN and event.pressed:
			SongSlider.value = snap_to_bpm(SongSlider.value * 1000) / 1000
			SongSlider.value -= 60 / chart.song_bpm / beatsdiv
	elif event is InputEventKey and event.pressed and not event.echo:
		var idx := -1
		if event.alt_pressed:
			match event.keycode:
				KEY_1: idx = 0
				KEY_2: idx = 1
				KEY_3: idx = 2
				KEY_4: idx = 3
				KEY_5: idx = 4
				KEY_6: idx = 5
				KEY_7: idx = 6
				KEY_8: idx = 7
				KEY_9: idx = 8
				KEY_0: idx = 9
				_: idx = -1
			if idx != -1 and selected != null and selected in notes:
				var anim_id := int(shortcut[idx])
				if anim_id > 0:
					selected.animation = anim_id
					if Inspector and Inspector.has_method("_update"):
						Inspector._update(selected)
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
var undo_objects = []
func undo():
	redo_objects.append(undo_objects[-1])
	if undo_objects.size() > 0:
		undo_objects[-1].visible = !undo_objects[-1].visible
		if undo_objects[-1] in rails:
			for note in undo_objects[-1].notes.get_children():
				note.hasrail = true
	undo_objects.pop_back()
var redo_objects = []
func redo():
	undo_objects.append(redo_objects[-1])
	if redo_objects.size() > 0:
		redo_objects[-1].visible = !redo_objects[-1].visible
		if redo_objects[-1] in rails:
			for note in redo_objects[-1].notes.get_children():
				note.hasrail = true
	redo_objects.pop_back()
func check_undo_size():
	redo_objects.clear()
	if undo_objects.size() > 20:
		if !undo_objects[0]:
			if !undo_objects[0].visible:
				var undo_item = undo_objects[0]
				if undo_item in rails:
					for note in undo_item.notes.get_children():
						notes.erase(note)
						note.queue_free()
					undo_item.queue_free()
					rails.erase(undo_item)
				if undo_item in notes:
					undo_item.queue_free()
					notes.erase(undo_item)
		undo_objects.remove_at(0)
func _on_remove_pressed():
	undo_objects.append(selected)
	check_undo_size()
	if selected != null:
		if selected in rails:
			for note in selected.notes.get_children():
				note.hasrail = false
		selected.visible = false

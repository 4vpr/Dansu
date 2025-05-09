extends Node3D
var rails_i = 0
var rails = []
var notes_i = 0
var notes = []
var nextnote_i = 0
var thread := Thread.new()
var rail_scene = load("res://objects/rail.tscn")
var note_scene = load("res://objects/note.tscn")
var judge_scene = load("res://objects/judge.tscn")
var sfx_pool = SfxPool.new()
var score = Score.new()
var combo = 0
var judgeDisplayDuration = 1
var judgeDisplayDurationCurrent = 0
var canplay = false
var score_final = 0
var song_end
@onready var player = $Player
@onready var rail_container = $Ground/RailContainor
@onready var songplayer = $SongPlayer
@onready var comboDisplayer = $UI/Combo/Combo
@onready var comboVbox = $UI/Combo
@onready var accDisplayer = $UI/Acc/Acc

func _ready() -> void:
	add_child(sfx_pool)
	Game.currentTime = 0
	var map_data = load_files()
	if map_data:
		parse_objects(map_data)
		player.parse_data(map_data)
		check_objects()
		songplayer.volume_db = linear_to_db(Game.volume)
		canplay = true
		current_time_msec = Time.get_ticks_msec()
		thread.start(self._update)
		var image_extensions = [".jpg", ".jpeg", ".png"]
		var dir = DirAccess.open(Game.select_folder)
		var image_path := ""
		if dir:
			dir.list_dir_begin()
			var file_name = dir.get_next()
			while file_name != "":
				for ext in image_extensions:
					if file_name.to_lower().ends_with(ext):
						image_path = Game.select_folder.path_join(file_name)
						break
				if image_path != "":
					break
				file_name = dir.get_next()
			dir.list_dir_end()
		if image_path != "":
			var image = Image.new()
			var err = image.load(image_path)
			if err == OK:
				#var tex = ImageTexture.create_from_image(image)
				#$Background.texture = tex
				pass
var lastTime = 0
var start_time = 0
var started = false
var wait = true
var lerping = 1.5
func _process(delta: float) -> void:
	if lerping < 0 && wait:
		songplayer.play()
		wait = false
	elif wait:
		lerping -= delta
		Game.currentTime = lerping * -1000
	if canplay:
		check_objects()
		comboDisplayer.text = str(combo)
		if not started and songplayer.playing:
			start_time = Time.get_ticks_msec() - songplayer.get_playback_position() * 1000
			print("오차값")
			print(songplayer.get_playback_position() * 1000)
			started = true
		if Input.is_action_just_pressed("ui_cancel"):
			get_tree().change_scene_to_file("res://Scene/SongSelect.tscn")
func parse_objects(json_data):
	if "rails" in json_data:
		for rail in json_data["rails"]:
			var new_rail = rail_scene.instantiate()
			new_rail.id = rail.get("id", -1)
			new_rail.start = rail.get("start", -1)
			new_rail.end = rail.get("end",-1)
			new_rail.moves = rail.get("move", [])
			new_rail.position.x = rail.get("position", 0.0)
			rails.push_back (new_rail)
	rails.sort_custom(func(a, b): return a.start < b.start)
	if "notes" in json_data:
		for note in json_data["notes"]:
			var new_note = note_scene.instantiate()
			new_note.type = note.get("type", 0)
			new_note.time = note.get("time", 0)
			new_note.rail = note.get("rail", 0)
			new_note.dir = note.get("dir", 0)
			new_note.animation = note.get("animation",0)
			notes.push_back (new_note)
	notes.sort_custom(func(a, b): return a.time < b.time)
func setNextNote():
	if nextnote_i < notes.size():
		notes[nextnote_i].queue_free()
		nextnote_i += 1
		if nextnote_i >= notes.size():
			song_end = true

#일반노트 판정확인
func check_judge():
	if nextnote_i < notes.size():
		if notes[nextnote_i].time + score.t_ok < Game.currentTime:
			call_deferred("write_judge",0)
			setNextNote()
# 노트스폰, 레일 스폰,디스폰;
var canSpawnRail = true
var canSpawnNote = true
func check_objects():
	while canSpawnRail:
		if rails[rails_i].start <= Game.currentTime + Game.travelTime:
			rail_container.add_child(rails[rails_i])
			rails_i += 1
			if rails_i >= rails.size():
				canSpawnRail = false
				break
		else:
			break
	while canSpawnNote:
		if notes[notes_i].time <= Game.currentTime + Game.travelTime:
			var contained_rails = rail_container.get_children()
			for rail in contained_rails:
				if rail.id == notes[notes_i].rail:
					var note_container = rail.find_child("NoteContainer", true, false)
					if note_container:
						note_container.add_child(notes[notes_i])
			notes_i += 1
			if notes_i >= notes.size():
				canSpawnNote = false
				break
		else:
			break

var running := true
var current_time_msec := 0

func _exit_tree():
	running = false
	thread.wait_to_finish()

func _update(_data = null):
	var last = Time.get_ticks_msec()
	while running:
		var now = Time.get_ticks_msec()
		while now - last >= 1:
			last += 1
			current_time_msec = last
			if started:
				Game.currentTime = Time.get_ticks_msec() - start_time - Game.offset_recom
				check_judge()
		OS.delay_msec(1)
func load_files() -> Dictionary:
	var map_path = Game.select_folder.path_join(Game.select_map)
	var song_path = Game.select_folder.path_join("song.mp3")
	var song_stream = AudioStreamMP3.new()
	var song_file = FileAccess.open(song_path, FileAccess.READ)
	if song_file:
		print("song loaded")
		song_stream.data = song_file.get_buffer(song_file.get_length())
		songplayer.stream = song_stream
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
func playerAction() -> void:
	if nextnote_i < notes.size():
		var acc = notes[nextnote_i].time - Game.currentTime
		if player.standRail.id == notes[nextnote_i].rail && notes[nextnote_i].type == 1:
			var j = score.getJudge(acc)
			if j != -1:
				write_judge(j)
				setNextNote()
		pass
func playerMove(dir:int,_rail) -> void:
	if nextnote_i < notes.size():
		if notes[nextnote_i].type == 2 && notes[nextnote_i].rail == player.standRail.id:
			if notes[nextnote_i].dir == dir:
				var acc = notes[nextnote_i].time - Game.currentTime
				var j = score.getJudge(acc)
				if j != -1:
					write_judge(j)
					setNextNote()
func write_judge(j:int):
	judgeDisplayDurationCurrent = judgeDisplayDuration
	var new_judge = judge_scene.instantiate()
	new_judge.judge = j
	new_judge.position.x = player.position.x
	add_child(new_judge)
	score.addScore(j)
	comboVbox._play()
	accDisplayer.text = str(snapped(score.getScore(), 0.01)) + "%"
	if j != 0:
		if j != 4:
			combo += 1
		sfx_pool.play_sound(preload("res://Resources/drum-slidertick.wav"))
		player.sprites_current = null
		if notes[nextnote_i].animation > 0:
			player.setAnimation(notes[nextnote_i].animation)
		else:
			player.setAnimation(player.getNextDefaultDance())
	else:
		combo = 0

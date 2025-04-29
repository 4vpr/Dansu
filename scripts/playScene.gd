extends Node3D

var rails_i = 0
var rails = []
var notes_i = 0
var notes = []

var nextnote_i = 0
var rail_scene = load("res://objects/rail.tscn")
var note_scene = load("res://objects/note.tscn")
var judge_scene = load("res://judge.tscn")


var exe_dir = OS.get_executable_path().get_base_dir()
var user_dir = OS.get_user_data_dir()
var max_score :float = 0
var score :float = 0
#var movenote_scene
var combo = 0
var judgeDisplayDuration = 1
var judgeDisplayDurationCurrent = 0
var canplay = false
var score_final = 0
@onready var player = $Player
@onready var rail_container = $Ground/RailContainor
@onready var songplayer = $SongPlayer
@onready var comboDisplayer = $UI/Combo/Combo
@onready var comboVbox = $UI/Combo
@onready var accDisplayer = $UI/Acc/Acc
@onready var nextnote = $UI/nextnote
var result_notes :float = 0
var result_perfect_plus = 0
var result_perfect = 0 
var result_good = 0
var result_ok = 0
var result_bad = 0
var result_miss = 0
func _ready() -> void:
	Game.currentTime = 0
	var map_data = load_files()
	if map_data:
		parse_objects(map_data)
		player.parse_data(map_data)
		check_objects()
		songplayer.volume_db = linear_to_db(Game.volume)
		songplayer.play()
		canplay = true
var lastTime = 0
#WAV 쓰는거 CHATGPT한테 물어보자
#혹시 까먹을까봐 적어두고 자러간다 수고
func _process(delta: float) -> void:
	if canplay:
		var playback: AudioStreamPlayback = songplayer.get_stream_playback()
		Game.currentTime = (playback.get_playing_position() + AudioServer.get_time_since_last_mix()) * 1000
		if(lastTime > Game.currentTime):
			print("[Debug] currentTime is going back bruh")
			print(lastTime - Game.currentTime)
			pass
		check_objects()
		check_judge()
		if Input.is_action_just_pressed("ui_cancel"):
			get_tree().change_scene_to_file("res://Scene/MainMenu.tscn")
		lastTime = Game.currentTime

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

#일반노트 판정확인
func check_judge():
	if nextnote_i < notes.size():
		var acc = notes[nextnote_i].time - Game.currentTime
		if notes[nextnote_i].time + Game.bad < Game.currentTime:
			write_judge(0)
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

func load_files() -> Dictionary:
	var map_path = user_dir.path_join("Songs/" + Game.selected + "/map.json")
	var song_path = user_dir.path_join("Songs/" + Game.selected + "/song.mp3")
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
			judege_acc(acc)
		pass

func playerMove(dir:int,_rail) -> void:
	if nextnote_i < notes.size():
		if notes[nextnote_i].type == 2 && notes[nextnote_i].rail == player.standRail.id:
			if notes[nextnote_i].dir == dir:
				var acc = notes[nextnote_i].time - Game.currentTime
				judege_acc(acc)
func getScore() -> float:
	var f:float = 0
	if result_notes <= result_perfect_plus + result_perfect:
		f = (result_perfect_plus / result_notes) + 100
	else:
		f = score / max_score * 100
	return f
func judege_acc(acc):
	if acc < Game.perfect_plus && acc > Game.perfect_plus * -1:
		write_judge(5)
		setNextNote()
	elif acc < Game.perfect && acc > Game.perfect * -1:
		write_judge(1)
		setNextNote()
	elif acc < Game.great && acc > Game.great * -1:
		write_judge(2)
		setNextNote()
	elif acc < Game.ok && acc > Game.ok * -1:
		write_judge(3)
		setNextNote()
	elif acc < Game.bad && acc > Game.bad * -1:
		write_judge(4)
		setNextNote()
func write_judge(j:int):
	judgeDisplayDurationCurrent = judgeDisplayDuration
	var new_judge = judge_scene.instantiate()
	new_judge.judge = j
	new_judge.position.x = player.position.x
	add_child(new_judge)
	comboVbox._play()
	max_score += Game.perfect_plus_score
	result_notes += 1
	if j == 5:
		result_perfect_plus += 1
		score += Game.perfect_plus_score
		combo += 1
	if j == 1:
		result_perfect += 1
		score += Game.perfect_score
		combo += 1
	if j == 2:
		result_good += 1
		score += Game.great_score
		combo += 1
	if j == 3:
		result_ok += 1
		score += Game.ok_score
		combo += 1
	if j == 4:
		result_bad += 1
		score += Game.bad_score
		combo = 0
	if j == 0:
		result_miss += 1
		combo = 0;
	accDisplayer.text = str(snapped(getScore(), 0.01)) + "%"
	if j != 0:
		player.sprites_current = null
		if notes[nextnote_i].animation > 0:
			player.setAnimation(notes[nextnote_i].animation)
		else:
			player.setAnimation(player.getNextDefaultDance())
	comboDisplayer.text = str(combo)

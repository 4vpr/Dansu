extends Node3D
var rails = []
var rails_i = 0
var notes = []
var notes_i = 0
var nextnote_i = -1
var hitnotes = []
var rail_scene = preload("res://Scene/Entity/rail.tscn")
var note_scene = preload("res://Scene/Entity/note.tscn")
var judge_scene = preload("res://Scene/Entity/judge.tscn")
var sfx_pool = SfxPool.new()
var score = Score.new()
var combo = 0
var judgeDisplayDuration = 1
var song_end = 0
const DifficultyAnalyzer = preload("res://scripts/Class/difficulty_analyzer.gd")
@onready var player = $Player
@onready var rail_container = $Ground/RailContainor
@onready var songplayer = $SongPlayer
@onready var comboDisplayer = $UI/Combo/Combo
@onready var comboVbox = $UI/Combo
@onready var accDisplayer = $UI/Acc/Acc
@onready var tc_left_position = 1260
@onready var tc_size = 250
@onready var tc_right_position = 1540
var chart: Chart
func _input(event: InputEvent) -> void:
	if event is InputEventScreenTouch && event.pressed:
		if event.position.x > tc_left_position && event.position.x < tc_left_position + tc_size:
			playerMove(2, Game.currentTime)
			player.move(-1)
		elif event.position.x > tc_right_position && event.position.x < tc_right_position + tc_size:
			playerMove(4, Game.currentTime)
			player.move(1)
		else:
			playerAction(Game.currentTime)
func _ready() -> void:
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
	$UI/TouchScreen.visible = Game.isTouchScreen
	load_background()
	add_child(sfx_pool)
	Game.currentTime = 0
	chart = CM.sc
	chart.parse_objects()
	check_objects()
	if chart:
		if chart.load_song(songplayer):
			parse_objects(chart)
			score.uuid = chart.map_uuid
			score.hash = chart.get_hash()
			current_time_msec = Time.get_ticks_msec()
			setNextNote()
var start_time = 0
var song_playing = false
var wait = true
var lerping = 1.5 + abs(Game.settings["audio"]["offset"] * 1000)

func _process(delta: float) -> void:
	if lerping < 0 and wait:
		songplayer.play()
		wait = false
	elif wait:
		lerping -= delta
		Game.currentTime = lerping * -1000
	if Game.currentTime > song_end:
		songplayer.volume_db -= delta * 30
		if Game.currentTime > song_end + 2000:
			Game.score = score
			get_tree().change_scene_to_file("res://Scene/result_scene.tscn")
	check_objects()
	comboDisplayer.text = str(combo)
	if not song_playing and songplayer.playing:
		start_time = Time.get_ticks_msec() - songplayer.get_playback_position() * 1000
		song_playing = true
	if Input.is_action_just_pressed("ui_cancel"):
		get_tree().change_scene_to_file("res://Scene/main_menu.tscn")

func parse_objects(chart: Chart):
	rails = chart.rails
	notes = chart.notes
	rails.sort_custom(func(a, b): return a.start < b.start)
	notes.sort_custom(func(a, b): return a.time < b.time)
	song_end = notes[-1].time + 1000 if notes.size() > 0 else 0

func load_background():
	var material = $Background.mesh.surface_get_material(0)
	material.albedo_texture = CM.ss._load_cover_image()

func check_objects():
	# 레일 스폰
	while rails_i < rails.size() and rails[rails_i].start <= Game.currentTime + Game.travelTime:
		rail_container.add_child(rails[rails_i])
		rails_i += 1

	# 노트 스폰
	while notes_i < notes.size() and notes[notes_i].time <= Game.currentTime + Game.travelTime:
		var note = notes[notes_i]
		var target_rail = null

		# 현재 스폰된 레일 중에서 ID로 찾기
		for rail_node in rail_container.get_children():
			if rail_node.id == note.rail:
				target_rail = rail_node
				break
		if target_rail:
			var note_container = target_rail.get_node_or_null("NoteContainer")
			if note_container:
				note_container.add_child(note)
				if note.type == 3 or note.type == 4:
					hitnotes.append(note)
		notes_i += 1
var current_time_msec = 0
func _physics_process(delta:float) -> void:
	if song_playing:
		Game.currentTime = Time.get_ticks_msec() - start_time - Game.offset_recom + Game.settings["audio"]["offset"]
	check_judge()
	if Input.is_action_just_pressed("move_left"):
		playerMove(2, Game.currentTime)
		player.move(-1)
	if Input.is_action_just_pressed("move_right"):
		playerMove(4, Game.currentTime)
		player.move(1)
	#if Input.is_action_just_pressed("move_up") and !isJumping:
	#	isJumping = true
	#	jumpDurationCurrent = jumpDuration
	if Input.is_action_just_pressed("action_1") or Input.is_action_just_pressed("action_2"):
		playerAction(Game.currentTime)
func check_judge():
	if nextnote_i < notes.size() && nextnote_i > -1:
		if notes[nextnote_i].time + score.t_ok < Game.currentTime:
			write_judge(0,notes[nextnote_i])
			setNextNote()
	for note in hitnotes:
		if note != null:
			if note.time <= Game.currentTime:
				if note.type == 3:
					if note.rail == player.standRail.id:
						write_judge(5,note)
						note.queue_free()
						hitnotes.erase(note)
					elif note.time + score.t_ok < Game.currentTime:
						write_judge(0,note)
						note.queue_free()
						hitnotes.erase(note)
				if note.type == 4:
					if note.rail == player.standRail.id:
						write_judge(0,note)
						note.type = -1
					else:
						note.type = -1
				if note.type == -1 && note.time + 300 < Game.currentTime:
					hitnotes.erase(note)
					note.queue_free()
func playerAction(time):
	if nextnote_i < notes.size():
		var note = notes[nextnote_i]
		var acc = note.time - time
		if player.standRail != null:
			if player.standRail.id == note.rail and note.type == 1:
				var j = score.getJudge(acc)
				if j != -1:
					write_judge(j, notes[nextnote_i])
					setNextNote()
func playerMove(dir: int, time):
	if nextnote_i < notes.size():
		var note = notes[nextnote_i]
		if player.standRail != null:
			if note.type == 2 and note.rail == player.standRail.id and note.dir == dir:
				var acc = note.time - time
				var j = score.getJudge(acc)
				if j != -1:
					write_judge(j, notes[nextnote_i])
					setNextNote()
func write_judge(j: int,note):
	player.groove = 0
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
			if score.high_combo < combo:
				score.high_combo = combo
		sfx_pool.play_sound(preload("res://Resources/drum-slidertick.wav"))
		player.sprites_current = null
		if note.animation > 0:
			player.setAnimation(notes[nextnote_i].animation)
		else:
			player.setAnimation(player.getNextDefaultDance())
	else:
		combo = 0
func setNextNote():
	if nextnote_i != -1:
		notes[nextnote_i].queue_free()
	for note in notes:
		nextnote_i += 1
		if nextnote_i < notes.size():
			if nextnote_i >= notes.size():
				return
			var type = 0
			if is_instance_valid(notes[nextnote_i]):
				type = notes[nextnote_i].type
			if type == 1 or type == 2:
				return
		else:
			return

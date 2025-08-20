extends Node

var score = Score.new()
var chart = CM.sc

@onready var ButtonExit = $Panel/Button
@onready var ScoreLabel = $Panel/Score
@onready var RankLabel = $Rank
@onready var JudgeLabel = $Panel/Jvalue
@onready var BGTexture = $TextureRect

func _ready() -> void:
	# 버튼 연결
	ButtonExit.pressed.connect(_exit)

	_load_background_image()
	
	# 점수 및 랭크 표시
	score = Game.score
	score.save_current_score()
	ScoreLabel.text = str(int(score.getScore() * 10000))
	RankLabel.text = Game.getRank(score.getScore())
	JudgeLabel.text = "%d\n%d\n%d\n%d\n%d\n%d\n" % [
		score.c_perfect_plus,
		score.c_perfect,
		score.c_great,
		score.c_ok,
		score.c_bad,
		score.c_miss
	]

func _load_background_image():
	$TextureRect.texture = Game.selected_beatmap_set.cover_image

func _process(delta: float) -> void:
	if Input.is_action_just_pressed("ui_cancel"):
		_exit()

func _exit() -> void:
	get_tree().change_scene_to_file("res://Scene/main_menu.tscn")

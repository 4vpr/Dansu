extends Node

var score = Score.new()
var beatmap = Game.select_map

@onready var ButtonExit = $Panel/Button
@onready var ScoreLabel = $Panel/Score
@onready var RankLabel = $Rank
@onready var JudgeLabel = $Panel/Jvalue
@onready var BGTexture = $TextureRect

func _ready() -> void:
	# 버튼 연결
	ButtonExit.pressed.connect(_exit)

	# 배경 이미지 로드
	_load_background_image()

	# 점수 및 랭크 표시
	score = Game.score
	ScoreLabel.text = str(int(score.getScore() * 10000))
	RankLabel.text = score.getRank()
	JudgeLabel.text = "%d\n%d\n%d\n%d\n%d\n%d\n" % [
		score.c_perfect_plus,
		score.c_perfect,
		score.c_good,
		score.c_ok,
		score.c_bad,
		score.c_miss
	]

func _load_background_image():
	$TextureRect.texture = Game.select_folder.cover_image

func _process(delta: float) -> void:
	if Input.is_action_just_pressed("ui_cancel"):
		_exit()

func _exit() -> void:
	get_tree().change_scene_to_file("res://Scene/main_menu.tscn")

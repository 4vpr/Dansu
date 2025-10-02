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
		score.counts[0],
		score.counts[1],
		score.counts[2],
		score.counts[3],
		score.counts[4],
		score.counts[5]
	]

func _load_background_image():
	$TextureRect.texture = CM.ss._load_cover_image()

func _process(delta: float) -> void:
	if Input.is_action_just_pressed("ui_cancel"):
		_exit()

func _exit() -> void:
	get_tree().change_scene_to_file("res://Scene/main_menu.tscn")

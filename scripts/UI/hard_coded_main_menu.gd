extends Control
@onready var Main_BG = $BG.position.x
@onready var Main_Menu = $Menu.position.x
@onready var Main_Player = $Player.position.x
@onready var Main_SongSelect = $SongSelect.position.x
@onready var Score_board = $ScoreBoard.position.x
@onready var Option_unselected = $Options.position.x
var Option_selected = 1000.0
var option_window: bool = false
var SS_BG = -2500.0
var SS_Menu = -3000.0
var SS_Player = 320.0
var SS_SongSelect = 0.0
var SS_ScoreBoard = 50.0
var is_option_window = false
func _ready() -> void:
	if Game.scene == Game.Scene.Play or Game.scene == Game.Scene.Edit:
		$BG.position.x = -2500.0
		$Menu.position.x = SS_Menu
		$Player.position.x = SS_Player
		$SongSelect.position.x = SS_SongSelect
	if	Game.scene == Game.Scene.Play:
		$ScoreBoard.position.x = SS_ScoreBoard
	$Menu/Play.pressed.connect(play)
	$Menu/Edit.pressed.connect(edit)
	$Menu/Options.pressed.connect(options)
	$Menu/Exit.pressed.connect(exit)
func exit():
	Game.save_settings()
	get_tree().quit()
func _process(delta: float) -> void:
	if is_option_window :
		$Options.position.x = lerp($Options.position.x , Option_selected , delta * 10.0)
		if Input.is_action_just_pressed("ui_cancel"):
			is_option_window  = false
	else:
		$Options.position.x = lerp($Options.position.x , Option_unselected , delta * 10.0)
		pass
	if Game.scene == Game.Scene.Play or Game.scene == Game.Scene.Edit:
		$Menu.position.x = lerp($Menu.position.x , SS_Menu , delta * 10.0)
		$BG.position.x = lerp($BG.position.x , SS_BG , delta * 10.0)
		$Player.position.x = lerp($Player.position.x, SS_Player, delta * 10.0)
		$SongSelect.position.x = lerp($SongSelect.position.x, SS_SongSelect , delta * 10.0)
		if Input.is_action_just_pressed("ui_cancel"):
			Game.scene = Game.Scene.Main
		if Game.scene == Game.Scene.Play:
			$ScoreBoard.position.x = lerp($ScoreBoard.position.x, SS_ScoreBoard , delta * 10.0)
	else:
		$Player.position.x = lerp($Player.position.x, Main_Player, delta * 10.0)
		$BG.position.x = lerp($BG.position.x , Main_BG , delta * 10.0)
		$Menu.position.x = lerp($Menu.position.x , 0.0 , delta * 10.0)
		$SongSelect.position.x = lerp($SongSelect.position.x,Main_SongSelect , delta * 10.0)
		$ScoreBoard.position.x = lerp($ScoreBoard.position.x, Score_board , delta * 10.0)
	pass

func play():
	if Game.scene == Game.Scene.Main:
		Game.scene = Game.Scene.Play
		$SongSelect/Edit.visible = false
		is_option_window  = false
		Game.save_settings()
func edit():
	if Game.scene == Game.Scene.Main:
		Game.scene = Game.Scene.Edit
		$SongSelect/Edit.visible = true
		is_option_window  = false
		Game.save_settings()
func options():
	is_option_window  = !is_option_window 
	Game.save_settings()

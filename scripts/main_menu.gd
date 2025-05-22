extends Control
@onready var Main_BG = $BG.position.x
@onready var Main_Menu = $Menu.position.x
@onready var Main_Player = $Player.position.x
@onready var Main_SongSelect = $SongSelect.position.x
var option_window: bool = false
var SS_BG = -2500.0
var SS_Menu = -3000.0
var SS_Player = 320.0
var SS_SongSelect = 0.0

func _ready() -> void:
	if Game.scene == Game.Scene.Play or Game.scene == Game.Scene.Edit:
		$BG.position.x = -2500.0
		$Menu.position.x = SS_Menu
		$Player.position.x = SS_Player
		$SongSelect.position.x = SS_SongSelect
	$Menu/Play.pressed.connect(play)
	$Menu/Edit.pressed.connect(edit)
	$Menu/Options.pressed.connect(options)
func _process(delta: float) -> void:
	if Game.scene == Game.Scene.Play or Game.scene == Game.Scene.Edit:
		$Menu.position.x = lerp($Menu.position.x , SS_Menu , delta * 10.0)
		$BG.position.x = lerp($BG.position.x , SS_BG , delta * 10.0)
		$Player.position.x = lerp($Player.position.x, SS_Player, delta * 10.0)
		$SongSelect.position.x = lerp($SongSelect.position.x, SS_SongSelect , delta * 10.0)
		if Input.is_action_just_pressed("ui_cancel"):
			Game.scene = Game.Scene.Main
	else:
		$Player.position.x = lerp($Player.position.x, Main_Player, delta * 10.0)
		$BG.position.x = lerp($BG.position.x , Main_BG , delta * 10.0)
		$Menu.position.x = lerp($Menu.position.x , 0.0 , delta * 10.0)
		$SongSelect.position.x = lerp($SongSelect.position.x,Main_SongSelect , delta * 10.0)
	pass

func play():
	if Game.scene == Game.Scene.Main:
		Game.scene = Game.Scene.Play
		option_window = false
func edit():
	if Game.scene == Game.Scene.Main:
		Game.scene = Game.Scene.Edit
		option_window = false
func options():
	option_window = !option_window

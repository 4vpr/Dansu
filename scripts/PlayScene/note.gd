extends Node3D
var time
var velo = 1
var dir
var type
var rail
var animation

# longnote things
#var duration = 0
#var is_longnote = false
#var endrail

@onready var NoteSprite= $NoteSprite
@onready var ArrowSprite = $ArrowSprite
var NoteTex = preload("res://Resources/note.png")
var MoveTex = preload("res://Resources/note2.png")
var SpikeTex = preload("res://Resources/note3.png")
func _ready() -> void:
	if type == 1:
		NoteSprite.texture = NoteTex
		ArrowSprite.visible = false
	elif type == 2:
		NoteSprite.texture = MoveTex
		ArrowSprite.visible = true
		NoteSprite.modulate.a = 0
		ArrowSprite.modulate.a = 0
	elif type == 3:
		NoteSprite.texture = NoteTex
		ArrowSprite.visible = false
		scale.x = 0.5
	elif type == 4:
		position.y = 0.15
		NoteSprite.texture = SpikeTex
		ArrowSprite.visible = false
	#if is_longnote:
		#pass
func _process(delta: float) -> void:
	if NoteSprite.modulate.a < 1:
		NoteSprite.modulate.a += delta * Game.settings["gameplay"]["velocity"] / 2
		ArrowSprite.modulate.a += delta * Game.settings["gameplay"]["velocity"] / 2
		if NoteSprite.modulate.a > 1:
			NoteSprite.modulate.a = 1
			ArrowSprite.modulate.a = 1
	position.z = Game.panelSize -((time - Game.currentTime) * Game.settings["gameplay"]["velocity"] / 1000)

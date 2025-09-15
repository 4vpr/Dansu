extends Node3D
var time: int
var velo = 1
var dir: int
var type: int
var rail: int
var animation: int
var origin_pos

# longnote things
#var duration = 0
#var is_longnote = false
#var endrail

@onready var NoteSprite= $NoteSprite
@onready var ArrowSprite = $ArrowSprite
var NoteTex = preload("res://Textures/note.png")
var MoveTex = preload("res://Textures/note2.png")
var SpikeTex = preload("res://Textures/note3.png")
func _ready() -> void:
	
	NoteSprite.modulate.a = 0.0
	ArrowSprite.modulate.a = 0.0
	match type:
		1: #Default
			NoteSprite.texture = NoteTex
			ArrowSprite.visible = false
		2: #Move
			NoteSprite.texture = MoveTex
			ArrowSprite.visible = true
		3: #Trace
			NoteSprite.texture = NoteTex
			ArrowSprite.visible = false
			scale.x = 0.5
		4: #Spike
			position.y = 0.13
			NoteSprite.texture = SpikeTex
			ArrowSprite.visible = false
		5: #Long
			pass
	origin_pos = position.y

func _process(delta: float) -> void:
	if NoteSprite.modulate.a < 1:
		NoteSprite.modulate.a += delta / 1.2 * Game.settings["gameplay"]["velocity"]
		ArrowSprite.modulate.a += delta / 1.2 * Game.settings["gameplay"]["velocity"]
		if NoteSprite.modulate.a > 1:
			NoteSprite.modulate.a = 1
			ArrowSprite.modulate.a = 1
	if type == 4:
		position.y = origin_pos - ((1 - NoteSprite.modulate.a))
	else:
		position.y = origin_pos + ((1 - NoteSprite.modulate.a) / 10)
	position.z = Game.panelSize -((time - Game.currentTime) * Game.settings["gameplay"]["velocity"] / 1000)

extends Node3D
var time
var velo = 1
var dir
var type
var rail
var animation
@onready var NoteSprite= $NoteSprite
@onready var ArrowSprite = $ArrowSprite
var NoteTex = preload("res://Resources/note.png")
var MoveTex = preload("res://Resources/note2.png")
func _ready() -> void:
	if type == 1:
		NoteSprite.texture = NoteTex
		ArrowSprite.visible = false
		pass
	if type == 2:
		NoteSprite.texture = MoveTex
		ArrowSprite.visible = true
		pass
	NoteSprite.modulate.a = 0
	ArrowSprite.modulate.a = 0
func _process(delta: float) -> void:
	if NoteSprite.modulate.a < 1:
		NoteSprite.modulate.a += delta * Game.settings.velocity / 2
		ArrowSprite.modulate.a += delta * Game.settings.velocity / 2
		if NoteSprite.modulate.a > 1:
			NoteSprite.modulate.a = 1
			ArrowSprite.modulate.a = 1
	position.z = Game.panelSize -((time - Game.currentTime) * Game.settings.velocity / 1000)

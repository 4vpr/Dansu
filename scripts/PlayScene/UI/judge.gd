extends Sprite3D
var duration = 0.1
var removing = 0.2
var removing_rst = 0.2
var speed = 0.00005
var judge
@onready var just = preload("res://Textures/Judges/Just.png")
@onready var good = preload("res://Textures/Judges/Good.png")
@onready var ok = preload("res://Textures/Judges/ok.png")
@onready var nah = preload("res://Textures/Judges/Nah.png")
@onready var miss = preload("res://Textures/Judges/Miss.png")
@onready var justplus = preload("res://Textures/Judges/JustPlus.png")

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	_reset()
	position.z = 1.1
	#position.y = 0.55
	position.y = 1

func _reset():
	if judge == 5:
		texture = miss
	elif judge == 1:
		texture = just
	elif judge == 2:
		texture = good
	elif judge == 3:
		texture = ok
	elif judge == 4:
		texture = nah
	elif judge == 0:
		texture = justplus
# Called every frame. 'delta' is the elapsed time since the previous frame
func _process(delta: float) -> void:
	duration -= delta
	if duration > 0:
		position.y -= speed / 4
		pass
	elif removing > 0:
		modulate.a = removing / removing_rst
		position.y -= speed / 2
		removing -= delta
	else:
		queue_free()
	pass

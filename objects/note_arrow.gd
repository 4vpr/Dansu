extends Sprite3D

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	var parent = get_parent()
	var dir = parent.dir
	if dir == null:
		rotation.z = 0
	else:
		rotation_degrees.z = dir * 90
	pass

extends Camera3D

func _process(delta: float) -> void:
	position.x = lerp(position.x, ($"../Player".position.x), delta * 10)
	pass

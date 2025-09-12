extends VBoxContainer
var extendSize = 0.1
var duration = 0
var endTime = 0
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if duration > 0:
		duration -= delta
	scale.y = 1 + duration

func _play():
	duration = 0.1

extends VBoxContainer
var extendSize = 0.1
var duration = 100
var endTime = 0

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if Game.currentTime < endTime:
		scale.y = 1 + extendSize * (endTime - Game.currentTime) / duration
		pass
	else:
		scale.y = 1
	pass

func _play():
	endTime = Game.currentTime + duration
	pass

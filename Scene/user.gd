extends Control


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	$Panel/rating.text = str(PP.calculate_total_pp())
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

extends Button

@export var hover_scale: Vector2 = Vector2(1.05, 1.05)
@export var press_scale: Vector2 = Vector2(0.9, 0.9)


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	mouse_entered.connect(_enter)
	mouse_exited.connect(_exit)
	button_down.connect(_press)
	call_deferred("_pivot")
	pass
func _pivot():
	pivot_offset = size/2.0
	
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
func _enter() -> void:
	create_tween().tween_property(self,"scale",hover_scale, 0.1).set_trans(Tween.TRANS_SINE)
func _exit() -> void:
	create_tween().tween_property(self,"scale",Vector2.ONE, 0.1).set_trans(Tween.TRANS_SINE)
func _press() -> void:
	var press_tween = create_tween()
	press_tween.tween_property(self,"scale", press_scale, 0.06).set_trans(Tween.TRANS_SINE)
	press_tween.tween_property(self,"scale", hover_scale, 0.12).set_trans(Tween.TRANS_SINE)
	

extends ScrollContainer

var velocity := 0.0
var target_offset := 0.0
var elasticity := 200.0
var damping := 10.0

func _process(_delta):
	pass
func _gui_input(event):
	if event is InputEventMouseMotion and event.button_mask & MOUSE_BUTTON_MASK_LEFT:
		target_offset -= event.relative.y

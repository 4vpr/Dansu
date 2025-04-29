extends TextureButton
var time
var dir
var type
var rail
var animation
var dragging = false
var offset
var note_texture = load("res://objects/editor/note.tres")
var left_texture = load("res://Textures/left.png")
var right_texture = load("res://Textures/right.png")
var time_offset
var can_drag = false
func _ready() -> void:
	pressed.connect(_on_pressed)
	mouse_exited.connect(_on_mouse_exited)
	mouse_entered.connect(_on_mouse_entered)
	_update_texture()
func _on_pressed():
	get_tree().current_scene.selected = self
	pass
func _update():
	get_parent().get_parent()._update()
func _on_mouse_entered():
	can_drag = true
func _on_mouse_exited():
	can_drag = false
func _input(event):
	if event is InputEventMouseButton:
		if event.pressed and event.button_index == MOUSE_BUTTON_LEFT and can_drag:
			dragging = true
			offset = event.position
			time_offset = time
		elif not event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			dragging = false
func _update_texture():
	if type == 2:
		if dir == 2:
			texture_normal = left_texture
		elif dir == 4:
			texture_normal = right_texture
	else:
		texture_normal = note_texture

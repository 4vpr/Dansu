extends TextureButton
var time:int
var dir:int
var type:int
var rail
var animation
var dragging = false
var hasrail = true
var offset
var tween
var note_texture = load("res://Resources/note.tres")
var left_texture = load("res://Textures/left.png")
var right_texture = load("res://Textures/right.png")
var spike_texture = load("res://Textures/editor_spike.png")
var time_offset
var can_drag = false
func _ready() -> void:
	pivot_offset = size / 2
	pressed.connect(_on_pressed)
	mouse_exited.connect(_on_mouse_exited)
	mouse_entered.connect(_on_mouse_entered)
	_update_texture()

var current_angle := 0.0
var target_angle := 0.0
func _select():
	modulate = Color(0.5,0.5,0.5)
	if tween:
		tween.kill()
	tween = create_tween()
	target_angle = deg_to_rad(10)
	tween.set_trans(Tween.TRANS_SINE)
	tween.set_ease(Tween.EASE_IN_OUT)
	tween.tween_method(Callable(self, "_update_rotation"), current_angle, target_angle, 0.5)
	tween.tween_method(Callable(self, "_update_rotation"), target_angle, -target_angle, 1.0)
	tween.tween_method(Callable(self, "_update_rotation"), -target_angle, 0.0, 0.5)
	tween.set_loops()  # 무한 반복
func _unselect():
	modulate = Color(1,1,1)
	if tween:
		tween.kill()
	var recover_tween = create_tween()
	recover_tween.tween_method(Callable(self, "_update_rotation"), current_angle, 0.0, 0.3)
func _update_rotation(value: float) -> void:
	# 각도를 최단 경로로 부드럽게 보간
	current_angle = lerp_angle(current_angle, value, 1.0)
	rotation = current_angle
func _on_pressed():
	get_tree().current_scene.select_object(self)
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
	elif type == 4:
		texture_normal = spike_texture
	else:
		texture_normal = note_texture
		if type == 3:
			size.x = 30
			position.x += 15

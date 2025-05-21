extends TextureButton
var id:int
var start
var end
var moves = []
var pos = 0
var dragging = false
var offset
var time_offset
var can_drag = false
@onready var notes = $NoteContainer

func sizeToNotes() -> void:
	var _min = INF
	var _max = 0
	for note in notes.get_children():
		if note.time < _min:
			_min = note.time
		if note.time > _max:
			_max = note.time
	start = _min - 85
	end = _max + 85
func _ready() -> void:
	_update()
	mouse_exited.connect(_on_mouse_exited)
	mouse_entered.connect(_on_mouse_entered)
	pressed.connect(_on_pressed)
	pass
func _update() -> void:
	for note in notes.get_children():
		note.position.y = (end - note.time) * Game.editor_velocity
		if note.time < start:
			start = note.time
		if note.time > end:
			end = note.time
	size.y = (end - start) * Game.editor_velocity
	position.x = pos * 250 / 0.9
func _on_mouse_entered():
	can_drag = true
func _on_mouse_exited():
	can_drag = false
func _input(event):
	if event is InputEventMouseButton:
		if event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			dragging = true
			offset = event.position - global_position
			time_offset = position.y
		elif not event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			dragging = false
func _on_pressed():
	get_tree().current_scene.selected = self
	pass

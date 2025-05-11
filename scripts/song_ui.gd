extends Control
@onready var Title = $Title
@onready var BG = $BG
@onready var select = $"../../.."
var diff_scene = load("res://objects/diff.tscn")
var folder
var title = "?"
var bpm = "?"
var songFile
var map = []
#signal button_pressed
var sizeY : float
var PositionX
var priority := [
		"easy", "normal", "hard", "expert", "insane", "master"
	]
func get_priority_index(s: String) -> int:
	s = s.to_lower()
	for i in priority.size():
		if s.contains(priority[i]):
			return i
	return 9999
func _ready() -> void:
	if Game.select_folder == folder:
		select.update_bg(BG.texture)
	set_mouse_filter(MOUSE_FILTER_STOP)
	connect("mouse_entered", Callable(self, "_on_mouse_entered"))
	connect("mouse_exited", Callable(self, "_on_mouse_exited"))
	Title.text = title
	map.sort_custom(func(a, b):
		var a_index := get_priority_index(a)
		var b_index := get_priority_index(b)
		return a_index < b_index
	)
	for m in map:
		var diff = diff_scene.instantiate()
		diff.map = m
		$HBoxContainer.add_child(diff)
func _process(delta: float) -> void:
	if Game.select_folder == folder:
		$HBoxContainer.visible = true
		$Buttons/Button.mouse_filter = Control.MOUSE_FILTER_STOP
		$Buttons/Button.text = "▶"
		sizeY = 150
		modulate = Color(1, 1, 1)
	elif hovered:
		sizeY = 100
	else:
		$Buttons/Button.mouse_filter = Control.MOUSE_FILTER_IGNORE
		$Buttons/Button.text = ""
		$HBoxContainer.visible = false
		sizeY = 75
		modulate = Color(0.7, 0.7, 0.7)
	size.y = lerp(size.y,sizeY,delta * 10)
	custom_minimum_size.y = lerp(custom_minimum_size.y,sizeY,delta * 15)
func _gui_input(event):
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		Game.select_folder = folder
		Game.select_map = map[0]
		select.update_bg(BG.texture)
var hovered = false
func _on_mouse_entered():
	print("work")
	hovered = true
	pass
func _on_mouse_exited():
	hovered = false
	pass

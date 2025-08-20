extends Control

@onready var Title = $Title
@onready var BG = $BG
var diff_scene = load("res://objects/diff.tscn")

var chart_set: ChartSet
var hovered = false
var tween
func _ready() -> void:
	CM.connect("chartset_selected", Callable(self, "_select_event"))
	if chart_set:
		Title.text = chart_set.meta_title
		load_background()
		set_mouse_filter(MOUSE_FILTER_STOP)
		connect("mouse_entered", Callable(self, "_on_mouse_entered"))
		connect("mouse_exited", Callable(self, "_on_mouse_exited"))
func _select_event():
	if CM.ss != chart_set:
		_unselect()
func _select():
	animate_size(200.0)
	modulate = Color("ffffff")
	reload()
	$Buttons/Button.text = "PLAY"
func _unselect():
	$HBoxContainer.get_children().map(func(c): c.queue_free())
	animate_size(75.0)
	modulate = Color("a2a2a2")
	$Buttons/Button.text = ""
func reload():
	chart_set.charts.sort_custom(func(a, b):
		return a.diff_value < b.diff_value
		)
	$HBoxContainer.get_children().map(func(c): c.queue_free())
	var closest_map = chart_set.charts[0]
	var closest_diff = abs(closest_map.diff_value - CM.lastSelectDiff)
	var closest_map_scene
	for chart in chart_set.charts:
		var diff = diff_scene.instantiate()
		if closest_map_scene == null:
			closest_map_scene = diff
		diff.chart = chart
		var diff_gap = abs(chart.diff_value - CM.lastSelectDiff)
		if diff_gap < closest_diff:
			closest_map = chart
			closest_diff = diff_gap
			closest_map_scene = diff
		$HBoxContainer.add_child(diff)
	CM.select_chart(closest_map)
func load_background():
	if chart_set.cover_image:
		BG.texture = chart_set.cover_image
func _gui_input(event):
	if CM.ss != chart_set:
		if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			CM.select_chartset(chart_set)
func _on_mouse_entered():
	if CM.ss != chart_set:
		animate_size(100.0)
func animate_size(target_height: float) -> void:
	tween = create_tween()
	var current_size = custom_minimum_size
	var target_size = Vector2(current_size.x, target_height)
	tween.tween_property(self, "custom_minimum_size", target_size, 0.3).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	custom_minimum_size.y = int(custom_minimum_size.y)
func _on_mouse_exited():
	if CM.ss != chart_set:
		animate_size(75.0)

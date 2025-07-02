extends Control

@onready var Title = $Title
@onready var BG = $BG
var diff_scene = load("res://objects/diff.tscn")

var beatmap_set: BeatmapSet
var hovered = false
var tween
func _ready() -> void:
	if beatmap_set:
		Title.text = beatmap_set.meta_title
		load_background()
		set_mouse_filter(MOUSE_FILTER_STOP)
		connect("mouse_entered", Callable(self, "_on_mouse_entered"))
		connect("mouse_exited", Callable(self, "_on_mouse_exited"))
func _select():
	animate_size(200.0)
	modulate = Color("ffffff")
	reload_beatmap()
	$Buttons/Button.text = "PLAY"
func _unselect():
	$HBoxContainer.get_children().map(func(c): c.queue_free())
	animate_size(75.0)
	modulate = Color("a2a2a2")
	$Buttons/Button.text = ""
func reload_beatmap():
	beatmap_set.beatmaps.sort_custom(func(a, b):
		return a.diff_value < b.diff_value
		)
	$HBoxContainer.get_children().map(func(c): c.queue_free())
	var closest_map = beatmap_set.beatmaps[0]
	var closest_diff = abs(closest_map.diff_value - Game.lastSelectDiff)
	var closest_map_scene
	for beatmap in beatmap_set.beatmaps:
		var diff = diff_scene.instantiate()
		if closest_map_scene == null:
			closest_map_scene = diff
		diff.beatmap = beatmap
		var diff_gap = abs(beatmap.diff_value - Game.lastSelectDiff)
		if diff_gap < closest_diff:
			closest_map = beatmap
			closest_diff = diff_gap
			closest_map_scene = diff
		$HBoxContainer.add_child(diff)
	Game.select_beatmap(closest_map,closest_map_scene)
func load_background():
	if beatmap_set.cover_image:
		BG.texture = beatmap_set.cover_image
	else:
		pass
func _gui_input(event):
	if Game.selected_beatmap_set != beatmap_set:
		if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			Game.select_beatmap_set(beatmap_set,self)
func _on_mouse_entered():
	if Game.selected_beatmap_set != beatmap_set:
		animate_size(100.0)
func animate_size(target_height: float) -> void:
	tween = create_tween()
	var current_size = custom_minimum_size
	var target_size = Vector2(current_size.x, target_height)
	tween.tween_property(self, "custom_minimum_size", target_size, 0.3).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	custom_minimum_size.y = int(custom_minimum_size.y)
func _on_mouse_exited():
	if Game.selected_beatmap_set != beatmap_set:
		animate_size(75.0)

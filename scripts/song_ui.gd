extends Control

@onready var Title = $Title
@onready var BG = $BG
@onready var select = "../../.."
var diff_scene = load("res://objects/diff.tscn")

var beatmap_set: BeatmapSet
var hovered = false
var sizeY: float

func _ready() -> void:
	if beatmap_set:
		Title.text = beatmap_set.meta_title
		load_background()
		set_mouse_filter(MOUSE_FILTER_STOP)
		connect("mouse_entered", Callable(self, "_on_mouse_entered"))
		connect("mouse_exited", Callable(self, "_on_mouse_exited"))

		# 난이도 정렬 후 추가
		beatmap_set.beatmaps.sort_custom(func(a, b):
			return a.diff_value < b.diff_value
		)
		
		for beatmap in beatmap_set.beatmaps:
			var diff = diff_scene.instantiate()
			diff.beatmap = beatmap
			$HBoxContainer.add_child(diff)

func load_background():
	if beatmap_set.cover_image:
		BG.texture = beatmap_set.cover_image
	else:
		BG.texture = load("res://objects/4aaf2f00918ee690a70ffad71acc5459.jpg")

func _process(delta: float) -> void:
	if Game.select_map and Game.select_map in beatmap_set.beatmaps:
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

	size.y = lerp(size.y, sizeY, delta * 10)
	custom_minimum_size.y = lerp(custom_minimum_size.y, sizeY, delta * 15)

func _gui_input(event):
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		if beatmap_set.beatmaps.size() > 0:
			Game.select_map = beatmap_set.beatmaps[0]
			#select.update_bg(BG.texture)

func _on_mouse_entered():
	hovered = true

func _on_mouse_exited():
	hovered = false

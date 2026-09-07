extends Control
class_name GameplaySongMeta

@export var title_label: Label
@export var artist_label: Label
@export var info_label: Label
@export var cover: TextureRect

func _ready() -> void:
	title_label.text = CM.selected_chart.title
	artist_label.text = CM.selected_chart.artist
	info_label.text = CM.selected_chart.difficulty + "(" +CM.selected_chart.creator + ")"
	cover.texture = CM.selected_chart.cover_image

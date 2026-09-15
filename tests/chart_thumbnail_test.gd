extends Node

var failures := 0

func _ready() -> void:
	var button: MenuChartButton = preload("res://scenes/mainmenu/chart.tscn").instantiate()
	add_child(button)
	var first := Chart.new()
	var second := Chart.new()
	var first_item := _item(first)
	var second_item := _item(second)
	var image := Image.create(4, 4, false, Image.FORMAT_RGBA8)
	image.fill(Color.WHITE)
	var texture := ImageTexture.create_from_image(image)
	button.set_item(first_item)
	_check(button.thumb.texture == null, "Pending thumbnail is empty")
	first.cover_image = texture
	CoverLoader.cover_loaded.emit(first, texture)
	_check(button.thumb.texture == texture and button.thumb.self_modulate.a == 0.0, "Loaded thumbnail starts transparent")
	var fade := button.thumb_tween
	fade.pause()
	fade.custom_step(0.1)
	_check(button.thumb.self_modulate.a > 0.0 and button.thumb.self_modulate.a < 1.0, "Thumbnail fades gradually")
	button.set_item(first_item)
	CoverLoader.cover_loaded.emit(first, texture)
	_check(button.thumb_tween == fade and button.thumb.self_modulate.a < 1.0, "Repeated updates preserve the fade")
	fade.custom_step(0.2)
	_check(is_equal_approx(button.thumb.self_modulate.a, 1.0), "Loaded thumbnail becomes fully visible")
	button.set_item(second_item)
	_check(button.thumb.texture == null and button.thumb_tween == null, "Recycled row clears the previous image and tween")
	CoverLoader.cover_loaded.emit(first, texture)
	_check(button.thumb.texture == null, "Late results for a previous chart are ignored")
	CoverLoader.cover_loaded.emit(second, texture)
	var interrupted := button.thumb_tween
	button.set_item(null)
	_check(not interrupted.is_valid() and button.thumb.texture == null, "Hidden row cancels an unfinished fade")
	button.set_item(first_item)
	_check(button.thumb.texture == texture and button.thumb.self_modulate.a == 1.0, "Cached cover is immediately visible")
	CoverLoader.cover_failed.emit(first)
	_check(button.thumb.texture == null and button.thumb.self_modulate.a == 0.0, "Failed cover clears the image")
	print("Chart thumbnail tests: %d failures" % failures)
	get_tree().quit(1 if failures else 0)

func _item(chart: Chart) -> SongListItem:
	var result := SongListItem.new()
	result.primary_chart = chart
	result.charts = [chart]
	return result

func _check(condition: bool, message: String) -> void:
	if not condition:
		failures += 1
		push_error(message)

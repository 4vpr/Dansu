extends Control
class_name SongFilterPopup

## Shared modal for local song selection and the online catalogue.
signal applied(filters: Dictionary)
signal visibility_set(blocked: bool)

var _online := false
var _open := false
var _saved: Dictionary = {}
@export_group("Node References")
@export var _sort: OptionButton
@export var _status: OptionButton
@export var _played: OptionButton
@export var _reverse: CheckBox
@export var _nsfl: CheckBox
@export var _error: Label
@export var _panel: PanelContainer
@export var _overlay: ColorRect
@export var min_length: LineEdit
@export var max_length: LineEdit
@export var min_rating: LineEdit
@export var max_rating: LineEdit
@export var max_size: LineEdit
@export var rank_status_row: Control
@export var content_row: Control
@export var max_download_row: Control
@export var close_button: Button
@export var reset_button: Button
@export var cancel_button: Button
@export var apply_button: Button
var _fields: Dictionary
var _server_rows: Array[Control]
var _tween: Tween
var _previous_focus: Control

func _ready() -> void:
	_fields = {
		"min_length_ms": min_length,
		"max_length_ms": max_length,
		"min_rating": min_rating,
		"max_rating": max_rating,
		"max_size_bytes": max_size,
	}
	_server_rows = [rank_status_row, content_row, max_download_row]
	_overlay.gui_input.connect(func(event: InputEvent):
		if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			close_popup()
	)
	close_button.pressed.connect(close_popup)
	reset_button.pressed.connect(func(): _sync(SongFilters.defaults(_online)))
	cancel_button.pressed.connect(close_popup)
	apply_button.pressed.connect(_apply)

func show_popup(online: bool, values: Dictionary, authenticated: bool = false) -> void:
	_online = online
	_saved = values.duplicate(true)
	_sort.clear()
	var options := {"Newest": "newest", "Length": "length", "Farming": "farming", "Popularity": "popularity"} if online else {"Title": "title", "Artist": "artist", "Difficulty": "rating", "Recently played": "recent", "Length": "length"}
	for caption in options:
		_sort.add_item(caption)
		_sort.set_item_metadata(_sort.item_count - 1, options[caption])
	for row in _server_rows:
		row.visible = online
	_played.disabled = online and not authenticated
	_sync(_saved)
	_previous_focus = get_viewport().gui_get_focus_owner()
	_open = true
	show()
	visibility_set.emit(true)
	_animate(true)
	_sort.grab_focus()

func _sync(values: Dictionary) -> void:
	for i in range(_sort.item_count):
		if _sort.get_item_metadata(i) == values.get("sort"):
			_sort.select(i)
	_reverse.button_pressed = values.get("reverse", false)
	_nsfl.button_pressed = values.get("nsfl", false)
	_status.select(maxi(0, ["", "ranked", "approved", "unranked"].find(values.get("status", ""))))
	_played.select(0 if not values.has("played") else (1 if values.played else 2))
	for key in _fields:
		var divisor := 1000.0 if key.ends_with("_ms") else (1048576.0 if key == "max_size_bytes" else 1.0)
		_fields[key].text = str(float(values[key]) / divisor) if values.has(key) else ""
	_error.text = ""

func _apply() -> void:
	var values := {"sort": _sort.get_selected_metadata(), "reverse": _reverse.button_pressed, "nsfl": _nsfl.button_pressed if _online else false}
	for key in _fields:
		if not _online and key == "max_size_bytes":
			continue
		var text_value: String = _fields[key].text.strip_edges()
		if text_value.is_empty():
			continue
		if not text_value.is_valid_float() or not is_finite(float(text_value)) or float(text_value) < 0:
			_error.text = "Enter a non-negative number, or leave the field empty."
			return
		var multiplier := 1000.0 if key.ends_with("_ms") else (1048576.0 if key == "max_size_bytes" else 1.0)
		values[key] = float(text_value) * multiplier
		if multiplier != 1.0:
			values[key] = int(values[key])
	for suffix in ["rating", "length_ms"]:
		if values.has("min_" + suffix) and values.has("max_" + suffix) and values["min_" + suffix] > values["max_" + suffix]:
			_error.text = "The minimum must not exceed the maximum."
			return
	if _online and _status.selected > 0:
		values.status = ["", "ranked", "approved", "unranked"][_status.selected]
	if not _played.disabled and _played.selected > 0:
		values.played = _played.selected == 1
	applied.emit(values)
	close_popup()

func is_open() -> bool:
	return visible

func close_popup() -> void:
	if not _open:
		return
	_open = false
	_animate(false)

func _input(event: InputEvent) -> void:
	if visible and event.is_action_pressed("ui_cancel"):
		close_popup()
		get_viewport().set_input_as_handled()

func _animate(opening: bool) -> void:
	if _tween:
		_tween.kill()
	_panel.pivot_offset = _panel.size * 0.5
	_tween = create_tween().set_parallel(true)
	if opening:
		_panel.scale = Vector2.ONE * 0.9
		modulate.a = 0
		_tween.tween_property(self, "modulate:a", 1.0, 0.12)
		_tween.tween_property(_panel, "scale", Vector2.ONE, 0.22).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	else:
		_tween.tween_property(self, "modulate:a", 0.0, 0.14)
		_tween.tween_property(_panel, "scale", Vector2.ONE * 0.94, 0.14)
		_tween.finished.connect(func():
			hide()
			visibility_set.emit(false)
			if is_instance_valid(_previous_focus):
				_previous_focus.grab_focus()
		)

extends Panel

@onready var vbox = $Vbox
@onready var root = get_tree().current_scene
@onready var divis: HSlider = $Defaults/Divis
@onready var divis_label: Label = $Defaults/DivisLabel
var allowed_divis := [1, 2, 3, 4, 5, 6, 7, 8, 12, 16]
var selected
func _ready() -> void:
	# Configure the slider to discrete indices 0..allowed_divis.size()-1
	divis.min_value = 0
	divis.max_value = allowed_divis.size() - 1
	divis.step = 1
	# Initialize slider from current root.beatsdiv
	var idx := allowed_divis.find(int(root.beatsdiv))
	if idx == -1:
		idx = 1 # default to 2
	divis.value = idx
	_update_divis_label(allowed_divis[idx])
	divis.value_changed.connect(_on_divis_slider_changed)
func _addItem(_name,_value):
	var label = Label.new()
	var edit = LineEdit.new()
	edit.set_meta("value",_name)
	edit.text_submitted.connect(_on_text_changed.bind(edit))
	#edit.set_regex(regex)
	label.text = _name
	edit.text = str(_value)
	vbox.add_child(label)
	vbox.add_child(edit)
	pass
func _update(object) -> void:
	for item in vbox.get_children():
		item.queue_free()
	if object.get("time") != null:
		_addItem("time",object.time)
	if object.get("start") != null:
		_addItem("start",object.start)
	if object.get("end") != null:
		_addItem("end",object.end)
	if object.get("pos") != null:
		_addItem("pos",object.pos)
	if object.get("animation") != null:
		_addItem("animation",object.animation)
	pass
func _on_divis_slider_changed(_value: float) -> void:
	var idx := int(divis.value)
	idx = clamp(idx, 0, allowed_divis.size() - 1)
	var value = allowed_divis[idx]
	root.beatsdiv = value
	_update_divis_label(value)

func _update_divis_label(value: int) -> void:
	divis_label.text = "1/%d (%d)" % [value, value]
func _on_text_changed(text,edit):
	var meta = edit.get_meta("value")
	if text.is_valid_float():
		if meta == "start":
			selected.start = float(text)
		if meta == "end":
			selected.end = float(text)
		if meta == "time":
			selected.time = float(text)
		if meta == "pos":
			selected.pos = float(text)
		if meta == "animation":
			selected.animation = float(text)
		selected._update()
		edit.release_focus()
	else:
		pass
	
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	if root.selected != null && root.selected != selected:
		selected = root.selected
		_update(selected)
		pass

extends Panel

@onready var vbox = $Vbox
@onready var root = get_tree().current_scene
@onready var divis = $Defaults/Divis
var selected

func _ready() -> void:
	divis.text_submitted.connect(_on_divis_changed)
	divis.text = str(root.beatsdiv)
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
func _on_divis_changed(text):
	if text.is_valid_int():
		root.beatsdiv = int(text)
	divis.release_focus()
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

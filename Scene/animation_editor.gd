extends Node
@onready var root = $"../.."
@onready var option = $OptionButton
@onready var box = $"../VBoxContainer"
@onready var animation_scene = load("res://objects/editor/animation.tscn")

func _ready() -> void:
	option.item_selected.connect(_on_item_selected)
	if root.selected_animation == null:
		self.visible = false
	$"../New".pressed.connect(_new_animation)
	$ADD.pressed.connect(_add_frame)
	$REMOVE.pressed.connect(_remove_frame)
	$fps.text_submitted.connect(_fps_change)
	$name.text_submitted.connect(_name_change)
func _fps_change(value:String) -> void:
	root.selected_animation["fps"] = float(value)
func _name_change(value:String) -> void:
	root.selected_animation["name"] = value
	for child in box.get_children():
		if child.has_method("_update"):
			child._update()
func _add_frame() -> void:
	root.selected_animation["frames"].insert(root.selected_frame + 1, root.selected_animation["frames"][root.selected_frame])
	root.selected_animation["frame_filenames"].insert(root.selected_frame + 1, root.selected_animation["frame_filenames"][root.selected_frame])
	
	_update()
	root.selected_frame += 1
	pass
func _remove_frame() -> void:
	if root.selected_animation["frames"].size() > 1:
		root.selected_animation["frames"].remove_at(root.selected_frame)
		root.selected_animation["frame_filenames"].remove_at(root.selected_frame)
		if root.selected_frame > 0:
			root.selected_frame -= 1
		_update()
func _new_animation() -> void:
	var used_ids = []
	for animation in root.animations:
		used_ids.append(int(animation["id"]))
	var id = 1
	var new_frame = []
	new_frame.append(root.sprites[0]["texture"])
	var new_frame_filename = []
	new_frame_filename.append(root.sprites[0]["filename"])
	while id in used_ids:
		id += 1
	print(id)
	var new_animation = {
		"id" = id,
		"name" = "new animation",
		"fps" = 10.0,
		"effect" = "none",
		"frames" = new_frame,
		"frame_filenames" = new_frame_filename
	}
	root.animations.append(new_animation)
	var new_anim_scene = animation_scene.instantiate()
	new_anim_scene.animation = new_animation
	box.add_child(new_anim_scene)
func _update_item_button() -> void:
	var s = root.selected_animation
	option.select(-1)
	for i in option.get_item_count():
		if root.selected_animation["frame_filenames"][root.selected_frame] == $OptionButton.get_item_text(i):
			option.select(i)
func _update() -> void:
	if root.selected_animation != null && root.selected_animation in root.animations:
		self.visible = true
		$fps.text = str(root.selected_animation["fps"])
		$name.text = root.selected_animation["name"]
		$FramesContainer.get_children().map(func(c): c.queue_free())
		var i = 0
		for frame in root.selected_animation["frames"]:
			i += 1
			var button = Button.new()
			button.text = str(i)
			button.pressed.connect(_frameButton.bind(button.text))
			$FramesContainer.add_child(button)
			root.selected_frame = 0
		updateTexture(0)
		_update_item_button()
	else:
		self.visible = false
func _frameButton(text_value: String) -> void:
	root.selected_frame = int(text_value) - 1
	updateTexture(int(text_value) - 1)
	_update_item_button()

func updateTexture(i: int) -> void:
	$TextureRect.texture = root.selected_animation["frames"][i]

func _on_item_selected(index):
	var text = option.get_item_text(index)
	root.selected_animation["frames"][root.selected_frame] = root.beatmap._load_texture(text)
	root.selected_animation["frame_filenames"][root.selected_frame] = text
	updateTexture(root.selected_frame)

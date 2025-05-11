extends Node
var score = Score.new()
var beatmap = Game.select_map

func _ready() -> void:
	$Panel/Button.pressed.connect(_exit)
	var image_extensions = [".jpg", ".jpeg", ".png"]
	var dir = DirAccess.open(Game.select_folder)
	var image_path := ""
	if dir:
		dir.list_dir_begin()
		var file_name = dir.get_next()
		while file_name != "":
			for ext in image_extensions:
				if file_name.to_lower().ends_with(ext):
					image_path = Game.select_folder.path_join(file_name)
					break
			if image_path != "":
				break
			file_name = dir.get_next()
		dir.list_dir_end()
	if image_path != "":
		var image = Image.new()
		var err = image.load(image_path)
		if err == OK:
			var tex = ImageTexture.create_from_image(image)
			$TextureRect.texture = tex
			pass
	score = Game.score
	$Panel/Score.text = str(int(score.getScore() * 10000))
	$Rank.text = score.getRank()
	$Panel/Jvalue.text = str(score.c_perfect_plus) + "\n" + str(score.c_perfect) + "\n" + str(score.c_good) + "\n" + str(score.c_ok) + "\n" + str(score.c_bad) + "\n" + str(score.c_miss) + "\n"
	pass

func _process(delta: float) -> void:
	if Input.is_action_just_pressed("ui_cancel"):
			_exit()
	pass

func _exit() -> void:
	get_tree().change_scene_to_file("res://Scene/SongSelect.tscn")

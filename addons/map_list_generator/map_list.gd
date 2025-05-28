@tool
extends EditorPlugin

var button: Button

func _enter_tree():
	button = Button.new()
	button.text = "맵리스트 갱신"
	button.pressed.connect(_generate_map_list)
	add_control_to_container(EditorPlugin.CONTAINER_TOOLBAR, button)

func _exit_tree():
	remove_control_from_container(EditorPlugin.CONTAINER_TOOLBAR, button)
	button.queue_free()
func _generate_map_list():
	var root_path = "res://song"
	var output_path = "res://song/map_list.json"
	var map_list = []
	var dir = DirAccess.open(root_path)
	if dir:
		dir.list_dir_begin()
		var folder_name = dir.get_next()
		while folder_name != "":
			if dir.current_is_dir() and folder_name != "." and folder_name != "..":
				var sub_dir = DirAccess.open(root_path.path_join(folder_name))
				if sub_dir:
					sub_dir.list_dir_begin()
					var file_name = sub_dir.get_next()
					while file_name != "":
						if file_name.ends_with(".json"):
							var sub_path = root_path.path_join(folder_name).path_join(file_name)
							map_list.append(sub_path)
						file_name = sub_dir.get_next()
					sub_dir.list_dir_end()
			folder_name = dir.get_next()
		dir.list_dir_end()

	var json_data = { "maps": map_list }
	var json_string = JSON.stringify(json_data, "\t")

	var file = FileAccess.open(output_path, FileAccess.WRITE)
	if file:
		file.store_string(json_string)
		file.close()
		print_rich("[color=lime]map_list.json 생성 완료![/color]")
	else:
		print_rich("[color=red]map_list.json 생성 실패![/color]")

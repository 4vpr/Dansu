extends EditorScript

func _run():
	var root_path = "res://songs"
	var output_path = "res://songs/map_list.json"
	var map_list = []

	var dir = DirAccess.open(root_path)
	if dir:
		dir.list_dir_begin()
		var folder_name = dir.get_next()
		while folder_name != "":
			if dir.current_is_dir() and folder_name != "." and folder_name != "..":
				var sub_path = root_path.path_join(folder_name).path_join("map.json")
				if FileAccess.file_exists(sub_path):
					map_list.append(sub_path)
			folder_name = dir.get_next()
		dir.list_dir_end()

	var json_data = { "maps": map_list }
	var json_string = JSON.stringify(json_data, "\t")

	var file = FileAccess.open(output_path, FileAccess.WRITE)
	if file:
		file.store_string(json_string)
		file.close()
		print("map_list.json Done")
	else:
		print("map_list.json Failed")

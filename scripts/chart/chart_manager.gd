extends Node

# ===== Signals =====

@warning_ignore("unused_signal")
signal chartset_loaded(_set)

@warning_ignore("unused_signal")
signal progress_changed(ratio: float) # 0.0 ~ 1.0

@warning_ignore("unused_signal")
signal loading_finished()

@warning_ignore("unused_signal")
signal chart_selected(chart)

@warning_ignore("unused_signal")
signal chartset_selected(chart_set)

@warning_ignore("unused_signal")
signal chart_loaded()

# ===== State =====
var charts: Array = []
var sc : Chart # selected chart
var ss : ChartSet # selected set
var folders: Array[String] = []
var lastSelectedDiff := 0

# ===== Loader internals =====
var thread_count: int = 4
var _threads: Array[Thread] = []
var _folders_to_load: Array[String] = []
var _loaded_count: int = 0
var _stop := false
var _mutex := Mutex.new()

func _ready() -> void:
	folders = get_folders_in_path("user://Songs")
	start_loading(folders, 4)

func reload() -> void:
	folders = get_folders_in_path("user://Songs")
	start_loading(folders,4)
	
# --- Public: start/stop loading ---
func start_loading(folders_in: Array[String], thread_num: int = 4) -> void:
	print("start loading")
	stop()
	_folders_to_load = folders_in.duplicate()
	_loaded_count = 0
	_stop = false
	thread_count = thread_num
	_threads.clear()
	for i in range(thread_count):
		var t := Thread.new()
		_threads.append(t)
		t.start(Callable(self, "_thread_func"))

func stop() -> void:
	_stop = true
	for t in _threads:
		if t.is_started():
			t.wait_to_finish()
	_threads.clear()

# ===== Export / Import =====
# Export currently selected ChartSet (ss) to user://Songs/Export as .dansu (zip)
func export_selected_chartset() -> void:
	if ss == null:
		print("[Export] No chart set selected.")
		return
	var source_dir: String = ss.folder_path
	if source_dir == "" or not DirAccess.dir_exists_absolute(source_dir):
		print("[Export] Invalid source folder:", source_dir)
		return

	var export_root := "user://Songs/Export"
	DirAccess.make_dir_recursive_absolute(export_root)

	var folder_name := source_dir.get_file() # last folder name of the chart set
	if folder_name == "":
		folder_name = "chartset_" + str(randi_range(100000, 999999))

	var export_file := export_root.path_join(folder_name + ".dansu")
	var ok = _zip_directory_with_root(source_dir, export_file, folder_name)
	if ok:
		print("[Export] Saved:", export_file)
	else:
		print("[Export] Failed:", export_file)

# Import a .dansu (zip) file into user://Songs and load it immediately
func import_dansu(archive_path: String) -> void:
	if archive_path == "" or not FileAccess.file_exists(archive_path):
		print("[Import] File not found:", archive_path)
		return
	var reader := ZIPReader.new()
	var open_status := reader.open(ProjectSettings.globalize_path(archive_path))
	if open_status != OK:
		print("[Import] ZIP open failed (status:", open_status, ") for:", archive_path)
		return

	var files: PackedStringArray = reader.get_files()
	if files.is_empty():
		reader.close()
		print("[Import] Empty archive:", archive_path)
		return

	# Determine top-level folder in archive (if any)
	var top_level := ""
	for f in files:
		var parts := f.split("/", false)
		if parts.size() > 1 and parts[0] != "":
			top_level = parts[0]
			break

	var base_name := archive_path.get_file().get_basename()
	var chartset_name := (top_level if top_level != "" else base_name)

	var songs_root := "user://Songs"
	DirAccess.make_dir_recursive_absolute(songs_root)
	var target_root := songs_root.path_join(chartset_name)
	# Ensure unique folder if already exists
	var unique_root := target_root
	var suffix := 1
	while DirAccess.dir_exists_absolute(unique_root):
		unique_root = target_root + "_" + str(suffix)
		suffix += 1
	DirAccess.make_dir_recursive_absolute(unique_root)

	for entry in files:
		# Skip directory entries
		if entry.ends_with("/"):
			continue
		var bytes := reader.read_file(entry)
		var rel_path := entry
		if top_level != "" and entry.begins_with(top_level + "/"):
			rel_path = entry.substr(top_level.length() + 1)
		# Guard against empty rel_path (e.g., if entry was exactly top-level folder)
		if rel_path == "":
			continue
		var out_path := unique_root.path_join(rel_path)
		DirAccess.make_dir_recursive_absolute(out_path.get_base_dir())
		var fa = FileAccess.open(out_path, FileAccess.WRITE)
		if fa:
			fa.store_buffer(bytes)
			fa.close()
		else:
			print("[Import] Failed to write:", out_path)

	reader.close()

	# Load chart set for metadata of imported files
	var new_set := ChartSet.new()
	new_set.load_from_folder(unique_root)
	if new_set.charts.size() == 0:
		print("[Import] No charts found after import at:", unique_root)
		return

	# Build index of existing charts by uuid and remember owning set
	var uuid_to_chart: Dictionary = {}
	var uuid_to_set: Dictionary = {}
	for s in charts:
		for c in s.charts:
			uuid_to_chart[c.map_uuid] = c
			uuid_to_set[c.map_uuid] = s

	# Determine if any chart in the import matches an existing set by uuid
	var matched_set: ChartSet = null
	for c in new_set.charts:
		if uuid_to_set.has(c.map_uuid):
			matched_set = uuid_to_set[c.map_uuid]
			break

	var any_updated := false
	var any_new_into_matched := false
	var all_identical := true

	if matched_set != null:
		# Merge/update into the matched existing set
		for nc in new_set.charts:
			var new_json = _read_json(nc.json_path)
			if typeof(new_json) != TYPE_DICTIONARY:
				continue
			var new_uuid: String = new_json.get("uuid", "0")
			var new_hash := Chart.compute_hash_from_json(new_json)
			if uuid_to_chart.has(new_uuid):
				var ec: Chart = uuid_to_chart[new_uuid]
				var existing_json = _read_json(ec.json_path)
				var existing_hash := Chart.compute_hash_from_json(existing_json) if typeof(existing_json) == TYPE_DICTIONARY else ""
				if existing_hash == new_hash and existing_hash != "":
					# identical -> skip
					continue
				# update existing chart assets + json (overwrite existing json file path)
				_copy_chart_resources(nc.folder_path, ec.folder_path, new_json)
				_copy_file(nc.json_path, ec.json_path)
				any_updated = true
				all_identical = false
			else:
				# new chart -> add into matched set folder
				_copy_chart_resources(nc.folder_path, matched_set.folder_path, new_json)
				_copy_file(nc.json_path, matched_set.folder_path.path_join(nc.json_path.get_file()))
				any_new_into_matched = true
				all_identical = false

		# Clean up extracted folder; reload sets to reflect changes
		_delete_dir_recursive(unique_root)
		if any_updated or any_new_into_matched:
			print("[Import] Merged into existing set:", matched_set.folder_path, " updated:", any_updated, " added:", any_new_into_matched)
			reload()
		else:
			print("[Import] All charts identical; nothing changed.")
		return

	# No matched set -> treat as new set
	charts.append(new_set)
	call_deferred("_emit_loaded", new_set)
	print("[Import] Imported to:", unique_root)

# Internal: zip a directory so that the root folder in the archive is `root_name`
func _zip_directory_with_root(src_dir: String, out_zip_path: String, root_name: String) -> bool:
	var packer := ZIPPacker.new()
	var status := packer.open(ProjectSettings.globalize_path(out_zip_path))
	if status != OK:
		print("[ZIP] Failed to open:", out_zip_path, " status:", status)
		return false
	var ok := _zip_dir_recursive(packer, src_dir, root_name)
	packer.close()
	return ok

func _zip_dir_recursive(packer: ZIPPacker, current_dir_path: String, rel_prefix: String) -> bool:
	var dir := DirAccess.open(current_dir_path)
	if not dir:
		print("[ZIP] Cannot open dir:", current_dir_path)
		return false
	dir.list_dir_begin()
	var name := dir.get_next()
	var all_ok := true
	while name != "":
		if name != "." and name != "..":
			if dir.current_is_dir():
				var sub_ok := _zip_dir_recursive(packer, current_dir_path.path_join(name), rel_prefix.path_join(name))
				all_ok = all_ok and sub_ok
			else:
				var file_path := current_dir_path.path_join(name)
				var data := FileAccess.get_file_as_bytes(file_path)
				var start_status := packer.start_file(rel_prefix.path_join(name))
				if start_status != OK:
					print("[ZIP] start_file failed:", name, " status:", start_status)
					all_ok = false
				else:
					packer.write_file(data)
					packer.close_file()
		name = dir.get_next()
	dir.list_dir_end()
	return all_ok

# ===== Helpers: JSON, hashing, file ops =====
func _read_json(path: String):
	var f := FileAccess.open(path, FileAccess.READ)
	if not f:
		return null
	var txt := f.get_as_text()
	return JSON.parse_string(txt)

func _copy_file(src: String, dst: String) -> void:
	DirAccess.make_dir_recursive_absolute(dst.get_base_dir())
	var data := FileAccess.get_file_as_bytes(src)
	var fa := FileAccess.open(dst, FileAccess.WRITE)
	if fa:
		fa.store_buffer(data)
		fa.close()

func _copy_dir_recursive(src_dir: String, dst_dir: String) -> void:
	if not DirAccess.dir_exists_absolute(src_dir):
		return
	DirAccess.make_dir_recursive_absolute(dst_dir)
	var dir := DirAccess.open(src_dir)
	if not dir:
		return
	dir.list_dir_begin()
	var name := dir.get_next()
	while name != "":
		if name != "." and name != "..":
			var src_path := src_dir.path_join(name)
			var dst_path := dst_dir.path_join(name)
			if dir.current_is_dir():
				_copy_dir_recursive(src_path, dst_path)
			else:
				_copy_file(src_path, dst_path)
		name = dir.get_next()
	dir.list_dir_end()

func _copy_chart_resources(src_folder: String, dst_folder: String, json: Dictionary) -> void:
	# Copy audio if present
	var audio_file: String = json.get("file_audio", "")
	if audio_file != "":
		var src_audio := src_folder.path_join(audio_file)
		if FileAccess.file_exists(src_audio):
			_copy_file(src_audio, dst_folder.path_join(audio_file))
	# Copy sprite directory wholesale if exists
	var src_sprite_dir := src_folder.path_join("sprite")
	if DirAccess.dir_exists_absolute(src_sprite_dir):
		_copy_dir_recursive(src_sprite_dir, dst_folder.path_join("sprite"))

func _delete_dir_recursive(path: String) -> void:
	if not DirAccess.dir_exists_absolute(path):
		return
	var dir := DirAccess.open(path)
	if not dir:
		return
	dir.list_dir_begin()
	var name := dir.get_next()
	while name != "":
		if name != "." and name != "..":
			var p := path.path_join(name)
			if dir.current_is_dir():
				_delete_dir_recursive(p)
			else:
				DirAccess.remove_absolute(p)
		name = dir.get_next()
	dir.list_dir_end()
	DirAccess.remove_absolute(path)

# --- Worker thread ---
func _thread_func() -> void:
	while true:
		if _stop:
			return
		var folder: String = ""
		_mutex.lock()
		if _folders_to_load.size() > 0:
			folder = _folders_to_load[0]
			_folders_to_load.remove_at(0)
		_mutex.unlock()

		if folder == "":
			return # 더 이상 작업 없음

		var _set := ChartSet.new()
		_set.load_from_folder(folder)
		if _set.charts.size() > 0:
			call_deferred("_emit_loaded", _set)

		_mutex.lock()
		_loaded_count += 1
		var progress := float(_loaded_count) / float(max(1, _loaded_count + _folders_to_load.size()))
		call_deferred("_emit_progress", progress)
		if _folders_to_load.is_empty():
			call_deferred("_emit_finished")
		_mutex.unlock()

# --- Emitters (main thread) ---
func _emit_loaded(_set: ChartSet) -> void:
	if charts.size() == 0:
		select_chartset(_set)
	charts.append(_set)
	emit_signal("chartset_loaded", _set)

func _emit_progress(ratio: float) -> void:
	emit_signal("progress_changed", ratio)

func _emit_finished() -> void:
	emit_signal("loading_finished")
	if charts.size() > 0:
		ss = charts[0]
		emit_signal("chart_loaded")

# ===== Manager helpers =====
func get_folders_in_path(path: String) -> Array[String]:
	var out: Array[String] = []
	var dir := DirAccess.open(path)
	if dir:
		dir.list_dir_begin()
		var file_name := dir.get_next()
		while file_name != "":
			if dir.current_is_dir() and file_name != "." and file_name != "..":
				out.append(path.path_join(file_name))
			file_name = dir.get_next()
		dir.list_dir_end()
	else:
		print(path)
	return out

func select_chartset(chartset) -> void:
	ss = chartset
	emit_signal("chartset_selected", chartset)

func select_chart(chart) -> void:
	sc = chart
	emit_signal("chart_selected", chart)

# 새 난이도 파일 추가
func _add_new_difficulty() -> void:
	if sc == null or ss == null:
		return
	var path: String = sc.json_path
	var file := FileAccess.open(path, FileAccess.READ)
	if file:
		var content := file.get_as_text()
		file.close()
		var json_data: Dictionary = JSON.parse_string(content)
		if typeof(json_data) != TYPE_DICTIONARY:
			return
		json_data.erase("rails")
		json_data.erase("notes")
		if json_data.has("difficulty_name"):
			json_data["difficulty_name"] = "New"
			json_data["uuid"] = "0"
			json_data["difficulty_value"] = 0
		var json_name = str(randi_range(100000, 999999)) + ".json"
		var target_path = ss.folder_path.path_join(json_name)
		var target_file = FileAccess.open(target_path, FileAccess.WRITE)
		if target_file:
			var json_string := JSON.stringify(json_data, "\t")
			target_file.store_string(json_string)
			target_file.close()
			var new_chart := Chart.new()
			new_chart.load_from_json(target_path)
			new_chart.folder_path = ss.folder_path
			for child in $MapPanel/VBoxContainer.get_children():
				if "chart_set" in child and child.chart_set == ss:
					child.chart_set.charts.append(new_chart)
					sc = new_chart
					if "reload" in child:
						child.reload()
					break

# 새 차트셋 폴더 생성
func _new_chart_set(files: Array[String]) -> void:
	for file_path in files:
		var file := file_path.get_file()
		var supported_extensions := [".mp3", ".wav_FIX", ".ogg_FIX"]
		for ext in supported_extensions:
			if file_path.to_lower().ends_with(ext):
				var song_file_name := file.get_basename()
				var base_dir := "user://Songs"
				DirAccess.make_dir_recursive_absolute(base_dir)
				var random_number := str(randi_range(100000, 999999)) + " "
				var folder_name := random_number + song_file_name
				var folder_path := base_dir.path_join(folder_name)
				DirAccess.make_dir_recursive_absolute(folder_path)
				DirAccess.make_dir_recursive_absolute(folder_path.path_join("sprite"))

				# 오디오 복사
				var src_file := FileAccess.open(file_path, FileAccess.READ)
				if src_file:
					var audio_bytes := src_file.get_buffer(src_file.get_length())
					src_file.close()
					var dst_file := FileAccess.open(folder_path.path_join(file), FileAccess.WRITE)
					if dst_file:
						dst_file.store_buffer(audio_bytes)
						dst_file.close()

				# 기본 JSON 생성
				var new_json := str(randi_range(100000, 999999)) + ".json"
				var json_path := folder_path.path_join(new_json)
				var json_data := {
					"file_audio": file,
					"title": song_file_name
				}
				var json := FileAccess.open(json_path, FileAccess.WRITE)
				if json:
					json.store_string(JSON.stringify(json_data, "\t"))
					json.close()

func _load_built_in_maps():
	var list_path = "res://song/map_list.json"
	if not FileAccess.file_exists(list_path):
		print("내장 맵 목록 파일 없음: ", list_path)
		return
	var file = FileAccess.open(list_path, FileAccess.READ)
	var json = JSON.parse_string(file.get_as_text())
	if json.has("maps"):
		var loaded_folders = {}
		for map_path in json["maps"]:
			var folder = map_path.get_base_dir()
			if not loaded_folders.has(folder):
				loaded_folders[folder] = true

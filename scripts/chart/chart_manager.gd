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
var sc # selected chart
var ss # selected set
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

# --- Public: start/stop loading ---
func start_loading(folders_in: Array[String], thread_num: int = 4) -> void:
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

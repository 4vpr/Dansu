extends Node

var db = DansuDB.new()
const verbosity_level : int = SQLite.VERBOSE

var DB_PATH := "user://data.db"

var SONG_PATH := "user://Songs"
var FOLDER_PATHS_CACHE := "user://cache"
var song_folders_cache: Array[String] = []
var song_folders: Array[String] = []

func _init():
	db._ready()
	sync_folders()
	get_all_charts()
	Chart.ensure_table_for(db)
	Score.ensure_table_for(db)
	User.ensure_table_for(db)

# 메모리 상 캐시
var all_charts: Array = []
var result_charts: Array = []

func get_all_charts():
	all_charts = db.select_rows("charts","",["*"])

# 폴더 캐시 읽기
func read_folder_cache():
	song_folders_cache.clear()
	var file := FileAccess.open(FOLDER_PATHS_CACHE, FileAccess.READ)
	if file:
		while not file.eof_reached():
			var line := file.get_line()
			if line != "":
				song_folders_cache.append(line)
		file.close()
	else:
		var new_file := FileAccess.open(FOLDER_PATHS_CACHE, FileAccess.WRITE)
		if new_file:
			new_file.store_string("")
			new_file.close()

func write_folder_cache():
	var file := FileAccess.open(FOLDER_PATHS_CACHE, FileAccess.WRITE)
	if file:
		for folder_name in song_folders:
			file.store_line(folder_name)
		file.close()

func load_folders():
	song_folders.clear()
	var dir := DirAccess.open(SONG_PATH)
	if dir:
		dir.list_dir_begin()
		var file_name := dir.get_next()
		while file_name != "":
			if dir.current_is_dir() and file_name != "." and file_name != "..":
				song_folders.append(file_name)
			file_name = dir.get_next()
		dir.list_dir_end()

# 폴더 동기화
func sync_folders():
	read_folder_cache()
	load_folders()

	var added = song_folders.filter(func(f): return not song_folders_cache.has(f))
	var removed = song_folders_cache.filter(func(f): return not song_folders.has(f))

	if added.size() > 0:
		for folder_name in added:
			add_folder_to_db(folder_name)
	if removed.size() > 0:
		for folder_name in removed:
			remove_folder_from_db(folder_name)
	write_folder_cache()

func _get_json_names(folder_name: String) -> Array:
	var folder_path = SONG_PATH.path_join(folder_name)
	var dir := DirAccess.open(folder_path)
	if not dir:
		return []
	var jsons = []
	dir.list_dir_begin()
	var name := dir.get_next()
	while name != "":
		if name.ends_with(".json"):
			var path := name
			jsons.append(path)
		name = dir.get_next()
	dir.list_dir_end()
	return jsons

func _read_json(folder_name:String ,json_file_name: String):
	var folder_path = SONG_PATH.path_join(folder_name)
	if not FileAccess.file_exists(folder_path.path_join(json_file_name)):
		return null
	var f := FileAccess.open(folder_path.path_join(json_file_name), FileAccess.READ)
	if not f:
		return null
	var text := f.get_as_text()
	f.close()
	return JSON.parse_string(text)

func add_folder_to_db(folder_name):
	var json_names := _get_json_names(folder_name)
	if json_names == null:
		return
	for json_name in json_names:
		var chart: Chart = Chart.new()
		chart.json_name = json_name
		chart.folder_name = folder_name
		chart.save(db)

func remove_folder_from_db(folder):
	
	pass

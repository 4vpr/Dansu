extends Node

var db : SQLite = null
const verbosity_level : int = SQLite.VERBOSE

var DB_PATH := "user://data.db"

var SONG_PATH := "user://Songs"
var FOLDER_PATHS_CACHE := "user://cache"
var song_folders_cache: Array[String] = []
var song_folders: Array[String] = []

func _ready():
	create_all()
	sync_folders()
	get_all_charts()

# 메모리 상 캐시
var all_charts: Array = []
var result_charts: Array = []

func get_all_charts():
	db = SQLite.new()
	db.path = DB_PATH
	db.open_db()
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
				song_folders.append(SONG_PATH.path_join(file_name))
			file_name = dir.get_next()
		dir.list_dir_end()

# 폴더 동기화
func sync_folders():
	read_folder_cache()
	load_folders()

	var added = song_folders.filter(func(f): return not song_folders_cache.has(f))
	var removed = song_folders_cache.filter(func(f): return not song_folders.has(f))

	if added.size() > 0:
		refrsh_folders(added)
	if removed.size() > 0:
		removed_folders(removed)

	write_folder_cache()

# 폴더 처리
func refrsh_folders(folders: Array):
	for folder in folders:
		add_folder(folder)

func add_folder(folder):
	var jsons := _get_jsons(folder)
	if jsons == null:
		return
	var i = 0
	for json_file in jsons:
		var json = _read_json(json_file)
		if typeof(json) != TYPE_DICTIONARY:
			return
		var chart_hash := CM.hash_from_json(json)
		var diff = Rating.calculate(json)
		var title = json["title"]
		var artist = json["artist"]
		var file_name = json_file.get_file()
		var found = db.select_rows("chart", "hash = ?", [chart_hash])
		if found.size() > 0:
			db.query_with_bindings(
				"UPDATE chart SET folder_name = ?, file_name = ? WHERE hash = ?",
				[folder, file_name, chart_hash]
			)
		else:
			# 신규 맵 등록
			db.query_with_bindings("""
				INSERT INTO charts (id_online, chartset_id, title, artist, hash, rating, folder_name, file_name)
				VALUES (0, 0, ?, ?, ?, ?, ?, ?)
			""", [title, artist, chart_hash, diff, folder, file_name])

func removed_folders(folders: Array):
	for folder in folders:
		db.query_with_bindings("DELETE FROM charts WHERE folder_name = ?", [folder])
		db.query_with_bindings("DELETE FROM chartsets WHERE folder_name = ?", [folder])

# DB 생성
func create_all():
	create_chartsets()
	create_charts()
	create_scores()

func create_chartsets():
	db = SQLite.new()
	db.path = DB_PATH
	db.open_db()
	db.query("""
	CREATE TABLE IF NOT EXISTS chartsets(
		id_local    INTEGER PRIMARY KEY AUTOINCREMENT,
		id_online   INTEGER DEFAULT 0,
		folder_name TEXT UNIQUE,
		created_at  TIMESTAMP DEFAULT CURRENT_TIMESTAMP
	)
	""")
	db.query("CREATE INDEX IF NOT EXISTS idx_chartset_folder ON chartsets(folder_name)")

func create_charts():
	db = SQLite.new()
	db.path = DB_PATH
	db.open_db()
	db.query("""
	CREATE TABLE IF NOT EXISTS charts(
		id_local    INTEGER PRIMARY KEY AUTOINCREMENT,
		id_online   INTEGER DEFAULT 0,
		chartset_id INTEGER NOT NULL DEFAULT 0,
		title       TEXT NOT NULL,
		artist      TEXT NOT NULL,
		source      TEXT,
		description TEXT,
		creator     TEXT,
		tags        TEXT,
		hash        TEXT NOT NULL,
		rating      REAL,
		folder_name TEXT,
		file_name   TEXT NOT NULL,
		created_at  TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
		FOREIGN KEY(chartset_id) REFERENCES chartsets(id_local)
	)
	""")
	db.query("CREATE INDEX IF NOT EXISTS idx_chart_hash ON charts(hash)")
	db.query("CREATE INDEX IF NOT EXISTS idx_chart_rating ON charts(rating)")

func create_scores():
	db = SQLite.new()
	db.path = DB_PATH
	db.open_db()
	db.query("""
	CREATE TABLE IF NOT EXISTS scores(
		id_local    INTEGER PRIMARY KEY AUTOINCREMENT,
		chart_id    INTEGER NOT NULL,
		chart_hash  TEXT NOT NULL,
		score       INTEGER NOT NULL,
		maxcombo    INTEGER NOT NULL,
		notes       INTEGER NOT NULL,
		justp       INTEGER NOT NULL,
		just        INTEGER NOT NULL,
		good        INTEGER NOT NULL,
		ok          INTEGER NOT NULL,
		nah         INTEGER NOT NULL,
		miss        INTEGER NOT NULL,
		replay_file TEXT,
		created_at  TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
		FOREIGN KEY(chart_id) REFERENCES charts(id_local)
	)
	""")

# 유틸
func _get_jsons(folder: String) -> Array:
	var dir := DirAccess.open(folder)
	if not dir:
		return []
	var jsons = []
	dir.list_dir_begin()
	var name := dir.get_next()
	while name != "":
		if name.ends_with(".json"):
			var path := folder.path_join(name)
			jsons.append(path)
		name = dir.get_next()
	dir.list_dir_end()
	return jsons

func _read_json(path: String):
	if not FileAccess.file_exists(path):
		return null
	var f := FileAccess.open(path, FileAccess.READ)
	if not f:
		return null
	var text := f.get_as_text()
	f.close()
	return JSON.parse_string(text)

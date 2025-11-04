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
		refrsh_folders(added)
	if removed.size() > 0:
		removed_folders(removed)

	write_folder_cache()

# 폴더 처리
func refrsh_folders(folders: Array):
	for folder in folders:
		add_folder_to_db(folder)

func _get_json_paths(folder: String) -> Array:
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

var chart_update_query = "uuid = ?, chartset_id = ?, title = ?, artist = ?, creator = ?, source = ?, tags = ?, hash = ?, rating = ?"
var chart_create_query = "uuid, chartset_id, title, artist, creator, source, tags, hash, rating"

func get_field(chart: Dictionary, chartset_id: int) -> Array:
	return [
			chart["uuid"], # uuid
			chartset_id,    # chartset_id
			chart["title"], # title
			chart["artist"], # artist
			chart["creator"], # creator
			chart["source"], # source
			chart["tags"], # tags
			CM.hash_from_json(chart), # hash
			Rating.calculate(chart), # rating
			CM.get_bpm_max(chart), # bpm_max
			CM.get_bpm_min(chart), # bpm_min
			chart["song_preview"] # song_preview
			]

func add_folder_to_db(folder):
	var json_names := _get_json_paths(folder)
	if json_names == null:
		return
	for json_name in json_names:
		var json = _read_json(folder, json_name)
		if typeof(json) != TYPE_DICTIONARY:
			return
		var chart_hash := CM.hash_from_json(json)
		var found := db.select_rows(
			"chart",
			"uuid = ?",
			[json["uuid"]]
		)
		var field = get_field(json, 0)
		if found.size() > 0:
			db.query_with_bindings(
				"UPDATE chart SET " + chart_update_query,
				field
			)
		else:
			# 신규 맵 등록
			db.query_with_bindings("""
				INSERT INTO charts (uuid, chartset_id, title, artist, creator, source, tags, hash, rating)
				VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)
			""", field)

func removed_folders(folders: Array):
	for folder in folders:
		db.query_with_bindings("DELETE FROM charts WHERE folder_name = ?", [folder])
		db.query_with_bindings("DELETE FROM chartsets WHERE folder_name = ?", [folder])

# Create DB
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
		id    INTEGER PRIMARY KEY AUTOINCREMENT,
		chartset_id INTEGER NOT NULL DEFAULT 0,
		uuid        TEXT NOT NULL,
		title       TEXT NOT NULL,
		artist      TEXT NOT NULL,
		source      TEXT,
		creator     TEXT,
		tags        TEXT,
		hash        TEXT NOT NULL,
		rating      REAL,
		max_bpm     REAL,
		min_bpm     REAL,
		folder_name TEXT,
		length      REAL,
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
		chart_uuid  INTEGER NOT NULL,
		player_id   INTEGER,
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
		FOREIGN KEY(chart_id) REFERENCES charts(id_)
	)
	""")

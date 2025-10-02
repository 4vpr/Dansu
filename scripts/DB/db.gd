extends Node

var db : SQLite = null
const verbosity_level : int = SQLite.VERBOSE

var DB_PATH := "user://data.db"

var SONG_PATH := "user://Songs"
var FOLDER_PATHS_CACHE := "user://cache"
var song_folders_cache := []
var song_folders : Array = []

var all_chartset = []
var result_chartset = []
# 해시 나오는 함수 -> CM.hash_from_json(json: Dictionary)
# 난이도 추출하는 함수 -> DifficultyAnalyzer.calculate_difficulty(json: Dictionary)
func laod():
	read_folder_cache()
	load_folders()
	var add = song_folders.filter(func(x): return song_folders_cache.has(x))
	# db에 추가할 노래폴더 리스트
	var del = song_folders_cache.filter(func(x): return song_folders.has(x))
	# db에서 삭제할 노래폴더 리스트

func read_folder_cache():
	var file := FileAccess.open(FOLDER_PATHS_CACHE, FileAccess.READ)
	if file:
		while not file.eof_reached():
			song_folders_cache.append(file.get_line())
	else:
		var new_file := FileAccess.open(FOLDER_PATHS_CACHE, FileAccess.WRITE)
		if new_file:
			new_file.store_string("")
			new_file.close()

func write_folder_cache():
	var file := FileAccess.open(FOLDER_PATHS_CACHE, FileAccess.WRITE)
	if file:
		for folder_name in song_folders:
			file.store_string(folder_name)
		file.close()

func load_folders():
	var dir := DirAccess.open(SONG_PATH)
	song_folders = []
	if dir:
		dir.list_dir_begin()
		var file_name := dir.get_next()
		while file_name != "":
			if dir.current_is_dir() and file_name != "." and file_name != "..":
				song_folders.append(SONG_PATH.path_join(file_name))
			file_name = dir.get_next()
		dir.list_dir_end()

func remove_chartset(folders : Array):
	for folder in folders:
		#TODO find chartset , chart from db's folder column and remove from db
		pass

func add_chartset(folders : Array):
	for folder in folders:
		#TODO parse chartset, chart and add metadata to db
		pass

func create_all():
	create_chart()
	create_chartset()

func create_chartset():
	db = SQLite.new()
	db.open(DB_PATH)
	db.query("""
	CREATE TABLE IF NOT EXISTS chartsets(
		id_local INTEGER PRIMARY KEY AUTOINCREMENT,
		id_online INTEGER DEFAULT=0,
		folder_name TEXT UNIQUE,
		created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
	)
	""")
	db.query("CREATE INDEX IF NOT EXISTS idx_title ON chartsets(title)")
	db.query("CREATE INDEX IF NOT EXISTS idx_artist ON chartsets(artist)")
	db.query("CREATE INDEX IF NOT EXISTS idx_source ON chartsets(source)")
	db.query("CREATE INDEX IF NOT EXISTS idx_creator ON chartsets(creator)")
	db.query("CREATE INDEX IF NOT EXISTS idx_tags ON chartsets(tags)")

func create_chart():
	db = SQLite.new()
	db.open(DB_PATH)
	db.query("""
	CREATE TABLE IF NOT EXISTS chartset(
		id_local INTEGER PRIMARY KEY AUTOINCREMENT,
		id_online INTEGER NOT NULL,

		chartset_id INTEGER NOT NULL,

		uuid TEXT,
		title TEXT NOT NULL,
		artist TEXT NOT NULL,
		source TEXT,
		description TEXT,
		creator TEXT,
		tags TEXT,

		hash TEXT,
		rating REAL,

		folder_name TEXT UNIQUE,
		file_name TEXT NOT NULL,
		created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,

		FOREIGN KEY(chartset_id) REFERENCES chartsets(id_local)
	)
	""")
	db.query("CREATE INDEX IF NOT EXISTS idx_tags ON chart(hash)")
	db.query("CREATE INDEX IF NOT EXISTS idx_tags ON chart(rating)")
func create_scores():
	db = SQLite.new()
	db.open(DB_PATH)
	db.query("""
	CREATE TABLE IF NOT EXISTS chartset(
		id INTEGER PRIMARY KEY AUTOINCREMENT,
		chart_id INTEGER NOT NULL,
		hash TEXT NOT NULL,
		
		score INTEGER NOT NULL,
		maxcombo INTEGER NOT NULL,
		notes INTEGER NOT NULL,

		justp INTEGER NOT NULL,
		just INTEGER NOT NULL,
		good INTEGER NOT NULL,
		ok INTEGER NOT NULL,
		nah INTEGER NOT NULL,
		miss INTEGER NOT NULL,
		replay_file,
		
		created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
		
		FOREIGN KEY(chart_id) REFERENCES chartsets(id_local)
	)
	""")

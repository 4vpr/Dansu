class_name MiniDB

var sql

func _ready() -> void:
	sql = SQLite.new()
	var ok = sql.open("user://app.db")
	assert(ok, "DB open failed")

func exec(q: String, params: Array = []) -> void:
	sql.query(q, params)

func fetch_all(q: String, params: Array = []) -> Array:
	sql.query(q, params)
	return sql.fetch_array()

func fetch_one(q: String, params: Array = []) -> Dictionary:
	var rows := fetch_all(q, params)
	return rows[0] if rows.size() > 0 else {}

extends RefCounted
class_name MiniModel

static func table() -> String:
	return "change_me"

static func fields() -> Dictionary:
	return {}

var id: int = 0

static func objects(db: MiniDB, cls) -> QuerySet:
	return QuerySet.new(db, cls) # cls는 Score 같은 클래스 자체

static func ensure_table(db: MiniDB, cls) -> void:
	var cols := ["id INTEGER PRIMARY KEY AUTOINCREMENT"]
	for k in cls.fields().keys():
		var f: Field = cls.fields()[k]
		var line := "%s %s" % [k, f.sql_type]
		if not f.null_ok:
			line += " NOT NULL"
		cols.append(line)
	var q := "CREATE TABLE IF NOT EXISTS %s (%s)" % [cls.table(), ", ".join(cols)]
	db.exec(q)
	var info := db.fetch_all("PRAGMA table_info(%s)" % cls.table())
	var existing := {}
	for row in info:
		existing[row["name"]] = true
	for k in cls.fields().keys():
		if not existing.has(k):
			var f2: Field = cls.fields()[k]
			var add := "ALTER TABLE %s ADD COLUMN %s %s" % [cls.table(), k, f2.sql_type]
			if not f2.null_ok:
				add += " NOT NULL DEFAULT " + _sql_default_literal(f2)
			db.exec(add)

static func _sql_default_literal(f: Field) -> String:
	if f.sql_type == "INTEGER" or f.sql_type == "REAL":
		return str(f.default_value)
	return "'" + str(f.default_value).replace("'", "''") + "'"

func save(db: MiniDB) -> void:
	var fs := self.fields().keys()
	if id == 0:
		var cols := ",".join(fs)
		var qs := ",".join(["?"] * fs.size())
		var p: Array = []
		for k in fs:
			p.append(_to_sql_value(k, get(k)))
		var ins := "INSERT INTO %s (%s) VALUES (%s)" % [self.table(), cols, qs]
		db.exec(ins, p)
		var row := db.fetch_one("SELECT last_insert_rowid() AS i")
		id = int(row.get("i", 0))
	else:
		var sets := []
		var p2: Array = []
		for k in fs:
			sets.append("%s = ?" % k)
			p2.append(_to_sql_value(k, get(k)))
		p2.append(id)
		var upd := "UPDATE %s SET %s WHERE id = ?" % [self.table(), ", ".join(sets)]
		db.exec(upd, p2)

func delete(db: MiniDB) -> void:
	if id == 0:
		return
	db.exec("DELETE FROM %s WHERE id = ?" % self.table(), [id])
	id = 0

static func _from_row(cls, row: Dictionary) -> Variant:
	var inst = cls.new()
	inst.id = int(row.get("id", 0))
	for k in cls.fields().keys():
		if not row.has(k):
			continue
		var f: Field = cls.fields()[k]
		var v = row[k]
		if f.sql_type == "TEXT" and typeof(inst.get(k)) in [TYPE_DICTIONARY, TYPE_ARRAY]:
			var parsed = JSON.parse_string(str(v))
			v = parsed if parsed != null else v
		inst.set(k, v)
	return inst

func _to_sql_value(col: String, v: Variant) -> Variant:
	var f: Field = self.fields()[col]
	if f.sql_type == "TEXT" and typeof(v) in [TYPE_DICTIONARY, TYPE_ARRAY]:
		return JSON.stringify(v)
	if f.sql_type == "INTEGER" and typeof(v) == TYPE_BOOL:
		return 1 if v else 0
	return v

extends RefCounted
class_name Model

static func table() -> String:
	return "not-set"

static func fields() -> Dictionary:
	return {}

var id: int = 0

func _defaults() -> void:
	for k in self.fields().keys():
		if not _has_prop(self, k):
			continue
		var f: Field = self.fields()[k]
		var v = f.default_value
		if f.sql_type == "TEXT" and typeof(v) == TYPE_STRING and (v.begins_with("{") or v.begins_with("[")):
			var parsed = JSON.parse_string(v)
			if parsed != null:
				v = parsed
		set(k, v)

static func _from_row(cls, row: Dictionary) -> Variant:
	var inst = cls.new()
	inst.id = int(row.get("id", 0)) if "id" in row else 0
	for k in cls.fields().keys():
		if not (k in row):
			continue
		var f: Field = cls.fields()[k]
		var v = row[k]
		if f.sql_type == "TEXT" and typeof(inst.get(k)) in [TYPE_DICTIONARY, TYPE_ARRAY]:
			var parsed = JSON.parse_string(str(v))
			v = parsed if parsed != null else v
		inst.set(k, v)
	return inst

static func _has_prop(obj: Object, name: String) -> bool:
	for p in obj.get_property_list():
		if p.get("name", "") == name:
			return true
	return false

static func objects(db: DansuDB, cls) -> QuerySet:
	return QuerySet.new(db, cls)

static func ensure_table(db: DansuDB, cls) -> void:
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

	for k in cls.fields().keys():
		var f3: Field = cls.fields()[k]
		if f3.unique:
			var iname := "ux_%s_%s" % [cls.table(), k]
			db.exec("CREATE UNIQUE INDEX IF NOT EXISTS %s ON %s(%s)" % [iname, cls.table(), k])
		elif f3.index:
			var iname2 := "ix_%s_%s" % [cls.table(), k]
			db.exec("CREATE INDEX IF NOT EXISTS %s ON %s(%s)" % [iname2, cls.table(), k])

	# complex index
	if "meta_indices" in cls and typeof(cls.meta_indices) == TYPE_CALLABLE:
		var list = cls.meta_indices()
		for item in list:
			var name = item.get("name", "")
			var cols2: Array = item.get("columns", [])
			if name == "" or cols2.is_empty():
				continue
			var uq = item.get("unique", false)
			var kind := "UNIQUE INDEX" if uq else "INDEX"
			db.exec("CREATE %s IF NOT EXISTS %s ON %s(%s)" % [
				kind, name, cls.table(), ",".join(cols2)
			])

static func _sql_default_literal(f: Field) -> String:
	if f.sql_type == "INTEGER" or f.sql_type == "REAL":
		return str(f.default_value)
	return "'" + str(f.default_value).replace("'", "''") + "'"

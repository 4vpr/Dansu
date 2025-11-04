extends RefCounted
class_name QuerySet

var db: MiniDB
var cls

var _where := []
var _params: Array = []
var _order := ""
var _limit := -1

func _init(_db: MiniDB, _cls) -> void:
	db = _db
	cls = _cls

func filter(conds: Dictionary) -> QuerySet:
	for k in conds.keys():
		var v = conds[k]
		if typeof(v) == TYPE_ARRAY:
			_where.append("%s IN (%s)" % [k, ",".join(["?"] * v.size())])
			_params.append_array(v)
		else:
			_where.append("%s = ?" % k)
			_params.append(v)
	return self

func where(raw: String, params: Array = []) -> QuerySet:
	_where.append("(" + raw + ")")
	_params.append_array(params)
	return self

func order_by(expr: String) -> QuerySet:
	_order = expr
	return self

func limit(n: int) -> QuerySet:
	_limit = n
	return self

func all() -> Array:
	var q := "SELECT * FROM %s" % cls.table()
	if _where.size() > 0:
		q += " WHERE " + " AND ".join(_where)
	if _order != "":
		q += " ORDER BY " + _order
	if _limit > 0:
		q += " LIMIT %d" % _limit
	var rows := db.fetch_all(q, _params)
	var out: Array = []
	for r in rows:
		out.append(MiniModel._from_row(cls, r))
	return out

func first() -> Variant:
	limit(1)
	var arr := all()
	return arr[0] if arr.size() > 0 else null

func get(conds: Dictionary) -> Variant:
	var qs := QuerySet.new(db, cls).filter(conds).limit(2).all()
	assert(qs.size() == 1, "get() expects exactly one row")
	return qs[0]

func create(vals: Dictionary) -> Variant:
	var inst = cls.new()
	for k in vals.keys():
		inst.set(k, vals[k])
	inst.save(db)
	return inst

func count() -> int:
	var q := "SELECT COUNT(*) AS c FROM %s" % cls.table()
	if _where.size() > 0:
		q += " WHERE " + " AND ".join(_where)
	var row := db.fetch_one(q, _params)
	return int(row.get("c", 0))

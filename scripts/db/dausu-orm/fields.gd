extends RefCounted
class_name Field

var sql_type := "TEXT"
var default_value: Variant = null
var null_ok := true
var unique := false
var index := false

func _init(_sql_type: String, _default: Variant = null, _null_ok: bool = true, _unique: bool = false, _index: bool = false) -> void:
	sql_type = _sql_type
	default_value = _default
	null_ok = _null_ok
	unique = _unique
	index = _index

static func INT(default_value: int = 0, null_ok: bool = false, unique: bool = false, index: bool = false) -> Field:
	return Field.new("INTEGER", default_value, null_ok, unique, index)

static func Text(default_value: String = "", null_ok: bool = false, unique: bool = false, index: bool = false) -> Field:
	return Field.new("TEXT", default_value, null_ok, unique, index)

static func Real(default_value: float = 0.0, null_ok: bool = false, unique: bool = false, index: bool = false) -> Field:
	return Field.new("REAL", default_value, null_ok, unique, index)

static func Bool(default_value: bool = false, null_ok: bool = false, unique: bool = false, index: bool = false) -> Field:
	return Field.new("INTEGER", int(default_value), null_ok, unique, index)

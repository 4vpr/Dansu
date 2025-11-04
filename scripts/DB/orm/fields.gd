extends RefCounted
class_name Field

var sql_type := "TEXT"
var default_value: Variant = null
var null_ok := true

func _init(_sql_type: String, _default: Variant = null, _nullable: bool = true) -> void:
	sql_type = _sql_type
	default_value = _default
	null_ok = _nullable

static func Integer(default_value: int = 0, null_ok: bool = false) -> Field:
	return Field.new("INTEGER", default_value, null_ok)

static func Text(default_value: String = "", null_ok: bool = false) -> Field:
	return Field.new("TEXT", default_value, null_ok)

static func Real(default_value: float = 0.0, null_ok: bool = false) -> Field:
	return Field.new("REAL", default_value, null_ok)

static func Bool(default_value: bool = false, null_ok: bool = false) -> Field:
	return Field.new("INTEGER", 1 if default_value else 0, null_ok)

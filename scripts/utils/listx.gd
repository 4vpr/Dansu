extends RefCounted
class_name ListX

static func repeat_str(s: String, n: int, sep: String = "") -> String:
	if n <= 0:
		return ""
	var parts := PackedStringArray()
	parts.resize(n)
	for i in range(n):
		parts[i] = s
	return sep.join(parts)

static func repeat_value(v: Variant, n: int) -> Array:
	if n <= 0:
		return []
	var a: Array = []
	a.resize(n)
	for i in range(n):
		a[i] = v
	return a

static func qmarks(n: int) -> String:
	return repeat_str("?", n, ", ")

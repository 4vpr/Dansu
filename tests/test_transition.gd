extends Node
var main_menu: Node
var cached_main_menu: Node
var last_scene := ""
func transition_to(path: String, _duration: float = 1.0) -> void:
	last_scene = path

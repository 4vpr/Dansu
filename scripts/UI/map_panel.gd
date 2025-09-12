extends ScrollContainer

var velocity := 0.0
var target_offset := 0.0
var elasticity := 200.0
var damping := 10.0

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and event.keycode == KEY_F3:
		print("list")
		for child in $VBoxContainer.get_children():
			print(child.name, " : ", child.global_position)
func _gui_input(event):
	if event is InputEventMouseMotion and event.button_mask & MOUSE_BUTTON_MASK_LEFT:
		target_offset -= event.relative.y

@export var preload_margin: int = 64
var _last_scroll := Vector2i(-1, -1)

func _ready() -> void:
	CM.connect("chart_reload",Callable(self, "_reload"))
func _process(_dt: float) -> void:
	var cur := Vector2i(scroll_horizontal, scroll_vertical)
	if cur == _last_scroll:
		return
	_last_scroll = cur
	_update_visible_items()
func _reload() -> void:
	pass
func _update_visible_items() -> void:
	var vp := get_global_rect().grow(preload_margin)
	for child in $VBoxContainer.get_children():
		_check_child_recursive(child, vp)

func _check_child_recursive(n: Node, vp: Rect2) -> void:
	if n is Control:
		var r = n.get_global_rect()
		var visible := vp.intersects(r)
		if n is LazyImage:
			if visible:
				n.ensure_loaded()
			else:
				n.ensure_unloaded()
	for c in n.get_children():
		_check_child_recursive(c, vp)

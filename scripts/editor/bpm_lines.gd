extends Control

@onready var root: Control = get_tree().current_scene
@onready var preview: Control = get_parent()

func _ready() -> void:
	set_process(true)

func _process(_delta: float) -> void:
	queue_redraw()

func _draw() -> void:
	if root == null:
		return
	# Proceed assuming MapEditor exports beatsdiv and chart; both exist in _map_editor.gd

	var chart = root.chart
	if chart == null:
		return
	if chart.song_bpm <= 0:
		return

	var divis: int = max(1, int(root.beatsdiv))
	var beat_ms: float = 60000.0 / chart.song_bpm
	var sub_ms: float = beat_ms / float(divis)

	var px_per_ms: float = Game.editor_velocity
	var px_per_sub: float = sub_ms * px_per_ms

	# Reference Y: align to center guideline (BG2) if present; else middle of this control.
	var ref_y: float = size.y * 0.5
	if preview and preview.has_node("BG2"):
		var bg2: Control = preview.get_node("BG2")
		ref_y = bg2.position.y

	var current_time: float = Game.currentTime
	var rel: float = current_time - chart.song_bpmstart
	var base_idx: int = int(floor(rel / sub_ms))

	var h: float = size.y
	var w: float = size.x

	# Draw past lines (scrolling down on screen)
	var i: int = base_idx
	while true:
		var t: float = chart.song_bpmstart + float(i) * sub_ms
		var y: float = ref_y + (current_time - t) * px_per_ms
		if y > h + 2.0:
			break
		_draw_line_at(w, y, i, divis)
		i -= 1

	# Draw future lines (appear above, fall down)
	i = base_idx + 1
	while true:
		var tf: float = chart.song_bpmstart + float(i) * sub_ms
		var yf: float = ref_y + (current_time - tf) * px_per_ms
		if yf < -2.0:
			break
		_draw_line_at(w, yf, i, divis)
		i += 1

func _draw_line_at(width: float, y: float, idx: int, divis: int) -> void:
	var j: int = posmod(idx, divis)
	var denom: int = 1
	if j == 0:
		denom = 1
	else:
		denom = int(divis / _gcd(j, divis))

	var col := Color(0.5, 0.5, 0.5, 0.7) # default gray
	var thickness := 1.0

	match denom:
		1:
			col = Color(1, 1, 1, 0.9) # white
			thickness = 2.0
		2:
			col = Color(0.2, 0.5, 1.0, 0.85) # blue
		3:
			col = Color(1.0, 1.0, 0.2, 0.85) # yellow
		4:
			col = Color(1.0, 0.2, 0.2, 0.85) # red
		6:
			col = Color(0.9, 0.7, 0.1, 0.85) # dark yellow
		_:
			# others remain gray
			pass

	draw_line(Vector2(0, y), Vector2(width, y), col, thickness)

func _gcd(a: int, b: int) -> int:
	a = abs(a)
	b = abs(b)
	while b != 0:
		var t: int = a % b
		a = b
		b = t
	return max(1, a)

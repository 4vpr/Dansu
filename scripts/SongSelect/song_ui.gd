extends Control

@onready var Title = $Title
@onready var BG = $BG
var diff_scene = load("res://objects/diff.tscn")

var chart_set: ChartSet
var hovered = false
var tween
var has_BG = false
func _ready() -> void:
	CM.connect("chartset_selected", Callable(self, "_select_event"))
	if chart_set:
		Title.text = chart_set.meta_title
		set_mouse_filter(MOUSE_FILTER_STOP)
		connect("mouse_entered", Callable(self, "_on_mouse_entered"))
		connect("mouse_exited", Callable(self, "_on_mouse_exited"))
	if CM.ss == chart_set:
		_select()
func _select_event(s):
	if s != chart_set:
		_unselect()
	else:
		_select()
func _select():
	animate_size(200.0)
	modulate = Color("ffffff")
	reload()
	$Buttons/Button.text = "PLAY"
func _unselect():
	$HBoxContainer.get_children().map(func(c): c.queue_free())
	animate_size(75.0)
	modulate = Color("a2a2a2")
	$Buttons/Button.text = ""
func reload():
	chart_set.charts.sort_custom(func(a, b):
		return a.diff_value < b.diff_value
		)
	$HBoxContainer.get_children().map(func(c): c.queue_free())
	var closest_map = chart_set.charts[0]
	var closest_diff = abs(closest_map.diff_value - CM.lastSelectedDiff)
	var closest_map_scene
	for chart in chart_set.charts:
		var diff = diff_scene.instantiate()
		if closest_map_scene == null:
			closest_map_scene = diff
		diff.chart = chart
		var diff_gap = abs(chart.diff_value - CM.lastSelectedDiff)
		if diff_gap < closest_diff:
			closest_map = chart
			closest_diff = diff_gap
			closest_map_scene = diff
		$HBoxContainer.add_child(diff)
	CM.select_chart(closest_map)


var _bg_req_token: int = 0
var _bg_thread: Thread

func load_background() -> void:
	has_BG = true
	if chart_set == null or chart_set.image_path == null or chart_set.image_path == "":
		push_warning("BG: empty image_path")
		return

	_bg_req_token += 1
	var token := _bg_req_token
	var path := chart_set.folder_path +  "/" + chart_set.image_path

	BG.texture = null
	BG.visible = true

	# 경로 확인
	if path.begins_with("res://"):
		if not ResourceLoader.exists(path):
			push_error("BG: res path not found: %s" % path)
			return
		# res:// 은 엔진 스레드 로더
		ResourceLoader.load_threaded_request(path, "Texture2D")
		_check_bg_load_res(path, token)
	else:
		if not FileAccess.file_exists(path):
			push_error("BG: user path not found: %s" % path)
			return
		# user:// 은 수동 스레드 필요
		if _bg_thread and _bg_thread.is_started():
			_bg_thread.wait_to_finish()
		_bg_thread = Thread.new()
		_bg_thread.start(Callable(self, "_thread_load_user_image").bind(path, token))

# res:// 전용 폴링
func _check_bg_load_res(path: String, token: int) -> void:
	while true:
		var st := ResourceLoader.load_threaded_get_status(path)
		if st == ResourceLoader.THREAD_LOAD_LOADED:
			var tex := ResourceLoader.load_threaded_get(path) as Texture2D
			if tex == null:
				push_error("BG: threaded_get returned null for %s" % path)
				return
			if token == _bg_req_token:
				BG.texture = tex
			return
		elif st == ResourceLoader.THREAD_LOAD_FAILED:
			push_error("BG: threaded load failed: %s" % path)
			return
		await get_tree().process_frame

# user:// 전용 스레드 함수
func _thread_load_user_image(path: String, token: int) -> void:
	var img := Image.new()
	var err := img.load(path)
	if err != OK:
		printerr("BG: Image.load failed(%s): %s" % [err, path])
		return
	call_deferred("_apply_bg_image_main", img, token)

# 메인 스레드에서 적용
func _apply_bg_image_main(img: Image, token: int) -> void:
	if token != _bg_req_token:
		return
	var tex := ImageTexture.create_from_image(img)
	if tex == null:
		push_error("BG: create_from_image returned null")
		return
	BG.texture = tex

func _gui_input(event):
	if CM.ss != chart_set:
		if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			CM.select_chartset(chart_set)
func _on_mouse_entered():
	if CM.ss != chart_set:
		animate_size(100.0)
func animate_size(target_height: float) -> void:
	tween = create_tween()
	var current_size = custom_minimum_size
	var target_size = Vector2(current_size.x, target_height)
	tween.tween_property(self, "custom_minimum_size", target_size, 0.3).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	custom_minimum_size.y = int(custom_minimum_size.y)
func _on_mouse_exited():
	if CM.ss != chart_set:
		animate_size(75.0)

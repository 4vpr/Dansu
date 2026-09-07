extends Control
class_name ChartLeaderboardPanel

signal visibility_set(blocked: bool)

const GLOBAL_LIMIT := 20
const RANK_SCAN_LIMIT := 50
const REQUEST_TIMEOUT_SECONDS := 15.0
const ROW_SCENE := preload("res://scenes/mainmenu/leaderboard_row.tscn")

@export_group("Node References")
@export var title_label: Label
@export var close_button: Button
@export var global_button: Button
@export var local_button: Button
@export var my_panel: PanelContainer
@export var my_rank_label: Label
@export var my_accuracy_label: Label
@export var my_combo_label: Label
@export var status_label: Label
@export var entries: VBoxContainer

var _chart: Chart
var _request: HTTPRequest
var _request_generation := 0
var _global_data: Dictionary = {}
var _expected_combo := 0
var _rank_scan_page := 0
var _rank_scan_pages := 0


func _ready() -> void:
	close_button.pressed.connect(close)
	global_button.pressed.connect(_show_global)
	local_button.pressed.connect(_show_local)
	hide()


func open(chart: Chart) -> void:
	if chart == null:
		return
	_chart = chart
	_expected_combo = int(chart.online_metadata.get("max_combo", 0))
	title_label.text = "%s  ·  %s" % [chart.title, chart.difficulty]
	show()
	visibility_set.emit(true)
	_show_global()


func close() -> void:
	_dispose_request()
	hide()
	visibility_set.emit(false)


func is_open() -> bool:
	return visible


func _unhandled_input(event: InputEvent) -> void:
	if visible and event.is_action_pressed("ui_cancel"):
		close()
		get_viewport().set_input_as_handled()


func _show_global() -> void:
	global_button.disabled = true
	local_button.disabled = false
	my_panel.show()
	_clear_entries()
	_set_status("Loading global leaderboard…")
	_set_my_empty("Loading your rank…" if Auth.is_authenticated() else "Sign in to see your rank")
	_global_data = {}
	var chart_id := _online_chart_id()
	if chart_id > 0:
		_request_leaderboard(chart_id, 1, GLOBAL_LIMIT, "top")
	else:
		_resolve_online_chart()


func _show_local() -> void:
	_dispose_request()
	global_button.disabled = false
	local_button.disabled = true
	my_panel.hide()
	_clear_entries()
	if _chart == null:
		_set_status("No chart selected")
		return
	var plays: Array = Scores.get_chart_plays(_chart, 500, 0)
	if plays.is_empty():
		_set_status("No local scores yet")
		return
	_set_status("%d local play%s" % [plays.size(), "" if plays.size() == 1 else "s"])
	for index in range(plays.size()):
		var score := plays[index] as Score
		if score == null:
			continue
		_add_row(
			str(index + 1),
			_format_played_at(score.played_at),
			score.total_score,
			_combo_text(score.high_combo, score.notes),
			false
		)


func _resolve_online_chart() -> void:
	if _chart == null or _chart.chart_set == null or _chart.chart_set.uuid.is_empty():
		_set_global_unavailable("This chart has no online leaderboard")
		return
	_start_request(
		_api_url("/chartsets/by-uuid/" + _chart.chart_set.uuid.uri_encode()),
		_on_chartset_resolved,
		[]
	)


func _on_chartset_resolved(
	result: int,
	code: int,
	_headers: PackedStringArray,
	body: PackedByteArray,
	generation: int
) -> void:
	if generation != _request_generation or not visible or local_button.disabled:
		return
	_dispose_request(false)
	if result != HTTPRequest.RESULT_SUCCESS or code != 200:
		_set_global_unavailable("Online leaderboard unavailable")
		return
	var data = JSON.parse_string(body.get_string_from_utf8())
	if not data is Dictionary or not data.get("charts") is Array:
		_set_global_unavailable("Invalid leaderboard response")
		return
	for value in data.charts:
		if not value is Dictionary:
			continue
		if str(value.get("chart_uuid", "")).to_lower() != _chart.uuid.to_lower():
			continue
		_chart.online_metadata = value.duplicate(true)
		_expected_combo = int(value.get("max_combo", 0))
		_request_leaderboard(int(value.get("id", -1)), 1, GLOBAL_LIMIT, "top")
		return
	_set_global_unavailable("This difficulty is not published")


func _request_leaderboard(chart_id: int, page: int, limit: int, purpose: String) -> void:
	if chart_id <= 0:
		_set_global_unavailable("This chart has no online leaderboard")
		return
	var url := _api_url("/leaderboards/charts/%d?page=%d&limit=%d" % [chart_id, page, limit])
	_start_request(url, _on_leaderboard_loaded, [purpose, page])


func _on_leaderboard_loaded(
	result: int,
	code: int,
	_headers: PackedStringArray,
	body: PackedByteArray,
	purpose: String,
	page: int,
	generation: int
) -> void:
	if generation != _request_generation or not visible or local_button.disabled:
		return
	_dispose_request(false)
	if result != HTTPRequest.RESULT_SUCCESS or code != 200:
		if purpose == "top":
			_set_global_unavailable("Online leaderboard unavailable")
		else:
			_set_my_empty("Could not load your rank")
		return
	var data = JSON.parse_string(body.get_string_from_utf8())
	if not data is Dictionary or not data.get("items") is Array:
		_set_global_unavailable("Invalid leaderboard response")
		return
	if purpose == "top":
		_render_global(data)
	else:
		_scan_for_current_user(data, page)


func _render_global(data: Dictionary) -> void:
	_global_data = data.duplicate(true)
	_clear_entries()
	var items: Array = data.get("items", [])
	var user_id := int(Auth.user.get("id", -1)) if Auth.is_authenticated() else -1
	var my_entry: Dictionary = {}
	for value in items:
		if not value is Dictionary:
			continue
		var item: Dictionary = value
		var is_me := int(item.get("user_id", -2)) == user_id
		_add_row(
			"#%d" % int(item.get("rank", 0)),
			str(item.get("username", "PLAYER")),
			float(item.get("total_score", 0.0)),
			_combo_text(int(item.get("max_combo", 0)), _expected_combo),
			is_me
		)
		if is_me:
			my_entry = item
	_set_status("Top %d of %d players" % [items.size(), int(data.get("total", items.size()))])
	if not Auth.is_authenticated():
		return
	if not my_entry.is_empty():
		_set_my_entry(my_entry)
		return
	var cached := _cached_rank(int(data.get("chart_id", -1)))
	if not cached.is_empty():
		_set_my_rank_response(cached)
		return
	var total := int(data.get("total", 0))
	if total <= items.size():
		_set_my_empty("Not ranked")
		return
	_rank_scan_page = 1
	_rank_scan_pages = int(ceil(float(total) / RANK_SCAN_LIMIT))
	_set_my_empty("Finding your rank…")
	_request_leaderboard(int(data.get("chart_id", -1)), _rank_scan_page, RANK_SCAN_LIMIT, "rank")


func _scan_for_current_user(data: Dictionary, page: int) -> void:
	var user_id := int(Auth.user.get("id", -1))
	for value in data.get("items", []):
		if value is Dictionary and int(value.get("user_id", -2)) == user_id:
			_set_my_entry(value)
			return
	if page >= _rank_scan_pages:
		_set_my_empty("Not ranked")
		return
	_rank_scan_page = page + 1
	_request_leaderboard(int(data.get("chart_id", -1)), _rank_scan_page, RANK_SCAN_LIMIT, "rank")


func _set_my_entry(item: Dictionary) -> void:
	my_rank_label.text = "#%d" % int(item.get("rank", 0))
	my_accuracy_label.text = "%.2f%%" % float(item.get("total_score", 0.0))
	my_combo_label.text = _combo_text(int(item.get("max_combo", 0)), _expected_combo)


func _set_my_rank_response(value: Dictionary) -> void:
	my_rank_label.text = "#%d" % int(value.get("rank", 0))
	my_accuracy_label.text = "%.2f%%" % float(value.get("total_score", 0.0))
	var combo := int(value.get("max_combo", 0))
	var notes := int(value.get("note_count", _expected_combo))
	my_combo_label.text = _combo_text(combo, notes)


func _set_my_empty(message: String) -> void:
	my_rank_label.text = message
	my_accuracy_label.text = "--"
	my_combo_label.text = "--"


func _cached_rank(chart_id: int) -> Dictionary:
	for index in range(Scores.scores.size() - 1, -1, -1):
		var score: Score = Scores.scores[index]
		var rank = score.submission_response.get("chart_rank", {})
		if rank is Dictionary and int(rank.get("chart_id", -1)) == chart_id:
			var result: Dictionary = rank.duplicate(true)
			result["max_combo"] = score.high_combo
			result["note_count"] = score.notes
			return result
	return {}


func _online_chart_id() -> int:
	return int(_chart.online_metadata.get("id", -1)) if _chart != null else -1


func _combo_text(combo: int, maximum: int) -> String:
	if maximum > 0 and combo >= maximum:
		return "Full Combo"
	return "%d combo" % combo


func _format_played_at(unix_time: int) -> String:
	if unix_time <= 0:
		return "Local play"
	var value := Time.get_datetime_dict_from_unix_time(unix_time)
	return "%04d-%02d-%02d  %02d:%02d" % [value.year, value.month, value.day, value.hour, value.minute]


func _add_row(rank_text: String, display_name: String, accuracy: float, combo_text: String, highlighted: bool) -> void:
	var row := ROW_SCENE.instantiate() as ChartLeaderboardRow
	entries.add_child(row)
	row.set_entry(rank_text, display_name, accuracy, combo_text, highlighted)


func _clear_entries() -> void:
	for child in entries.get_children():
		child.queue_free()


func _set_status(message: String) -> void:
	status_label.text = message


func _set_global_unavailable(message: String) -> void:
	_clear_entries()
	_set_status(message)
	_set_my_empty("No online record")


func _start_request(url: String, callback: Callable, context: Array) -> void:
	_dispose_request()
	_request_generation += 1
	var generation := _request_generation
	_request = HTTPRequest.new()
	_request.timeout = REQUEST_TIMEOUT_SECONDS
	_request.max_redirects = 0
	_request.body_size_limit = 2 * 1024 * 1024
	add_child(_request)
	_request.request_completed.connect(
		_dispatch_request_completed.bind(callback, context.duplicate(), generation)
	)
	var headers := Auth.authorization_headers()
	headers.append("Accept: application/json")
	if _request.request(url, headers) != OK:
		_dispose_request(false)
		_set_global_unavailable("Could not start leaderboard request")


func _dispatch_request_completed(
	result: int,
	code: int,
	headers: PackedStringArray,
	body: PackedByteArray,
	callback: Callable,
	context: Array,
	generation: int
) -> void:
	var arguments: Array = [result, code, headers, body]
	arguments.append_array(context)
	arguments.append(generation)
	callback.callv(arguments)


func _dispose_request(invalidate: bool = true) -> void:
	if invalidate:
		_request_generation += 1
	if is_instance_valid(_request):
		_request.cancel_request()
		_request.queue_free()
	_request = null


func _api_url(path: String) -> String:
	return ServerURLs.api(path)

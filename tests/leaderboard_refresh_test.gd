extends Node

class TestLeaderboard extends InlineLeaderboard:
	var paths: Array[String] = []
	func _request_json(path: String, _callback: Callable) -> void:
		paths.append(path)

var failures := 0

func _ready() -> void:
	var chart := Chart.new()
	chart.uuid = "test-chart"
	chart.online_metadata = {"id": 42, "max_combo": 100}
	CM.selected_chart = chart
	var board := TestLeaderboard.new()
	var scroll := ScrollContainer.new()
	scroll.name = "Scroll"
	var entries := VBoxContainer.new()
	entries.name = "Entries"
	scroll.add_child(entries)
	board.add_child(scroll)
	add_child(board)
	board._debounce.stop()
	board._load_selected()
	board._on_page({"chart_id": 42, "page": 2, "total_pages": 3, "items": []})
	entries.add_child(Label.new())
	board._select_chart(chart)
	_check(board._page == 2, "Ordinary same-chart selection keeps loaded pages")
	var generation := board._generation
	board.refresh_selected_chart()
	_check(board._page == 0 and board._total_pages == 0, "Return refresh resets pagination")
	_check(entries.get_child_count() == 0, "Return refresh removes stale rows")
	_check(board._generation > generation and not board._debounce.is_stopped(), "Return refresh invalidates pending responses and schedules reload")
	board._debounce.stop()
	board._load_selected()
	_check(board.paths.back() == "/leaderboards/charts/42?page=1&limit=20", "Reload starts at page one")
	board._on_page({"chart_id": 42, "page": 1, "total_pages": 1, "items": []})
	Scores.submission_completed.emit(Score.new(), {"score": {"chart_id": 99}})
	_check(board._page == 1, "Other chart submissions do not refresh the list")
	Scores.submission_completed.emit(Score.new(), {"score": {"chart_id": 42}})
	_check(board._page == 0 and not board._debounce.is_stopped(), "Late submission refreshes the selected chart")
	board._debounce.stop()
	board._page = 1
	var score := Score.new()
	score.replay = Replay.new()
	score.replay.setup(chart)
	Scores.submission_completed.emit(score, {})
	_check(board._page == 0, "Already-submitted response matches by replay UUID")
	board._debounce.stop()
	board.hide()
	board._page = 1
	Scores.submission_completed.emit(score, {})
	_check(board._page == 1 and board._debounce.is_stopped(), "Hidden menu does not fetch on submission")
	print("Leaderboard refresh tests: %d failures" % failures)
	get_tree().quit(1 if failures else 0)

func _check(condition: bool, message: String) -> void:
	if not condition:
		failures += 1
		push_error(message)

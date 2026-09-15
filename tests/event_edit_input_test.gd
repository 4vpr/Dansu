extends Node

@onready var root := get_tree().root

var editor: ChartEditor
var workspace: Node
var failures := 0

func _ready() -> void:
	call_deferred("_run")

func check(condition: bool, message: String) -> void:
	if not condition:
		failures += 1
		push_error(message)

func settle() -> void:
	await get_tree().process_frame
	await get_tree().process_frame

func mouse(point: Vector2, pressed: bool, ctrl: bool = false, shift: bool = false) -> void:
	var event := InputEventMouseButton.new()
	event.position = workspace.canvas.get_global_transform_with_canvas() * point
	event.button_index = MOUSE_BUTTON_LEFT
	event.pressed = pressed
	event.ctrl_pressed = ctrl
	event.shift_pressed = shift
	editor._input(event)

func click(point: Vector2, ctrl: bool = false, shift: bool = false) -> void:
	mouse(point, true, ctrl, shift)
	mouse(point, false)

func motion(point: Vector2) -> void:
	var event := InputEventMouseMotion.new()
	event.position = workspace.canvas.get_global_transform_with_canvas() * point
	editor._input(event)

func key(code: Key, ctrl: bool = false) -> void:
	var event := InputEventKey.new()
	event.pressed = true
	event.keycode = code
	event.ctrl_pressed = ctrl
	editor._input(event)

func position_at(time: int, column: float) -> Vector2:
	return Vector2(workspace.canvas.size.x * column, workspace.canvas._time_y(time))

func theme_event() -> ThemeEvent:
	for event in workspace.get_events():
		if event is ThemeEvent:
			return event
	return null

func _run() -> void:
	Config.custom_skin_path = ""
	var chart := Chart.new()
	chart.title = "Event input test"
	chart.storage_root = "user://test-fixtures"
	chart.folder_name = "event-input"
	chart.chart_set = ChartSet.new()
	chart.build_uuid()
	CM.selected_chart = chart
	CM.parsed_chart = ParsedChart.new(chart)
	Game.reopen_editor_without_chart_reload = true
	editor = load("res://scenes/chart/editor/editor_scene.tscn").instantiate()
	root.add_child(editor)
	await settle()
	workspace = editor.event_controller
	key(KEY_H)
	check(workspace.active, "H enters event mode through editor input")
	editor._set_current_time(0)
	workspace.place("theme", 0, 0)
	workspace.place("theme", 250, 0)
	workspace.place("theme", 500, 0)
	workspace.place("camera", 125, 0)
	workspace.place("skin", 250, 0)
	workspace.place("overlay", 0, 5)
	await settle()
	click(position_at(0, 0.1))
	click(position_at(250, 0.1), true)
	check(editor.selection.selected_event_items.size() == 2, "Ctrl-click adds a second event frame")
	click(position_at(250, 0.1), true)
	check(editor.selection.selected_event_items.size() == 1, "Ctrl-click toggles frame off")
	click(position_at(0, 0.1))
	click(position_at(500, 0.1), false, true)
	check(editor.selection.selected_event_items.size() == 3, "Shift-click selects frame range")
	var origin := position_at(0, 0.1)
	mouse(origin, true)
	motion(origin + Vector2(0, -125 * editor.get_pixels_per_ms()))
	check(theme_event().frames[0].time == 125 and theme_event().frames[2].time == 625, "Grouped drag preserves timing offsets")
	mouse(Vector2(-50, -50), false)
	check(not workspace.canvas.gesture_active, "Release outside canvas ends drag")
	key(KEY_Z, true)
	check(theme_event().frames[0].time == 0 and editor.selection.selected_event_items.size() == 3, "One undo restores full move and multiselection")
	key(KEY_Y, true)
	check(theme_event().frames[0].time == 125, "Redo restores full group move")
	key(KEY_Z, true)
	await settle()
	click(position_at(0, 0.04))
	click(position_at(0, 0.1))
	mouse(position_at(0, 0.1), true)
	motion(position_at(250, 0.1))
	check(theme_event().frames[0].time == 0, "Dragging into unselected frame rejects collision atomically")
	motion(position_at(125, 0.1))
	check(theme_event().frames[0].time == 125, "Valid drag resumes after collision")
	key(KEY_ESCAPE)
	check(theme_event().frames[0].time == 0 and not workspace.canvas.gesture_active, "Escape restores original event without leaving editor")
	await settle()
	var box_start := position_at(600, 0.04)
	var box_end := position_at(-50, 0.38)
	mouse(box_start, true)
	motion(box_end)
	check(editor.selection.selected_event_items.size() == 5, "Box selects theme, camera and skin markers")
	if DisplayServer.get_name() != "headless":
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://.godot/event-box-selection.png")
	mouse(box_end, false)
	key(KEY_C, true)
	check(workspace.selection_ops.clipboard.size() == 3, "Ctrl+C copies mixed event types")
	editor._set_current_time(1000)
	key(KEY_V, true)
	check(theme_event().frames.size() == 6 and theme_event().frames[3].time == 1000, "Ctrl+V anchors earliest item to playhead in existing stream")
	check(editor.selection.selected_event_items.size() == 5, "Paste selects the entire pasted group")
	key(KEY_Z, true)
	check(theme_event().frames.size() == 3, "One undo removes mixed paste")
	editor._set_current_time(0)
	await settle()
	var overlay: OverlayEvent
	for event in workspace.get_events():
		if event is OverlayEvent:
			overlay = event
	var body := Vector2(workspace.canvas.slot_x(5), workspace.canvas._time_y(250))
	click(body)
	check(editor.selection.selected_event_items.size() == 1 and editor.selection.selected_event_items[0].frame == null, "Overlay body selects whole clip")
	editor.get_node("Object/Copy").pressed.emit()
	editor.get_node("Object/Paste").pressed.emit()
	check(workspace.get_events().filter(func(e): return e is OverlayEvent).size() == 2, "Toolbar copy/paste duplicates overlay")
	check(editor.selection.selected_event.x == 6, "Pasted overlay avoids occupied column")
	key(KEY_Z, true)
	await settle()
	for event in workspace.get_events():
		if event is OverlayEvent:
			overlay = event
	click(Vector2(workspace.canvas.slot_x(5), workspace.canvas._time_y(0)))
	check(editor.selection.selected_event_items[0].frame != null, "Overlay diamond selects frame")
	key(KEY_C, true)
	editor._set_current_time(1000)
	key(KEY_V, true)
	check(editor.selection.selected_event is OverlayEvent and editor.selection.selected_event.time == 1000, "Frame pasted outside original duration creates overlay instead of failing")
	key(KEY_Z, true)
	key(KEY_DELETE)
	check(workspace.get_events().filter(func(e): return e is OverlayEvent).is_empty(), "Delete removes selected frame and its empty overlay")
	key(KEY_Z, true)
	check(workspace.get_events().filter(func(e): return e is OverlayEvent).size() == 1, "Undo restores deleted overlay")
	editor._set_current_time(0)
	workspace.place("overlay", 0, 7)
	await settle()
	click(Vector2(workspace.canvas.slot_x(5), workspace.canvas._time_y(250)))
	click(Vector2(workspace.canvas.slot_x(7), workspace.canvas._time_y(250)), true)
	var clips: Array = workspace.get_events().filter(func(e): return e is OverlayEvent)
	check(editor.selection.selected_event_items.size() == 2, "Ctrl-click selects two overlay bodies")
	var drag_start := Vector2(workspace.canvas.slot_x(5), workspace.canvas._time_y(250))
	var drag_end := Vector2(workspace.canvas.slot_x(6), workspace.canvas._time_y(375))
	mouse(drag_start, true)
	motion(drag_end)
	check(clips[0].time == 125 and clips[1].time == 125, "Overlay group moves along time together")
	check(clips[0].x == 6 and clips[1].x == 8, "Overlay group snaps horizontally preserving column spacing")
	check(clips[0].frames[0].time == 0 and clips[1].frames[0].time == 0, "Moving whole overlays preserves local frame timing")
	motion(Vector2(workspace.canvas.slot_x(9), workspace.canvas._time_y(375)))
	check(clips[0].x == 6 and clips[1].x == 8, "Group movement blocks at column boundary without partial change")
	key(KEY_ESCAPE)
	check(clips[0].x == 5 and clips[1].x == 7 and clips[0].time == 0, "Cancel restores overlay group positions")
	await settle()
	click(position_at(0, 0.04))
	check(editor.selection.selected_event_items.is_empty(), "Blank click clears event selection")
	mouse(Vector2(workspace.canvas.slot_x(5) - 18, workspace.canvas._time_y(550)), true)
	motion(Vector2(workspace.canvas.slot_x(7) + 18, workspace.canvas._time_y(-50)))
	mouse(Vector2(workspace.canvas.slot_x(7) + 18, workspace.canvas._time_y(-50)), false)
	check(editor.selection.selected_event_items.size() == 2 and editor.selection.selected_event_items[0].frame == null, "Box around whole overlays selects clips without duplicate child frames")
	key(KEY_DELETE)
	check(workspace.get_events().filter(func(e): return e is OverlayEvent).is_empty(), "Delete removes overlay selection as one action")
	key(KEY_Z, true)
	check(workspace.get_events().filter(func(e): return e is OverlayEvent).size() == 2 and editor.selection.selected_event_items.size() == 2, "Undo restores deleted overlay group and selection")
	# Moving a marker while an inspector text input was focused must still release focus.
	await settle()
	var field := LineEdit.new()
	editor.add_child(field)
	field.grab_focus()
	var focus_press := InputEventMouseButton.new()
	focus_press.button_index = MOUSE_BUTTON_LEFT
	focus_press.pressed = true
	focus_press.position = workspace.canvas.get_global_transform_with_canvas() * position_at(0, 0.1)
	editor._input(focus_press)
	check(not field.has_focus() and workspace.canvas.gesture_active, "Chart click releases inspector text focus and starts event gesture")
	mouse(position_at(0, 0.1), false)
	key(KEY_C, true)
	check(workspace.selection_ops.clipboard.size() == 1 and editor.selection.selected_event is ThemeEvent, "Copy shortcut works after leaving inspector text field")
	field.queue_free()
	print("Event edit input: %d failures" % failures)
	editor.queue_free()
	await get_tree().process_frame
	get_tree().quit(0 if failures == 0 else 1)

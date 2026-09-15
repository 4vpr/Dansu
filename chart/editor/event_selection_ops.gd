extends RefCounted

var workspace: Node
var clipboard: Array[Dictionary] = []
var first_time := 0

func items() -> Array[Dictionary]:
	return workspace.editor.selection.selected_event_items

func is_selected(event: ChartEvent, frame: ChartEventFrame) -> bool:
	for item in items():
		if item.event == event and item.frame == frame:
			return true
	return false

func set_items(values: Array[Dictionary]) -> void:
	var normalized: Array[Dictionary] = []
	for item in values:
		if not workspace.get_events().has(item.event):
			continue
		if item.frame != null and not workspace.get_frames(item.event).has(item.frame):
			continue
		var skip := false
		for other in normalized:
			if other.event == item.event and (other.frame == null or other.frame == item.frame):
				skip = true
		if skip:
			continue
		if item.frame == null:
			normalized = normalized.filter(func(other): return other.event != item.event)
		normalized.append({"event": item.event, "frame": item.frame})
	var selection: ChartEditorSelection = workspace.editor.selection
	if normalized.is_empty():
		selection.clear()
		return
	if normalized == selection.selected_event_items:
		return
	var primary = normalized.back()
	selection.selected_rail = null
	selection.selected_note = null
	selection.selected_point_index = -1
	selection.selected_notes.clear()
	selection.selected_points.clear()
	selection.selected_event = primary.event
	selection.selected_event_frame_index = workspace.get_frames(primary.event).find(primary.frame)
	selection.selected_event_items = normalized
	selection.refresh()

func toggle(event: ChartEvent, frame: ChartEventFrame) -> void:
	var next := items().duplicate()
	if is_selected(event, frame):
		next = next.filter(func(item): return item.event != event or item.frame != frame)
	else:
		if frame != null:
			next = next.filter(func(item): return item.event != event or item.frame != null)
		next.append({"event": event, "frame": frame})
	set_items(next)

func capture() -> Dictionary:
	var state := {"items": items().duplicate(), "events": {}, "frames": {}}
	for item in items():
		var event: ChartEvent = item.event
		state.events[event] = {"time": event.time, "duration": event.duration, "x": event.x if event is OverlayEvent else 0}
		for frame in workspace.get_frames(event):
			state.frames[frame] = frame.time
	return state

func move(state: Dictionary, dt: int, dx: int, resize: ChartEvent = null) -> bool:
	var events: Dictionary = {}
	for event in state.events:
		events[event] = state.events[event].duplicate()
	var frames: Dictionary = state.frames.duplicate()
	for item in state.items:
		var event: ChartEvent = item.event
		if item.frame != null:
			frames[item.frame] = int(state.frames[item.frame]) + dt
		elif event == resize:
			events[event].duration += dt
		else:
			events[event].time += dt
			if event is OverlayEvent:
				events[event].x += dx
	if not validate(events, frames):
		return false
	apply_values(events, frames)
	return true

func validate(values: Dictionary, frame_times: Dictionary, additions: Dictionary = {}) -> bool:
	var all_events: Array = workspace.get_events().duplicate()
	for event in values:
		if not all_events.has(event):
			all_events.append(event)
	for event in values:
		var value: Dictionary = values[event]
		if event is OverlayEvent:
			if value.time < workspace.editor.timeline.get_min_time() or value.duration <= 0 or value.x < 0 or value.x >= workspace.SLOT_COUNT:
				return false
			for other in all_events:
				if other == event or not other is OverlayEvent:
					continue
				var o: Dictionary = values.get(other, {"time": other.time, "duration": other.duration, "x": other.x})
				if value.x == o.x and value.time < o.time + o.duration and value.time + value.duration > o.time:
					return false
		elif event is SkinEvent:
			if value.time < workspace.editor.timeline.get_min_time():
				return false
			for other in all_events:
				if other != event and other is SkinEvent and absi(int(value.time) - int(values.get(other, {"time": other.time}).time)) <= 1:
					return false
		var times: Array[int] = []
		var event_frames: Array = workspace.get_frames(event).duplicate()
		event_frames.append_array(additions.get(event, []))
		for frame: ChartEventFrame in event_frames:
			var time := int(frame_times.get(frame, frame.time))
			if value.time + time < workspace.editor.timeline.get_min_time():
				return false
			if event is OverlayEvent and (time < 0 or time > value.duration):
				return false
			times.append(time)
		times.sort()
		for i in range(1, times.size()):
			if times[i] - times[i - 1] <= 1:
				return false
	return true

func apply_values(events: Dictionary, frames: Dictionary) -> void:
	var primary: ChartEventFrame = workspace._get_selected_frame()
	for event in events:
		event.time = events[event].time
		event.duration = events[event].duration
		if event is OverlayEvent:
			event.x = events[event].x
	for frame in frames:
		frame.time = frames[frame]
	for event in events:
		if not event is SkinEvent:
			event.sort_frames()
	if primary != null:
		workspace.editor.selection.selected_event_frame_index = workspace.get_frames(workspace._get_selected_event()).find(primary)
	CM.parsed_chart.sort_events()
	workspace.refresh_timeline()

func delete_selected() -> bool:
	if items().is_empty():
		return false
	workspace.editor._push_history_snapshot()
	for item in items():
		if item.frame != null:
			workspace.get_frames(item.event).erase(item.frame)
		if item.frame == null or workspace.get_frames(item.event).is_empty():
			CM.parsed_chart.events.erase(item.event)
	workspace.editor.selection.clear()
	workspace.refresh_timeline()
	return true

func copy_selected() -> bool:
	if items().is_empty():
		return false
	clipboard.clear()
	first_time = 2147483647
	var owners: Array[ChartEvent] = []
	for item in items():
		if not owners.has(item.event):
			owners.append(item.event)
	for event in owners:
		var indices: Array[int] = []
		var whole := false
		for item in items():
			if item.event != event:
				continue
			whole = whole or item.frame == null
			if item.frame != null:
				indices.append(workspace.get_frames(event).find(item.frame))
			first_time = mini(first_time, event.time + (item.frame.time if item.frame != null else 0))
		clipboard.append({"data": EditorHistory.capture_events_data([event])[0], "indices": indices, "whole": whole})
	return true

func paste() -> bool:
	if clipboard.is_empty():
		return false
	var shift: int = workspace.editor.timeline.snap_time(int(Game.current_time)) - first_time
	var events: Dictionary = {}
	var new_events: Array[ChartEvent] = []
	var additions: Dictionary = {}
	var selection: Array[Dictionary] = []
	for entry in clipboard:
		var source: ChartEvent = EditorHistory.restore_events_data([entry.data])[0]
		var selected: Array[ChartEventFrame] = []
		for index: int in entry.indices:
			var frame: ChartEventFrame = workspace.get_frames(source)[index]
			if source is OverlayEvent:
				var resolved := ChartEventEvaluator._overlay_state_at(source.frames, index)
				frame.sprite = resolved.sprite
				frame.opacity = resolved.opacity
				frame.has_opacity = true
			selected.append(frame)
		var target: ChartEvent = null
		if source is ThemeEvent or source is CameraEvent:
			for candidate in workspace.get_events() + new_events:
				if (source is ThemeEvent and candidate is ThemeEvent) or (source is CameraEvent and candidate is CameraEvent):
					target = candidate
					break
			if target == null:
				target = ThemeEvent.new() if source is ThemeEvent else CameraEvent.new()
				target.time = 0
				new_events.append(target)
			if entry.whole:
				selected.assign(workspace.get_frames(source))
		elif source is OverlayEvent and not entry.whole and clipboard.size() == 1 and workspace._get_selected_event() is OverlayEvent:
			var candidate: OverlayEvent = workspace._get_selected_event()
			var inside := true
			for frame in selected:
				var time := source.time + frame.time + shift - candidate.time
				if time < 0 or time > candidate.duration:
					inside = false
			if inside:
				target = candidate
		if target != null:
			if not additions.has(target):
				additions[target] = []
			for frame in selected:
				frame.time += source.time + shift - target.time
				additions[target].append(frame)
				selection.append({"event": target, "frame": frame})
			events[target] = {"time": target.time, "duration": target.duration, "x": target.x if target is OverlayEvent else 0}
		else:
			if source is OverlayEvent and not entry.whole:
				selected.sort_custom(func(a, b): return a.time < b.time)
				var offset := selected[0].time
				source.time += offset
				source.duration = maxi(1, source.duration - offset)
				source.frames.assign(selected)
				for frame in source.frames:
					frame.time -= offset
			source.time += shift
			new_events.append(source)
			events[source] = {"time": source.time, "duration": source.duration, "x": source.x if source is OverlayEvent else 0}
			selection.append({"event": source, "frame": null})
	# Shift the overlay group rigidly to the closest available columns.
	var original_slots: Dictionary = {}
	for event in new_events:
		if event is OverlayEvent:
			original_slots[event] = event.x
	var offsets: Array[int] = [0]
	for distance in range(1, workspace.SLOT_COUNT):
		offsets.append(distance)
		offsets.append(-distance)
	var valid := false
	for offset in offsets:
		for event in original_slots:
			events[event].x = original_slots[event] + offset
		if validate(events, {}, additions):
			valid = true
			break
	if not valid:
		Notification.notice("No room for the selected events", Notification.Type.WARNING)
		return false
	workspace.editor._push_history_snapshot()
	for event in new_events:
		event.id = workspace._make_unique_id(workspace._get_event_type_name(event).to_lower())
		CM.parsed_chart.events.append(event)
	for event in additions:
		workspace.get_frames(event).append_array(additions[event])
	apply_values(events, {})
	set_items(selection)
	return true

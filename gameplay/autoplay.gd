extends RefCounted
class_name Autoplay

enum Action { RELEASE, PREPARE, NOTES }

class NoteEntry extends RefCounted:
	var note: Note
	var rail: Rail

	func _init(p_note: Note, p_rail: Rail) -> void:
		note = p_note
		rail = p_rail

class Event:
	var time: int
	var action: Action
	var entries: Array[NoteEntry]
	var target: Rail
	var note_time: int

	func _init(at: int, kind: Action, items: Array[NoteEntry], rail: Rail = null, due: int = 0) -> void:
		time = at
		action = kind
		entries = items
		target = rail
		note_time = due

var events: Array[Event] = []
var _index := 0
var _rails: Array[Rail] = []


func setup(rails: Array[Rail], start_time: int = 0, note_order: Dictionary = {}) -> void:
	events.clear()
	_index = 0
	_rails = rails.duplicate()
	var groups: Dictionary = {}
	var releases: Dictionary = {}
	for rail in rails:
		for note in rail.notes:
			if note.type == Note.NoteType.NONE or note.time < start_time:
				continue
			if not groups.has(note.time):
				groups[note.time] = []
			groups[note.time].append(NoteEntry.new(note, rail))
			if note.length > 0 and note.type in [Note.NoteType.HIT, Note.NoteType.MOVE]:
				if not releases.has(note.end_time):
					releases[note.end_time] = []
				releases[note.end_time].append(NoteEntry.new(note, rail))
	var boundary_set := groups.duplicate()
	boundary_set.merge(releases, true)
	var boundaries := boundary_set.keys()
	boundaries.sort()
	var previous_time := start_time
	for time: int in boundaries:
		if releases.has(time):
			var tails: Array[NoteEntry] = []
			tails.assign(releases[time])
			events.append(Event.new(time, Action.RELEASE, tails))
		if groups.has(time):
			var entries: Array[NoteEntry] = []
			entries.assign(groups[time])
			if not note_order.is_empty():
				entries.sort_custom(func(a: NoteEntry, b: NoteEntry) -> bool:
					return int(note_order.get(a.note, 0)) < int(note_order.get(b.note, 0))
				)
			var target := _required_rail(entries)
			var move_time := previous_time + (time - previous_time) / 2
			if time > previous_time:
				move_time = maxi(previous_time + 1, move_time)
			if target != null:
				move_time = maxi(move_time, target.start_time - Score.T.GREAT)
			move_time = mini(time, maxi(start_time, move_time))
			events.append(Event.new(move_time, Action.PREPARE, entries, target, time))
			events.append(Event.new(time, Action.NOTES, entries, target, time))
		previous_time = time
	events.sort_custom(func(a: Event, b: Event) -> bool:
		if a.time == b.time:
			return a.action < b.action
		return a.time < b.time
	)


func event_times() -> Array[int]:
	var times: Array[int] = []
	for event in events:
		times.append(event.time)
	return times


func advance(gameplay: Node, time: int) -> void:
	while _index < events.size() and events[_index].time <= time:
		var event := events[_index]
		_index += 1
		match event.action:
			Action.RELEASE:
				for entry in event.entries:
					if gameplay.holding_long_hit_note == entry.note:
						gameplay._release_long_hit(event.time)
					if gameplay.holding_long_move_note == entry.note:
						gameplay._release_long_move(event.time)
			Action.PREPARE:
				_prepare(gameplay, event)
			Action.NOTES:
				# A rail may have ended since the midpoint, or a hold just released.
				_prepare(gameplay, event)
				for entry in event.entries:
					var note: Note = entry.note
					match note.type:
						Note.NoteType.HIT:
							var key := int(Config.action_hit2) if gameplay.holding_long_hit_note != null else int(Config.action_hit1)
							gameplay._input_action(event.time, key)
						Note.NoteType.MOVE:
							gameplay._move_action(note.dir, event.time, false)


func _required_rail(entries: Array[NoteEntry]) -> Rail:
	for entry in entries:
		if entry.note.type in [Note.NoteType.HIT, Note.NoteType.MOVE]:
			return entry.rail
	for entry in entries:
		if entry.note.type == Note.NoteType.TRACE:
			return entry.rail
	return null


func _prepare(gameplay: Node, event: Event) -> void:
	if gameplay.holding_long_hit_note != null or gameplay.holding_long_move_note != null:
		return
	var target := event.target
	if target == null:
		target = _safe_rail(gameplay, event)
	if target == null or target == gameplay.standing_rail or not gameplay._is_rail_active(target, event.time):
		return
	gameplay.standing_rail = target
	gameplay.player.move_to_rail(target)


func _safe_rail(gameplay: Node, event: Event) -> Rail:
	var forbidden: Array[Rail] = []
	for entry in event.entries:
		if entry.note.type == Note.NoteType.SPIKE:
			forbidden.append(entry.rail)
	var current: Rail = gameplay.standing_rail
	if current != null and not forbidden.has(current) and current.end_time >= event.note_time:
		return current
	var current_x := current._get_rail_x_at_time(event.time) if current != null else 0.5
	var nearest: Rail
	var distance := INF
	for rail in _rails:
		if forbidden.has(rail) or rail.end_time < event.note_time or not gameplay._is_rail_active(rail, event.time):
			continue
		var gap := absf(rail._get_rail_x_at_time(event.time) - current_x)
		if gap < distance:
			nearest = rail
			distance = gap
	return nearest

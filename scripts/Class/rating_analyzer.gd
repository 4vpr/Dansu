extends RefCounted
class_name Rating

const SEGMENT_DURATION_MS := 2000
# 세그먼트 나누는 시간;
const POWER := 10.5
# powermean의 power
const WEIGHT := 2.15
# 배수

static func calculate(json_data: Dictionary) -> float:
	var notes = json_data.get("notes", [])
	var rails = json_data.get("rails", [])
	if notes.size() == 0:
		return 0.0

	var rail_pos := {}
	for rail in rails:
		rail_pos[rail.get("id", 0)] = rail.get("position", rail.get("pos", 0.0))

	notes.sort_custom(func(a, b): return a["time"] < b["time"])
	var start_time = notes[0].get("time", 0)
	var end_time = notes[-1].get("time", 0)
	var segment_count = int((end_time - start_time) / SEGMENT_DURATION_MS) + 1
	var segments := []
	for i in segment_count:
		segments.append(0.0)

	for i in notes.size():
		var n = notes[i]
		var n_type = n.get("type", 1)
		if n_type == 4:
			continue  # ignore spike

		var seg_index = int((n.get("time", 0) - start_time) / SEGMENT_DURATION_MS)
		if seg_index >= segment_count:
			continue

		var value := 1.0
		if n_type == 2:
			value = 1.2
		elif n_type == 3:
			value = 0.1
		if i < notes.size() - 1:
			var next = notes[i + 1]
			if next.get("type", 1) != 4:
				var cur_pos = rail_pos.get(n.get("rail", 0), 0)
				var next_pos = rail_pos.get(next.get("rail", 0), 0)
				if abs(next_pos - cur_pos) > 0:
					value += 1.0

		segments[seg_index] += value

	# how many there are input per second
	for i in segments.size():
		segments[i] /= (SEGMENT_DURATION_MS / 1000.0)

	# Power Mean
	var acc := 0.0
	var valid_count := 0
	for val in segments:
		if val > 0.0:
			acc += pow(val, POWER)
			valid_count += 1

	if valid_count == 0:
		return 0.0

	var mean = pow(acc / valid_count, 1.0 / POWER)
	return mean * WEIGHT


const FAST_INPUT_THRESHOLD := 180.0  # ms
const FAST_INPUT_WEIGHT := 1.25

static func calculate_ver2(json_data: Dictionary) -> float:
	var notes: Array = json_data.get("notes", [])
	var rails: Array = json_data.get("rails", [])
	if notes.is_empty():
		return 0.0

	# rail.id -> position 매핑
	var rail_pos := {}
	for rail in rails:
		rail_pos[rail.get("id", 0)] = rail.get("position", rail.get("pos", 0.0))

	# 시간순 정렬
	notes.sort_custom(func(a, b): return a["time"] < b["time"])
	var start_time :int = notes[0].get("time", 0)
	var end_time :int = notes[-1].get("time", 0)
	var segment_count := int((end_time - start_time) / SEGMENT_DURATION_MS) + 1
	var segments: Array[float] = []
	for i in segment_count:
		segments.append(0.0)

	# 누적
	for i in notes.size():
		var note = notes[i]
		var n_type : int = note.get("type", 1)
		if n_type == 4:
			continue  # 장애물 제외

		var seg_index := int((note.get("time", 0) - start_time) / SEGMENT_DURATION_MS)
		if seg_index >= segment_count:
			continue

		var value := 1.0
		if n_type == 2:
			value = 1.2
		elif n_type == 3:
			value = 0.1

		# 보이지 않는 이동 고려 (다음 note와 pos 다를 경우)
		if i < notes.size() - 1:
			var next = notes[i + 1]
			if next.get("type", 1) != 4:
				var cur_pos = rail_pos.get(note.get("rail", 0), 0)
				var next_pos = rail_pos.get(next.get("rail", 0), 0)
				if abs(next_pos - cur_pos) > 0:
					value += 1.0

		# 빠른 인풋 간격 가중치
		if i > 0 and notes[i - 1].get("type", 1) != 4:
			var prev_time :int = notes[i - 1].get("time", 0)
			var cur_time :int = note.get("time", 0)
			var gap := cur_time - prev_time
			var mid_time := (prev_time + cur_time) / 2.0

			if gap < FAST_INPUT_THRESHOLD:
				var mid_seg := int((mid_time - start_time) / SEGMENT_DURATION_MS)
				if mid_seg >= 0 and mid_seg < segments.size():
					segments[mid_seg] += FAST_INPUT_WEIGHT

		segments[seg_index] += value

	# 초당 입력으로 환산
	for i in segments.size():
		segments[i] /= (SEGMENT_DURATION_MS / 1000.0)

	# Power Mean 계산
	var acc := 0.0
	var valid_count := 0
	for v in segments:
		if v > 0.0:
			acc += pow(v, POWER)
			valid_count += 1

	if valid_count == 0:
		return 0.0

	var mean := pow(acc / valid_count, 1.0 / POWER)
	return mean * WEIGHT

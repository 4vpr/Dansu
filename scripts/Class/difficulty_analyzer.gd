extends RefCounted
class_name BeatmapDifficultyAnalyzer

const SEGMENT_DURATION_MS := 3000
const POWER := 8.0
const WEIGHT := 2.3

static func calculate_difficulty(json_data: Dictionary) -> float:
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
			continue  # 장애물 제외

		var seg_index = int((n.get("time", 0) - start_time) / SEGMENT_DURATION_MS)
		if seg_index >= segment_count:
			continue

		var value := 1.0
		if n_type == 2:
			value = 1.2
		elif n_type == 3:
			value = 0.1

		# 다음 노트가 존재하고 type != 4일 때만 이동 가중치 추가
		if i < notes.size() - 1:
			var next = notes[i + 1]
			if next.get("type", 1) != 4:
				var cur_pos = rail_pos.get(n.get("rail", 0), 0)
				var next_pos = rail_pos.get(next.get("rail", 0), 0)
				if abs(next_pos - cur_pos) > 0:
					value += 1.0

		segments[seg_index] += value

	# 초당 입력으로 환산
	for i in segments.size():
		segments[i] /= (SEGMENT_DURATION_MS / 1000.0)

	# Power Mean 계산
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

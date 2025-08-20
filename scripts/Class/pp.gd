extends Node
class_name PP
static func calculate_pp(score: float, difficulty: float) -> float:
	var pp_max := 0.0
	if difficulty <= 10.0:
		pp_max = lerp(0.0, 50.0, difficulty / 10.0)
	elif difficulty <= 20.0:
		pp_max = lerp(50.0, 150.0, (difficulty - 10.0) / 10.0)
	elif difficulty <= 30.0:
		pp_max = lerp(150.0, 400.0, (difficulty - 20.0) / 10.0)
	elif difficulty <= 40.0:
		pp_max = lerp(400.0, 1000.0, (difficulty - 30.0) / 10.0)
	else:
		pp_max = 1000.0 + (difficulty - 40.0) * 20.0 
	var multiplier := 0.0
	if score <= 90.0:
		multiplier = lerp(0.0, 0.1, score / 80.0)
	elif score <= 93.0:
		multiplier = lerp(0.1, 0.3, (score - 80.0) / 10.0)
	elif score <= 95.0:
		multiplier = lerp(0.3, 0.8, (score - 90.0) / 5.0)
	elif score <= 99.0:
		multiplier = lerp(0.8, 1.0, (score - 95.0) / 4.0)
	elif score <= 100.0:
		multiplier = lerp(1.0, 1.1, (score - 99.0))
	elif score <= 101.0:
		multiplier = lerp(1.1, 1.3, (score - 100.0))
	else:
		multiplier = 1.3
	return snappedf(pp_max * multiplier, 0.01)

static func calculate_total_pp(max_count: int = 30) -> float:
	var pp_list = get_pp_list_from_saved_scores()
	pp_list.sort_custom(func(a, b): return b > a)

	max_count = min(max_count, pp_list.size())
	var total: float = 0.0
	for i in range(max_count):
		var weight: float = pow(0.95, i)
		total += pp_list[i] * weight

	return snappedf(total, 0.01)

static func get_rank_from_pp(pp: float) -> int:
	var thresholds = [
		0, 100, 300,   # 브론즈1~3
		500, 800, 1200, # 실버1~3
		1500, 2000, 2500, # 골드1~3
		3000, 3750, 4250, # 플레1~3
		5000, 6000, 7000, # 다이아1~3
		8000, # 마스터
		10000, # 그랜드마스터
		15000 # 얼티메이트
	]
	for i in range(thresholds.size()):
		if pp < thresholds[i]:
			return i
	return thresholds.size()
	
static func get_pp_list_from_saved_scores() -> Array[float]:
	var pp_list: Array[float] = []

	for uuid in Game.save_data.keys():
		var entries = Game.save_data[uuid]
		if typeof(entries) != TYPE_ARRAY or entries.is_empty():
			continue

		var max_score := -1.0
		for entry in entries:
			if typeof(entry) == TYPE_DICTIONARY and entry.has("score"):
				max_score = max(max_score, entry["score"])

		if max_score < 0:
			continue
		for chart_set in CM.charts:
			for chart in chart_set:
				if chart.map_uuid == uuid:
					var diff_value = chart.diff_value
					var pp = calculate_pp(max_score, diff_value)
					pp_list.append(pp)
	return pp_list

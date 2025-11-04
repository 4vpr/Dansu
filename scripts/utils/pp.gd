extends Node
class_name PP
static func calculate_pp(score: float, difficulty: float) -> float:
	var pp_max := 0.0
	if difficulty <= 10.0:
		pp_max = lerp(0.0, 80.0, difficulty / 10.0)
	elif difficulty <= 20.0:
		pp_max = lerp(80.0, 160.0, (difficulty - 10.0) / 10.0)
	elif difficulty <= 30.0:
		pp_max = lerp(160.0, 290.0, (difficulty - 20.0) / 10.0)
	elif difficulty <= 40.0:
		pp_max = lerp(290.0, 500.0, (difficulty - 30.0) / 10.0)
	else:
		pp_max = 500.0 + (difficulty - 40.0) * 20.0
	var multiplier := 0.0
	if score <= 8.0:
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
		multiplier = lerp(1.1, 1.2, (score - 100.0))
	else:
		multiplier = 1.3
	return snappedf(pp_max * multiplier, 0.01)
"""
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
"""

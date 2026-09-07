extends RefCounted
class_name SongFilters

static func defaults(online: bool) -> Dictionary:
	return {"sort": "newest" if online else "title", "reverse": false, "nsfl": false}

static func matches_local(chart, filters: Dictionary) -> bool:
	for pair in [["min_rating", chart.rating, true], ["max_rating", chart.rating, false],
		["min_length_ms", chart.play_time_ms, true], ["max_length_ms", chart.play_time_ms, false]]:
		if filters.has(pair[0]):
			if pair[2] and pair[1] < filters[pair[0]]:
				return false
			if not pair[2] and pair[1] > filters[pair[0]]:
				return false
	if filters.has("played") and (chart.play_count > 0) != filters.played:
		return false
	return true

static func active_count(filters: Dictionary) -> int:
	var count := 0
	for key in filters:
		if key == "sort" or (key in ["reverse", "nsfl"] and not filters[key]):
			continue
		count += 1
	return count

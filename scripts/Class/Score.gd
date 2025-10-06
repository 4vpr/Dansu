extends Node
class_name Score

# timing of each judgements (ms)
const timings = [
	21 , # 0 Just+
	42 , # 1 Just
	63 , # 2 Good
	84 ,  # 3 Ok
	105, # 4 Nah
]
# scores of each judgements
const scores = [
	100 , # 0 Just +
	99 , # 1 Just
	50 , # 2 Good
	30 , # 3 Ok
	15 , # 4 Nah
	0 # 5 Miss
]
var notes = 0
# count of judgement for result
var counts = [
	0,
	0,
	0,
	0,
	0,
	0
]

# current score
var score: float = 0
# max score for the map
var high_combo: int = 0

var uuid = 0
# hash for the score
var hash = 0
# 맵 실행시 맵파일로 해시를 생성, 비교해서 맵이 되었을시 uuid만으로 상호호환이 안되기 하기 위함.
# 예시상황) 유저가 맵을 배포함 -> 다른유저가 플레이하여 기록 남김 -> 맵이 업데이트 됨
# -> 해당 기록은 해시값의 비교로 맵의 다른버전에서 기록된 점수라는 사실을 알 수 있음.

func getJudge(t) -> int:
	var j:int = -1
	var i = 0
	for timing in timings:
		if timing * -1 < t and t < timing:
			return i
		i += 1
	return -1
func getScore() -> float:
	var f:float = 0
	if notes == 0:
		return 0
	if notes <= counts[0] + counts[1]:
		f = (counts[0] * 1.01 + counts[1] * 1.0) / notes * 100
	else:
		f = score / (notes * 100) * 100
	return f
func save_current_score():
	return
	var data: Dictionary = {
		"score": getScore(),
		"note": notes,
		"justp": counts[0],
		"just": counts[1],
		"good": counts[2],
		"ok": counts[3],
		"nah": counts[4],
		"miss": counts[5],
		"high_combo": high_combo,
		"hash": hash
	}

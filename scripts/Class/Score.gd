extends Node
class_name Score

# timing of each judgements (ms)
const t_perfect_plus: float = 21
const t_perfect: float = 42
const t_great: float = 63
const t_ok: float = 84
const t_bad: float = 105

# score of each judgements
const s_perfect_plus: float = 100
const s_perfect: float = 99
const s_great: float = 50
const s_ok: float = 30
const s_bad: float = 15

# count of judgement for result
var c_note: int = 0
var c_perfect_plus: int = 0
var c_perfect: int = 0 
var c_great: int = 0
var c_ok: int = 0
var c_bad: int = 0
var c_miss: int = 0

# current score
var score :float = 0
# max score for the map
var max_score :float = 0
var high_combo: int = 0


var uuid = 0
# hash for the score
var hash = 0
# 맵 실행시 맵파일로 해시를 생성, 비교해서 맵이 되었을시 uuid만으로 상호호환이 안되기 하기 위함.
# 예시상황) 유저가 맵을 배포함 -> 다른유저가 플레이하여 기록 남김 -> 맵이 업데이트 됨
# -> 해당 기록은 해시값의 비교로 맵의 다른버전에서 기록된 점수라는 사실을 알 수 있음.

func getJudge(i) -> int:
	var j:int = -1
	if i < t_perfect_plus && i > t_perfect_plus * -1:
		j = 5
	elif i < t_perfect && i > t_perfect * -1:
		j = 1
	elif i < t_great && i > t_great * -1:
		j = 2
	elif i < t_ok && i > t_ok * -1:
		j = 3
	elif i < t_bad && i > t_bad * -1:
		j = 4
	return j
func addScore(i):
	max_score += s_perfect_plus
	c_note += 1
	if i == 5:
		c_perfect_plus += 1
		score += s_perfect_plus
	if i == 1:
		c_perfect += 1
		score += s_perfect
	elif i == 2:
		c_great += 1
		score += s_great
	elif i == 3:
		c_ok += 1
		score += s_ok
	elif i == 4:
		c_bad += 1
		score += s_bad
	elif i == 0:
		c_miss += 1
func getScore() -> float:
	var f:float = 0
	if c_note == 0:
		return 0
	if c_note <= c_perfect_plus + c_perfect:
		f = (float(c_perfect_plus) / float(c_note)) + 100
	else:
		f = score / max_score * 100
	return f
func save_current_score():
	if uuid == null or uuid == "0":
		print("no uuid found")
		return
	var data: Dictionary = {
		"score": getScore(),
		"note": c_note,
		"perfect_plus": c_perfect_plus,
		"perfect": c_perfect,
		"good": c_great,
		"ok": c_ok,
		"bad": c_bad,
		"miss": c_miss,
		"high_combo": high_combo,
		"hash": hash
	}
	if Game.save_data.has(uuid):
		Game.save_data[uuid].append(data)
	else:
		Game.save_data[uuid] = [data]
	Game.save_data_to_file()

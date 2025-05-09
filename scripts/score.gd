extends Node
class_name Score

const t_perfect_plus: float = 24
const t_perfect: float = 48
const t_great: float = 72
const t_ok: float = 144
const t_bad: float = 288

const s_perfect_plus: float = 100
const s_perfect = 99
const s_great = 50
const s_ok = 25
const s_bad = 0

# 친 노트 갯
var c_note :int = 0
var c_perfect_plus = 0
var c_perfect = 0 
var c_good = 0
var c_ok = 0
var c_bad = 0
var c_miss = 0

var score :float = 0
var max_score :float = 0
var high_combo = 0


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
		c_good += 1
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
	if c_note <= c_perfect_plus + c_perfect:
		f = (c_perfect_plus / c_note) + 100
	else:
		f = score / max_score * 100
	return f

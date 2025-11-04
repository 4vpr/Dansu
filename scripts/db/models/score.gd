class_name Score
extends Model

# links
var uuid: String = ""
var hash: String = ""
var user_id: int

# Score
var base_score = 0
var score: int = 0

# Counter
var note_count:int = 0
var just_plus:int = 0
var just:int = 0
var good:int = 0
var ok:int = 0
var nah:int = 0
var miss:int = 0

var mods: String = ""

func getJudge(t) -> int:
	var j:int = -1
	var i = 0
	for timing in Consts.timings:
		if timing * -1 < t and t < timing:
			return i
		i += 1
	return -1

func getScore() -> float:
	var f:float = 0
	if note_count == 0:
		return 0
	if note_count <= just_plus + just:
		f = (just_plus * 1.01 + just * 1.0) / note_count * 100
	else:
		f = base_score / (note_count * 100) * 100
		score = f
	return f

static func table() -> String: return "scores"
static func fields() -> Dictionary:
	return {
		# meta
		"uuid": Field.Text("",true,false,true),
		"hash": Field.Text("",true,false,true),
		"user_id": Field.INT(0),
		"score": Field.INT(0),
		# counts
		"note_count": Field.INT(0),
		"just_plus" : Field.INT(0),
		"just" : Field.INT(0),
		"good" : Field.INT(0),
		"ok" : Field.INT(0),
		"nah" : Field.INT(0),
		"miss" : Field.INT(0),
		"mods" : Field.Text(""),
	}
func _init() -> void:
	_defaults()

static func objects_for(db: DansuDB) -> QuerySet:
	return Model.objects(db, User)

static func ensure_table_for(db: DansuDB) -> void:
	Model.ensure_table(db, User)

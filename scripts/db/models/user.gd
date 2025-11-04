extends Model
class_name User

var username: String

static func table() -> String: return "users"
static func fields() -> Dictionary:
	return {
		"username": Field.Text("", false, true),
	}
func _init() -> void:
	_defaults()

static func objects_for(db: DansuDB) -> QuerySet:
	return Model.objects(db, User)

static func ensure_table_for(db: DansuDB) -> void:
	Model.ensure_table(db, User)

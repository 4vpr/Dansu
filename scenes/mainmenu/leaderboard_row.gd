extends PanelContainer
class_name ChartLeaderboardRow

@export_group("Node References")
@export var rank_label: Label
@export var name_label: Label
@export var accuracy_label: Label
@export var combo_label: Label


func set_entry(rank_text: String, display_name: String, accuracy: float, combo_text: String, highlighted: bool = false) -> void:
	rank_label.text = rank_text
	name_label.text = display_name
	accuracy_label.text = "%.2f%%" % accuracy
	combo_label.text = combo_text
	self_modulate = Color(1.0, 0.91, 0.55) if highlighted else Color.WHITE

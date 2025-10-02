extends Panel
var scores = []
func _ready():
	CM.connect("chart_selected", Callable(self,"_update"))
func _update(chart):
	var diff = chart.get_difficulty()
	# scores = Game.get_sorted_scores_for_uuid(chart.map_uuid)
	$Title.text = chart.meta_title
	$Artist.text = chart.meta_artist
	$BPM.text = "BPM " + str(chart.song_bpm)
	$Difficulty.text = chart.diff_name + " (" + str(snappedf(diff,0.01)) + ")"
	if scores.size() == 0:
		$Rank.text = ""
		$Score.text = "never played"
		$FC.visible = false
		$AJ.visible = false
		$Combo.visible = false
		$pp.visible = false
	else:
		$FC.visible = false
		$AJ.visible = false
		$Combo.visible = true
		$pp.visible = true
		$Rank.text = Game.getRank(scores[0]["score"])
		$Score.text = str(str(int(scores[0]["score"] * 10000)))
		$pp.text = str(PP.calculate_pp(scores[0]["score"],diff)) + "pp"
		if scores[0]["score"] >= 100:
			$AJ.visible = true
		elif scores[0]["miss"] == 0:
			$FC.visible = true
		$Combo.text =  str(scores[0]["high_combo"]) + ("X") + " / "+ str(scores[0]["note"]) + ("X")

extends Panel
var scores = []
func _update():
	var diff = Game.selected_beatmap.get_difficulty()
	scores = Game.get_sorted_scores_for_uuid(Game.selected_beatmap.map_uuid)
	$Title.text = Game.selected_beatmap.meta_title
	$Artist.text = Game.selected_beatmap.meta_artist
	$BPM.text = "BPM " + str(Game.selected_beatmap.song_bpm)
	$Difficulty.text = Game.selected_beatmap.diff_name + " (" + str(snappedf(diff,0.01)) + ")"
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

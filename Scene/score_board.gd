extends Panel
var scores = []
func _update():
	scores = Game.get_sorted_scores_for_uuid(Game.selected_beatmap.map_uuid)
	$Title.text = Game.selected_beatmap.meta_title
	$Artist.text = Game.selected_beatmap.meta_artist
	$BPM.text = "BPM " + str(Game.selected_beatmap.song_bpm)
	$Difficulty.text = Game.selected_beatmap.diff_name
	if scores.size() == 0:
		$Rank.text = "never"
		$Score.text = "played"
	else:
		$Rank.text = Game.getRank(scores[0]["score"])
		$Score.text = str(str(int(scores[0]["score"] * 10000)))

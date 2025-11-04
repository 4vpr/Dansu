
func load_chart(path: String):
	var chart_cfg := ConfigFile.new()
	var chart_err := chart_cfg.load(path)

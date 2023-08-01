extends TabContainer


var color : Color
var pattern : int = 1

signal background_changed(color, pattern)


func _on_COLOR_color_changed(color):
	emit_signal("background_changed", color, pattern)
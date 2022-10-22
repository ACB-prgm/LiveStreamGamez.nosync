tool
extends EditorPlugin


var refresh_timer := Timer.new()


func _enter_tree():
	refresh_timer.set_wait_time(60)
	refresh_timer.set_one_shot(false)
	refresh_timer.connect("timeout", self, "refresh_dir")
	get_tree().root.add_child(refresh_timer)

func _exit_tree():
	refresh_timer.free()





func refresh_dir():
	pass

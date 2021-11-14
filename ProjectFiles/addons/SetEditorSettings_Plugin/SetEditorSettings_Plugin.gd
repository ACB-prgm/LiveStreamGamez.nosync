tool
extends EditorPlugin


func _enter_tree():
	get_editor_interface().get_editor_settings().set_setting("network/debug/remote_port", 8007)

func _exit_tree():
	pass

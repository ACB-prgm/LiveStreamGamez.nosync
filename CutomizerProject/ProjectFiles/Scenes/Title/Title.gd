extends Control


onready var tween = $Tween

var force_sign_in := false

signal change_tab(from_obj, to_tab)


func show_tab() -> void:
	Background.move_head(Vector2(1920/2.0, 1080/2.0))
	force_sign_in = true


func _on_Button_pressed():
	GoogleSignIn.authorize(force_sign_in)
	yield(GoogleSignIn, "sign_in_completed")
	force_sign_in = false

#	emit_signal("change_tab", self, 1)


func _on_Selector_signout():
	Background.move_head(Vector2(1920/2.0, 1080/2.0))
	force_sign_in = true

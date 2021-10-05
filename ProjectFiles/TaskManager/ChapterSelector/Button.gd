extends Button


signal fileButton_pressed(file)


func _on_Button_toggled(button_pressed):
	if button_pressed:
		emit_signal("fileButton_pressed", text)
	else:
		emit_signal("fileButton_pressed", null)

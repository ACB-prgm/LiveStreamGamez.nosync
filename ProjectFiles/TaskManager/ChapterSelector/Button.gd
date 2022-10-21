extends HBoxContainer


onready var fileButton = $Button

var text := ""

signal fileButton_pressed(file)
signal deleteButton_pressed(file)


func _ready():
	fileButton.set_text(text)


func _on_Button_toggled(button_pressed):
	if button_pressed:
		emit_signal("fileButton_pressed", text)
	else:
		emit_signal("fileButton_pressed", null)


func _on_DeleteButton_pressed():
	emit_signal("deleteButton_pressed", text)


func set_pressed(pressed):
	fileButton.set_pressed(pressed)

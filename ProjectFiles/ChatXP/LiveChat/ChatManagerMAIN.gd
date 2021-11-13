extends Control



onready var chatbox = $ChatManager
onready var button = $Button




func _on_Button_pressed():
	chatbox.show()
	button.hide()

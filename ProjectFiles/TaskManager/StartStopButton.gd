extends Button


const GREEN = Color(0.65, 0.94, 0.67, 1.0)
const RED = Color(0.98, 0.6, 0.61, 1.0)

onready var stylebox = get("custom_styles/normal")


func _on_StartStopButton_toggled(button_pressed):
	if button_pressed:
		text = "STOP"
		stylebox.bg_color = RED
	else:
		text = "START"
		stylebox.bg_color = GREEN

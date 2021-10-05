extends Button


const GREEN = Color(0.65, 0.94, 0.67, 1.0)
const RED = Color(0.99, 0.61, 0.61, 1.0)

onready var colorRect = $ColorRect

signal completed
signal started


func _on_StartStopButton_toggled(button_pressed):
	if button_pressed:
		text = "ACTIVE"
		colorRect.color = RED
		emit_signal("started")
	else:
		text = "COMPLETED"
		disabled = true
		colorRect.color = Color(1,1,1,0)
		emit_signal("completed")


func _on_StartStopButton_mouse_entered():
	if not disabled:
		if text == "ACTIVE":
			colorRect.color = RED
		else:
			colorRect.color = GREEN


func _on_StartStopButton_mouse_exited():
	colorRect.color = Color(1,1,1,0)

extends HBoxContainer


const ALPHA_VALUE = 0.25

onready var lineEdit := $LineEdit
onready var tween := $Tween


signal task_created(task_name)

func _ready():
	lineEdit.modulate.a = ALPHA_VALUE

func _on_Button_pressed():
	var task_name = lineEdit.text
	if task_name.length() > 0 and TaskManagerGlobals.started:
		emit_signal("task_created", task_name)
		lineEdit.clear()


func _on_VBoxContainer_mouse_entered():
	# warning-ignore:return_value_discarded
	tween.interpolate_property(lineEdit, "modulate:a", modulate.a, 1.0, 0.2,
	Tween.TRANS_SINE, Tween.EASE_IN)
	# warning-ignore:return_value_discarded
	tween.start()


func _on_VBoxContainer_mouse_exited():
	tween.interpolate_property(lineEdit, "modulate:a", modulate.a, ALPHA_VALUE, 0.2,
	Tween.TRANS_SINE, Tween.EASE_IN)
	# warning-ignore:return_value_discarded
	tween.start()

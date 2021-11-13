extends PanelContainer


var task : String = "TASK NAME"
var start_time_str : String
var start_time_sec : int
var end_time_secs : int
var stream_start_time : int = 0
var completed : bool = false

onready var name_label := $VBoxContainer/HBoxContainer/NameLabel
onready var time_label := $VBoxContainer/TimeLabel

signal task_completed(task_name, start, stop)


func _ready():
# warning-ignore:return_value_discarded
	TaskManagerGlobals.connect("refresh", self, "_on_Refresh")
	name_label.text = task


func _on_StartStopButton_started():
# warning-ignore:integer_division
	start_time_sec = TaskManagerGlobals.get_current_time_sec() - stream_start_time
	start_time_str = "%s:%s:%s" % get_time_from_secs(start_time_sec)


func _on_StartStopButton_completed():
# warning-ignore:integer_division
	emit_signal("task_completed", task, start_time_sec, TaskManagerGlobals.get_current_time_sec())
	completed = true


func _on_Refresh():
	if start_time_sec and not completed:
# warning-ignore:integer_division
		var seconds_elapsed = TaskManagerGlobals.get_current_time_sec() - stream_start_time
		time_label.set_text(start_time_str + " — %s:%s:%s" % get_time_from_secs(seconds_elapsed))


func get_time_from_secs(seconds):
	var secs = str(seconds % 60).pad_zeros(2)
	var mins = str(seconds / 60 % 60).pad_zeros(2)
	var hrs = str(seconds / 3600).pad_zeros(2)
	
	return [hrs, mins, secs]

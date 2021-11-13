extends VBoxContainer


const ALPHA_VALUE = 0.5

var loadingScreen = preload("res://LoadingScreen/LoadingScreen.tscn")
var task_TSCN = preload("res://TaskManager/Task/Task.tscn")
var tween := Tween.new()
var start_time : int
var seconds_elapsed : int
var chapters := []
var time_passed := {
	"hours" : 0,
	"minutes" : 0,
	"seconds" : 0,
}

onready var popup_INS = preload("res://TaskManager/FinishedPopup/FinishedPopup.tscn").instance()
onready var streamTimeLabel = $PanelContainer/HBoxContainer/StreamTimeLabel
onready var tasksContainter = $ScrollContainer/TasksVBoxContainer


func _ready():
	popup_INS.connect("set_final_duration", self, "_on_set_final_duration")
	get_parent().call_deferred("add_child", popup_INS)
	
	add_child(tween)
# warning-ignore:return_value_discarded
	TaskManagerGlobals.connect("refresh", self, "_on_Refresh")
# warning-ignore:return_value_discarded
	YoutTubeApi.connect("BroadcastID_recieved", self, "_on_YoutTubeApi_BroadcastID_recieved")
	modulate.a = ALPHA_VALUE


func _on_VBoxContainer_mouse_entered():
# warning-ignore:return_value_discarded
	tween.interpolate_property(self, "modulate:a", modulate.a, 1.0, 0.2,
	Tween.TRANS_SINE, Tween.EASE_IN)
# warning-ignore:return_value_discarded
	tween.start()


func _on_VBoxContainer_mouse_exited():
# warning-ignore:return_value_discarded
	tween.interpolate_property(self, "modulate:a", modulate.a, ALPHA_VALUE, 0.2,
	Tween.TRANS_SINE, Tween.EASE_IN)
# warning-ignore:return_value_discarded
	tween.start()



func _on_StartStopButton_toggled(button_pressed):
	if button_pressed:
#		make_loading_screen(OAuth2, "token_recieved", "waiting for oath2.0")
		OAuth2.authorize()
		yield(OAuth2, "token_recieved")
		make_loading_screen(YoutTubeApi, "BroadcastID_recieved", "waiting for livestream info")
		yield(YoutTubeApi, "BroadcastID_recieved")
		
		if YoutTubeApi.BroadcastID:
			TaskManagerGlobals.set_active(true)
			start_time = TaskManagerGlobals.get_seconds_from_time(YoutTubeApi.get_time_from_BroadcastDateTime(YoutTubeApi.LiveBroadcastResource.get("snippet").get("actualStartTime")))
	else:
		TaskManagerGlobals.set_active(false)
# warning-ignore:integer_division
		seconds_elapsed = get_seconds_elapsed()
		if YoutTubeApi.BroadcastID:
			popup_INS.popup()


func _on_YoutTubeApi_BroadcastID_recieved(success):
	if success:
		TaskManagerGlobals.set_active(true)
# warning-ignore:integer_division
		chapters = [
			{
				"name" : "Intro",
				"start_time" : 0
			}
		]
	else:
		$PanelContainer/HBoxContainer/StartStopButton.pressed = false


func _on_Refresh():
	# happens once every 60 physics frames
# warning-ignore:integer_division
	seconds_elapsed = get_seconds_elapsed()
	streamTimeLabel.set_text("Stream Time : %s:%s:%s" % TaskManagerGlobals.get_time_from_secs(seconds_elapsed))


func _on_TaskCreator_task_created(task_name):
	var task_INS = task_TSCN.instance()
	task_INS.task = task_name
	task_INS.stream_start_time = start_time
	task_INS.connect("task_completed", self, "_on_task_completed")
	tasksContainter.add_child(task_INS)


func _on_task_completed(task_name, start_time_secs, _end_time_secs):
	var formatted_task = {
				"name" : task_name,
				"start_time" : start_time_secs,
				}
	chapters.append(formatted_task)


func _on_set_final_duration(title):
		save_data(title, chapters)


func get_seconds_elapsed():
	var current_time = TaskManagerGlobals.get_current_time_sec()
	if start_time > current_time:
		current_time += 86400 # 24 hours in seconds
	
	return current_time - start_time


# SAVE/LOAD
const SAVE_DIR = 'user://LiveStreamChapters/'


func save_data(file_name, data):
	var save_path = SAVE_DIR + file_name + ".dat"
	var dir = Directory.new()
	if !dir.dir_exists(SAVE_DIR):
		dir.make_dir_recursive(SAVE_DIR)

	var file = File.new()
	var error = file.open(save_path, File.WRITE)
	if error == OK:
		file.store_var(data)
		file.close()
	else:
		print("ERROR SAVING FILE : %s" % error)


func make_loading_screen(obj, signal_, message):
	var loading = loadingScreen.instance()
	loading.kill_obj = obj
	loading.kill_signal = signal_
	loading.message = message
	get_parent().add_child(loading)

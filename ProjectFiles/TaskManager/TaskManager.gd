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
		make_loading_screen(OAuth2, "token_recieved", "waiting for oath2.0")
		OAuth2.authorize()
		yield(OAuth2, "token_recieved")
		make_loading_screen(YoutTubeApi, "BroadcastID_recieved", "waiting for livestream info")
	else:
		TaskManagerGlobals.set_active(false)
# warning-ignore:integer_division
		seconds_elapsed = OS.get_ticks_msec()/1000 - start_time
		if YoutTubeApi.BroadcastID:
			popup_INS.popup()


func _on_YoutTubeApi_BroadcastID_recieved(success):
	if success:
		TaskManagerGlobals.set_active(true)
# warning-ignore:integer_division
		start_time = OS.get_ticks_msec()/1000
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
	seconds_elapsed = OS.get_ticks_msec()/1000 - start_time
	streamTimeLabel.set_text("Stream Time : %s:%s:%s" % get_time_from_secs(seconds_elapsed))


func get_time_from_secs(seconds):
	var secs = str(seconds % 60).pad_zeros(2)
	var mins = str(seconds / 60 % 60).pad_zeros(2)
	var hrs = str(seconds / 3600).pad_zeros(2)
	
	return [hrs, mins, secs]


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


func _on_set_final_duration(final_duration, title):
	var duration_offset = get_seconds_from_time(final_duration) - seconds_elapsed
	
	for chapter in chapters: # modifies to adjust for start time difference
		if not chapter["name"] == "Intro":
			var true_offset = (seconds_elapsed - chapter["start_time"]) + duration_offset
			chapter["start_time"] += true_offset
	
		save_data(title, chapters)


func get_seconds_from_time(time):
	# time = [hrs, mins, secs]
	var hrs = time[0] * 3600
	var mins = time[1] * 60
	var secs = time[2]
	
	return hrs + mins + secs



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

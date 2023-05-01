extends Node


var started := false
var frames := 0

signal refresh

func _ready():
	set_physics_process(false)


func level_func(x) -> int:
	return int(100 * pow(1.05, x))


func set_active(active):
	started = active
	set_physics_process(active)


func _physics_process(_delta):
	if frames >= 60:
		frames = 0
		emit_signal("refresh")
	
	frames += 1


func get_time_from_secs(seconds):
	var secs = str(seconds % 60).pad_zeros(2)
	var mins = str(seconds / 60 % 60).pad_zeros(2)
	var hrs = str(seconds / 3600).pad_zeros(2)
	
	return [hrs, mins, secs]


func get_seconds_from_time(time):
	# time = [hrs, mins, secs]
	var hrs = int(time[0]) * 3600
	var mins = int(time[1]) * 60
	var secs = int(time[2])
	
	return hrs + mins + secs


func get_current_time_sec():
	var time = OS.get_time(true)
	time = get_seconds_from_time([time["hour"], time["minute"], time["second"]])
	return time

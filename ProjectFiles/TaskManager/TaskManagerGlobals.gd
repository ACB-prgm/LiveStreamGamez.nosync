extends Node

const LEVEL_INFO = {1:300, 10:3000, 11:3300, 12:3600, 13:3900, 14:4200, 15:4500, 16:4800, 17:5100, 18:5400, 19:5700, 2:600, 20:6000, 21:6300, 22:6600, 23:6900, 24:7200, 25:7500, 26:7800, 27:8100, 28:8400, 29:8700, 3:900, 30:9000, 31:9300, 32:9600, 33:9900, 34:10200, 35:10500, 36:10800, 37:11100, 38:11400, 39:11700, 4:1200, 40:12000, 41:12300, 42:12600, 43:12900, 44:13200, 45:13500, 46:13800, 47:14100, 48:14400, 49:14700, 5:1500, 50:15000, 6:1800, 7:2100, 8:2400, 9:2700}


var started := false
var frames := 0

signal refresh

func _ready():
	### GENERATES THE LEVEL INFO
#	LEVEL_INFO.clear()
#	for level in range(0, 50):
#		LEVEL_INFO[level + 1] = 300 + (300 * level)
#	print(LEVEL_INFO)
	set_physics_process(false)


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

extends Node

const LEVEL_INFO = {1:300, 10:1650, 11:1800, 12:1950, 13:2100, 14:2250, 15:2400, 16:2550, 17:2700, 18:2850, 19:3000, 2:450, 20:3150, 21:3300, 22:3450, 23:3600, 24:3750, 25:3900, 26:4050, 27:4200, 28:4350, 29:4500, 3:600, 30:4650, 31:4800, 32:4950, 33:5100, 34:5250, 35:5400, 36:5550, 37:5700, 38:5850, 39:6000, 4:750, 40:6150, 41:6300, 42:6450, 43:6600, 44:6750, 45:6900, 46:7050, 47:7200, 48:7350, 49:7500, 5:900, 50:7650, 6:1050, 7:1200, 8:1350, 9:1500}


var started := false
var frames := 0

signal refresh

func _ready():
	### GENERATES THE LEVEL INFO
#	LEVEL_INFO.clear()
#	for level in range(0, 50):
#		LEVEL_INFO[level + 1] = 300 + (300 * level * 0.5)
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

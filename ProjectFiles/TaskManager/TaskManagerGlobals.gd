extends Node


var started := false
var frames := 0

signal refresh

func _ready():
	set_physics_process(false)


func set_active(active):
	started = active
	set_physics_process(active)


func _physics_process(_delta):
	if frames >= 60:
		frames = 0
		emit_signal("refresh")
	
	frames += 1

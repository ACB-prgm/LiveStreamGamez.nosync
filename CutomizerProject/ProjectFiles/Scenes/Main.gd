extends Control


const TOTAL_TIME := 10
const MAX_SKEW := 18.0

onready var tween = $Tween
onready var grid_material = $TextureRect.material

var forward: = false


func _ready():
	grid_material.set("shader_param/y_rot", -MAX_SKEW)
	grid_tween()

func grid_tween() -> void:
	forward = !forward
	var dir = (int(forward) - 0.5) * 2
	
	tween.interpolate_property(grid_material, "shader_param/y_rot", null, 
	MAX_SKEW * dir, TOTAL_TIME / 2, Tween.TRANS_SINE, Tween.EASE_IN_OUT)
	tween.start()

func _on_Tween_tween_all_completed():
	grid_tween()

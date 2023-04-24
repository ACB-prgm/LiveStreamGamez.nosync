extends Control


const TOTAL_TIME := 10
const MAX_SKEW := 18

onready var tween = $Tween
onready var grid_material = $Grid.material

var grid_dir := 1


func _ready():
	grid_material.set("shader_param/y_rot", MAX_SKEW)
	grid_tween()



func grid_tween() -> void:
	grid_dir *= -1
	var time = TOTAL_TIME / 2.0
	
	tween.interpolate_property(grid_material, "shader_param/y_rot", null, 
	MAX_SKEW * grid_dir, 
	time, Tween.TRANS_SINE, Tween.EASE_IN_OUT)
	
	tween.start()


func _on_Tween_tween_completed(object, key):
	if object == grid_material:
		grid_tween()

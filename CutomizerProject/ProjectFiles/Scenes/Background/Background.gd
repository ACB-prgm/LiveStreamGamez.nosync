extends Control


const TOTAL_TIME := 10
const MAX_SKEW := 18

onready var tween = $Tween
onready var grid_material = $Grid.material
onready var circle = $Circle
onready var head = $CanvasLayer/Head

var grid_dir := 1

signal head_moved


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


func _on_Tween_tween_completed(object, _key):
	if object == grid_material:
		grid_tween()
	if object == head:
		emit_signal("head_moved")


func circle_visibile(vis:=true, time=0.75) -> void:
	tween.interpolate_property(circle, "modulate:a", null, int(vis), time, Tween.TRANS_BOUNCE, Tween.EASE_IN_OUT)
	tween.start()


func move_head(pos:Vector2, start_pos=null, time=0.75) -> void:
	tween.interpolate_property(head, "rect_global_position", start_pos, pos, time, Tween.TRANS_SINE, Tween.EASE_IN_OUT)
	tween.start()




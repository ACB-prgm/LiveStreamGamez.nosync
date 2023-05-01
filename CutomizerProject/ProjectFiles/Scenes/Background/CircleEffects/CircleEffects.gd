extends Control


const TOTAL_TIME := 10
const MAX_SCALE := 1.5
const BAR_DIST := 250

onready var tween = $Tween
onready var white_lines_material = $WhiteLinesTop.material
onready var bottom_colors_material = $BotomColorsAndTopWhite.material
onready var bar = $Bar


var w_lines_dir: = -1
var bar_dir: = 1


func _ready():
	bar.rect_position.x = BAR_DIST
	w_lines_tween()
	bar_tween()


func _process(_delta):
	var dist = abs(bar.rect_position.x) / BAR_DIST
	dist = max(dist, .4)
	bar.rect_scale.x = lerp(1, 0.7, dist)
	


func w_lines_tween() -> void:
	w_lines_dir *= -1
	var time = TOTAL_TIME / 2.0
	
	tween.interpolate_property(white_lines_material, "shader_param/scale", 
	null, Vector2(max(1.0, MAX_SCALE * w_lines_dir), 1.0), 
	time, Tween.TRANS_SINE, Tween.EASE_IN_OUT)
	
	tween.start()


func bar_tween() -> void:
	bar_dir *= -1
	var time = TOTAL_TIME / 9.0
	
	tween.interpolate_property(bar, "rect_position:x", null, BAR_DIST * bar_dir, 
	time, Tween.TRANS_SINE, Tween.EASE_IN_OUT)
	tween.start()
	
	bottom_colors_material.set("shader_param/scale", Vector2(bar_dir, 1))


func _on_Tween_tween_completed(object, _key):
	if object == white_lines_material:
		w_lines_tween()
	if object == bar:
		bar_tween()
	

extends Control


const TOTAL_TIME := 10
const MAX_SCALE := 1.5
const BAR_DIST := 250
const EYE_RADIUS := 7
const CENTER := Vector2(1920/2, 1080/2)

onready var tween = $Tween
onready var head_material = $Control/Head.material
onready var white_lines_material = $WhiteLinesTop.material
onready var bottom_colors_material = $BotomColorsAndTopWhite.material
onready var bar = $Bar
onready var button = $Button
onready var eyes = [
	[$Control/EyeLeft, $Control/EyeLeft.rect_global_position, Vector2(-50,0) + $Control/EyeLeft.rect_size / 2.0], 
	[$Control/EyeRight, $Control/EyeRight.rect_global_position, Vector2(50,0)  + $Control/EyeRight.rect_size / 2.0]
]

var w_lines_dir: = -1
var bar_dir: = 1


func _ready():
	tween.interpolate_property(self, "modulate:a", 0, 1, 1, Tween.TRANS_BOUNCE, Tween.EASE_IN_OUT)
	tween.start()
	bar.rect_position.x = BAR_DIST
	w_lines_tween()
	bar_tween()


func _process(_delta):
	var dist = abs(bar.rect_position.x) / BAR_DIST
	dist = max(dist, .4)
	bar.rect_scale.x = lerp(1, 0.7, dist)
	
	for eye in eyes:
		look_at_mouse(eye[0], eye[1], eye[2])
#
	var dir = get_global_mouse_position().direction_to(CENTER) * 10
	
	
	head_material.set("shader_param/y_rot", lerp(head_material.get("shader_param/y_rot"), dir.x * -1, 0.2))
	head_material.set("shader_param/x_rot", lerp(head_material.get("shader_param/x_rot"), dir.y, 0.2))


func look_at_mouse(obj:Control, start_pos:Vector2, offset:Vector2) -> void:
	var dir = (start_pos + offset).direction_to(get_global_mouse_position())
	
	obj.rect_global_position = lerp(obj.rect_global_position, start_pos + EYE_RADIUS * dir, .1)


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


func _on_Button_pressed():
	GoogleSignIn.authorize()

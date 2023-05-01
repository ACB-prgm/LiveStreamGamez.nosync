extends Control


const EYE_RADIUS := 6.5

var CENTER
onready var eyes := [
	[$EyeLeft, $EyeLeft.rect_position, Vector2.LEFT * 50], 
	[$EyeRight, $EyeRight.rect_position, Vector2.RIGHT * 50]
]

onready var head_material = $Head.material


func _ready():
	set_process(false)
	yield(get_tree().create_timer(0.1), "timeout")
	
	CENTER = rect_global_position - rect_size / 2
	set_process(true)


func _process(_delta):
	for eye in eyes:
		look_at_mouse(eye[0], eye[1], eye[2])
	
	var dir = get_global_mouse_position().direction_to(CENTER) * 10
	head_material.set("shader_param/y_rot", lerp(head_material.get("shader_param/y_rot"), dir.x * -1, 0.1))
	head_material.set("shader_param/x_rot", lerp(head_material.get("shader_param/x_rot"), dir.y, 0.1))
	
	CENTER = rect_global_position - rect_size / 2



func look_at_mouse(obj:Control, start_pos:Vector2, offset:Vector2) -> void:
	var dir = (CENTER + offset).direction_to(get_global_mouse_position())
	
	obj.rect_position = lerp(obj.rect_position, start_pos + EYE_RADIUS * dir, .1)

extends PanelContainer


onready var tween = $Tween
onready var nameLabel = $VBoxContainer/Identifier/Label
onready var icon = $VBoxContainer/Identifier/TextureRect
onready var xp_bar = $VBoxContainer/XP/ProgressBar
onready var commentLabel = $VBoxContainer/CommentLabel


func _ready():
	give_xp(80)


func _on_Tween_tween_completed(object, key):
	yield(get_tree().create_timer(1), "timeout")
	xp_bar.value = 0
	yield(get_tree().create_timer(1), "timeout")
	give_xp(80)


#func _physics_process(delta):
#	var xp_pos = xp_bar.rect_global_position + Vector2(0, xp_bar.rect_size.y/2)
#	var offset = xp_bar.rect_size.x * xp_bar.value/100.0 + 3
#	particles.global_position = xp_pos + Vector2(offset, 0)


func give_xp(xp):
	tween.interpolate_property(xp_bar, "value", xp_bar.value, xp, 1, 
	Tween.TRANS_CIRC, Tween.EASE_OUT)
	tween.start()

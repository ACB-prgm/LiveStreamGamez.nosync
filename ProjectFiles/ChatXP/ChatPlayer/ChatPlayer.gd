extends PanelContainer


onready var tween = $Tween
onready var nameLabel = $VBoxContainer/Identifier/Label
onready var icon = $VBoxContainer/Identifier/TextureRect
onready var xp_bar = $VBoxContainer/XP/ProgressBar
onready var commentLabel = $VBoxContainer/CommentLabel
onready var glow_bar = $VBoxContainer/XP/ProgressBar/ColorRect


func _ready():
	set_physics_process(false)
	glow_bar.modulate.a = 0
	give_xp(20)


func _on_Tween_tween_completed(object, _key):
	if object == xp_bar:
		yield(get_tree().create_timer(1), "timeout")
		xp_bar.value = 0
		yield(get_tree().create_timer(1), "timeout")
		give_xp(20)


func _physics_process(_delta):
	var xp_pos = xp_bar.rect_global_position
	var offset = xp_bar.rect_size.x * xp_bar.value/100.0 - glow_bar.rect_size.x/4
	glow_bar.rect_global_position = xp_pos + Vector2(offset, 0)


func give_xp(xp):
	set_physics_process(true)
	tween.interpolate_property(xp_bar, "value", xp_bar.value, xp, 1, 
	Tween.TRANS_CIRC, Tween.EASE_OUT)
	tween.start()
	glow_bar.modulate.a = 2
	
	yield(tween, "tween_completed")
	set_physics_process(false)
	tween.interpolate_property(glow_bar, "modulate:a", glow_bar.modulate.a, 0, .5, 
	Tween.TRANS_CIRC, Tween.EASE_OUT)
	tween.start()

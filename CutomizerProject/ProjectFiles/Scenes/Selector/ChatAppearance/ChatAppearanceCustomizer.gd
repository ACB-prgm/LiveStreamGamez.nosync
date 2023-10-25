extends Control


onready var tween = $Tween
onready var timer = $Timer

signal change_tab(from_obj, to_tab)
signal info_received(info)

var info_to_push : Dictionary


func _ready():
	push_warning("MAKE SURE AND REMOVE THIS SO HEAD NO MOVE")
#	show_tab()


func show_tab():
	Background.move_head(Vector2(1450, 150))
	Background.circle_visibile(false)
	
	yield(Background, "head_moved")


func _on_BackButton_pressed():
	emit_signal("change_tab", self, 1)
	

func _on_Selector_info_received(info):
	emit_signal("info_received", info)


# UPDATE PLAYER INFO ON FLASK
func _on_player_info_updated(info):
	info_to_push = info
	timer.start()


func _on_Timer_timeout():
	push_warning("update user here")
#	FlaskApi.update_user_info(info_to_push)

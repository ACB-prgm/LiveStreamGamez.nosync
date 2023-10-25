extends Control


onready var tab_parent = get_parent()
onready var tween = $Tween
onready var player_info_label = $CustomizationMenu/PlayerInfo

var player_info : Dictionary
var chat_appr_TSCN = preload("res://Scenes/Selector/ChatAppearance/ChatAppearanceCustomizer.tscn")

signal change_tab(from_obj, to_tab)
signal info_received(info)


func show_tab() -> void:
	Background.move_head(Vector2(1750, 150))
	Background.circle_visibile(true)
	
	push_warning("set player info here")
	player_info = {} #yield(FlaskApi.get_user_info(), "completed")
	emit_signal("info_received", player_info)
	
	var progression = player_info.get("progression")
	player_info_label.set_text("%s | Level: %s" % [GoogleSignIn.display_name, progression.get("level")])
	
	yield(Background, "head_moved")


func _on_SignoutButton_pressed():
	emit_signal("change_tab", self, 0)


func _on_ChatApprButton_pressed():
	emit_signal("change_tab", self, 2)



#var default_player_info = {
#	"progression" : {
#		"level": 1,
#		"level_xp" : 0,
#		"last_stream" : "",
#		"total_num_comments" : 0, # num lifetime comments
#		"current_num_comments" : 0 # num comments on current stream
#	},
#	"appearance" : {
#		"icon" : null
#	}
#}

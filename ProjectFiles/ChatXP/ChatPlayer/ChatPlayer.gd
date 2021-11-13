extends PanelContainer


onready var tween = $Tween
onready var nameLabel = $VBoxContainer/Identifier/Label
onready var icon = $VBoxContainer/Identifier/Icon
onready var levelLabel = $VBoxContainer/Identifier/LevelLabel
onready var xp_bar = $VBoxContainer/Identifier/ProgressBar
onready var commentLabel = $VBoxContainer/CommentLabel
onready var glow_bar = $VBoxContainer/Identifier/ProgressBar/ColorRect

var player_info = {
	"user" : "Default",
	"icon" : null,
	"xp" : 0,
	"last_stream" : "",
	"num_comments" : 0
}
var XP_to_give := 0
var comment := "Subscribe to ACB_Gamez"

signal player_fading


func _ready():
	nameLabel.text = player_info["user"]
	commentLabel.text = comment
	
	if player_info["icon"]:
		icon.texture = player_info["icon"]
	
	var player_xp = player_info["xp"] - XP_to_give
	var player_level = int(player_xp / 300)
	player_level = clamp(player_level, 1, 50)
	levelLabel.text = "Lv " + str(player_level)
	
	give_xp(player_xp, player_level, XP_to_give)
	
	set_physics_process(false)
	glow_bar.modulate.a = 0
	
	# transition in tween
	modulate.a = 0
#	yield(get_tree().create_timer(0.1), "timeout")
	tween.interpolate_property(self, "rect_position", 
	rect_position + Vector2(rect_size.x * 1.5, 0), rect_position, .5, 
	Tween.TRANS_CIRC, Tween.EASE_OUT)
	tween.interpolate_property(self, "modulate:a", 0, 1, .25, 
	Tween.TRANS_CIRC, Tween.EASE_OUT)
	tween.start()


func _physics_process(_delta):
	var xp_pos = xp_bar.rect_global_position
	var offset = xp_bar.rect_size.x * xp_bar.value/100.0 - glow_bar.rect_size.x/4
	glow_bar.rect_global_position = xp_pos + Vector2(offset, 0)


func give_xp(player_xp, player_level, xp):
	var level_xp = TaskManagerGlobals.LEVEL_INFO.get(clamp(player_level + 1, 1, 50)) - TaskManagerGlobals.LEVEL_INFO.get(player_level)
	var current_lv_xp = TaskManagerGlobals.LEVEL_INFO.get(player_level) - player_xp
	
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


func _on_Timer_timeout():
	tween.interpolate_property(self, "modulate:a", self.modulate.a, 0, 1, 
	Tween.TRANS_SINE, Tween.EASE_IN_OUT)
	tween.start()
	yield(tween, "tween_all_completed")
	emit_signal("player_fading")
	queue_free()

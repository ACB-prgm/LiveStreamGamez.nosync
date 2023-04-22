extends PanelContainer


onready var tween = $Tween
onready var nameLabel = $VBoxContainer/Identifier/Label
onready var icon = $VBoxContainer/Identifier/Icon
onready var levelLabel = $VBoxContainer/Identifier/LevelLabel
onready var xp_bar = $VBoxContainer/Identifier/ProgressBar
onready var commentLabel = $VBoxContainer/CommentLabel
onready var timer = $Timer

var level_particles_TSCN = preload("res://ChatXP/LevelUpParticles2D.tscn")
var anim_info = {}

signal player_fading


func _ready():
	randomize()
	nameLabel.text = anim_info.get("user")
	commentLabel.text = anim_info.get("comment")
	levelLabel.text = "Lv " + str(anim_info.get("level"))
	
	if anim_info.get("icon"):
		icon.texture = anim_info.get("icon")
	
	set_physics_process(false)
	transition_in()
	
	xp_bar.value = anim_info.get("bar_start_val")
	yield(tween, "tween_all_completed")
	give_xp()


func transition_in() -> void:
	modulate.a = 0
	tween.interpolate_property(self, "rect_position", 
	rect_position + Vector2(rect_size.x * 1.5, 0), rect_position, .5, 
	Tween.TRANS_CIRC, Tween.EASE_OUT)
	tween.interpolate_property(self, "modulate:a", 0, 1, .25, 
	Tween.TRANS_CIRC, Tween.EASE_OUT)
	tween.start()


func give_xp():
	if anim_info.get("level_up"):
		tween.interpolate_property(xp_bar, "value", null, 100, 
		.6, Tween.TRANS_CIRC, Tween.EASE_OUT)
		tween.start()
		yield(tween, "tween_all_completed")
		xp_bar.value = 0
		spawn_lvl_particles()
		anim_info["level"] += 1
		levelLabel.text = "lv" + str(anim_info.get("level"))
	
	var xp_gain = anim_info.get("xp_gain") / TaskManagerGlobals.LEVEL_INFO.get(anim_info.get("level")) * 100
	
	tween.interpolate_property(xp_bar, "value", null, xp_bar.value + xp_gain, 
	1, Tween.TRANS_CIRC, Tween.EASE_OUT)
	tween.start()
	
	yield(tween, "tween_all_completed")
	timer.start()
	
	

func spawn_lvl_particles():
	for _i in range(3):
		var particles_INS = level_particles_TSCN.instance()
		levelLabel.add_child(particles_INS)
		particles_INS.global_position += levelLabel.rect_size * rand_range(-.25, 1)
		var rand = rand_range(.25, 1)
		particles_INS.scale = Vector2(rand, rand)
		yield(get_tree().create_timer(0.2), "timeout")


func _on_Timer_timeout():
	tween.interpolate_property(self, "modulate:a", self.modulate.a, 0, 1, 
	Tween.TRANS_SINE, Tween.EASE_IN_OUT)
	tween.start()
	yield(tween, "tween_all_completed")
	emit_signal("player_fading")
	queue_free()

extends PanelContainer


onready var nameLabel = $VBoxContainer/Identifier/Label
onready var icon = $VBoxContainer/Identifier/Icon
onready var levelLabel = $VBoxContainer/Identifier/LevelLabel
onready var xp_bar = $VBoxContainer/Identifier/ProgressBar
onready var commentLabel = $VBoxContainer/CommentLabel

#var level_particles_TSCN = preload("res://ChatXP/LevelUpParticles2D.tscn")
var anim_info = {}

signal player_fading


func _ready():
	pass

extends PanelContainer


onready var nameLabel = $PanelContainer/VBoxContainer/Identifier/Label
onready var icon = $PanelContainer/VBoxContainer/Identifier/Icon
onready var levelLabel = $PanelContainer/VBoxContainer/Identifier/LevelLabel
onready var xp_bar = $PanelContainer/VBoxContainer/Identifier/ProgressBar
onready var commentLabel = $PanelContainer/VBoxContainer/CommentLabel

var player_info : Dictionary


func populate_player_info() -> void:
	var appearance = player_info.get("appearance")
	var progression = player_info.get("progression")
	
	if not (appearance or progression):
		return
	
	if appearance["icon"]:
		icon.set_texture(appearance["icon"])
	
	levelLabel.set_text("LV %s" % progression["level"])
	nameLabel.set_text(GoogleSignIn.display_name)
	
	xp_bar.set_value(progression["xpbar_value"])


func _on_info_received(info):
	player_info = info
	populate_player_info()

extends PanelContainer


onready var bg_panel = $PanelContainer.get("custom_styles/panel")
onready var nameLabel = $PanelContainer/VBoxContainer/Identifier/Label
onready var icon = $PanelContainer/VBoxContainer/Identifier/Icon
onready var levelLabel = $PanelContainer/VBoxContainer/Identifier/LevelLabel
onready var vsep = $PanelContainer/VBoxContainer/Identifier/VSeparator
onready var xp_bar = $PanelContainer/VBoxContainer/Identifier/ProgressBar
onready var commentLabel = $PanelContainer/VBoxContainer/CommentLabel

var player_info : Dictionary


func populate_player_info() -> void:
	var appearance = player_info.get("appearance")
	var progression = player_info.get("progression")
	
	if not (appearance or progression):
		return
	
	if appearance.get("icon"):
		icon.set_texture(image_data_to_texture(appearance.get("icon")))
	if appearance.get("info_color"):
		var color = Color(appearance.get("info_color"))
		nameLabel.modulate = color
		levelLabel.modulate = color
		vsep.modulate = color
	if appearance.get("xp_bar_color"):
		var color = Color(appearance.get("xp_bar_color"))
		xp_bar.get("custom_styles/fg").bg_color = color
	if appearance.get("bg"):
		if appearance["bg"].get("outline"):
			var color = Color(appearance["bg"].get("outline"))
			bg_panel.border_color = color
			
		
	
	levelLabel.set_text("LV %s" % progression["level"])
	nameLabel.set_text(GoogleSignIn.display_name)
	
	xp_bar.set_value(progression["xpbar_value"])



func image_data_to_texture(data:Dictionary) -> ImageTexture:
	var texture = ImageTexture.new()
	var image = Image.new()
	image.data = data
	texture.create_from_image(image)
	
	return texture


func _on_info_received(info):
	player_info = info
	populate_player_info()

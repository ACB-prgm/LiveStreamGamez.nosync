extends Button


onready var texture_rect = $HBoxContainer/TextureRect
onready var name_label = $HBoxContainer/NameLabel
onready var level_label = $HBoxContainer/LevelLabel
onready var hbox = $HBoxContainer

var _icon
var _level : int



func populate_info(texture, _name, level) -> void:
	_icon = texture
	_level = level
	
	texture_rect.set_texture(texture)
	name_label.set_text(_name)
	level_label.set_text("LV %s" % level)


func _on_other_pressed(button) -> void:
	if button != self:
		set_pressed(false)


func set_disabled(val:bool) -> void:
	disabled = val
	if disabled:
		hbox.modulate.a = 0.5
	else:
		hbox.modulate.a = 1.0

extends Button


onready var texture_rect = $HBoxContainer/TextureRect
onready var label = $HBoxContainer/Label

var _icon



func populate_info(texture, _name, level) -> void:
	_icon = texture
	texture_rect.set_texture(texture)
	label.set_text("%s | LV %s" % [_name, level])


func _on_other_pressed(button) -> void:
	if button != self:
		set_pressed(false)

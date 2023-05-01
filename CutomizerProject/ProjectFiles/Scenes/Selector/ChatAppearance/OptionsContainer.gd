extends VBoxContainer


onready var options = get_children()

signal option_selected(option)


func _ready():
	for button in options:
		button.connect("toggled", self, "_on_option_selected", [button])
	
	options[0].set_pressed(true)


func _on_option_selected(toggled, option):
	if toggled:
		emit_signal("option_selected", options.find(option))
		
		for button in options:
			if button != option:
				button.set_pressed(false)

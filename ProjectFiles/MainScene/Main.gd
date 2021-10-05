extends Control


onready var chaptersButton = $ChaptersButton


func _ready():
	chaptersButton.modulate.a = 0.1
	get_tree().root.set_transparent_background(true)




 #### CHAPTERS SELECT ####
func _on_ChaptersButton_mouse_entered():
	chaptersButton.modulate.a = 1.0

func _on_ChaptersButton_mouse_exited():
	chaptersButton.modulate.a = 0.1

func _on_ChaptersButton_pressed():
	$ChaptersSelectPopup.popup()

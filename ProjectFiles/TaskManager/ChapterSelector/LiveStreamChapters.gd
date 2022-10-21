extends Popup


const SAVE_DIR := 'user://LiveStreamChapters/'

var button_TSCN = preload("res://TaskManager/ChapterSelector/FileButton.tscn")
var stream_files : Array

onready var filesContainer = $Panel/HBoxContainer/ScrollContainer/FilesContainer
onready var chaptersDisplay = $Panel/HBoxContainer/ChaptersDisplayTextedit
onready var confirmDeleteDialogue = $ConfirmationDialog


func _ready():
	confirmDeleteDialogue.connect("confirmed", self, "_on_confirm_delete")
	confirmDeleteDialogue.get_cancel().connect("pressed", self, "_on_confirm_delete_cancelled")


func _on_Popup_about_to_show():
	refresh_display()


func _on_fileButton_pressed(file_name):
	var chapters_text = ""
	
	if file_name:
		for file in filesContainer.get_children():
			if file.text != file_name:
				file.set_pressed(false)
		
		var path = SAVE_DIR + file_name
		for chapter in load_file(path):
			chapters_text += "%s %s\n" % [get_timestring_from_secs(chapter["start_time"]), chapter["name"]]
	
	chaptersDisplay.text = chapters_text


func _on_deleteButton_pressed(file_name):
	confirmDeleteDialogue.dialog_text = file_name
	confirmDeleteDialogue.popup()


func refresh_display():
	for child in filesContainer.get_children():
		child.queue_free()
	chaptersDisplay.text = ""
	
	stream_files = get_files_in_directory(SAVE_DIR)
	
	for file in stream_files:
		var button_INS = button_TSCN.instance()
		button_INS.text = file
		button_INS.connect("fileButton_pressed", self, "_on_fileButton_pressed")
		button_INS.connect("deleteButton_pressed", self, "_on_deleteButton_pressed")
		filesContainer.add_child(button_INS)
	
	while !visible:
		yield(get_tree().create_timer(0.01), "timeout")
	
	if filesContainer.get_children():
		filesContainer.get_child(0).set_pressed(true)


func _on_confirm_delete_cancelled():
	pass

func _on_confirm_delete():
	var file_name = confirmDeleteDialogue.dialog_text
	var dir = Directory.new()
	dir.remove(SAVE_DIR + file_name)
	hide()
	popup()



func get_files_in_directory(path):
	var files = []
	var dir = Directory.new()
	dir.open(path)
	dir.list_dir_begin()

	while true:
		var file = dir.get_next()
		if file == "":
			break
		elif not file.begins_with("."):
			files.append(file)

	dir.list_dir_end()

	return files


func load_file(save_path):
	var data = null
	var file = File.new()
	if file.file_exists(save_path):
		var error = file.open(save_path, File.READ)
		if error == OK:
			data = file.get_var()
			file.close()
		else:
			print("ERROR LOADING FILE : %s" % error)
	return data


func get_timestring_from_secs(seconds):
	var secs = str(seconds % 60).pad_zeros(2)
	var mins = str(seconds / 60 % 60).pad_zeros(2)
	var hrs = str(seconds / 3600).pad_zeros(2)
	
	return "%s:%s:%s" % [hrs, mins, secs]

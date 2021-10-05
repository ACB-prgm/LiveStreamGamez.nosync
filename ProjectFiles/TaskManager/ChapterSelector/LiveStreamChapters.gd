extends Popup


const SAVE_DIR := 'user://LiveStreamChapters/'

var outlineStylebox = preload("res://TaskManager/OutlineOnlyStylebox.tres")
var button_TSCN = preload("res://TaskManager/ChapterSelector/Button.tscn")
var stream_files : Array

onready var filesContainer = $Panel/HBoxContainer/ScrollContainer/FilesContainer
onready var chaptersDisplay = $Panel/HBoxContainer/ChaptersDisplayTextedit


func _on_Popup_about_to_show():
	stream_files = get_files_in_directory(SAVE_DIR)
	
	for child in filesContainer.get_children():
		child.queue_free()
	
	for file in stream_files:
		var button_INS = button_TSCN.instance()
		button_INS.text = file
		button_INS.connect("fileButton_pressed", self, "_on_fileButton_pressed")
		filesContainer.add_child(button_INS)
	print(filesContainer.get_children())
	filesContainer.get_child(0).set_pressed(true)
#	_on_fileButton_pressed(stream_files[0])


func _on_fileButton_pressed(file_name):
	var chapters_text = ""
	
	if file_name:
		var path = SAVE_DIR + file_name
		for chapter in load_file(path):
			chapters_text += "%s %s\n" % [get_timestring_from_secs(chapter["start_time"]), chapter["name"]]
	
	chaptersDisplay.text = chapters_text


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

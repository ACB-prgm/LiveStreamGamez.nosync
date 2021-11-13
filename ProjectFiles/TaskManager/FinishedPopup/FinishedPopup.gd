extends Popup


var title := ""

onready var hourInput = $Panel/StreamDuration/HBoxContainer/HourInput
onready var minInput = $Panel/StreamDuration/HBoxContainer/MinutesInput
onready var secInput = $Panel/StreamDuration/HBoxContainer/SecondsInput
onready var streamNameLineEdit = $Panel/StreamName/StreamNameLineEdit

signal set_final_duration(title)


func _on_EnterButton_pressed():
		title = streamNameLineEdit.text
		
		emit_signal("set_final_duration", title)
		hide()


func _on_Popup_about_to_show():
	var date = OS.get_datetime()
	date = "%s_%s_%s" % [date["day"], date["month"], date["year"]]
	
	if YoutTubeApi.LiveBroadcastResource:
		title = YoutTubeApi.LiveBroadcastResource.get("snippet").get("title")
		title = title.replace(" ", "_")
		title += "_" + date
	else:
		title = date
	
	streamNameLineEdit.text = title

extends Popup


var title := ""

onready var hourInput = $Panel/StreamDuration/HBoxContainer/HourInput
onready var minInput = $Panel/StreamDuration/HBoxContainer/MinutesInput
onready var secInput = $Panel/StreamDuration/HBoxContainer/SecondsInput
onready var streamNameLineEdit = $Panel/StreamName/StreamNameLineEdit

signal set_final_duration(final_duration, title)


func _on_EnterButton_pressed():
	var hrs = hourInput.text
	var mins = minInput.text
	var secs = secInput.text
	
	if hrs and mins and secs:
		emit_signal("set_final_duration", [int(hrs), int(mins), int(secs)], title)
		hide()


func _on_Popup_about_to_show():
	var date = OS.get_datetime()
	date = "%s_%s_%s" % [date["day"], date["month"], date["year"]]
	
	if YoutTubeApi.LiveBroadcastResource:
		title = YoutTubeApi.LiveBroadcastResource.get("snippet").get("title")
		title = title.replace(" ", "_")
		title += " " + date
	else:
		title = date
	
	streamNameLineEdit.text = title

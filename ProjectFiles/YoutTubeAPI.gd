extends Node


var LiveChatID : String
var nextPageToken : String
var timer := Timer.new()


func _ready():
	add_child(timer)
	timer.set_wait_time(2.0)
	timer.set_one_shot(true)
	
	OS.delay_msec(100)
	get_LiveChatID()


func get_LiveChatID():
	var http_request = HTTPRequest.new()
	add_child(http_request)
	http_request.connect("request_completed", self, "_on_http_request_get_LiveChatID", [http_request])
	
	var request_url := "https://youtube.googleapis.com/youtube/v3/liveBroadcasts?part=snippet&broadcastStatus=active"
	var headers := [
		"Authorization: Bearer %s" % OAuth2.token,
		"Accept: application/json"
	]
	
	var error = http_request.request(request_url, PoolStringArray(headers))
	if error != OK:
		push_error("ERROR OCCURED @ FUNC get_LiveChatID() : %s" % error)
		http_request.queue_free()

func _on_http_request_get_LiveChatID(_result, _response_code, _headers, body, HTTP_node):
	HTTP_node.queue_free()
	
	var json_result = JSON.parse(body.get_string_from_utf8())
	if json_result.error != OK or not json_result.result is Dictionary:
		push_error("Unable to parse JSON from server : %s" % json_result.error)
		return
	
	var data = json_result.result
	LiveChatID = data.get("items")[0].get("snippet").get("liveChatId")
	
	get_LiveChat_messages()


func get_LiveChat_messages():
	var http_request = HTTPRequest.new()
	add_child(http_request)
	http_request.connect("request_completed", self, "_on_get_LiveChat_messages", [http_request])
	
	var request_url = "https://youtube.googleapis.com/youtube/v3/liveChat/messages?liveChatId=%s" % LiveChatID + "&part=snippet%2CauthorDetails&maxResults=10"
	if nextPageToken:
		request_url += "&pageToken=%s" % nextPageToken

	var headers := [
		"Authorization: Bearer %s" % OAuth2.token,
		"Accept: application/json"
	]
	
	var error = http_request.request(request_url, PoolStringArray(headers))
	if error != OK:
		push_error("ERROR OCCURED @ FUNC get_LiveChat_messages() : %s" % error)
		http_request.queue_free()

func _on_get_LiveChat_messages(_result, _response_code, _headers, body, HTTP_node):
	print("LiveChat Messages Recieved")
	HTTP_node.queue_free()
	
	var json_result = JSON.parse(body.get_string_from_utf8())
	if json_result.error != OK or not json_result.result is Dictionary:
		push_error("Unable to parse JSON from server : %s" % json_result.error)
		return
	
	var data = json_result.result
	nextPageToken = data.get("nextPageToken")
	
	# GET THE CHAT MESSAGES AS A LIST OF LISTS EHHH!?
	data = data.get("items")
	var messages := []
	for datum in data:
		messages.append([datum.get("authorDetails").get("displayName"), datum.get("snippet").get("displayMessage")])
	print(messages)
	
	timer.start()
	yield(timer, "timeout")
	get_LiveChat_messages()









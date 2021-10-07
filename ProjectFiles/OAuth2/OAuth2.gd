extends Node


const token_json_path = "res://OAuth2/token_info.json"

var token : String

onready var global_dir_path = ProjectSettings.globalize_path("res://OAuth2")
onready var interpreter_path = ProjectSettings.globalize_path("res://venv/bin/python")

signal token_recieved


func authorize():
	var ERR = OS.execute(interpreter_path, [global_dir_path + "/get_credentials.py"], true)
	if ERR == OK:
		get_token_from_JSON()
	else:
		push_error("ERROR EXECUTING 'get_credentials.py' WITH ERROR CODE: %s"%ERR)


func get_token_from_JSON():
	var file = File.new()
	if file.file_exists(token_json_path):
		var ERR = file.open(token_json_path, file.READ)
		if ERR == OK:
			var text = file.get_as_text()
			token = parse_json(text)["TOKEN"]
			emit_signal("token_recieved")
		else:
			push_error("ERROR LOADING 'token_info.json' WITH ERROR CODE: %s"%ERR)
		file.close()


































#const PORT = 31419
#const auth_server := "https://accounts.google.com/o/oauth2/v2/auth"
#const token_req := "https://oauth2.googleapis.com/token"
#
#var redirect_uri = "http://127.0.0.1:%s" % PORT
#
#func _ready():
#	get_auth_code()
#
#
#func get_auth_code():
#	var headers = [
#		"client_id = 694582530887-sipt32jliecakrvo41l9b9g8ujfedk53.apps.googleusercontent.com&",
#		"redirect_uri = %s&" % redirect_uri,
#		"response_type = code&",
#		"scope = https://www.googleapis.com/auth/youtube.readonly",
#	]
#
#	var url = auth_server + "?"
#	for x in headers:
#		x = x.replace(" ", "")
#		url += x
#
#	# Opens window for user authentication
## warning-ignore:return_value_discarded
#	OS.shell_open(url)
#
#	# Creates the Loopback IP redirect server
#	prints("python HTTP Server Return Value: ", OS.execute("python", ["-m", "http.server", "--cgi" ,str(PORT)]))
#
#	var http_ = HTTPRequest.new()
#	http_.connect("request_completed", self, "_on_auth_req_completed", [http_])
#	add_child(http_)
#
#	var err = http_.request(redirect_uri + "/OAuth2.0/code.txt")
#	if err != OK:
#		print(err)
#
#var attempts := 0
#var defualt = null
#
#func _on_auth_req_completed(_result, _response_code, _headers, body:PoolByteArray, HTTP_Node:HTTPRequest):
#	HTTP_Node.queue_free()
#
#	if attempts == 0:
#		defualt = body
#		var text = body.get_string_from_utf8()
#		print(text)
#	elif defualt != body:
#		var text = body.get_string_from_utf8()
#		print(text)
#
#	attempts += 1
#	print("ATTEMPT: ",attempts)
#
#	OS.delay_msec(1000)
#
#	var http_ = HTTPRequest.new()
#	http_.set_timeout(10000)
#	http_.connect("request_completed", self, "_on_auth_req_completed", [http_])
#	add_child(http_)
#
#	var err = http_.request(redirect_uri + "/?code=")
#	if err != OK:
#		print(err)



#	var err := 0
#	var http := HTTPClient.new() # Create the Client.
#
#	err = http.connect_to_host("http://127.0.0.1", PORT) # Connect to host/port.
#	assert(err == OK) # Make sure connection is OK.
#
#	while http.get_status() == HTTPClient.STATUS_CONNECTING or http.get_status() == HTTPClient.STATUS_RESOLVING:
#		http.poll()
#		print("Connecting...")
#		if not OS.has_feature("web"):
#			OS.delay_msec(500)
#		else:
#			yield(Engine.get_main_loop(), "idle_frame")
#
#	assert(http.get_status() == HTTPClient.STATUS_CONNECTED)
#
#
#	err = http.request(HTTPClient.METHOD_GET, "http://127.0.0.1:%s" % PORT, ["Accept: application/json"]) # Request a page from the site (this one was chunked..)
#	assert(err == OK) # Make sure all is OK.
#
#	while http.get_status() == HTTPClient.STATUS_REQUESTING:
#		# Keep polling for as long as the request is being processed.
#		http.poll()
#		print("Requesting...")
#		if OS.has_feature("web"):
#			# Synchronous HTTP requests are not supported on the web,
#			# so wait for the next main loop iteration.
#			yield(Engine.get_main_loop(), "idle_frame")
#		else:
#			OS.delay_msec(500)
#
#	assert(http.get_status() == HTTPClient.STATUS_BODY or http.get_status() == HTTPClient.STATUS_CONNECTED) # Make sure request finished well.
#
#	if http.has_response():
#		# If there is a response...
#
#		headers = http.get_response_headers_as_dictionary() # Get response headers.
#		print("code: ", http.get_response_code()) # Show response code.
#		print("**headers:\\n", headers) # Show headers.
#
#		# Getting the HTTP Body
#		if http.is_response_chunked():
#			# Does it use chunks?
#			print("Response is Chunked!")
#		else:
#			# Or just plain Content-Length
#			var bl = http.get_response_body_length()
#			print("Response Length: ", bl)
#
#		# This method works for both anyway
#		var rb = PoolByteArray() # Array that will hold the data.
#
#		while http.get_status() == HTTPClient.STATUS_BODY:
#			# While there is body left to be read
#			http.poll()
#			# Get a chunk.
#			var chunk = http.read_response_body_chunk()
#			if chunk.size() == 0:
#				if not OS.has_feature("web"):
#					# Got nothing, wait for buffers to fill a bit.
#					OS.delay_usec(1000)
#				else:
#					yield(Engine.get_main_loop(), "idle_frame")
#			else:
#				rb = rb + chunk # Append to read buffer.
#					# Done!
#
#			print("bytes got: ", rb.size())
#			var text = rb.get_string_from_ascii()
#			print("Text: ", text)






#func _on_request_completed(result, response_code, headers, body):
#	prints(result, response_code, headers, body)
#
#	var json_result = JSON.parse(body.get_string_from_utf8())
#	if json_result.error != OK or not json_result.result is Dictionary:
#		push_error("Unable to parse JSON from server : %s" % json_result.error)
#		return
#
#	var data: Dictionary = json_result.result
#	print(data)


# SAVE/LOAD
#const SAVE_DIR = 'user://credentials/'
#var save_path = SAVE_DIR + 'credentials.dat'
#
#func save_data():
#	var dir = Directory.new()
#	if !dir.dir_exists(SAVE_DIR):
#		dir.make_dir_recursive(SAVE_DIR)
#
#	var file = File.new()
#	var error = file.open(save_path, File.WRITE)
#	if error == OK:
#		var data = "hi"
#
#		file.store_var(data)
#		file.close()
#
#func load_data():
#	var file = File.new()
#	if file.file_exists(save_path):
#		var error = file.open_encrypted_with_pass(save_path, File.READ, 'abigail')
#		if error == OK:
#			var data = file.get_var()
#
#			high_score = data.get("high_score")
#			shoot_on_aim = data.get("shoot_on_aim")
#			layout_preset = data.get("layout_preset")
#
#			file.close()

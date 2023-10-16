extends Node


const CLIENT_SECRET_PATH = "res://Scenes/BackendScripts/client_secret.dat"
const AUTH_API = "https://opalescent-agate-lemon.glitch.me"
const AUTH_URI := "https://accounts.google.com/o/oauth2/v2/auth"
const TOKEN_URI := "https://oauth2.googleapis.com/token"
const YT_DATA_ENDPOINT = "https://www.googleapis.com/youtube/v3/channels"
const SAVE_DIR = 'user://token/'


var client_secrets : Dictionary
var save_path = SAVE_DIR + 'token.dat'
var token
var id_token
var display_name : String
var state_id : String
var poll_timer : Timer

signal token_recieved


# HIGH LEVEL FUNCTIONS —————————————————————————————————————————————————————————
func _ready():
	set_process(false)
	client_secrets = load_client_secrets()
	
	load_tokens()
	create_poll_timer()
	
	var http_request = HTTPRequest.new()
	add_child(http_request)
	var _error = http_request.request(AUTH_API)

func authorize(force_signin:=false) -> void:
	if force_signin:
		get_auth_code()
	else:
		if (id_token and display_name) and is_token_valid():
			yield(get_tree().create_timer(0.01), "timeout")
			emit_signal("token_recieved")
		else:
			get_auth_code()

# OAUTH2.0 FUNCTIONS ———————————————————————————————————————————————————————————
func get_auth_code():
	var http_request = HTTPRequest.new()
	add_child(http_request)
	var error = http_request.request(
		AUTH_API.plus_file("/auth/store"), 
		PoolStringArray(["Content-Type: application/json"]), 
		true, 
		HTTPClient.METHOD_PUT, 
		to_json(create_auth_api_data())
	)
	
	if error != OK:
		push_error("An error occurred in the HTTP request with ERR Code: %s" % error)
	
	var response = yield(http_request, "request_completed")
	if response[1] == 200:
		OS.shell_open(AUTH_API.plus_file("/auth/login/%s" % state_id)) # Opens window for user authentication
		yield(get_tree().create_timer(5), "timeout")
		poll_timer.start()
	else:
		print(response[3].get_string_from_utf8())


func _on_poll_timer_timeout():
	var http_request = HTTPRequest.new()
	add_child(http_request)
	var error = http_request.request(AUTH_API.plus_file("/auth/check/%s" % state_id))
	
	if error != OK:
		print(error)
	
	var response = yield(http_request, "request_completed")
	match response[1]:
		200:
			poll_timer.stop()
			var data = parse_json(response[3].get_string_from_utf8())
			token = data.get("access_token")
			id_token = get_id_token_from_JWT(data.get("id_token"))
			get_display_name()
			
		201:
			print(response[3].get_string_from_utf8())
		_:
			poll_timer.stop()
			print("AUTH POLLING ERROR")
			print(response[3].get_string_from_utf8())


func get_display_name():
	var headers = PoolStringArray([
		"Authorization: Bearer %s" % token,
		"Accept: application/json",
	])
	# Make YT Data API request
	var params : PoolStringArray = [
		"part=snippet",
		"mine=true",
	]
	var http_request = HTTPRequest.new()
	add_child(http_request)
	var error = http_request.request(YT_DATA_ENDPOINT + "?" + params.join("&"), 
		headers, true, HTTPClient.METHOD_GET)
	if error != OK:
		push_error("An error occurred in the HTTP request with ERR Code: %s" % error)
	
	var response = yield(http_request, "request_completed")
	print(response[3].get_string_from_utf8())
	var response_body = parse_json(response[3].get_string_from_utf8())


func is_token_valid() -> bool:
	if !token:
		yield(get_tree().create_timer(0.001), "timeout")
		return false
	
	var headers = [
		"Content-Type: application/x-www-form-urlencoded"
	]
	
	var body = "access_token=%s" % token
# warning-ignore:return_value_discarded
	var http_request = HTTPRequest.new()
	add_child(http_request)
	
	var error = http_request.request(TOKEN_URI + "info", headers, true, HTTPClient.METHOD_POST, body)
	if error != OK:
		push_error("An error occurred in the HTTP request with ERR Code: %s" % error)
	
	var response = yield(http_request, "request_completed")
	
	var expiration = parse_json(response[3].get_string_from_utf8()).get("expires_in")
	
	if expiration and int(expiration) > 0:
		print("token is valid")
		emit_signal("token_recieved")
		return true
	else:
		return false


# HELPER FUNCTIONS —————————————————————————————————————————————————————————————
func create_poll_timer() -> void:
	var timer := Timer.new()
	add_child(timer)
	timer.connect("timeout", self, "_on_poll_timer_timeout")
	
	self.poll_timer = timer

func create_state_id() -> String:
	var now_dict = Time.get_time_dict_from_system()
	return "%s%s%s%s" % [Time.get_ticks_usec(), now_dict.hour, now_dict.minute, now_dict.second]

func create_auth_api_data() -> Dictionary:
	state_id = create_state_id()
	
	return {
		"auth_uri" : AUTH_URI,
		"token_uri" : TOKEN_URI,
		"auth_params" : {
			"client_id" : client_secrets["client_id"],
			"state" : state_id,
			"response_type" : "code",
			"scope" : "https://www.googleapis.com/auth/youtube.readonly openid",
			"access_type" : "offline"
		},
		"token_params": {
			"client_id" : client_secrets["client_id"],
			"client_secret" : client_secrets["client_secret"],
			"state" : state_id,
		}
	}

func save_tokens():
	var dir = Directory.new()
	if !dir.dir_exists(SAVE_DIR):
		dir.make_dir_recursive(SAVE_DIR)
	
	var file = File.new()
	var error = file.open_encrypted_with_pass(save_path, File.WRITE, 'abigail')
	if error == OK:
		var tokens = {
			"token" : token,
			"id_token" : id_token,
			"display_name" : display_name
		}
		file.store_var(tokens)
		file.close()


func load_tokens():
	var file = File.new()
	if file.file_exists(save_path):
		var error = file.open_encrypted_with_pass(save_path, File.READ, 'abigail')
		if error == OK:
			var tokens = file.get_var()
			token = tokens.get("token")
			id_token = tokens.get("id_token")
			display_name = tokens.get("display_name", "")
			
			file.close()
			print("token loaded successfully")


func base64url_to_base64(input: String) -> String:
	var base64 = input.replace("-","+") # Replace '-' with '+'
	base64 = base64.replace("_","/") # Replace '_' with '/'
	var padding = (4 - base64.length() % 4) % 4 # Calculate padding
	base64 += "====".left(padding) # Add padding
	return base64


func get_id_token_from_JWT(JWT:String) -> String:
	var payload = JWT.split(".")[1]
	var json = Marshalls.base64_to_raw(base64url_to_base64(payload)).get_string_from_ascii()
	json = parse_json(json)

	return json.get("sub")


func load_client_secrets():
	var file = File.new()
	var ERR = file.open_encrypted_with_pass(CLIENT_SECRET_PATH, File.READ, "abigail")
	var content
	if ERR == OK:
		content = file.get_var()
		file.close()
		return content
	else:
		push_error("File not loaded correctly")
		return null

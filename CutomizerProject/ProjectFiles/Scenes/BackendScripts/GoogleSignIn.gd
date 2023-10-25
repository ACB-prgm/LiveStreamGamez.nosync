extends Node


const CLIENT_SECRET_PATH = "res://Scenes/BackendScripts/client_secret.dat"
const AUTH_API = "https://opalescent-agate-lemon.glitch.me"
const AUTH_URI := "https://accounts.google.com/o/oauth2/v2/auth"
const TOKEN_URI := "https://oauth2.googleapis.com/token"
const YT_DATA_ENDPOINT = "https://www.googleapis.com/youtube/v3/channels"
const SAVE_DIR = 'user://token/'


var client_secrets : Dictionary
var save_path = SAVE_DIR + 'token.dat'
var token : String
var id_token : String
var refresh_token : String
var state_id : String
var poll_timer : Timer
var cred_expire_timer : Timer
var AWS_Creds := {}

signal sign_in_completed

# HIGH LEVEL FUNCTIONS —————————————————————————————————————————————————————————
func _ready():
	set_process(false)
	client_secrets = load_client_secrets()
	
	load_tokens()
	poll_timer = create_timer("_on_poll_timer_timeout")
	cred_expire_timer = create_timer("_on_AWS_expired")
	
	var http_request = HTTPRequest.new()
	add_child(http_request)
	var _error = http_request.request(AUTH_API)
	
	var _err = connect("sign_in_completed", PlayerInfoManager, "_on_sign_in_completed")


func authorize(force_signin:=false) -> void:
	if force_signin or !token:
		get_auth_code()
	elif yield(is_token_valid(), "completed") or yield(refresh_google_tokens(), "completed"):
		yield(get_aws_creds(), "completed")
	else:
		get_auth_code()
	
	PlayerInfoManager.player_info["google_sub"] = get_sub_from_JWT(id_token)
	yield(get_display_name(), "completed")
	emit_signal("sign_in_completed")

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
		var _err = OS.shell_open(AUTH_API.plus_file("/auth/login/%s" % state_id))
		yield(get_tree().create_timer(5), "timeout")
		poll_timer.start()
	else:
		print(response[3].get_string_from_utf8())


func _on_poll_timer_timeout():
	var http_request = HTTPRequest.new()
	add_child(http_request)
	var error = http_request.request(AUTH_API.plus_file("/auth/check/%s" % state_id))
	
	if error != OK:
		push_error(error)
	
	var response = yield(http_request, "request_completed")
	match response[1]:
		200:
			poll_timer.stop()
			var data = parse_json(response[3].get_string_from_utf8())
			token = data.get("access_token")
			id_token = data.get("id_token")
			refresh_token = data.get("refresh_token")
			save_tokens()
			get_display_name()
			yield(get_aws_creds(), "completed")
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
	if response[1] == 200:
		var response_body = parse_json(response[3].get_string_from_utf8())["items"][0]["snippet"]
		PlayerInfoManager.player_info["display_name"] = response_body["title"]
		PlayerInfoManager.player_info["thumbnail_id"] = get_thumbnail_id(response_body["thumbnails"])

func get_aws_creds():
	var http_request = HTTPRequest.new()
	add_child(http_request)
	var error = http_request.request(AUTH_API + "/get_temp_role/" + id_token)
	if error != OK:
		push_error("An error occurred in the HTTP request with ERR Code: %s" % error)
	
	var response = yield(http_request, "request_completed")
	if response[1] == 200:
		AWS_Creds = parse_json(response[3].get_string_from_utf8())
		cred_expire_timer.set_wait_time(AWS_Creds.get("LifetimeSeconds"))
		cred_expire_timer.start()
	else:
		push_error(response[3].get_string_from_utf8())

func _on_AWS_expired():
	yield(authorize(), "completed")

func is_token_valid():
	var token_info_url = "https://www.googleapis.com/oauth2/v3/tokeninfo?access_token=" + token
	var http_request = HTTPRequest.new()
	add_child(http_request)
	var error = http_request.request(token_info_url)
	if error != OK:
		push_error("An error occurred in the HTTP request with ERR Code: %s" % error)

	var response = yield(http_request, "request_completed")
	if response[1] == 200:
		return true
	else:
		return false


func refresh_google_tokens():
	print("refreshing")
	var token_endpoint = "https://oauth2.googleapis.com/token"
	var payload = {
		"refresh_token": refresh_token,
		"client_id": client_secrets["client_id"],
		"client_secret": client_secrets["client_secret"],
		"grant_type": "refresh_token"
	}
	
	var http_request = HTTPRequest.new()
	add_child(http_request)
	var error = http_request.request(
		token_endpoint,
		PoolStringArray(),
		true,
		HTTPClient.METHOD_POST,
		to_json(payload)
		)
	if error != OK:
		push_error("An error occurred in the HTTP request with ERR Code: %s" % error)
	var response = yield(http_request, "request_completed")
	if response[1] == 200:
		var data = parse_json(response[3].get_string_from_utf8())
		token = data.get("access_token")
		id_token = data.get("id_token")
		save_tokens()
		return true
	else:
		return false

# HELPER FUNCTIONS —————————————————————————————————————————————————————————————
func create_timer(connect_func:String) -> Timer:
	var timer := Timer.new()
	add_child(timer)
	var _E =timer.connect("timeout", self, connect_func)
	
	return timer

func get_thumbnail_id(thumbs:Dictionary) -> String:
	return thumbs["default"]["url"].get_slice("/", 4).get_slice("=", 0)

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
			"access_type" : "offline",
			"prompt" : "consent"
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
			"refresh_token" : refresh_token
		}
		file.store_var(tokens)
		file.close()


func load_tokens():
	var file = File.new()
	if file.file_exists(save_path):
		var error = file.open_encrypted_with_pass(save_path, File.READ, 'abigail')
		if error == OK:
			var tokens = file.get_var()
			token = tokens.get("token", "")
			id_token = tokens.get("id_token", "")
			refresh_token = tokens.get("refresh_token", "")
			
			file.close()
			print("token loaded successfully")


func base64url_to_base64(input: String) -> String:
	var base64 = input.replace("-","+") # Replace '-' with '+'
	base64 = base64.replace("_","/") # Replace '_' with '/'
	var padding = (4 - base64.length() % 4) % 4 # Calculate padding
	base64 += "====".left(padding) # Add padding
	return base64


func get_sub_from_JWT(JWT:String) -> String:
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

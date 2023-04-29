extends Node


const PORT := 8000
const BINDING := "127.0.0.1"
const FLASK_URL := "http://lsg-flask-api-env.eba-6hk8kiiv.us-east-1.elasticbeanstalk.com"
const CLIENT_SECRET_PATH = "res://Scenes/BackendScripts/client_secret.dat"
const AUTH_SERVER := "https://accounts.google.com/o/oauth2/v2/auth"
const TOKEN_REQ := "https://oauth2.googleapis.com/token"
const SAVE_DIR = 'user://token/'


var client_secrets : Dictionary
var redirect_server := TCP_Server.new()
var redirect_uri := "http://%s:%s" % [BINDING, PORT]
var save_path = SAVE_DIR + 'token.dat'
var token
var id_token
var display_name : String

signal token_recieved


# HIGH LEVEL FUNCTIONS —————————————————————————————————————————————————————————
func _ready():
	var _E = connect("token_recieved", self, "_on_token_recieved")
	set_process(false)
	client_secrets = load_client_secrets()


func authorize(force_signin:=false) -> void:
	if force_signin:
		get_auth_code()
	else:
		load_tokens()
		
		if !id_token:
			get_auth_code()


func _on_token_recieved():
	var endpoint = "/matchid/"
	var body = to_json({
		"token" : token,
		"id" : id_token
	})
	var headers = PoolStringArray([
		"Content-Type: application/json"
	])
	
	var http_request = HTTPRequest.new()
	add_child(http_request)
	var error = http_request.request(FLASK_URL.plus_file(endpoint), 
		headers, true, HTTPClient.METHOD_PUT, body)
	if error != OK:
		push_error("An error occurred in the HTTP request with ERR Code: %s" % error)
	
	var response = yield(http_request, "request_completed")
	
	var response_body = parse_json(response[3].get_string_from_utf8())
	
	display_name = response_body.get("display_name")
	save_tokens()


# OAUTH2.0 FUNCTIONS ———————————————————————————————————————————————————————————
func get_auth_code():
	set_process(true)
	var _redir_err = redirect_server.listen(PORT, BINDING)

	var body_parts = [
		"client_id=%s" % client_secrets.get("client_id"),
		"redirect_uri=%s" % redirect_uri,
		"response_type=code",
		"scope=https://www.googleapis.com/auth/youtube.readonly%20openid",
	]
	var url = AUTH_SERVER + "?" + PoolStringArray(body_parts).join("&")

# warning-ignore:return_value_discarded
	OS.shell_open(url) # Opens window for user authentication


func _process(_delta):
	if redirect_server.is_connection_available():
		var connection = redirect_server.take_connection()
		var request = connection.get_string(connection.get_available_bytes())
		if request:
			set_process(false)

			connection.put_data(("HTTP/1.1 %d\r\n" % 200).to_ascii())

			connection.put_data(""""<!DOCTYPE html>
								<html>
								<head>
								  <title>Hello</title>
								</head>
								<body>
								  <h1>Hello, World!</h1>
								</body>
								</html>""".to_ascii())
			redirect_server.stop()
			
			var auth_code = request.split("&scope")[0].split("=")[1]
			get_token_from_auth(auth_code)


func get_token_from_auth(auth_code):
	var headers = [
		"Content-Type: application/x-www-form-urlencoded"
	]
	headers = PoolStringArray(headers)

	var body_parts = [
		"code=%s" % auth_code, 
		"client_id=%s" % client_secrets.get("client_id"),
		"client_secret=%s" % client_secrets.get("client_secret"),
		"redirect_uri=%s" % redirect_uri,
		"grant_type=authorization_code"
	]

	var body = PoolStringArray(body_parts).join("&")

# warning-ignore:return_value_discarded
	var http_request = HTTPRequest.new()
	add_child(http_request)

	var error = http_request.request(TOKEN_REQ, headers, true, HTTPClient.METHOD_POST, body)
	if error != OK:
		push_error("An error occurred in the HTTP request with ERR Code: %s" % error)

	var response = yield(http_request, "request_completed")
	var response_body = parse_json(response[3].get_string_from_utf8())

	token = response_body["access_token"]
	id_token = get_id_token_from_JWT(response_body["id_token"])
	
	save_tokens()
	emit_signal("token_recieved")


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
	
	var error = http_request.request(TOKEN_REQ + "info", headers, true, HTTPClient.METHOD_POST, body)
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

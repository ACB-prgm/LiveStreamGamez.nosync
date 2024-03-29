extends Node


const PORT := 31419
const BINDING := "127.0.0.1"
const client_secret := "e346e1ul0W0mdqyPgIwBXeJy"
const client_ID := "694582530887-sipt32jliecakrvo41l9b9g8ujfedk53.apps.googleusercontent.com"
const AUTH_SERVER := "https://accounts.google.com/o/oauth2/v2/auth"
const TOKEN_REQ := "https://oauth2.googleapis.com/token"

var redirect_server := TCP_Server.new()
var redirect_uri := "http://%s:%s" % [BINDING, PORT]
var token
var refresh_token

signal token_recieved


func _ready():
	set_process(false)


func authorize():
	load_tokens()
	
	if !yield(is_token_valid(), "completed"):
		if !yield(refresh_tokens(), "completed"):
			get_auth_code()


func _process(_delta):
	if redirect_server.is_connection_available():
		var connection = redirect_server.take_connection()
		var request = connection.get_string(connection.get_available_bytes())
		if request:
			set_process(false)
			var auth_code = request.split("&scope")[0].split("=")[1]
			get_token_from_auth(auth_code)
			
			connection.put_data(("HTTP/1.1 %d\r\n" % 200).to_ascii())
			
			connection.put_data(load_HTML("user://display_page.html").to_ascii())
			redirect_server.stop()


func get_auth_code():
	set_process(true)
	var _redir_err = redirect_server.listen(PORT, BINDING)
	
	var body_parts = [
		"client_id=%s" % client_ID,
		"redirect_uri=%s" % redirect_uri,
		"response_type=code",
		"scope=https://www.googleapis.com/auth/youtube.readonly",
	]
	var url = AUTH_SERVER + "?" + PoolStringArray(body_parts).join("&")
	
# warning-ignore:return_value_discarded
	OS.shell_open(url) # Opens window for user authentication


func get_token_from_auth(auth_code):
	
	var headers = [
		"Content-Type: application/x-www-form-urlencoded"
	]
	headers = PoolStringArray(headers)
	
	var body_parts = [
		"code=%s" % auth_code, 
		"client_id=%s" % client_ID,
		"client_secret=%s" % client_secret,
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
	refresh_token = response_body["refresh_token"]
	
	save_tokens()
	emit_signal("token_recieved")


func refresh_tokens():
	print("refreshing")
	var headers = [
		"Content-Type: application/x-www-form-urlencoded"
	]
	
	var body_parts = [
		"client_id=%s" % client_ID,
		"client_secret=%s" % client_secret,
		"refresh_token=%s" % refresh_token,
		"grant_type=refresh_token"
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
	
	if response_body.get("access_token"):
		token = response_body["access_token"]
		save_tokens()
		print("token refreshed")
		emit_signal("token_recieved")
		return true
	else:
		return false


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


# SAVE/LOAD
const SAVE_DIR = 'user://token/'
var save_path = SAVE_DIR + 'token.dat'


func save_tokens():
	var dir = Directory.new()
	if !dir.dir_exists(SAVE_DIR):
		dir.make_dir_recursive(SAVE_DIR)
	
	var file = File.new()
	var error = file.open_encrypted_with_pass(save_path, File.WRITE, 'abigail')
	if error == OK:
		var tokens = {
			"token" : token,
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
			token = tokens.get("token")
			refresh_token = tokens.get("refresh_token")
			file.close()
			print("token loaded successfully")


func load_HTML(path):
	var file = File.new()
	if file.file_exists(path):
		file.open(path, File.READ)
		var HTML = file.get_as_text().replace("    ", "\t").insert(0, "\n")
		file.close()
		return HTML

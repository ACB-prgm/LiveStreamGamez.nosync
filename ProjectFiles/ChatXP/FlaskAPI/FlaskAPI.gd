extends Node


const PASSWORD = "Abigail"
const KEY_PATH = "res://ChatXP/FlaskAPI/key.dat"
const BASE_URL = "http://lsg-flask-api-env.eba-6hk8kiiv.us-east-1.elasticbeanstalk.com"

onready var KEY = load_key()


func load_key():
	var data = null
	var file = File.new()
	if file.file_exists(KEY_PATH):
		var error = file.open_encrypted_with_pass(KEY_PATH, File.READ, PASSWORD)
		if error == OK:
			data = file.get_var()
			file.close()
		else:
			print("ERROR LOADING FILE : %s" % error)
	else:
		print("KEY FILE NOT FOUND ON THIS DEVICE. API WILL NOT WORK.")
	return data


func update_user_info(user_name:String, info:Dictionary) -> void:
	var endpoint = "/users/name/%s/info" % user_name
	var body = to_json({
		"info" : info,
		"key" : KEY
	})
	var headers = PoolStringArray([
		"Content-Type: application/json"
	])
	
	
	var http_request = HTTPRequest.new()
	add_child(http_request)
	var error = http_request.request(BASE_URL.plus_file(endpoint), 
		headers, true, HTTPClient.METHOD_PUT, body)
	if error != OK:
		push_error("An error occurred in the HTTP request with ERR Code: %s" % error)
	
	var response = yield(http_request, "request_completed")
	var response_body = parse_json(response[3].get_string_from_utf8())
	print(response_body)


func update_all_users_info(info:Dictionary) -> void:
	var endpoint = "/users/all/info"
	var body = to_json({
		"info" : info,
		"key" : KEY
	})
	var headers = PoolStringArray([
		"Content-Type: application/json"
	])
	
	var http_request = HTTPRequest.new()
	add_child(http_request)
	var error = http_request.request(BASE_URL.plus_file(endpoint), 
		headers, true, HTTPClient.METHOD_PUT, body)
	if error != OK:
		push_error("An error occurred in the HTTP request with ERR Code: %s" % error)
	
	var response = yield(http_request, "request_completed")
	var response_body = parse_json(response[3].get_string_from_utf8())
	prints("update_all_users_info", response_body)


func get_user_info(user_name:String) -> Dictionary:
	var endpoint = "/users/name/%s/info" % user_name
	var body = to_json({
		"key" : KEY
	})
	var headers = PoolStringArray([
		"Content-Type: application/json"
	])
	
	var http_request = HTTPRequest.new()
	add_child(http_request)
	var error = http_request.request(BASE_URL.plus_file(endpoint), 
		headers, true, HTTPClient.METHOD_GET, body)
	if error != OK:
		push_error("An error occurred in the HTTP request with ERR Code: %s" % error)
	
	var response = yield(http_request, "request_completed")
	var response_body = parse_json(response[3].get_string_from_utf8())
	return response_body.get("info")


func get_all_users_info() -> void:
	var endpoint = "/users/all/info"
	var body = to_json({
		"key" : KEY
	})
	var headers = PoolStringArray([
		"Content-Type: application/json"
	])
	
	var http_request = HTTPRequest.new()
	add_child(http_request)
	var error = http_request.request(BASE_URL.plus_file(endpoint), 
		headers, true, HTTPClient.METHOD_GET, body)
	if error != OK:
		push_error("An error occurred in the HTTP request with ERR Code: %s" % error)
	
	var response = yield(http_request, "request_completed")
	var response_body = parse_json(response[3].get_string_from_utf8())
	if !response_body:
		print(response[3].get_string_from_utf8())
	return response_body.get("info")

extends Node


const FLASK_URL := "http://lsg-flask-api-env.eba-6hk8kiiv.us-east-1.elasticbeanstalk.com"
#const FLASK_URL := "http://127.0.0.1:5000"


func _on_token_recieved() -> void:
	if not yield(GoogleSignIn.is_token_valid(), "completed"):
		return
	
	var token = GoogleSignIn.token
	var id_token = GoogleSignIn.id_token
	
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
	
	GoogleSignIn.display_name = response_body.get("display_name")
	GoogleSignIn.save_tokens()


func update_user_info(info:Dictionary) -> void:
	var id_token = GoogleSignIn.id_token
	
	var endpoint = "/users/id/%s/info" % id_token
	var body = to_json({
		"info" : info,
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
	var _response_body = parse_json(response[3].get_string_from_utf8())


func get_user_info() -> Dictionary:
	var id_token = GoogleSignIn.id_token
	var endpoint = "/users/id/%s/info" % id_token
	var headers = PoolStringArray([
		"Content-Type: application/json"
	])
	
	var http_request = HTTPRequest.new()
	add_child(http_request)
	var error = http_request.request(FLASK_URL.plus_file(endpoint), 
		headers, true, HTTPClient.METHOD_GET, to_json({}))
	if error != OK:
		push_error("An error occurred in the HTTP request with ERR Code: %s" % error)
	
	var response = yield(http_request, "request_completed")
	var response_body = parse_json(response[3].get_string_from_utf8())

	return response_body["info"]



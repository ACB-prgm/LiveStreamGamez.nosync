extends Node


const TABLE_NAME = "LSG_user_data"
const dynamodb_data_type_map := {
	0: "NULL",
	1: "BOOL",
	2: "N",
	3: "N",	
	4: "S",
	18: "M",
	19: "L",
	20: "B",
	21: "NS",
	22: "NS",
	23: "SS",
}

var dynamo_db := AWSDynamoDB.new()
var player_info := {}

signal player_info_received

func _on_sign_in_completed():
	var creds = GoogleSignIn.AWS_Creds
	add_child(dynamo_db)
	dynamo_db.init(creds["AccessKeyId"], creds["SecretAccessKey"], "us-east-1")
	
	var ERR = yield(update_player_info(), "completed")
	if ERR != OK:
		yield(GoogleSignIn._on_AWS_expired(), "completed")
		ERR = yield(update_player_info(), "completed")
		if ERR != OK:
			push_error(ERR)
	
	emit_signal("player_info_received")
	print("success")

func get_player_info():
	var item = encode_dynamodb_item({
		"display_name" : player_info["display_name"],
		"google_sub" : player_info["google_sub"]
	})
	var response = yield(dynamo_db.get_item(
			TABLE_NAME, 
			item, 
			{"x-amz-security-token": GoogleSignIn.AWS_Creds["SessionToken"]}
			), "completed")
	
	if response[1] == 200:
		return parse_json(response[-1].get_string_from_utf8())
	else:
		return response[1]

func put_player_info():
	if not ("display_name" in player_info and "google_sub" in player_info):
		return false
	
	var item = encode_dynamodb_item(player_info)
	var response = yield(dynamo_db.put_item(
		TABLE_NAME,
		item,
		{"x-amz-security-token": GoogleSignIn.AWS_Creds["SessionToken"]}
		), 
		"completed"
		)
	
	return response[1]

func update_player_info():
	var get_info = yield(get_player_info(), "completed")
	if get_info is int:
		return ERR_INVALID_DATA
	player_info.merge(get_info)
	
	var response_code = yield(put_player_info(), "completed")
	if response_code != 200:
		push_error("Update Player Failed")
	
	return OK

func encode_dynamodb_item(item: Dictionary) -> Dictionary:
	var encoded = {}
	for key in item:
		var value = item[key]
		var dynamo_type = dynamodb_data_type_map.get(typeof(value), null)
		if dynamo_type:
			match dynamo_type:
				"M":
					value = encode_dynamodb_item(value)
				"N":
					value = str(value)
				"L":
					var list_encoded : Array = []
					for elem in value:
						list_encoded.append(encode_dynamodb_item({"item": elem})["item"])
					value = list_encoded
				"NS":
					var num_set : PoolStringArray = []
					for elem in value:
						num_set.append(str(elem))
					value = num_set
			encoded[key] = {dynamo_type : value}
		else:
			push_error("ERROR: DICT CONTAINS UN-ENCODABLE TYPE: " + str(value))
			return {}
	
	return encoded

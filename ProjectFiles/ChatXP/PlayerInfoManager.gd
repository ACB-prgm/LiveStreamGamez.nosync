extends Node


const FRAME_THRESH = 600 # ~10 seconds
const TABLE_NAME = "LSG_user_data"
const REGION = "us-east-1"
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

var frame_count := 0
var AWS_KEY : String
var AWS_SECRET : String
var dynamo_db := AWSDynamoDB.new()
var player_info_stack = []


func _ready():
	load_secrets()
	
	add_child(dynamo_db)
	dynamo_db.init(AWS_KEY, AWS_SECRET, REGION)
#
#	var ERR = yield(update_player_info(), "completed")
#	if ERR != OK:
#		yield(GoogleSignIn._on_AWS_expired(), "completed")
#		ERR = yield(update_player_info(), "completed")
#		if ERR != OK:
#			push_error(ERR)

func _physics_process(delta):
	frame_count += 1
	if frame_count >= FRAME_THRESH:
		sync_player_infos()
		frame_count = 0

func sync_player_infos():
	pass

func get_player_info(display_name:String, google_sub:String):
	var item = encode_dynamodb_item({
		"display_name" : display_name,
		"google_sub" : google_sub
	})
	var response = yield(dynamo_db.get_item(
			TABLE_NAME, 
			item
			), "completed")

	if response[1] == 200:
		return parse_json(response[-1].get_string_from_utf8())
	else:
		return response[1]

func put_player_info(player_info:Dictionary):
	var item = encode_dynamodb_item(player_info)
	var response = yield(dynamo_db.put_item(
		TABLE_NAME,
		item
		), 
		"completed"
		)

	return response[1]

func update_player_info(display_name:String, google_sub:String, old_info:Dictionary) -> void:
	var get_info = yield(get_player_info(display_name, google_sub), "completed")
	if get_info is int:
		return ERR_INVALID_DATA
	old_info.merge(get_info)

	var response_code = yield(put_player_info(old_info), "completed")
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

func load_secrets():
	var file = File.new()
	if file.open("res://ChatXP/aws_secrets.json", File.READ) == OK:
		var data : Dictionary = parse_json(file.get_as_text())
		AWS_KEY = data["KEY"]
		AWS_SECRET = data["SECRET"]

extends Node


const FRAME_THRESH = 1200 # ~20 seconds
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

var example_player_info = {
	"display_name" : "YoungWood",
	"thumbnail_id" : "APkrFKbGGhT4v0N6PxIIOVb0bwG_FCWGuf1dMKnCNyCL",
	"progression" : {
		"level": 1,
		"level_xp" : 0,
		"xpbar_value" : 0.0,
		"last_stream" : "",
		"total_num_comments" : 0, # num lifetime comments
		"current_num_comments" : 0 # num comments on current stream
	},
	"appearance" : {
		"icon" : null
	}
}

var frame_count := 0
var AWS_KEY : String
var AWS_SECRET : String
var dynamo_db := AWSDynamoDB.new()
var player_info_stack = {}
# user_name : {
#	"changed" : bool,
#	"info: : dict
#}


func _ready():
	load_secrets()
	
	add_child(dynamo_db)
	dynamo_db.init(AWS_KEY, AWS_SECRET, REGION)
	
	player_info_stack["YoungWood/APkrFKbGGhT4v0N6PxIIOVb0bwG_FCWGuf1dMKnCNyCL"] = {"changed": true, "info": example_player_info}
	player_info_stack["Testy/uajhgregkerkajlg678"] = {"changed": true, "info" : {"display_name": "Testy", "thumbnail_id": "uajhgregkerkajlg678", "values": true}}
	
	var response = yield(pull_player_stack(), "completed")
	print(response[0])
	print(response[-1].get_string_from_utf8())
#	var ERR = yield(update_player_info(), "completed")
#	if ERR != OK:
#		yield(GoogleSignIn._on_AWS_expired(), "completed")
#		ERR = yield(update_player_info(), "completed")
#		if ERR != OK:
#			push_error(ERR)

func _physics_process(_delta):
	frame_count += 1
	if frame_count >= FRAME_THRESH:
		sync_player_infos()
		frame_count = 0

func sync_player_infos():
	var to_change := []
	for player in player_info_stack:
		var player_info = player_info_stack.get(player)
		if player_info.get("changed"):
			to_change.append(player_info)
	
	# pull infos
	# update changes
	# push infos
	pass

func put_player_stack():
	var items = []
	for player in player_info_stack:
		player = player_info_stack.get(player)
		if player["changed"]:
			items.append(encode_dynamodb_item(player["info"]))
	
	var response = yield(dynamo_db.batch_put_item(TABLE_NAME, items), "completed")
	
	return response

func pull_player_stack():
	var keys = []
	for player in player_info_stack.values():
		var info = player["info"]
		keys.append(encode_dynamodb_item({
			"display_name": info["display_name"],
			"thumbnail_id": info["thumbnail_id"]
			}))
	
	var response = yield(dynamo_db.batch_get_item(TABLE_NAME, keys), "completed")
	
	return response


func get_player_info(display_name:String, thumbnail_id:String, force_pull:= false):
	var fullname : String = "%s/%s" % [display_name, thumbnail_id]
	if !force_pull and fullname in player_info_stack.keys():
		return player_info_stack.get(fullname)
	
	var item = encode_dynamodb_item({
		"display_name" : display_name,
		"thumbnail_id" : thumbnail_id
	})
	var response = yield(dynamo_db.get_item(
			TABLE_NAME, 
			item
			), "completed")

	if response[1] == 200:
		var info = parse_json(response[-1].get_string_from_utf8())
		player_info_stack[fullname] = info
		return info
	else:
		return response[1]

func put_player_info(player_info:Dictionary):
	if not ("display_name" in player_info and "thumbnail_id" in player_info):
		return false
	
	var item = encode_dynamodb_item(player_info)
	var response = yield(dynamo_db.put_item(
		TABLE_NAME,
		item
		), 
		"completed"
		)

	return response

func update_player_info(display_name:String, thumbnail_id:String, old_info:Dictionary) -> void:
	var get_info = yield(get_player_info(display_name, thumbnail_id), "completed")
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
				"NULL":
					value = true
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
	if file.open("res://AWS/aws_secrets.dat", File.READ) == OK:
		var data : Dictionary = file.get_var()
		AWS_KEY = data["KEY"]
		AWS_SECRET = data["SECRET"]
		
	file.close()

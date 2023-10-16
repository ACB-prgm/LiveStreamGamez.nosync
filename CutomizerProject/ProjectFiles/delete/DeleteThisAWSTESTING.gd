extends Node

const ID = "AKIAVVWQARCLB5BEEIWH"
const SECRET = "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"
const REGION = "us-east-1"
const TABLE_NAME	 = "LSG_user_data"

var info = { 
	"display_name" : "YoungWood",
	"appearance": {
		"bg": {
			"outline": "ffff0000"
		},
		"icon": "null",
		"info_color": "ffff0000",
		"xp_bar_color": "ffff0000"
	},
	"progression": {
		"current_num_comments": 1,
		"last_stream": "test",
		"level": 1,
		"level_xp": 50,
		"total_num_comments": 1,
		"xpbar_value": 47.619048
	}
}

var gettr_info = {
	"DisplayName": {"S": "YoungWood"},
	"Sub": {"S": "normal"},
}


func _ready():
	var dynamo = AWSDynamoDB.new()
	add_child(dynamo)
	dynamo.init(ID, SECRET, REGION)
	
	var item = dynamo.encode_dynamodb_item(info)
	print(item)
	var result = yield(dynamo.put_item(
		TABLE_NAME, 
		item
		), "completed")
	print(result[-1].get_string_from_utf8())
		
	
	

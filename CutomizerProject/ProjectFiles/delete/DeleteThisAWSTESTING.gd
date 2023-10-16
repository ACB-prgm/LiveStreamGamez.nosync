extends Node

const ID = "AKIAVVWQARCLB5BEEIWH"
const SECRET = "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"
const REGION = "us-east-1"
const TABLE_NAME	 = "LSG_user_data"

var info = {
	"DisplayName": {"S": "YoungWood"},
	"Sub": {"S": "test"},  # Assuming it's a string type. If you want it to be null in DynamoDB, you'd use {"NULL": true}
	"appearance": {
		"M": {
			"bg": {
				"M": {
					"outline": {"S": "ffff0000"}
				}
			},
			"icon": {"NULL": true},  # NULL type for DynamoDB
			"info_color": {"S": "ffff0000"},
			"xp_bar_color": {"S": "ffff0000"}
		}
	},
	"progression": {
		"M": {
			"current_num_comments": {"N": "1"},  # DynamoDB represents numbers as strings
			"last_stream": {"S": "test"},
			"level": {"N": "1"},
			"level_xp": {"N": "50"},
			"total_num_comments": {"N": "1"},
			"xpbar_value": {"N": "47.619048"}  # Represent the float as a string
		}
	}
}

#const AWSAccessKeyId := "AKIAVVWQARCLMVB3TDTB"
#const AWSSecretKey := "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"
#const REGION := "us-east-1"

var file_name = "plugin.json"
var bucket = "godot-test-bucket"

func _ready():
#	var s3 = AWSs3.new()
#	add_child(s3)
#	s3.init(ID, SECRET, REGION)
#
#	s3.put_file_object(bucket, file_name, to_json(info))
	var dynamo = AWSDynamoDB.new()
	add_child(dynamo)
	dynamo.init(ID, SECRET, REGION)

	var result = yield(dynamo.put_item(TABLE_NAME, info), "completed")
	print(result[-1].get_string_from_utf8())


func list_buckets(_s3) -> Array:
	var buckets = []
	var response = yield(_s3.list_buckets(), "completed")
	
	var xml = XMLReader.new()
	xml.open_string(response[3].get_string_from_utf8())
	var dict = xml.find_and_get_element("Buckets_0")
	
	for bucket_num in range(dict.size()):
		var _bucket = "Bucket_%s" % bucket_num
		var _name = "Name_%s" % bucket_num
		
		buckets.append(dict[_bucket][_name][_name + "_text"])
	
	return buckets
		
	
	

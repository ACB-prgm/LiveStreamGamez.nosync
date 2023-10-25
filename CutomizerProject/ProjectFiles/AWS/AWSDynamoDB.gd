class_name AWSDynamoDB
extends Node


const NO_CONTENT = "e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855"

var AWSACCESSKEYID : String
var AWSSECRETKEY : String
var REGION : String
var HOST : String


# HIGH LEVEL FUNCTIONS —————————————————————————————————————————————————————————
func init(AWSAccessKeyID:String, AWSSecretKey:String, Region:String) -> void:
	AWSACCESSKEYID = AWSAccessKeyID
	AWSSECRETKEY = AWSSecretKey
	REGION = Region
	HOST = "dynamodb.%s.amazonaws.com" % REGION

func requirements_met(push_if:bool=false) -> bool:
	if not (AWSACCESSKEYID and AWSSECRETKEY and REGION):
		if push_if:
			push_error("'AWSACCESSKEYID', 'AWSSECRETKEY', and 'REGION' must be set.")
		return false
	return true

func put_item(table_name:String, item:Dictionary, add_headers:={}) -> Array:
	if requirements_met(true):
		var url = "https://%s/" % HOST
		var timestamp = get_amz_time()

		var body = to_json({
			"TableName": table_name,
			"Item": item
		})
		
		add_headers.merge({
			"x-amz-target": "DynamoDB_20120810.PutItem",
			"Content-Type": "application/x-amz-json-1.0",
			"x-amz-content-sha256": body.sha256_text()
		})

		var headers = PoolStringArray([
			"Authorization: %s" % create_authorization_header(HOST, timestamp, "POST", add_headers),
			"x-amz-content-sha256: %s" % add_headers["x-amz-content-sha256"],
			"x-amz-date: %s" % timestamp
		])

		for header in add_headers:
			var new_header := "%s: %s" % [header, add_headers.get(header)]
			if not new_header in headers:
				headers.append(new_header)

		var http_request = HTTPRequest.new()
		get_tree().root.call_deferred("add_child", http_request)
		http_request.call_deferred("request", url, headers, true, HTTPClient.METHOD_POST, body)
		
		var response = yield(http_request, "request_completed")
		http_request.queue_free()
		return response
	else:
		return []

func get_item(table_name:String, item:Dictionary, add_headers:={}) -> Array:
	if requirements_met(true):
		var url = "https://%s/" % HOST
		var timestamp = get_amz_time()

		var body = to_json({
			"TableName": table_name,
			"Key": item
		})
		
		add_headers.merge({
			"x-amz-target": "DynamoDB_20120810.GetItem",
			"Content-Type": "application/x-amz-json-1.0",
			"x-amz-content-sha256": body.sha256_text()
		})

		var headers = PoolStringArray([
			"Authorization: %s" % create_authorization_header(HOST, timestamp, "POST", add_headers),
			"x-amz-content-sha256: %s" % add_headers["x-amz-content-sha256"],
			"x-amz-date: %s" % timestamp
		])

		for header in add_headers:
			var new_header := "%s: %s" % [header, add_headers.get(header)]
			if not new_header in headers:
				headers.append(new_header)

		var http_request = HTTPRequest.new()
		get_tree().root.call_deferred("add_child", http_request)
		http_request.call_deferred("request", url, headers, true, HTTPClient.METHOD_POST, body)

		var response = yield(http_request, "request_completed")
		http_request.queue_free()
		return response
	else:
		return []

func delete_item(table_name:String, item:Dictionary, add_headers:={}) -> Array:
	if requirements_met(true):
		var url = "https://%s/" % HOST
		var timestamp = get_amz_time()

		var body = to_json({
			"TableName": table_name,
			"Key": item
		})
		
		add_headers.merge({
			"x-amz-target": "DynamoDB_20120810.DeleteItem",
			"Content-Type": "application/x-amz-json-1.0",
			"x-amz-content-sha256": body.sha256_text()
		})

		var headers = PoolStringArray([
			"Authorization: %s" % create_authorization_header(HOST, timestamp, "POST", add_headers),
			"x-amz-content-sha256: %s" % add_headers["x-amz-content-sha256"],
			"x-amz-date: %s" % timestamp
		])

		for header in add_headers:
			var new_header := "%s: %s" % [header, add_headers.get(header)]
			if not new_header in headers:
				headers.append(new_header)

		var http_request = HTTPRequest.new()
		get_tree().root.call_deferred("add_child", http_request)
		http_request.call_deferred("request", url, headers, true, HTTPClient.METHOD_POST, body)

		var response = yield(http_request, "request_completed")
		http_request.queue_free()
		return response
	else:
		return []



# LOW LEVEL FUNCTIONS ——————————————————————————————————————————————————————————
func UriEncode(base:String, obj_key_name:String="") -> String:
	var encoded_uri = base.http_escape()
	
	if obj_key_name:
		obj_key_name = obj_key_name.http_escape().replace("%2F", "/")
		if !base:
			return obj_key_name
		encoded_uri += obj_key_name
	
	return encoded_uri

func HMAC_SHA256(key, msg:String) -> PoolByteArray:
	var cr = Crypto.new()
	if key is String:
		key = key.to_utf8()
	return cr.hmac_digest(HashingContext.HASH_SHA256, key, msg.to_utf8())

func get_SignedHeaders(headers:Dictionary) -> String:
	var keys = headers.keys()
	keys.sort()
	return PoolStringArray(keys).join(";").to_lower()

func get_amz_time() -> String:
# warning-ignore:narrowing_conversion
	var time = Time.get_datetime_string_from_unix_time(Time.get_unix_time_from_system())
	time = time.replace("-", "").replace(":", "") + "Z"
	return time

func get_defualt_headers(timestamp:String) -> Dictionary:
	return {
		"host" : "dynamodb.amazonaws.com",
		"x-amz-content-sha256" : NO_CONTENT, 
		"x-amz-date" : timestamp # yyyyMMdd T HHmmss Z
	}

func create_canonical_request(HTTPRequestMethod:String, 
							CanonicalURI:String,
							headers:Dictionary,
							CanonicalQueryString:String=""
							) -> String:
	var CanonicalHeaders := ""
	var keys = headers.keys()
	keys.sort()
	
	for header in keys:
		CanonicalHeaders += "%s:%s\n" % [
			header.to_lower(),
			headers.get(header).strip_edges()
		]
	var SignedHeaders := PoolStringArray(keys).join(";").to_lower()
	
	var HashedPayload = headers.get("x-amz-content-sha256", NO_CONTENT)
	
	var CanonicalRequest := PoolStringArray([
		HTTPRequestMethod,
		CanonicalURI,
		CanonicalQueryString,
		CanonicalHeaders,
		SignedHeaders,
		HashedPayload
	]).join("\n")
	
	return CanonicalRequest

func create_string_to_sign(scope:String, canonical_request:String, 
		timestamp:String) -> String:
	return PoolStringArray([
		"AWS4-HMAC-SHA256",
		timestamp,
		scope,
		canonical_request.sha256_text()
	]).join("\n")

func create_signature(StringToSign:String, timestamp:String) -> String:
	var signing_key = HMAC_SHA256(HMAC_SHA256(HMAC_SHA256(HMAC_SHA256(
		"AWS4%s" % AWSSECRETKEY, timestamp.get_slice("T", 0)), REGION), "dynamodb"), "aws4_request")
	return HMAC_SHA256(signing_key, StringToSign).hex_encode()

func create_authorization_header(host:String,
		timestamp:String, method:String="POST", add_headers:Dictionary={}, 
		verbose:=false) -> String:
	var headers = get_defualt_headers(timestamp)
	headers["host"] = host
	if add_headers:
		headers.merge(add_headers, true)
	
	var scope = "%s/%s/dynamodb/aws4_request" % [timestamp.get_slice("T", 0), REGION]
	# For DynamoDB, the Canonical URI is just "/"
	var canon_req = create_canonical_request(method, "/", headers)
	var sts = create_string_to_sign(scope, canon_req, timestamp)
	var signature = create_signature(sts, timestamp)
	var auth_header = "AWS4-HMAC-SHA256 " + PoolStringArray([
		"Credential=%s/%s" % [AWSACCESSKEYID, scope],
		"SignedHeaders=%s" % get_SignedHeaders(headers),
		"Signature=%s" % signature
	]).join(",")
	
	if verbose:
		print("CANONICAL REQ", canon_req)
		print("\nSTRING TO SIGN", sts)
		print("\nSIGNATURE", signature)
		print("\nAUTH HEADER", auth_header)
	
	return auth_header



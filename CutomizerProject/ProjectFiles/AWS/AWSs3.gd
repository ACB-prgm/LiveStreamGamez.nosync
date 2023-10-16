class_name AWSs3
extends Node


const NO_CONTENT = "e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855"

var AWSACCESSKEYID : String
var AWSSECRETKEY : String
var REGION : String


# HIGH LEVEL FUNCTIONS —————————————————————————————————————————————————————————
func init(AWSAccessKeyID:String, AWSSecretKey:String, Region:String) -> void:
	AWSACCESSKEYID = AWSAccessKeyID
	AWSSECRETKEY = AWSSecretKey
	REGION = Region

func requirements_met(push_if:bool=false) -> bool:
	if not (AWSACCESSKEYID or AWSSECRETKEY or REGION):
		if push_if:
			push_error("'AWSACCESSKEYID', 'AWSSECRETKEY', and 'REGION' must be set.")
		return false
	return true

func create_bucket(bucket:String, CreateBucketConfiguration:="", 
		add_headers:={}) -> Array:
	# MAKE SURE AND FOLLOW AWS BUCKET NAMING RULES
	#https://docs.aws.amazon.com/AmazonS3/latest/API/API_CreateBucket.html
	if requirements_met(true):
		var host = "%s.s3.amazonaws.com" % bucket
		var timestamp = get_amz_time()
		var url = "http://%s" % host
		
		var headers = PoolStringArray([
			"Authorization:%s" % create_authorization_header(host, "/", 
				timestamp, "PUT", add_headers
				),
			"x-amz-content-sha256:%s" % NO_CONTENT,
			"x-amz-date:%s" % timestamp
			])
		
		for header in add_headers:
			var new_header := "%s:%s" % [header, add_headers.get(header)]
			if not new_header in headers:
				headers.append(new_header)
		
		var http_request = HTTPRequest.new()
		get_tree().root.call_deferred("add_child", http_request)
		http_request.call_deferred(
			"request", url, headers, true, 
			HTTPClient.METHOD_PUT, CreateBucketConfiguration
			)
		
		return yield(http_request, "request_completed")
	else:
		return []

func delete_bucket(bucket:String, add_headers:={}) -> Array:
	# https://docs.aws.amazon.com/AmazonS3/latest/API/API_DeleteBucket.html
	if requirements_met(true):
		var host = "%s.s3.amazonaws.com" % bucket
		var timestamp = get_amz_time()
		
		var url = "http://%s" % host
		var headers = PoolStringArray([
			"Authorization:%s" % create_authorization_header(host, "/", 
				timestamp, "DELETE", add_headers
				),
			"x-amz-content-sha256:%s" % NO_CONTENT,
			"x-amz-date:%s" % timestamp
		])
		for header in add_headers:
			headers.append("%s:%s" % [header, add_headers.get(header)])
		
		var http_request = HTTPRequest.new()
		get_tree().root.call_deferred("add_child", http_request)
		http_request.call_deferred("request", url, headers, true, HTTPClient.METHOD_DELETE)

		return yield(http_request, "request_completed")
	else:
		return []

func get_bucket_info(bucket:String, add_headers:={}) -> Array:
	if requirements_met(true):
		var host = "%s.s3.amazonaws.com" % bucket
		var timestamp = get_amz_time()
		var url = "http://%s/" % host
		
		var headers = PoolStringArray([
			"Authorization:%s" % create_authorization_header(host, "/", timestamp, 
				"GET", add_headers
				),
			"x-amz-content-sha256:%s" % NO_CONTENT,
			"x-amz-date:%s" % timestamp
			])
		for header in add_headers:
			headers.append("%s:%s" % [header, add_headers.get(header)])
		
		var http_request = HTTPRequest.new()
		get_tree().root.call_deferred("add_child", http_request)
		http_request.call_deferred("request", url, headers)

		return yield(http_request, "request_completed")
	else:
		return []

func get_file_object(bucket:String, file_name:String, add_headers:={}) -> Array:
	# CALL get_string_from_utf8 ON THE BODY, DO NOT USE XML_READER
	# https://docs.aws.amazon.com/AmazonS3/latest/API/API_GetObject.html
	if requirements_met(true):
		var host = "%s.s3.amazonaws.com" % bucket
		var timestamp = get_amz_time()
		
		var url = "http://%s/%s" % [host, file_name]
		var headers = PoolStringArray([
			"Authorization:%s" % create_authorization_header(host, "/" + file_name, 
				timestamp, "GET", add_headers
				),
			"x-amz-content-sha256:%s" % NO_CONTENT,
			"x-amz-date:%s" % timestamp
		])
		for header in add_headers:
			headers.append("%s:%s" % [header, add_headers.get(header)])
		
		var http_request = HTTPRequest.new()
		get_tree().root.call_deferred("add_child", http_request)
		http_request.call_deferred("request", url, headers)

		return yield(http_request, "request_completed")
	else:
		return []

func put_file_object(bucket:String, file_name:String, file_content:String, 
		add_headers:={}) -> Array:
	# https://docs.aws.amazon.com/AmazonS3/latest/API/API_PutObject.html
	if requirements_met(true):
		var host = "%s.s3.amazonaws.com" % bucket
		var timestamp = get_amz_time()
		var url = "http://%s/%s" % [host, file_name]
		add_headers["x-amz-content-sha256"] = file_content.sha256_text()
		
		var headers = PoolStringArray([
			"Authorization:%s" % create_authorization_header(host, "/" + file_name, 
				timestamp, "PUT", add_headers
				),
			"x-amz-content-sha256:%s" % add_headers["x-amz-content-sha256"],
			"x-amz-date:%s" % timestamp
			])
		
		for header in add_headers:
			var new_header := "%s:%s" % [header, add_headers.get(header)]
			if not new_header in headers:
				headers.append(new_header)
		
		print("\n".join(headers))
		
		var http_request = HTTPRequest.new()
		get_tree().root.call_deferred("add_child", http_request)
		http_request.call_deferred("request", url, headers, true, HTTPClient.METHOD_PUT, file_content)
		
		return yield(http_request, "request_completed")
	else:
		return []

func list_buckets(add_headers:={}) -> Array:
	if requirements_met(true):
		var host = "s3.amazonaws.com"
		var timestamp = get_amz_time()
		var url = "http://%s/" % host
		
		var headers = PoolStringArray([
			"Authorization:%s" % create_authorization_header(host, "/", timestamp, 
				"GET", add_headers
				),
			"x-amz-content-sha256:%s" % NO_CONTENT,
			"x-amz-date:%s" % timestamp
			])
		for header in add_headers:
			headers.append("%s:%s" % [header, add_headers.get(header)])
		
		var http_request = HTTPRequest.new()
		get_tree().root.call_deferred("add_child", http_request)
		http_request.call_deferred("request", url, headers)

		return yield(http_request, "request_completed")
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
	return PoolStringArray(keys).join(";")

func get_amz_time() -> String:
# warning-ignore:narrowing_conversion
	var time = Time.get_datetime_string_from_unix_time(Time.get_unix_time_from_system())
	time = time.replace("-", "").replace(":", "") + "Z"
	return time

func get_defualt_headers(timestamp:String) -> Dictionary:
	return {
		"host" : "s3.amazonaws.com",
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
	var SignedHeaders := PoolStringArray(keys).join(";")
	
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
		"AWS4%s" % AWSSECRETKEY, timestamp.get_slice("T", 0)), REGION), "s3"), "aws4_request")
	return HMAC_SHA256(signing_key, StringToSign).hex_encode()

func create_authorization_header(host:String, file_name:String,
		timestamp:String, method:String="GET", add_headers:Dictionary={}, 
		verbose:=false) -> String:
	var headers = get_defualt_headers(timestamp)
	headers["host"] = host
	if add_headers:
		headers.merge(add_headers, true)
	
	var scope = "%s/%s/s3/aws4_request" % [timestamp.get_slice("T", 0), REGION]
	var canon_req = create_canonical_request(method, UriEncode("", file_name), headers)
	var sts = create_string_to_sign(scope, canon_req, timestamp)
	var signature = create_signature(sts, timestamp)
	var auth_header = "AWS4-HMAC-SHA256 " + PoolStringArray([
		"Credential=%s/%s" % [AWSACCESSKEYID, scope],
		"SignedHeaders=%s" % get_SignedHeaders(headers),
		"Signature=%s" % signature
	]).join(",")
	
	if verbose:
		print("CANONICAL REQ\n", canon_req)
		print("\nSTRING TO SIGN\n", sts)
		print("\nSIGNATURE\n", signature, "\n")
		print("\nAUTH HEADER\n", auth_header, "\n")
	
	return auth_header



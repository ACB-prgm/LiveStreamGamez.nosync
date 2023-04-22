from flask import Flask, jsonify, request, make_response
import os
import boto3
import json


LSG_KEY = os.environ.get('LSG_KEY')
BUCKET = "lsg-user-info"
USER_INFO_JSON = "user_info.json"
ID_LOOKUP_JSON = "user_id_lookup.json"

application = Flask(__name__)

# create S3 client object with the credentials
s3 = boto3.client('s3')


@application.route("/", methods=["GET"])
def home():
    return "Hello World!"


# Check if a user with the given user_name or user_id exists
@application.route("/users/name/<string:user_name>/", methods=["GET"])
@application.route("/users/id/<string:user_id>/", methods=["GET"])
def user_exists(user_name=None, user_id=None):
    if user_id:
        user_name = get_username_from_id(user_id)
        if not user_name:
            error(400, "user_id not found")
    
    users = json.loads(s3.get_object(Bucket=BUCKET, Key=USER_INFO_JSON)["Body"].read().decode("utf-8"))
    
    return jsonify(users.get(user_name) != None)


@application.route("/users/id/<string:user_id>/<string:user_name>", methods=["PUT"])
def create_user_id_lookup(user_id, user_name):
    id_lookups = json.loads(s3.get_object(Bucket=BUCKET, Key=ID_LOOKUP_JSON)["Body"].read().decode("utf-8"))
    id_lookups[user_id] = user_name
    s3.put_object(Bucket=BUCKET, Key=USER_INFO_JSON, Body=json.dumps(id_lookups))
    return jsonify({"message" : f"Successfully added {user_id}/{user_name}"})


# Update the info of a user with the given user_name or user_id
@application.route("/users/name/<string:user_name>/info", methods=["PUT"])
@application.route("/users/id/<string:user_id>/info", methods=["PUT"])
def update_user_info(user_name=None, user_id=None):
    data = request.get_json()
    new_info = data.get("info")
    if not new_info:
        error(400, "'info' not found in headers")

    if user_id:
        user_name = get_username_from_id(user_id)
        if not user_name:
            error(400, "user_id not found")
    elif user_name:
        if data.get("key") != LSG_KEY:
            return error(400, "invalid key or 'key' not found in headers")

    users = json.loads(s3.get_object(Bucket=BUCKET, Key=USER_INFO_JSON)["Body"].read().decode("utf-8"))
    old_info = users.get(user_name)
    
    if user_id:
        old_info["appearance"] = new_info.get("appearance")
    else:
        old_info = new_info
    
    users[user_name] = old_info
    s3.put_object(Bucket=BUCKET, Key=USER_INFO_JSON, Body=json.dumps(users))

    return jsonify({"message": f"Updated {user_name}'s info"})


# Update the info of all users with the given id_key
@application.route("/users/all/info", methods=["PUT"])
def update_all_users_info():
    data = request.get_json()
    new_info = data.get("info")
    if not new_info:
        error(400, "'info' not found in headers")
    
    if data.get("key") != LSG_KEY:
        error(400, "invalid key or 'key' not found in headers")
    
    s3.put_object(Bucket=BUCKET, Key=USER_INFO_JSON, Body=json.dumps(new_info))
    return jsonify({"message": "Updated info for all users"})


# Get the info of a user with the given user_name and id_key
@application.route("/users/name/<string:user_name>/info", methods=["GET"])
@application.route("/users/id/<string:user_id>/info", methods=["GET"])
def get_user_info(user_name=None, user_id=None):
    if request.get_json().get("key") != LSG_KEY:
        error(400, "invalid key or 'key' not found in headers")
    
    if user_id:
        user_name = get_username_from_id(user_id)
        if not user_name:
            error(400, "user_id not found")

    users = json.loads(s3.get_object(Bucket=BUCKET, Key=USER_INFO_JSON)["Body"].read().decode("utf-8"))
    info = users.get(user_name)
    if not info:
        error(400, "user_name not found")
    
    return jsonify({"info" : info})


# Get the info of all users for the given id_key
@application.route("/users/all/info", methods=["GET"])
def get_all_users_info():
    if request.get_json().get("key") != LSG_KEY:
        error(400, "invalid key or 'key' not found in headers")

    users = json.loads(s3.get_object(Bucket=BUCKET, Key=USER_INFO_JSON)["Body"].read().decode("utf-8"))

    return jsonify({"info" : users})


# HELPER FUNCTIONS ————————————————————————————————————————————————————————————————————————————————————————
def get_username_from_id(user_id) -> str:
    users = json.loads(s3.get_object(Bucket=BUCKET, Key=ID_LOOKUP_JSON)["Body"].read().decode("utf-8"))
    return users.get(user_id)


def error(num, message):
    status_code = num
    message = message
    response = make_response(jsonify({'error': message}), status_code)
    return response


if __name__ == "__main__":
    application.run()
from flask import Flask, jsonify, request, abort
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
@application.route("/users/<string:user_name>/", methods=["GET"])
@application.route("/users/id/<string:user_id>/", methods=["GET"])
def user_exists(user_name=None, user_id=None):
    if user_id:
        user_name = get_username_from_id(user_id)
        if not user_name:
            abort(404, "user_id not found")
    
    users = json.loads(s3.get_object(Bucket=BUCKET, Key=USER_INFO_JSON)["Body"].read().decode("utf-8"))
    
    return jsonify(users.get(user_name) != None)


# Update the info of a user with the given user_name or user_id
@application.route("/users/<string:user_name>/info", methods=["PUT"])
@application.route("/users/id/<string:user_id>/info", methods=["PUT"])
def update_user_info(user_name=None, user_id=None):
    data = request.get_json()
    new_info = data.get("info")
    if not new_info:
        abort(405, "'info' not found in headers")

    if user_id:
        user_name = get_username_from_id(user_id)
        if not user_name:
            abort(404, "user_id not found")
    elif user_name:
        if data.get("key") != LSG_KEY:
            abort(405, "invalid key or 'key' not found in headers")

    users = json.loads(s3.get_object(Bucket=BUCKET, Key=USER_INFO_JSON)["Body"].read().decode("utf-8"))
    old_info = users.get(user_name)
    if not old_info:
        abort(404, "user_name not found")

    if user_id:
        old_info["applicationearance"] = new_info.get("applicationearance")
    else:
        old_info = new_info

    users[user_name] = old_info
    s3.put_object(Bucket=BUCKET, Key=USER_INFO_JSON, Body=json.dumps(users))

    return jsonify({"message": f"Updated {user_name}'s info"})


# Update the info of all users with the given id_key
@application.route("/users/all", methods=["PUT"])
def update_all_users_info():
    data = request.get_json()
    new_info = data.get("info")
    if not new_info:
        abort(405, "'info' not found in headers")
    
    if data.get("key") != LSG_KEY:
        abort(405, "invalid key or 'key' not found in headers")
    
    s3.put_object(Bucket=BUCKET, Key=USER_INFO_JSON, Body=json.dumps(new_info))
    return jsonify({"message": "Updated info for all users"})


# Get the info of a user with the given user_name and id_key
@application.route("/users/<string:user_name>/info", methods=["GET"])
@application.route("/users/id/<string:user_id>/info", methods=["GET"])
def get_user_info(user_name=None, user_id=None):
    if user_id:
        user_name = get_username_from_id(user_id)
        if not user_name:
            abort(404, "user_id not found")

    users = json.loads(s3.get_object(Bucket=BUCKET, Key=USER_INFO_JSON)["Body"].read().decode("utf-8"))
    info = users.get(user_name)
    if not info:
        abort(404, "user_name not found")
    
    return jsonify({"info" : info})


# Get the info of all users for the given id_key
@application.route("/users/all/info", methods=["GET"])
def get_all_users_info():
    key = request.get_json().get("key")
    if key != LSG_KEY:
        abort(405, "invalid key or 'key' not found in headers")

    users = json.loads(s3.get_object(Bucket=BUCKET, Key=USER_INFO_JSON)["Body"].read().decode("utf-8"))

    return jsonify({"info" : users})


# HELPER FUNCTIONS ————————————————————————————————————————————————————————————————————————————————————————
def get_username_from_id(user_id) -> str:
    users = json.loads(s3.get_object(Bucket=BUCKET, Key=ID_LOOKUP_JSON)["Body"].read().decode("utf-8"))
    return users.get(user_id)




if __name__ == "__main__":
    application.run()
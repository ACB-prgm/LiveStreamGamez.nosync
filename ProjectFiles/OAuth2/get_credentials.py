import os
import json
import pickle
from webbrowser import Error
from google.auth.transport.requests import Request
from google_auth_oauthlib.flow import InstalledAppFlow

dir_path = os.path.dirname(os.path.realpath(__file__))
scopes = ["https://www.googleapis.com/auth/youtube"]
credentials_pickle = os.path.join(dir_path, "stored_credentials.pickle")
client_secrets_file = os.path.join(dir_path, "client_secrets.json")
token_json = os.path.join(dir_path, "token_info.json")
credentials = None

def main():
	if os.path.exists(credentials_pickle):
		with open(credentials_pickle, "rb") as credentials_info:
			credentials = pickle.load(credentials_info)
		
		if credentials.expired:
			os.system("osascript -e 'display notification \"Refreshing Token\" with title \"OAuth2.0\"\'")
			try:
				credentials.refresh(Request())
			except:
				get_new_token()
		
		save_token_to_json(credentials)

	else:
		get_new_token()


def get_new_token():
	# Disable OAuthlib's HTTPS verification when running locally.
	# *DO NOT* leave this option enabled in production.
	os.environ["OAUTHLIB_INSECURE_TRANSPORT"] = "1"

	if os.path.isfile(client_secrets_file):
		flow = InstalledAppFlow.from_client_secrets_file(
		client_secrets_file, scopes)
		
		credentials_ = flow.run_local_server(port=8080, prompt="consent")

		with open(credentials_pickle, "wb") as outfile: 
			pickle.dump(credentials_, outfile)
		
		save_token_to_json(credentials_)


def save_token_to_json(credentials_):
	with open(token_json, "w") as json_file:
		json.dump({"TOKEN" : credentials_.token,}, json_file)
	os.system("osascript -e 'display notification \"Token Saved to JSON!\" with title \"OAuth2.0\"\'")

if __name__ == "__main__":
	main()

# "-e", 'display notification "Today at 4 PM" with title "Organizer" subtitle "Event"'
# import googleapiclient.discovery

# using the API
#     youtube = googleapiclient.discovery.build("youtube", "v3", credentials=credentials)
#     request = youtube.liveBroadcasts().list(
#         part="snippet",
#         broadcastStatus="active"
#     )
#     response = request.execute()
#     print(response)

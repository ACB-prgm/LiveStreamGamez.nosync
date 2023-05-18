# Flask API for User Info Communication

This Flask API provides endpoints for communicating user information between a livestream and an application that allows users to customize their appearance. The API is built using Flask, and it utilizes AWS S3 for storing and retrieving user information.

## API Endpoints

### Home

- **URL:** `/`
- **Method:** GET
- **Description:** Returns a simple "Hello World!" message.
- **Response:** String

### Match ID and Display Name

- **URL:** `/matchid/`
- **Method:** PUT
- **Description:** Matches a user ID with their corresponding display name.
- **Request Body:**
  - `token` (string): User token for authentication
  - `id` (string): User ID
- **Response:** JSON object containing the matched display name.

### Check User Existence

- **URL:** `/users/name/<string:user_name>/`
- **URL:** `/users/id/<string:user_id>/`
- **Method:** GET
- **Description:** Checks if a user with the given username or ID exists.
- **Response:** JSON object indicating whether the user exists.

### Update User Info

- **URL:** `/users/name/<string:user_name>/info`
- **URL:** `/users/id/<string:user_id>/info`
- **Method:** PUT
- **Description:** Updates the information of a user with the given username or ID.
- **Request Body:**
  - `info` (object): New user information
- **Response:** JSON object indicating the success of the update.

### Update All Users Info

- **URL:** `/users/all/info`
- **Method:** PUT
- **Description:** Updates the information of all users.
- **Request Body:**
  - `info` (object): New user information
- **Response:** JSON object indicating the success of the update.

### Get User Info

- **URL:** `/users/name/<string:user_name>/info`
- **URL:** `/users/id/<string:user_id>/info`
- **Method:** GET
- **Description:** Retrieves the information of a user with the given username or ID.
- **Response:** JSON object containing the user information.

### Get All Users Info

- **URL:** `/users/all/info`
- **Method:** GET
- **Description:** Retrieves the information of all users.
- **Response:** JSON object containing the user information.

## Helper Functions

The API also includes several helper functions:

- `get_username_from_id(user_id)`: Retrieves the username associated with the given user ID.
- `set_id_username_pair(user_id, user_name)`: Sets the user ID and username pair in the ID lookup JSON.
- `error(num, message)`: Generates an error response with the specified status code and error message.

## Running the API

To run the API, execute the following command in your terminal:

```
python app.py
```

The API will be hosted at `http://localhost:5000/`. You can test the API endpoints using tools like cURL or Postman.

Note: Make sure you have the necessary AWS credentials and permissions to access and modify the S3 bucket specified in the code.

Feel free to modify the code to suit your specific requirements and integrate it into your livestream and application for user information communication.

from flask import Flask, request, jsonify
from Dbconnection import Dbconnect

app = Flask(__name__)

@app.route("/tablescout/pages/login", methods =["POST"])
def login():

    # get the request data
    info = request.get_json()

    #get email and password from the request
    email = info.get("email")
    password = info.get("password")

    #checking if email and password are provided
    if not email or not password:
        return jsonify({
            "error": "Please enter the correct details"
        }

        ), 400

    connection = Dbconnect.connect

    #create a cursor object
    cursor = connection.cursor()

    cursor.execute(
        """SELECT * FROM USERS
        WHERE email = ?""",(email,))

    #user data from the database
    user = cursor.fetchone()

    connection.close()

    #error handling for invalid email or password
    if user is None:
         return jsonify({
             "error": "invalid email or password please try again"
         }),401

    if user["password"] != password:
        return jsonify({
                     "error": "invalid email or password please try again"
                 }),401

    return jsonify({
        "message": "Login successful",
        # returning user data
        "user":{
            "id": user["id"],
            "email": user["email"],
            "username": user["username"],
            "role": user["role"]
        }
    }), 200
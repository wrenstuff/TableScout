from flask import Flask, request, jsonify
from Dbconnection import Dbconnect
from argon2 import PasswordHasher

app = Flask(__name__)
hasher = PasswordHasher()

@app.route("/tablescout/pages/login", methods =["POST"])
def login():

    # get the request data
    info = request.get_json(silent=True) or {}

    #get email and password from the request
    email = info.get("email")
    password = info.get("password")


    #checking if email and password are provided
    if not email or not password:
        return jsonify({
            "error": "Please enter the correct details"
        }

        ), 400

    connection = Dbconnect.connect()

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

    try:
        hasher.verify(user["pwhash"], password)

    except Exception:
        return jsonify  ({
        "success": False,
        "message":"Invalid email or password"
        }
        ),401


    return jsonify({
        "message": "Login successful",
        # returning user data
        "user":{
            "id": user["userid"],
            "email": user["email"],
            "username": user["username"],
            "role": user["role"]
        }
    }), 200

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000, debug=True)
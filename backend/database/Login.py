import sys
import jwt
import os

from flask import Flask, request, jsonify
from Dbconnection import Dbconnect
from flask_cors import CORS
from argon2 import PasswordHasher
from pathlib import Path
from datetime import datetime, timedelta, timezone
from dotenv import load_dotenv
from argon2.exceptions import VerificationError, InvalidHashError


backend_path =Path(__file__).resolve().parent.parent

sys.path.append(str(backend_path))

env_path = backend_path /"api.env"

load_dotenv(dotenv_path= env_path, override=True)

from email_service import contact_email
from update_details import updatedetails_bp


SECRET_KEY = os.getenv("TABLESCOUT_SECRET_KEY")

if not SECRET_KEY:
    raise RuntimeError("key is missing ensure api file is present")

app = Flask(__name__)
app.register_blueprint(updatedetails_bp)

CORS (app, resources={
    r"/tablescout/*": {
        "origins": [
            r"^http://localhost:\d+$",
            r"^http://127\.0\.0\.1:\d+$",
        ]
    }
})
hasher = PasswordHasher()

def create_token(userid):
    now = datetime.now(timezone.utc)

    payload = {
        "sub": str(userid),
        "iat": now,
        "exp": now + timedelta(hours=1)
    }

    return jwt.encode(
        payload,
        SECRET_KEY,
        algorithm="HS256"
    )

@app.route("/tablescout/pages/login", methods =["POST"])
def login():

    # get the request data
    info = request.get_json(silent=True) or {}

    #get email and password from the request, / If the request doesn't contain an email, .lower() will be called on None and potential crash, so removed
    email = info.get("email")
    password = info.get("password")


    #checking if email and password are provided
    if not isinstance(email, str) or not isinstance(password, str):
        return jsonify({
            "error": "Please enter the correct details"
        }), 400

    email = email.strip().lower()

    if not email or not password:
        return jsonify({
            "error": "Please enter your email and password."
        }), 400

    connection = Dbconnect.connect()


    try:
        #create a cursor object
        cursor = connection.cursor()
        cursor.execute(
            """SELECT 
                    users.userid,
                    users.email,
                    users.username,
                    users.pwhash,
                    users.role,
                    users.accstatus,
                    users.store_id,
                    stores.store_name
            FROM users
            LEFT JOIN stores
                ON users.store_id = stores.store_id
            WHERE users.email = ?
            """,
            (email,)
        )

        #user data from the database
        user = cursor.fetchone()
    finally:
        connection.close()

    #error handling for invalid email or password
    if user is None:
         return jsonify({
             "error": "invalid email or password please try again"
         }),401

    try:
        hasher.verify(user["pwhash"], password)
    except (VerificationError, InvalidHashError):
        return jsonify({
            "error": "Invalid email or password. Please try again."
        }), 401

    # Prevent pending or inactive accounts from accessing the app.
    if user["accstatus"] != "ACTIVE":
        return jsonify({
            "error": "Your account is pending approval or inactive."
        }), 403

    token = create_token(user["userid"])
    # Return the details needed by Flutter's SessionManager.
    return jsonify({
        "message": "Login successful",
        "token": token,
        "user":{
            "id": user["userid"],
            "email": user["email"],
            "username": user["username"],
            "role": user["role"],
            "accountStatus": user["accstatus"],
            "storeId": user["store_id"],
            "storeName": user["store_name"]
        }
    }), 200
@app.route("/tablescout/pages/contact", methods=["POST"])
def contact():
    info = request.get_json(silent=True) or {}

    name = info.get("name")
    email = info.get("email")
    subject = info.get("subject")
    message = info.get("message")

    if(
        not isinstance(name,str) or not name.strip()
        or not isinstance(email, str) or not email.strip()
        or not isinstance(subject, str) or not subject.strip()
        or not isinstance(message, str) or not message.strip()
        

    ):
        return jsonify({
            "success": False,
            "message": "Please complete all fields"
        }), 400

    success = contact_email(
        name.strip(),
        email.strip(),
        subject.strip(),
        message.strip(),
    )

    if success: 
        return jsonify({
            "success": True,
            "message": "Message has been sent."
        }), 200

    return jsonify({
                "success": False,
                "message": "unable to send message, please try again later."
            }), 500
        
if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000, debug=True)
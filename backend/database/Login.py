import sys
import jwt
import os
import secrets
import time


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

from email_service import contact_email, recovery_email
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

@app.route("/tablescout/pages/password-recovery", methods=["POST"])
def password_recovery():
    #time delay
    start_time =time.monotonic()

    info = request.get_json(silent=True) or {}
    email = info.get("email")

    if not isinstance(email, str) or not email.strip():
        return jsonify ({
            "success": False,
            "message": "please enter your email address"
        }), 400

    email = email.strip().lower()
    connection = Dbconnect.connect()

    try:
        cursor = connection.cursor()

        cursor.execute("""
        SELECT userid
        FROM users
        WHERE email = ?
        AND accstatus = 'ACTIVE'""", (email,))

        user = cursor.fetchone()

        if user is None:
            elapsed_time = time.monotonic() - start_time
            if elapsed_time < 2:
                time.sleep(2- elapsed_time)
            
            return jsonify({
            "success": True,
            "message": "Recovery code will be sent to email address"
        }), 200
        #invalidate previous codes
        cursor.execute("""
        UPDATE password_resets
        set used =1
        WHERE userid =?
        AND used = 0""", (user["userid"],))

        #6 digit recovery code
        recovery_code = str (secrets.randbelow(900000) + 100000)
        #hash the code
        code_hash = hasher.hash(recovery_code)

        #expitarion of code
        expires_at = int(( datetime.now(timezone.utc) + timedelta(minutes =15)).timestamp())

        cursor.execute("""
            INSERT INTO password_resets(userid, code_hash, expires_at)
            VALUES (?, ?, ?)
            """, (user["userid"], code_hash, expires_at))

        reset_id  = cursor.lastrowid
        connection.commit()

        if not recovery_email(email, recovery_code):

            cursor.execute ("""
            DELETE FROM password_resets
            WHERE reset_id =?""",
            (reset_id,)
            )

            connection.commit()

            return jsonify({
                "success": False,
                "message": "Unable to send the email please check details"
            }), 500

        return jsonify({
            "success": True,
            "message": "Sending the recovery code to email"
        }), 200

    except Exception as error:
        connection.rollback()
        print(f"Password recovery error {error}")

        return jsonify({
            "success": False,
            "message": "unable to prcoess your request."
        }), 500

    
    finally:
        connection.close()

@app.route("/tablescout/pages/verify-recovery-code", methods =["POST"])
def verify_recovery_code():
    info = request.get_json(silent=True) or {}

    email = info.get("email")
    recovery_code = info.get("code")

    if (
        not isinstance(email, str)
        or not email.strip()
        or not isinstance(recovery_code, str)
        or not recovery_code.isdigit()
        or len(recovery_code) !=6
    ):
        return jsonify({
            "success": False,
            "message": "pelase enter a valid code"
        }), 400
    email = email.strip().lower()
    connection =Dbconnect.connect()

    try:
        cursor = connection.cursor()

        cursor.execute("""
        SELECT
            password_resets.reset_id,
            password_resets.userid,
            password_resets.code_hash,
            password_resets.expires_at
        FROM password_resets
        INNER JOIN users
          ON password_resets.userid = users.userid
        Where users.email =?
        AND users.accstatus = 'ACTIVE'
        AND password_resets.used = 0
        ORDER BY password_resets.reset_id DESC
        LIMIT 1  """, (email,))
        reset = cursor.fetchone()

        if reset is None: 
            return jsonify({
                "success": False,
                "message": "Invalid or expired code"
            }
        ),400
        current_time =int(datetime.now(timezone.utc).timestamp())

        if reset["expires_at"] <= current_time:

            cursor.execute("""
            UPDATE password_resets
            SET used = 1
            WHERE reset_id =?""", (reset["reset_id"],))

            connection.commit()

            return jsonify({
                "success": False,
                "message": "recovery code has expired, please go back through the process"
            }), 400

        try:
            hasher.verify(reset["code_hash"], recovery_code)

        except (VerificationError, InvalidHashError):
            return jsonify({
                "success": False,
                "message": "invalid or expired recovery code."
            }), 400
        timenow = datetime.now(timezone.utc)

        payload = {
            "sub": str(reset["userid"]),
            "reset_id": reset["reset_id"],
            "purpose": "password_reset",
            "iat": timenow,
            "exp": timenow + timedelta(minutes = 10)
        }

        reset_token = jwt.encode(
            payload,
            SECRET_KEY,
            algorithm="HS256"
        )

        return jsonify({
            "success": True,
            "message": "Code verified, Proceeding",
            "reset_token": reset_token
        }), 200

    except Exception as error:
        connection.rollback()
        print(f"Recovery verification error: {error}")

        return jsonify({
           "success": False,
            "message": "Cant verify the code please try again",
        }), 500

    finally: 
        connection.close()
        

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000, debug=True)
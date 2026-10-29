
import re
import sqlite3

from flask import Blueprint, jsonify, request
from argon2 import PasswordHasher
from argon2.exceptions import VerificationError, InvalidHashError

from Dbconnection import Dbconnect

updatedetails_bp = Blueprint("updatedetails", __name__)

hasher = PasswordHasher()

@updatedetails_bp.route(
    "/tablescout/pages/update-account",
    methods=["POST"]
)
def update_account():
    #1. Recieve the submitted details.
    info = request.get_json(silent=True)

    if not isinstance(info, dict):
        return jsonify({
            "error": "Please submit valid account details."
        }), 400

    user_id = info.get("userId")
    current_password = info.get("currentPassword")
    username = info.get("username")
    email = info.get("email")
    phone_number = info.get("phoneNumber", "")

    #2. Validate the types of the submitted values.
    if type(user_id) is not int or user_id <= 0:
        return jsonify({
            "error": "Invalid account details."
        }), 400

    if not all(
        isinstance(value, str)
        for value in [
            current_password,
            username,
            email,
            phone_number
        ]
    ):
        return jsonify({
            "error": "Please check all submitted fields."
        }), 400

    #3. Clean up the text values.
    username = username.strip()
    email = email.strip().lower()
    phone_number = phone_number.strip()

    #4. Validate the username.
    if not username or len(username) > 50:
        return jsonify({
            "error: Username must be between 1 and 50 characters."
        }), 400

    #5. Validate the email addy.
    if len(email) > 254 or not re.fullmatch(
        r"[^@\s]+@[^@\s]+\.[^@\s]+",
        email
    ):
        return jsonify({
            "error": "Please enter a valid email address."
        }), 400

    #6. Validate the optional Phone Number.
    if len(phone_number) > 40:
        return jsonify({
            "error": "Phone number is too long."
        }), 400

    connection = None

    try:
        #7. Connect to the existing SQL DB
        connection = Dbconnect.connect()

        user = connection.execute(
            """
            SELECT userid, pwhash, accstatus
            FROM users
            WHERE userid = ?
            """,
            (user_id,)
        ).fetchone()

        if user is None:
            return jsonify({
                "error": "Account not found."
            }), 404

        #8. Verify the users current password
        try:
            hasher.verify(
                user["pwhash"],
                current_password
            )
        except (VerificationError, InvalidHashError):
            return jsonify({
                "error": "Current password is incorrect."
            }), 401

        #9. Only allow active accounts to be updated.
        if user["accstatus"] != "ACTIVE":
            return jsonify({
                "error": "This account cannot be updated."
            }), 403

        #10. Update the account inside the database.
        connection.execute(
            """
            UPDATE users
            SET username = ?,
                email = ?,
                phone_number = ?
            WHERE userid = ?
            """,
            (
                username,
                email,
                phone_number or None,
                user_id
            )
        )

        connection.commit()

        #11. Tell Flutter that the update succeeded.
        return jsonify({
            "message": "Account updated successfully.",
            "user": {
                "id": user_id,
                "username": username,
                "email": email,
                "phoneNumber": phone_number
            }
        }), 200

    except sqlite3.IntegrityError:
        if connection is not None:
            connection.rollback()

        return jsonify({
            "error": "That username or email address is already in use."
        }), 409

    except sqlite3.Error:
        if connection is not None:
            connection.rollback()

        return jsonify({
            "error": "Unable to update your account right now."
        }), 500

    finally:
        if connection is not None:
            connection.close()
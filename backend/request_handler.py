
import asyncio
import json
import sqlite3

from signup_handler import handle_signup
from contact_handler import handle_contact
from database.jwt_auth import token_verify
from contextlib import closing
from database.Dbconnection import Dbconnect

from event_page_handler import (
    create_event,
    create_game,
    create_format,
    get_events_data,
)

def get_authenticated_user(token):
    payload = token_verify(token)

    if payload is None:
        return None

    user_id = payload.get("sub")

    if not user_id:
        return None
    with closing(Dbconnect.connect()) as connection:
        user = connection.execute(
"""
SELECT userid, store_id, accstatus
FROM users
WHERE userid = ?
""",
(user_id,),
        ).fetchone()

    if user is None:
        return None

    if user["accstatus"] != "ACTIVE":
        return None

    if user["store_id"] is None:
        return None

    return {
        "user_id": user["userid"],
        "store_id": user["store_id"],
    }

async def handle_request(message, session):
    try:
        data = json.loads(message)
    except (ValueError, UnicodeDecodeError):
        return {
            "type": "error",
            "message": "Send a valid JSON object."
        }

    if not isinstance(data, dict):
        return {
            "type": "error",
            "message": "Request must be a JSON object."
        }

    request_type = data.get("type")
    request_id = data.get("request_id")

    def error_response(message):
        return {
            "type": "error",
            "request_id": request_id,
            "message": message,
        }
    if request_type =="token_verify":
        token = data.get("token")

        if not isinstance(token, str) or not token:
            return error_response("JWT is missing.")

        user = await asyncio.to_thread(
            get_authenticated_user,
            token,
        )

        if user is None:
            session["user_id"] = None
            session["store_id"] = None

            return {
                "type": "verified_token",
                "request_id": request_id,
                "valid": False,
            }

        session["user_id"] = user["user_id"]
        session["store_id"] = user["store_id"]

        return {
            "type": "verified_token",
            "request_id": request_id,
            "valid": True,
            "user_id": user["user_id"],
        }
      
    if request_type in (
        "signup",
        "contact"
    ):
        if request_type == "signup":
            return await handle_signup(data)
        if request_type == "contact":
            try:
                return await handle_contact(data)
            except Exception as error:
                print(f"Error handling contact request: {error}")
                return {
                    "type": "error",
                    "success": False,
                    "message": "An error occurred while processing the contact request."
                }

    store_id = session.get("store_id")

    if store_id is None:
        return error_response(
            "Authentication required. Please log in again."
        )

    if request_type not in (
        "get_events_data",
        "create_game",
        "create_format",
        "create_event"   
    ):
        return {
            "type": "error",
            "message": f"Unknown request type: {request_type}",
        }

    try:
        if request_type == "create_event":
            event_id = await asyncio.to_thread(
                create_event,
                data,
                store_id,
            )

            return {
                "type": "event_created",
                "request_id": request_id,
                "event_id": event_id
            }

        # Handle signup requests
        
        
        # Handle game and format creation
        if request_type in ("create_game", "create_format"):
            name = data.get("name")
            name_short = data.get("name_short")

            if not isinstance(name, str) or not name.strip():
                raise ValueError("Name is required.")

            if not isinstance(name_short, str) or not name_short.strip():
                raise ValueError("Short name is required.")

            if request_type == "create_game":
                await asyncio.to_thread(
                    create_game,
                    name,
                    name_short,
                )

            elif request_type == "create_format":
                game_id = data.get("game_id")

                if type(game_id) is not int or game_id <= 0:
                    raise ValueError("Select a valid game.")

                await asyncio.to_thread(
                    create_format,
                    game_id,
                    name,
                    name_short,
                )

        # Return event data for event-related requests
        return await asyncio.to_thread(
            get_events_data, 
            store_id,
        )

    except ValueError as error:
        return error_response(str(error))

    except sqlite3.IntegrityError as error:
        print(f"Database constraint error during {request_type}: {error}")

        if request_type == "create_event":
            return error_response(
                "Unable to save the event. Check selected game and format, then try again."
            )

        return error_response(
            "Unable to create item. A name or short name may already exist, or the selected game no longer exists"
        )

    except sqlite3.Error as error:
        print(f"Database error during {request_type}: {error}")

        return error_response(
            "Unable to complete the database request"
        )


import asyncio
import json
import sqlite3

from signup_handler import handle_signup
from contact_handler import handle_contact

from event_page_handler import (
    create_game,
    create_format,
    get_events_data,
)


async def handle_request(message):
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

    if request_type not in (
        "get_events_data",
        "create_game",
        "create_format",
        "signup",
        "contact",
    ):
        return {
            "type": "error",
            "message": f"Unknown request type: {request_type}",
        }

    try:
        # Handle signup requests
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
        return await asyncio.to_thread(get_events_data)

    except ValueError as error:
        return {
            "type": "error",
            "message": str(error),
        }

    except sqlite3.IntegrityError as error:
        print(f"Database constraint error: {error}")

        return {
            "type": "error",
            "message": (
                "Unable to create item. A name or short name may "
                "already exist, or the selected game no longer exists."
            ),
        }

    except sqlite3.Error as error:
        print(f"Database error during {request_type}: {error}")

        return {
            "type": "error",
            "message": "Unable to complete the database request."
        }

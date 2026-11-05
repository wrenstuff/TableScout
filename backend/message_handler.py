
import json

from signup_handler import handle_signup


async def handle_message(websocket, message):
    # Convert the incoming JSON message into a Python dictionary.
    try:
        data = json.loads(message)

    except (json.JSONDecodeError, TypeError):
        return {
            "type": "error",
            "message": "Invalid JSON message."
        }

    # Check that the incoming data is a dictionary.
    if not isinstance(data, dict):
        return {
            "type": "error",
            "message": "Message must be a JSON object."
        }

    # Identify what the client is requesting.
    request_type = data.get("type")

    # Handle signup requests.
    if request_type == "signup":
        return await handle_signup(data)

    # Handle unknown requests.
    return {
        "type": "error",
        "message": "Unknown request type."
    }

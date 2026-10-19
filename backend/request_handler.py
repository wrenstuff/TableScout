import asyncio
import json
import sqlite3

from event_page_handler import get_events_data


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
            "message": "Request mst be a JSON object."
        }

    request_type = data.get("type")

    if request_type == "get_events_data":
        try:
            return await asyncio.to_thread(get_events_data)
        except sqlite3.Error as error:
            print(f"Failed to read event data: {error}")

            return {
                "type": "error",
                "message": "Unable to load event data"
            }

    return {
        "type": "error",
        "message": f"Unknown request type: {request_type}"
    }
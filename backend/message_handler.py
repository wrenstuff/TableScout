import json

from signup_handler import handle_signup, send_response


async def handle_message(websocket, message):
    try:
        # Converting incoming JSON into a Python dictionary
        data = json.loads(message)

        if not isinstance(data, dict):
            await send_response(
                websocket,
                success=False,
                error="Message must be a JSON object."
            )
            return
        
        # Identifing what client will be doing
        request_type = data.get("type")

        # - Signup
        if request_type == "signup":
            await handle_signup(websocket, data)

        else:
            await send_response(
                websocket,
                success=False,
                error="Unknown request type."
            )

    except json.JSONDecodeError:
        await send_response(
            websocket,
            success=False,
            error="Invalid JSON message."
        )
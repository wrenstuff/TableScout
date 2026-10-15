import asyncio
import json

from websockets.asyncio.server import serve
from signup_handler import handle_signup, send_response

async def handle_connection(websocket):
    print("Flutter Connected")

    async for message in websocket:
        try:
            # Converting incoming JSON into a Python dictionary
            data = json.loads(message)

            if not isinstance(data, dict):
                await send_response(
                    websocket,
                    success=False,
                    error="Message must be a JSON object."
                )
                continue

            # Identifing what client will be doing - Signup
            request_type = data.get("type")

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


async def main():
    async with serve(
        handle_connection,
          "127.0.0.1",
            8765
        ) as server:
        print("Server running as ws://127.0.0.1:8765")
        await server.serve_forever()

asyncio.run(main())
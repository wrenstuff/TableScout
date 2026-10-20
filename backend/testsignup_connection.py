import asyncio
import json

from websockets.asyncio.client import connect


async def main():
    async with connect("ws://127.0.0.1:8765") as websocket:
        signup_request = {
            "type": "signup",
            "username": "websocket_test_user",
            "store_name": "WebSocket Test Store",
            "email": "websocket_test@example.com",
            "password": "TestPassword123!"
        }

        await websocket.send(json.dumps(signup_request))

        response = await websocket.recv()
        print("Server response:")
        print(json.dumps(json.loads(response), indent=2))


asyncio.run(main())

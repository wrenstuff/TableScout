import asyncio
import json

from websockets.asyncio.server import serve
from websockets.exceptions import ConnectionClosed

from request_handler import handle_request


from message_handler import handle_message
from request_handler import handle_request


async def handle_connection(websocket):
    print("Flutter Connected")

    try:
        async for message in websocket:
            response = await handle_request(message)
            await websocket.send(json.dumps(response))
    
    except ConnectionClosed:
        pass

    finally:
        print("Flutter disconnected")

async def main():
    async with serve(
        handle_connection,
          "127.0.0.1",
            8765
        ) as server:
        print("Server running as ws://127.0.0.1:8765")
        await server.serve_forever()

if __name__ == "__main__":
    asyncio.run(main())
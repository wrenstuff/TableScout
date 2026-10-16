import asyncio

from websockets.asyncio.server import serve
from message_handler import handle_message

async def handle_connection(websocket):
    print("Flutter Connected")

    async for message in websocket:
        await handle_message(websocket, message)


async def main():
    async with serve(
        handle_connection,
             8765
        ) as server:
        print("Server running as ws://127.0.0.1:8765")
        await server.serve_forever()

asyncio.run(main())
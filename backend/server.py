import asyncio
import json
import logging

from contextlib import suppress

from websockets.asyncio.server import serve
from websockets.exceptions import ConnectionClosed

from events_update import EventsUpdates
from message_handler import handle_message
from request_handler import handle_request

updates = EventsUpdates()


async def handle_connection(websocket):
    print("Flutter Connected")
    updates.add_client(websocket)

    try:
        async for message in websocket:
            response = await handle_request(message)
            await websocket.send(json.dumps(response))
    
    except ConnectionClosed:
        pass

    finally:
        updates.remove_client(websocket)
        print("Flutter disconnected")

async def main():
    async with serve(handle_connection, "0.0.0.0", 8765 ) as server:
        watcher = asyncio.create_task(updates.watch())

        print("WebSocket server listening on port 8765")
        
        try:
            await server.serve_forever()
        finally:
            watcher.cancel()

            with suppress(asyncio.CancelledError):
                await watcher

if __name__ == "__main__":
    logging.basicConfig(level=logging.INFO)
    asyncio.run(main())
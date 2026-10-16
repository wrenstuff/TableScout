import asyncio
import json

from websockets.asyncio.server import serve
from websockets.exceptions import ConnectionClosed

async def handle_connection(websocket):
    print("Flutter Connected")

    try:
        async for message in websocket:
            print(f"Received: {message}")
            await websocket.send(f"Server Recieved: {message}")
    
    except ConnectionClosed:
        pass

    finally:
        print("Flutter disconnected")

async def main():
    async with serve(handle_connection, "127.0.0.1", 8765) as server:
        print("Server running as ws://127.0.0.1:8765")
        await server.serve_forever()

if __name__ == "__main__":
    asyncio.run(main())
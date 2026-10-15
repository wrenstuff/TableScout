import asyncio
import json
import sqlite3

from websockets.asyncio.server import serve
from database.Signup import create_store_owner

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


async def handle_signup(websocket, data):
    # Reads all required data for signup - not emailver or accstatus as preset
    username = data.get("username")
    store_name = data.get("store_name")
    email = data.get("email")
    password = data.get("password")

    # Check that all required fields are present and are strings.
    fields = [username, store_name, email, password]

    if not all(isinstance(field, str) for field in fields):
        await send_response(
            websocket,
            success=False,
            error="All signup fields are required."
        )
        return

    # Basic validation before accessing the database.
    if not all(field.strip() for field in fields):
        await send_response(
            websocket,
            success=False,
            error="Signup fields cannot be empty."
        )
        return

    try:
        # Run the database operation without blocking the
        # WebSocket event loop while Argon2 hashes the password 
        result = await asyncio.to_thread(
            create_store_owner,
            username,
            store_name,
            email,
            False,
            password
        )

        await send_response(
            websocket,
            success=True,
            message="Signup successful.",
            store_id=result["store_id"]
        )

    except sqlite3.IntegrityError:
        # The username, email, or store name
        # may already exist.
        await send_response(
            websocket,
            success=False,
            error="That username, email, or store name may already be in use."
        )

    except Exception as error:
        print(f"Signup failed: {type(error).__name__}: {error}")

        await send_response(
        websocket,
        success=False,
        error="Signup could not be completed. Please try again."
    )


async def send_response(websocket, **response):
    await websocket.send(json.dumps(response))

async def main():
    async with serve(
        handle_connection,
          "127.0.0.1",
            8765
        ) as server:
        print("Server running as ws://127.0.0.1:8765")
        await server.serve_forever()

asyncio.run(main())
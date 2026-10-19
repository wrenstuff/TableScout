import asyncio
import json
import sqlite3

from database.Signup import create_store_owner

async def send_response(websocket, **response):
    await websocket.send(json.dumps(response))

async def handle_signup(websocket, data):
    username = data.get("username")
    store_name = data.get("store_name")
    email = data.get("email")
    password = data.get("password")

    fields = [username, store_name, email, password]

    if not all(isinstance(field,str) for field in fields):
        await send_response(
            websocket,
            success=False,
            error="Signup fields cannot be empty."
        )
        return
    
    try:
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
        await send_response(
            websocket,
            success=False,
            error="That username, email, or store name may already be in use."
        )

    except Exception:
        print("Signup failed due to an internal server error.")

        await send_response(
            websocket,
            success=False,
            error="Signup could not be completed. Please try again."
        )
import asyncio
import json
import sqlite3

from database.Signup import create_store_owner


async def handle_signup(data):
    username = data.get("username")
    store_name = data.get("store_name")
    email = data.get("email")
    password = data.get("password")

    fields = [username, store_name, email, password]

    if not all(isinstance(field, str) and field.strip() for field in fields):
        return {
            "type": "error",
            "message": "All fields (username, store_name, email, password) are required."
        }
    
    try:
        result = await asyncio.to_thread(
            create_store_owner,
            username,
            store_name,
            email,
            False,
            password
        )

        return {
            "type": "signup_response",
            "success": result["success"],
            "store_id": result.get("store_id")
        }

    except sqlite3.IntegrityError:
        return {
            "type": "error",
            "message": "Username or email already exists."
        }

    except Exception:
        print("Signup failed due to an internal server error.")

        return {
            "type": "error",
            "message": "Signup could not be completed. Please try again."
        }
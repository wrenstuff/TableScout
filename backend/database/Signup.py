from Dbconnection import Dbconnect
from argon2 import PasswordHasher

hasher = PasswordHasher()

def create_store_owner(username, store_name, email, emailver, password):
    connection = Dbconnect.connect()

    try:
        #start the transaction
        connection.execute("BEGIN")

        #1. Hash the passowrd before storing
        pwhash = hasher.hash(password)

        #2.Create the store
        store_cursor = connection.execute(
            """
            INSERT INTO stores (store_name, email, emailver, accstatus)
            VALUES (?, ?, ?, ?)
            """,
            (store_name.strip(), email.strip().lower(), emailver, "PENDING")
        )

        #3. Retrieve the stores ID
        store_id = store_cursor.lastrowid

        #4. Create owner account
        connection.execute(
            """
            INSERT INTO users
                (username, email, pwhash, role, accstatus, store_id)
            VALUES (?, ?, ?, ?, ?, ?)
            """,
            (
                username.strip(),
                email.strip().lower(),
                pwhash,
                "STORE",
                "PENDING",
                store_id
            )
        )

        #both inserts succeed, so saves both
        connection.commit()

        return {
            "success": True,
            "store_id": store_id
        }
    except Exception:
        #if either insert fails, transaction cancelled
        connection.rollback()
        raise

    finally:
        connection.close()
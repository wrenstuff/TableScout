from Dbconnection import Dbconnect
from argon2 import PasswordHasher

connection = Dbconnect.connect()

try:
    hasher = PasswordHasher()
    pwhash = hasher.hash("TemporaryTestPassword123!")

    connection.execute(
        """
        INSERT INTO users (
            username, email, pwhash, role, accstatus, store_id
        )
        VALUES (?, ?, ?, ?, ?, ?)
        """,
        (
            "rollback_test_user",
            "rollback_user@example.com",
            pwhash,
            "EMPLOYEE",
            "ACTIVE",
            None
        )
    )

    connection.commit()
    print("Test user created successfully.")

except Exception:
    connection.rollback()
    raise

finally:
    connection.close()
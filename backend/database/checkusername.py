from Dbconnection import Dbconnect

connection = Dbconnect.connect()

try:
    user = connection.execute(
        "SELECT userid, username FROM users WHERE username = ?",
        ("testuser",)
    ).fetchone()

    if user:
        print("Found existing user:", user["username"])
    else:
        print("User does not exist yet.")

finally:
    connection.close()
from Dbconnection import Dbconnect

connection = Dbconnect.connect()

connection.execute("""
INSERT INTO users (
    username,
    email,
    pwhash,
    accstatus,
    role,
    store_id
)
VALUES (?, ?, ?, ?, ?, ?)
""", (
    "testuser",
    "test@example.com",
    "testpasswordhash",
    "ACTIVE",
    "EMPLOYEE",
    1
))
connection.commit()
connection.close()

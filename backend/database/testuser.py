from connection import dbconnect

connection = dbconnect()

connection.execute("""
INSERT INTO users (
    username,
    email,
    pwhash,
    accstatus,
    role,
    roleid,
    store_id
)
VALUES (?, ?, ?, ?, ?, ?, ?)
""", (
    "testuser",
    "test@example.com",
    "testpasswordhash",
    "ACTIVE",
    "EMPLOYEE",
    101,
    1
))
connection.commit()
connection.close()

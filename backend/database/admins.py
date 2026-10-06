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
    "Wren",
    "wren@example.com",
    "elspeth",
    "ACTIVE",
    "ADMIN",
    1
)
)

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
    "Cody",
    "Cody@example.com",
    "bob",
    "ACTIVE",
    "ADMIN",
    1
)
)

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
    "Jack",
    "Jack@example.com",
    "mybums",
    "ACTIVE",
    "ADMIN",
    1
)
)
connection.commit()
connection.close()
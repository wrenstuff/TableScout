from Dbconnection import Dbconnect
from argon2 import PasswordHasher

hasher = PasswordHasher()

connection = Dbconnect.connect()

password ="elspeth"
pwhash =hasher.hash(password)

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
    pwhash,
    "ACTIVE",
    "ADMIN",
    1
)
)

password ="bob"
pwhash =hasher.hash(password)
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
    pwhash,
    "ACTIVE",
    "ADMIN",
    1
)
)
password ="mybums"
pwhash =hasher.hash(password)
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
    pwhash,
    "ACTIVE",
    "ADMIN",
    1
)
)
connection.commit()
connection.close()
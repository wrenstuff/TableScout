import sqlite3

DATABASE = "users.db"
def dbconnect():
    connection =sqlite3.connect(DATABASE)
    connection.row_factory =sqlite3.Row
    connection.execute("PRAGMA foreign_keys = ON")
    return connection
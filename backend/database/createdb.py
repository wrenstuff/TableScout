from connection import dbconnect

connection = dbconnect()

#users
connection.execute(
    """
CREATE TABLE IF NOT EXISTS users (
    userid INTEGER PRIMARY KEY AUTOINCREMENT,
    username TEXT UNIQUE NOT NULL,
    email TEXT UNIQUE NOT NULL,
    pwhash TEXT NOT NULL,
    role TEXT NOT NULL,
    accstatus TEXT NOT NULL DEFAULT 'ACTIVE',
    createdat TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
    store_id INTEGER,
    
    FOREIGN KEY (store_id)
        REFERENCES stores(store_id)
)
"""
)

#stores
connection.execute(
    """
CREATE TABLE IF NOT EXISTS stores (
    store_id INTEGER PRIMARY KEY AUTOINCREMENT,
    store_name TEXT UNIQUE NOT NULL,
    email TEXT UNIQUE NOT  NULL,
    accstatus TEXT NOT NULL DEFAULT 'ACTIVE'
)
"""
)

#events
connection.execute(
    """
CREATE TABLE IF NOT EXISTS events (
table_id INTEGER PRIMARY KEY AUTOINCREMENT
)
"""
)


#tables
connection.execute(
    """
CREATE TABLE IF NOT EXISTS tables (
event_id INTEGER PRIMARY KEY AUTOINCREMENT
)
"""
)

connection.commit()
connection.close()
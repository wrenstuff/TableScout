from Dbconnection import Dbconnect

connection = Dbconnect.connect()

#stores
connection.execute(
    """
CREATE TABLE IF NOT EXISTS stores (
    store_id INTEGER PRIMARY KEY AUTOINCREMENT,
    store_name TEXT UNIQUE NOT NULL,
    email TEXT UNIQUE NOT  NULL,
    emailver TEXT NOT NULL DEFAULT 'FALSE',
    accstatus TEXT NOT NULL DEFAULT 'ACTIVE'
)
"""
)


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

connection.execute(
    """
CREATE TABLE IF NOT EXISTS games (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    name TEXT NOT NULL COLLATE NOCASE UNIQUE
);
"""
)

connection.execute(
    """
CREATE TABLE IF NOT EXISTS formats (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    game_id INTEGER NOT NULL,
    name TEXT NOT NULL COLLATE NOCASE,
    FOREIGN KEY (game_id) REFERENCES games(id),
    UNIQUE (game_id, name)
);
"""
)

#events
connection.execute(
    """
CREATE TABLE IF NOT EXISTS events (
    event_id INTEGER PRIMARY KEY AUTOINCREMENT
)
"""
)


#tables
connection.execute(
    """
CREATE TABLE IF NOT EXISTS tables (
    table_id INTEGER PRIMARY KEY AUTOINCREMENT
)
"""
)

connection.commit()
connection.close()
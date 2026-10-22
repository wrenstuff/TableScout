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

connection.executescript("""
CREATE TABLE IF NOT EXISTS games (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    name TEXT NOT NULL COLLATE NOCASE UNIQUE,
    name_short TEXT NOT NULL COLLATE NOCASE UNIQUE
);

CREATE TABLE IF NOT EXISTS formats (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    game_id INTEGER NOT NULL,
    name TEXT NOT NULL COLLATE NOCASE,
    name_short TEXT NOT NULL COLLATE NOCASE UNIQUE,
    FOREIGN KEY (game_id) REFERENCES games(id),
    UNIQUE (game_id, name)
);

CREATE TABLE IF NOT EXISTS events (
    event_id INTEGER PRIMARY KEY AUTOINCREMENT,
    game_id INTEGER REFERENCES games(id),
    format_id INTEGER REFERENCES formats(id),
    name TEXT,
    description TEXT,
    date TEXT,
    start_time TEXT,
    end_time TEXT,
    rounds INTEGER DEFAULT 0,
    current_round INTEGER DEFAULT 0,
    current_round_end_time TEXT,
    participants TEXT DEFAULT '[]',
    tables TEXT DEFAULT '[]',
    status TEXT DEFAULT 'not_started',
    standings TEXT DEFAULT '[]',
    bracket TEXT DEFAULT '[]'
);
    """)

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
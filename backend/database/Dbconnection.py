import sqlite3
from pathlib import Path


class Dbconnect:
    DATABASE = Path(__file__).resolve().parent / "Tablescout.db"

    @staticmethod
    def connect():
        connection = sqlite3.connect(Dbconnect.DATABASE)
        connection.row_factory = sqlite3.Row
        connection.execute("PRAGMA foreign_keys = ON")
        return connection
    @staticmethod
    def initialize():
        connection =Dbconnect.connect()
        try: 
            connection.execute("""
        Create TABLE IF NOT EXISTS password_resets(
        reset_id INTEGER PRIMARY KEY AUTOINCREMENT,
        userid INTEGER NOT NULL,
        code_hash TEXT NOT NULL,
        expires_at INTEGER NOT NULL,
        used INTEGER NOT NULL DEFAULT 0,
        FOREIGN KEY(userid)
            REFERENCES users(usersid)
            ON DELETE CASCADE
                               ) """)
            connection.execute("""
            CREATE INDEX IF NOT idx_password_resets_userid
            ON password_resets(userid)""")
            connection.commit()

            print("Password table created"
            )
        finally:
            connection.close()
if __name__ == "__main__":
    connection = Dbconnect.connect()
    try:
        print(f"Database path: {Dbconnect.DATABASE}")
        print(f"File exists: {Dbconnect.DATABASE.is_file()}")
    finally:
        connection.close()
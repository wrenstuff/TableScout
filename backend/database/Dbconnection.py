import sqlite3
from pathlib import Path

#connection for all dbs
class Dbconnect():
    # Resolve the database file relative to this Python file.
    DATABASE = Path(__file__).resolve().parent / "Tablescout.db"

    @staticmethod
    def connect():
        connection = sqlite3.connect(Dbconnect.DATABASE)
        connection.row_factory = sqlite3.Row

        #Enable foreign key enforcement for this connection
        connection.execute("PRAGMA foreign_keys = ON")

        return connection
    
#user db connection

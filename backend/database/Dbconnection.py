import sqlite3
from pathlib import Path


class Dbconnect:
    DATABASE = Path(__file__).resolve().parent / "Tablescout.db"

    @staticmethod
    def connect():
        if not Dbconnect.DATABASE.is_file():
            raise FileNotFoundError(
                f"Database not found: {Dbconnect.DATABASE}"
            )
        
        connection = sqlite3.connect(Dbconnect.DATABASE)
        connection.row_factory = sqlite3.Row
        connection.execute("PRAGMA foreign_keys = ON")
        return connection

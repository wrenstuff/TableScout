import sqlite3

#connection for all dbs
class Dbconnect():
    DATABASE ="Tablescout.db"

    @staticmethod
    def connect():
        connection = sqlite3.connect(Dbconnect.DATABASE)
        connection.row_factory = sqlite3.Row
        return connection
#user db connection

import sqlite3
from backend.database import users

#connection for all dbs

#user db connection
def db_user_conn():

    connection = sqlite3.connect(users.db)

    connection.row_factory = sqlite3.Row
    return connection
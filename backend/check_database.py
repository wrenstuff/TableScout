from database.Dbconnection import Dbconnect

connection = Dbconnect.connect()

try:
    print("Database path:", Dbconnect.DATABASE)

    query = """
        SELECT name
        FROM sqlite_master
        WHERE type = 'table'
        ORDER BY name
    """

    tables = connection.execute(query).fetchall()

    print("Tables found:")
    for table in tables:
        print(f"- {table['name']}")

finally:
    connection.close()
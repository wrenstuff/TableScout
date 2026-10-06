from Dbconnection import Dbconnect

connection = Dbconnect.connect()

connection.execute("""
    INSERT INTO stores (
        store_name,
        email,
        accstatus
    )
    VALUES (?, ?, ?)
""", (
    "Test Hobby Store",
    "store@test.com",
    "ACTIVE"
))

connection.commit()
connection.close()
from Dbconnection import Dbconnect

connection = Dbconnect.connect()

connection.execute("""
    INSERT INTO stores (
        store_name,
        email,
        emailver,
        accstatus
    )
    VALUES (?, ?, ?, ?)
""", (
    "Test Hobby Store",
    "store@test.com",
    "PENDING",
    "INACTIVE"
))

connection.commit()
connection.close()
import sqlite3

from Dbconnection import Dbconnect
from Signup import create_store_owner

#This username must already exist in 'users'
duplicate_username = "rollback_test_user"

#Unique store details for this test
store_name = "Rollback Test Store"
email = "rollback_test@example.com"
emailver = False
password = "TestPassword456!"

connection = Dbconnect.connect()

try:
    #Ensure the duplicate username exists
    existing_user = connection.execute(
        "SELECT userid FROM users WHERE username = ?",
        (duplicate_username,)
    ).fetchone()

    if existing_user is None:
        raise RuntimeError(
            "Create a user named rollback_test_user first"
        )

    #Check whether this test email already exists
    existing_store = connection.execute(
        "SELECT store_id FROM stores WHERE email = ?",
        (email,)
    ).fetchone()

    if existing_store is not None:
        raise RuntimeError(
            "Change the test email before re-running"
        )

finally:
    connection.close()

#Sugnup should fail because the username is duplicated
try:
    create_store_owner(
        duplicate_username,
        store_name,
        email,
        emailver,
        password
    )
except sqlite3.IntegrityError as error:
    if "users.username" not in str(error):
        raise

    print("PASS: Duplicate username caused an insert failure.")
    
else:
    raise AssertionError("Signup should have failed.")

#Check store insert was rolled back
connection = Dbconnect.connect()

try:
    store = connection.execute(
        "SELECT store_id FROM stores WHERE email = ?",
        (email,)
    ).fetchone()

    assert store is None, "Store was NOT rolled back?!?!?"

    print("PASS: Store insert was rolled back.")

finally:
    connection.close()
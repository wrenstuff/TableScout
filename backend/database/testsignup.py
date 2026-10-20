from Dbconnection import Dbconnect
from Signup import create_store_owner
from argon2 import PasswordHasher
from uuid import uuid4

#Genrate unique test details for each run
test_id = uuid4().hex[:8]

username = f"signup_test_{test_id}"
store_name = f"Signup Test Store {test_id}"
email = f"signup_{test_id}@example.com"
emailver = "FALSE"
password = "TestPassword123!"

#1. Call the acutal signup function
result = create_store_owner(
    username,
    store_name,
    email,
    emailver,
    password
)

print ("Signup result", result)

#2. read the saved records from database
connection = Dbconnect.connect()

try:
    user = connection.execute(
        "SELECT * FROM users WHERE email = ?",
        (email,)
    ).fetchone()

    store = connection.execute(
        "SELECT * FROM stores WHERE store_id = ?",
        (result["store_id"],)
    ).fetchone()

    #3. Check the results
    assert result["success"] is True, "Signup failed"
    assert user is not None, "User was not saved"
    assert store is not None, "Store was not saved"
    
    assert user["store_id"] == store["store_id"], \
        "User is linked to the wrong store"
    
    assert user["role"] == "STORE", "Incorrect user role"
    assert user["accstatus"] == "PENDING", \
        "Incorrect user account status"
    
    assert store["accstatus"] == "PENDING", \
        "Incorrect store account"
    
    #4. Verify the stored password
    hasher = PasswordHasher()
    assert hasher.verify(user["pwhash"], password), \
        "Password hash verification failed"
    
    assert user["pwhash"] != password, \
        "Plain-text password was stored!"
    
    print("PASS: User and store were created.")
    print("PASS: User is linked to the correct store.")
    print("PASS: Password was hashed and verified.")
    print("PASS: Account and store statuses are correct.")

finally:
    connection.close()
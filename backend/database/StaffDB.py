import sqlite3
from Dbconnection import Dbconnect

class StaffDB:

    @staticmethod
    def get_staff_by_id(staff_id):

        connection = Dbconnect.connect()

        try:
            cursor = connection.execute(
                """
                SELECT
                userid,
                username,
                email,
                phone_number,
                role,
                accstatus,
                createdat
                FROM staff
                WHERE userid = ?
                ORDER BY 
                 CASE role
                    WHEN 'Manager' THEN 1
                    WHEN 'Supervisor' THEN 2
                    WHEN 'Employee' THEN 3
                    ELSE 4
                END
                username COLLATE NOCASE
                """,
                (staff_id,)
            )

            staff = cursor.fetchall()

            return [dict(employee) for employee in staff]

        except sqlite3.Error as e:
            print(f"Error retrieving staff by ID: {e}")
            return None

        finally:
            connection.close()

    @staticmethod
    def update_staff(
        userid,
        store_id,
        username,
        email,
        phone_number,
        role,
        accstatus
    ):
        if role not in ['STAFF', 'SUPERVISOR']:
            return{
                "success": False,
                "message": "Invalid role. Role must be either 'STAFF' or 'SUPERVISOR'."
            }

        if not username or not username.strip():
            return {
                "success": False,
                "message": "Username cannot be empty."
            }

        if not email or not email.strip() or '@' not in email:
            return {
                "success": False,
                "message": "Invalid email address."
            } 

        connection = Dbconnect.connect()

        try:
            employee = connection.execute(
                """
                SELECT userid, role
                FROM users
                WHERE userid = ?
                and store_id = ?
                """,
                (userid, store_id)
            ).fetchone()

            if employee is None:
                return {
                    "success": False,
                    "message": "Staff member not found."
                }

            if employee['role'] in ("MANAGER", "ADMIN"):
                return {
                    "success": False,
                    "message": "Cannot downgrade a SUPERVISOR to STAFF."
                }

            connection.execute(
                """
                UPDATE users
                SET username = ?,
                    email = ?,
                    phone_number = ?,
                    role = ?,
                    accstatus = ?
                WHERE userid = ?
                """,
                (username.strip(), 
                 email.strip(), 
                 phone_number.strip(), 
                 role, accstatus, 
                 userid,
                 store_id
                 )
            )

            connection.commit()
            return {
                "success": True,
                "message": "Staff member updated successfully."
            }

        except sqlite3.Error as e:
            print(f"Error updating staff member: {e}")
            return {
                "success": False,
                "message": "An error occurred while updating the staff member."
            }
        finally:
            connection.close()
        

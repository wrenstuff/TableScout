import json
import sqlite3

from contextlib import closing
from database.Dbconnection import Dbconnect


def get_floor_plan(store_id):
    with closing(Dbconnect.connect()) as connection:
        row = connection.execute(
            """
            SELECT layout_json
            FROM floor_plans
            WHERE store_id = ?
            """,
            (store_id,),
        ).fetchone()

    if row is None:
        return None

    try:
        return json.loads(row["layout_json"])
    except (ValueError, TypeError):
        raise ValueError("The saved floor plan contains invlaid data.")



def save_floor_plan(store_id, layout):
    if not isinstance(layout, dict):
        raise ValueError("Invalid floor plan data")

    if not isinstance(layout.get("objects"), list):
        raise ValueError("Floor plan objects must be a list.")

    layout_json = json.dumps(layout)

    with closing(Dbconnect.connect()) as connection:
        connection.execute(
            """
            INSERT INTO floor_plans (store_id, layout_json)
            VALUES (?, ?)
            ON CONFLICT(store_id)
            DO UPDATE SET
                layout_json = excluded.layout_json,
                updated_at = CURRENT_TIMESTAMP
            """,
            (store_id, layout_json),
        )

        connection.commit()

    return True
import json

from contextlib import closing
from database.Dbconnection import Dbconnect

def create_game(name, name_short):
    name = name.strip()
    name_short = name_short.strip()

    if not name:
        raise ValueError("Game name is required.")

    if not name_short:
        raise ValueError("Game short name is required.")

    with closing(Dbconnect.connect()) as connection:
        with connection:
            cursor = connection.execute(
                "INSERT INTO games (name, name_short) VALUES (?, ?)",
                (name, name_short),
            )

            return {
                "id": cursor.lastrowid,
                "name": name,
                "name_short": name_short,
            }

def create_format(game_id, name, name_short):
    name = name.strip()
    name_short = name_short.strip()

    if not name:
        raise ValueError("Format name is required.")

    if not name_short:
        raise ValueError("Format short name is required.")

    with closing(Dbconnect.connect()) as connection:
        connection.execute("PRAGMA foreign_keys = ON")

        with connection:
            cursor = connection.execute(
                "INSERT INTO formats (game_id, name, name_short) VALUES (?, ?, ?)",
                (game_id, name, name_short),
            )

            return {
                "id": cursor.lastrowid,
                "game_id": game_id,
                "name": name,
                "name_short": name_short
            }

def get_events_data():
    with closing(Dbconnect.connect()) as connection:
        for row in connection.execute("PRAGMA database_list"):
            print("Database path:", row["file"])
        games = connection.execute(
"""
SELECT id, name, name_short
FROM games
ORDER BY name
"""
        ).fetchall()

        formats = connection.execute(
"""
SELECT id, game_id, name, name_short
FROM formats
ORDER BY name
"""
        ).fetchall()

        events = connection.execute(
"""
SELECT *
FROM events
ORDER BY date, start_time
"""
        ).fetchall()

    games = [dict(row) for row in games]
    formats = [dict(row) for row in formats]
    events = [dict(row) for row in events]

    for event in events:
        for field in ("participants", "tables", "standings", "bracket"):
            value = event.get(field)
            event[field] = json.loads(value) if value else []

    return {
        "type": "events_data",
        "games": games,
        "formats": formats,
        "events": events,
    }

if __name__ == "__main__":
    data = get_events_data()

    print(f"Games: {len(data['games'])}")
    print(f"Formats: {len(data['formats'])}")
    print(f"Events: {len(data['events'])}")

    print(json.dumps(data, indent=2))
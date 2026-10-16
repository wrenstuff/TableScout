import json

from contextlib import closing
from database.Dbconnection import Dbconnect as dcon

def create_game(name):
    name = name.strip()

    if not name:
        raise ValueError("Game name is required.")

    with closing(dcon.connect()) as connection:
        with connection:
            cursor = connection.excecute(
                "INSERT INTO games (name) VALUES (?)",
                (name,),
            )

            return {
                "id": cursor.lastrowid,
                "name": name,
            }

def create_format(game_id, name):
    name = name.strip()

    if not name:
        raise ValueError("Format name is required.")

    with closing(dcon.connect()) as connection:
        connection.execute("PRAGMA foreign_keys = ON")

        with connection:
            cursor = connection.execute(
                "INSERT INTO formats (game_id, name) VALUES (?, ?)"
                (game_id, name),
            )

            return {
                "id": cursor.lastrowid,
                "game_id": game_id,
                "name": name,
            }

def get_events_data():
    with closing(dcon.connect()) as connection:
        games = connection.execute(
"""
SELECT id, name
FROM games
ORDER BY name
"""
        ).fetchall()

        formats = connection.execute(
"""
SELECT id, game_id, name
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
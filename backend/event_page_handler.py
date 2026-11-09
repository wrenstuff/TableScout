import json

from contextlib import closing
from database.Dbconnection import Dbconnect
from datetime import datetime
from datetime import date, time

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

def get_events_data(store_id):

    if type(store_id) is not int or store_id <= 0:
        raise ValueError("Invalid store.")

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
WHERE store_id = ?
ORDER BY date, start_time
""",
(store_id,),
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

def create_event(data, store_id):
    name = data.get("name")
    description = data.get("description", "")
    game_id = data.get("game_id")
    format_id = data.get("format_id")
    capacity = data.get("capacity")
    rounds = data.get("rounds")

    if type(store_id) is not int or store_id <= 0:
        raise ValueError("Invalid store.")

    if not isinstance(name, str) or not name.strip():
        raise ValueError("Event name is required.")

    if not isinstance(description, str):
        raise ValueError("Description must be text.")

    if type(game_id) is not int or game_id <= 0:
        raise ValueError("Select a valid game.")

    if type(format_id) is not int or format_id <= 0:
        raise ValueError("Select a valid format.")

    if capacity is not None:
        if type(capacity) is not int or capacity <= 0:
            raise ValueError("Capacity must be a whole numberr greater than zero.")

    if type(rounds) is not int or rounds <= 0:
        raise ValueError("Rounds must be a whole number greater than zero.")

    try:
        event_date = date.fromisoformat(data.get("date"))
    except (TypeError, ValueError):
        raise ValueError("Select a valid event date.") from None

    try:
        start_time = time.fromisoformat(data.get("start_time"))
        end_time = time.fromisoformat(data.get("end_time"))
    except (TypeError, ValueError):
        raise ValueError("Select valid start and end times") from None

    if start_time.tzinfo is not None or end_time.tzinfo is not None:
        raise ValueError("Event times must be local times without a timezone.")

    if end_time <= start_time:
        raise ValueError("End time must be after start time.")

    with closing(Dbconnect.connect()) as connection:
        with connection:
            game = connection.execute(
                "SELECT id FROM games WHERE id = ?",
                (game_id,),
            ).fetchone()

            if game is None:
                raise ValueError("The selected game no longer exists.")

            selected_format = connection.execute(
                "SELECT id FROM formats WHERE id = ? AND game_id = ?",
                (format_id, game_id),
            ).fetchone()

            if selected_format is None:
                raise ValueError("The selected format does not belong to this game or no longer exists")

            cursor = connection.execute(
"""
INSERT INTO events (
    store_id,
    game_id,
    format_id,
    name,
    description,
    date,
    start_time,
    end_time,
    capacity,
    rounds
)
VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
""",
                (
                    store_id,
                    game_id,
                    format_id,
                    name.strip(),
                    description.strip(),
                    event_date.isoformat(),
                    start_time.isoformat(timespec = "minutes"),
                    end_time.isoformat(timespec = "minutes"),
                    capacity,
                    rounds,
                ),
            )

            event_id = cursor.lastrowid

    return event_id

if __name__ == "__main__":
    data = get_events_data()

    print(f"Games: {len(data['games'])}")
    print(f"Formats: {len(data['formats'])}")
    print(f"Events: {len(data['events'])}")

    print(json.dumps(data, indent=2))
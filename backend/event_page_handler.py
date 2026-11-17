import json
import random

from contextlib import closing
from database.Dbconnection import Dbconnect
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

def create_format(game_id, name, name_short, play_rec=2):
    name = name.strip()
    name_short = name_short.strip()

    if not name:
        raise ValueError("Format name is required.")

    if not name_short:
        raise ValueError("Format short name is required.")

    if type(play_rec) is not int or play_rec <= 0:
        raise ValueError("Recommended players must be a positive integer.")

    with closing(Dbconnect.connect()) as connection:
        connection.execute("PRAGMA foreign_keys = ON")

        with connection:
            cursor = connection.execute(
                "INSERT INTO formats (game_id, name, name_short, play_rec) VALUES (?, ?, ?, ?)",
                (game_id, name, name_short, play_rec),
            )

            return {
                "id": cursor.lastrowid,
                "game_id": game_id,
                "name": name,
                "name_short": name_short,
                "play_rec": play_rec,
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
            SELECT id, game_id, name, name_short, play_rec
            FROM formats
            ORDER BY name
            """
        ).fetchall()

        print('Requested store ID:', store_id)

        events = connection.execute(
            """
            SELECT *
            FROM events
            WHERE store_id = ?
            ORDER BY date, start_time
            """,
            (store_id,),
        ).fetchall()

        print("Returned event IDs:", [row["event_id"] for row in events])

    games = [dict(row) for row in games]
    formats = [dict(row) for row in formats]
    events = [dict(row) for row in events]

    for event in events:
        for field in (
            "participants",
            "tables",
            "standings",
            "bracket",
            "pairings"
        ):
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

def update_event_player(event_id, player_name, action, store_id):
    
    player_name = player_name.strip()

    if not player_name:
        raise ValueError("Player name cannot be empty")

    if action not in ("add", "remove"):
        raise ValueError("Invalid player action")

    conn = Dbconnect.connect()

    try:
        cursor = conn.cursor()

        cursor.execute(
            """
            SELECT participants
            FROM events
            WHERE event_id = ? AND store_id = ?
            """,
            (event_id, store_id),
        )

        event = cursor.fetchone()

        if event is None:
            raise ValueError("Event not found")

        participants = json.loads(event['participants'] or '[]')

        if action == "add":
            if player_name not in participants:
                participants.append(player_name)

        elif action == "remove":
            if player_name in participants:
                participants.remove(player_name)

        cursor.execute(
            """
            UPDATE events
            SET participants = ?,
                pairings = '[]'
            WHERE event_id = ? AND store_id = ?
            """,
            (json.dumps(participants), event_id, store_id)
        )

        conn.commit()
    finally:
        conn.close()

def generate_pairings(players, play_rec):
    if type(play_rec) is not int or play_rec < 2:
        raise ValueError("Recommenced players must be at least 2.")

    players = list(players)
    random.shuffle(players)

    groups = []
    byes = []
    unassigned = []

    total = len(players)

    if play_rec == 2:
        while len(players) >= 2:
            groups.append(players[:2])
            players = players[2:]

        if players:
            byes.append(players[0])

        return {
            "play_rec": play_rec,
            "groups": groups,
            "byes": byes,
            "unassigned": []
        }

    if total == play_rec + 1:
        return {
            "play_rec": play_rec,
            "groups": [players],
            "byes": [],
            "unassigned": []
        }

    smaller_group = play_rec - 1

    best = (0, 0, 0)

    for recommended_count in range(total // play_rec + 1):
        for smaller_count in range(total // smaller_group + 1):

            assigned = (
                recommended_count * play_rec + smaller_count * smaller_group
            )

            if assigned > total:
                continue

            candidate = (
                assigned,
                recommended_count,
                smaller_count,
            )

            if candidate[:2] > best[:2]:
                best = candidate

    recommended_count = best[1]
    smaller_count = best[2]

    for _ in range(recommended_count):
        groups.append(players[:play_rec])
        players = players[play_rec:]

    for _ in range(smaller_count):
        groups.append(players[:smaller_group])
        players = players[smaller_group:]

    unassigned = players

    return {
        "play_rec": play_rec,
        "groups": groups,
        "byes": byes,
        "unassigned": unassigned
    }

def generate_event_pairings(event_id, store_id):

    if type(event_id) is not int or event_id <= 0:
        raise ValueError("Invalid event.")

    if type(store_id) is not int or store_id <= 0:
        raise ValueError("Invalid store.")

    with closing(Dbconnect.connect()) as conn:

        with conn:

            event = conn.execute(
                """
                SELECT
                    events.event_id,
                    events.participants,
                    formats.play_rec
                FROM events
                JOIN formats
                    ON events.format_id = formats.id
                WHERE events.event_id = ?
                AND events.store_id = ?
                """,
                (event_id, store_id)
            ).fetchone()

            if event is None:
                raise ValueError("Event not found")

            participants = json.loads(event['participants'] or '[]')

            if not isinstance(participants, list):
                raise ValueError("Invalid participant data")

            pairings = generate_pairings(
                participants,
                event["play_rec"]
            )

            conn.execute(
                """
                UPDATE events
                SET pairings = ?
                WHERE event_id = ?
                AND store_id = ?
                """,
                (
                    json.dumps(pairings),
                    event_id,
                    store_id
                )
            )

    return {
        "type": "pairings_generated",
        "event_id": event_id,
        "pairings": pairings
    }

def _update_event_status(event_id, store_id, allowed_statuses, new_status, reset_round=False):

    if type(event_id) is not int or event_id <= 0:
            raise ValueError("Invalid event.")
    
    if type(store_id) is not int or store_id <= 0:
        raise ValueError("Invalid store.")

    conn = Dbconnect.connect()

    try:
        cursor = conn.cursor()

        cursor.execute(
            "SELECT status FROM events WHERE event_id = ? AND store_id = ?",
            (event_id, store_id)
        )

        event = cursor.fetchone()

        if event is None:
            raise ValueError("Event not found.")

        if event["status"] not in allowed_statuses:
            raise ValueError(
                f"Cannot perform this action while event is "
                f"{event['status']}"
            )

        if reset_round:
            cursor.execute(
                """
                UPDATE events
                SET status = ?,
                    current_round = 0,
                    current_round_end_time = NULL
                WHERE event_id = ? AND store_id = ?
                """,
                (new_status, event_id, store_id)
            )
        else:
            cursor.execute(
                """
                UPDATE events
                SET status = ?
                WHERE event_id = ? AND store_id = ?
                """,
                (new_status, event_id, store_id)
            )

        conn.commit()

    except Exception:
        conn.rollback()
        raise

    finally:
        conn.close

def start_event(event_id, store_id):
    _update_event_status(
        event_id,
        store_id,
        ["not_started"],
        "running"
    )

def pause_event(event_id, store_id):
    _update_event_status(
        event_id,
        store_id,
        ["running"],
        "paused"
    )

def resume_event(event_id, store_id):
    _update_event_status(
        event_id,
        store_id,
        ["paused"],
        "running"
    )

def stop_event(event_id, store_id):
    _update_event_status(
        event_id,
        store_id,
        ["running", "paused"],
        "stopped"
    )

def restart_event(event_id, store_id):
    _update_event_status(
        event_id,
        store_id,
        ["stopped"],
        "running",
        reset_round=True
    )

def reset_event(event_id, store_id):
    _update_event_status(
        event_id,
        store_id,
        ['not_started', 'running', 'paused', 'stopped'],
        "not_started",
        reset_round=True
    )

if __name__ == "__main__":
    data = get_events_data()

    print(f"Games: {len(data['games'])}")
    print(f"Formats: {len(data['formats'])}")
    print(f"Events: {len(data['events'])}")

    print(json.dumps(data, indent=2))
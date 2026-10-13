from contextlib import closing
from Dbconnection import Dbconnect as dcon

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

def get_catalogue():
    with closing(dcon.connect()) as connection:
        games = connection.execute(
            "SELECT id, name FROM games ORDER BY name"
        ).fetchall()

        formats = connection.execute(
            "SELECT id, game_id, name FROM formats ORDER BY name"
        ).fetchall()

        return {
            "type": "catalogue",
            "games": [dict(game) for game in games],
            "formats": [dict(format) for format in formats],
        }
import asyncio
import json
import logging

from event_page_handler import get_events_data


logger = logging.getLogger(__name__)

class EventsUpdates:
    def __init__(self):
        self._clients = {}
        self._last_snapshot = {}

    def add_client(self, websocket, session):
        self._clients[websocket] = session

    def remove_client(self, websocket):
        self._clients.pop(websocket, None)

    async def _send(self, websocket, message):
        try:
            await websocket.send(message)
        except Exception:
            self.remove_client(websocket)

    async def watch(self):
        while True:
            try:

                store_clients = {}

                for websocket, session in tuple(self._clients.items()):
                    store_id = session.get("store_id")

                    if store_id is None:
                        continue

                    store_clients.setdefault(
                        store_id, []
                    ).append(websocket)

                for store_id, clients in store_clients.items():

                    data = await asyncio.to_thread(
                        get_events_data,
                        store_id,
                    )
               
                    snapshot = json.dumps(
                        data,
                        sort_keys=True,
                    )

                    if snapshot != self._last_snapshot.get(store_id):

                        await asyncio.gather(
                            *(
                                self._send(client, snapshot)
                                for client in clients
                            )
                        )

                        self._last_snapshot[store_id] = snapshot

            except Exception:
                logger.exception("Unable to broadcast event updates")

            await asyncio.sleep(1)
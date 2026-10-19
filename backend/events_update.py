import asyncio
import json
import logging

from event_page_handler import get_events_data


logger = logging.getLogger(__name__)

class EventsUpdates:
    def __init__(self):
        self._clients = set()
        self._last_snapshot = None

    def add_client(self, websocket):
        self._clients.add(websocket)

    def remove_client(self, websocket):
        self.discard(websocket)

    async def _send(self, websocket, message):
        try:
            await websocket.send(message)
        except Exception:
            self.remove_client(websocket)

    async def watch(self):
        while True:
            try:
                if self._clients:
                    data = await asyncio.to_thread(get_events_data)

                    snapshot = json.dumps(
                        data,
                        sort_keys=True,
                    )

                    if snapshot != self._last_snapshot:
                        clients = tuple(self._clients)

                        await asyncio.gather(
                            *(
                                self._send(client, snapshot)
                                for client in clients
                            )
                        )

                        self._last_snapshot = snapshot

            except Exception:
                logger.exception("Unable to broadcast event updates")

            await asyncio.sleep(1)
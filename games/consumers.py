import json
from channels.generic.websocket import AsyncWebsocketConsumer
from asgiref.sync import sync_to_async
from games.services import move_service, room_service


class GameConsumer(AsyncWebsocketConsumer):
    async def connect(self):
        self.room_id = self.scope['url_route']['kwargs']['room_id']
        self.room_group_name = f'game_{self.room_id}'

        # Use Django session key as stable identifier — same as HTTP views.
        # This ensures the player is always recognised as the same person
        # regardless of which endpoint (HTTP or WS) they use.
        session = self.scope.get('session')
        if session:
            if not session.session_key:
                await sync_to_async(session.create)()
            self.player_id = session.session_key
        else:
            self.player_id = None

        # Join the channel-layer room group
        await self.channel_layer.group_add(
            self.room_group_name,
            self.channel_name
        )

        await self.accept()

        if self.player_id:
            # Auto-join: register player in the room if there is an empty slot
            try:
                await sync_to_async(room_service.join_room)(self.room_id, self.player_id)
            except Exception:
                pass

            # Notify everyone in the room that a player has connected
            await self.channel_layer.group_send(
                self.room_group_name,
                {
                    "type": "game_update",
                    "data": {
                        "type": "player_joined",
                        "username": self.player_id
                    }
                }
            )

            # Send the full current game state back to this connection only
            try:
                sync_data = await sync_to_async(room_service.get_sync_data)(
                    self.room_id, self.player_id
                )
                await self.send(text_data=json.dumps({
                    "type": "connection_success",
                    **sync_data
                }))
            except Exception as e:
                await self.send(text_data=json.dumps({
                    "type": "error",
                    "message": str(e)
                }))

    async def disconnect(self, close_code):
        if getattr(self, 'player_id', None):
            await self.channel_layer.group_send(
                self.room_group_name,
                {
                    "type": "game_update",
                    "data": {
                        "type": "player_left",
                        "username": self.player_id
                    }
                }
            )

        await self.channel_layer.group_discard(
            self.room_group_name,
            self.channel_name
        )

    async def receive(self, text_data):
        try:
            text_data_json = json.loads(text_data)
            message_type = text_data_json.get('type')

            # Always use server-side session identity.
            # Never trust a 'player' field sent from the client — it could be spoofed
            # or belong to the wrong session.
            identifier = self.player_id

            if message_type == 'sync':
                sync_data = await sync_to_async(room_service.get_sync_data)(
                    self.room_id, identifier
                )
                await self.send(text_data=json.dumps({
                    "type": "sync_state",
                    **sync_data
                }))
                return

            if message_type == 'surrender':
                broadcast_data = await sync_to_async(room_service.handle_surrender)(
                    self.room_id, identifier
                )
                await self.channel_layer.group_send(
                    self.room_group_name,
                    {
                        "type": "game_update",
                        "data": broadcast_data
                    }
                )
                return

            if message_type == 'move':
                move_data = {
                    "from": text_data_json.get('from'),
                    "to": text_data_json.get('to')
                }

                broadcast_data = await sync_to_async(move_service.handle_socket_move)(
                    self.room_id, identifier, move_data
                )

                await self.channel_layer.group_send(
                    self.room_group_name,
                    {
                        "type": "game_update",
                        "data": broadcast_data
                    }
                )

        except Exception as e:
            await self.send(text_data=json.dumps({
                "type": "error",
                "message": str(e)
            }))

    async def game_update(self, event):
        """Forward group broadcast to this WebSocket connection."""
        await self.send(text_data=json.dumps(event['data']))

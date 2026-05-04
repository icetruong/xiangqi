import json
from urllib.parse import parse_qs
from channels.generic.websocket import AsyncWebsocketConsumer
from asgiref.sync import sync_to_async
from games.services import move_service, room_service

class GameConsumer(AsyncWebsocketConsumer):
    async def connect(self):
        self.room_id = self.scope['url_route']['kwargs']['room_id']
        self.room_group_name = f'game_{self.room_id}'

        query_string = self.scope.get('query_string', b'').decode('utf-8')
        query_params = parse_qs(query_string)
        self.player_id = query_params.get('player', [None])[0]

        # Tham gia room group
        await self.channel_layer.group_add(
            self.room_group_name,
            self.channel_name
        )

        await self.accept()

        if self.player_id:
            # Try to auto-join the player to the room if there is an empty slot
            try:
                await sync_to_async(room_service.join_room)(self.room_id, self.player_id)
            except Exception:
                pass

            # Báo cho phòng biết có người vào
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
            # Gửi lại toàn bộ state ngay khi connect cho người dùng này
            try:
                sync_data = await sync_to_async(room_service.get_sync_data)(self.room_id, self.player_id)
                await self.send(text_data=json.dumps({
                    "type": "connection_success",
                    **sync_data
                }))
            except Exception as e:
                await self.send(text_data=json.dumps({"type": "error", "message": str(e)}))

    async def disconnect(self, close_code):
        if getattr(self, 'player_id', None):
            # Báo cho phòng biết có người thoát
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

        # Rời room group
        await self.channel_layer.group_discard(
            self.room_group_name,
            self.channel_name
        )

    # Nhận message từ WebSocket
    async def receive(self, text_data):
        try:
            text_data_json = json.loads(text_data)
            message_type = text_data_json.get('type')

            if message_type == 'sync':
                identifier = text_data_json.get('player', self.player_id)
                sync_data = await sync_to_async(room_service.get_sync_data)(self.room_id, identifier)
                await self.send(text_data=json.dumps({
                    "type": "sync_state",
                    **sync_data
                }))
                return

            if message_type == 'surrender':
                identifier = text_data_json.get('player', self.player_id)
                broadcast_data = await sync_to_async(room_service.handle_surrender)(self.room_id, identifier)
                await self.channel_layer.group_send(
                    self.room_group_name,
                    {
                        "type": "game_update",
                        "data": broadcast_data
                    }
                )
                return

            if message_type == 'move':
                identifier = text_data_json.get('player', self.player_id)
                move_data = {
                    "from": text_data_json.get('from'),
                    "to": text_data_json.get('to')
                }

                # Thực thi logic move trong DB thông qua service synchronous
                broadcast_data = await sync_to_async(move_service.handle_socket_move)(
                    self.room_id, identifier, move_data
                )
                
                # Broadcast lại nước đi hợp lệ và trạng thái cho toàn phòng
                await self.channel_layer.group_send(
                    self.room_group_name,
                    {
                        "type": "game_update",
                        "data": broadcast_data
                    }
                )
        except Exception as e:
            # Gửi lỗi ngược lại cho riêng client request
            await self.send(text_data=json.dumps({
                "type": "error",
                "message": str(e)
            }))
            
    # Hàm handler được gọi khi group_send kích hoạt
    async def game_update(self, event):
        data = event['data']
        # Gửi dữ liệu ra kênh websocket đến frontend
        await self.send(text_data=json.dumps(data))

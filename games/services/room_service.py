import random
import string
from django.db import transaction
from games.models import Room
from games.services import game_service

def generate_room_code(length=6):
    return ''.join(random.choices(string.ascii_uppercase + string.digits, k=length))

def create_room(identifier):
    with transaction.atomic():
        room_code = generate_room_code()
        while Room.objects.filter(room_code=room_code).exists():
            room_code = generate_room_code()
        
        # Create a PvP game without AI
        game = game_service.create_new_game(difficulty='pvp', player_side='r')
        game.ai_side = 'n' # Placeholder for none to prevent AI trigger
        game.save()
        
        room = Room.objects.create(room_code=room_code, game=game, status='waiting', player_red=identifier)
        return room

def join_room(room_code, identifier):
    with transaction.atomic():
        room = Room.objects.select_for_update().get(room_code=room_code)
        
        # User already in room
        if room.player_red == identifier:
            return room, 'r'
        if room.player_black == identifier:
            return room, 'b'
            
        # Try to assign available player slot
        if not room.player_red:
            room.player_red = identifier
            room.save()
            return room, 'r'
        elif not room.player_black:
            room.player_black = identifier
            if room.status == 'waiting':
                room.status = 'playing'
            room.save()
            return room, 'b'
        else:
            # Room is full, client becomes spectator
            return room, 'spectator'

def get_sync_data(room_code, identifier):
    try:
        room = Room.objects.get(room_code=room_code)
    except Room.DoesNotExist:
        raise ValueError("Phòng không tồn tại")
        
    side = 'spectator'
    if room.player_red == identifier:
        side = 'r'
    elif room.player_black == identifier:
        side = 'b'
        
    game = room.game
    return {
        "room_id": room_code,
        "status": room.status, 
        "current_turn": game.current_turn,
        "board_state": game.board_state,
        "side": side,
        "winner": game.winner,
        "end_reason": game.end_reason
    }

def handle_surrender(room_code, identifier):
    with transaction.atomic():
        try:
            room = Room.objects.select_for_update().get(room_code=room_code)
        except Room.DoesNotExist:
            raise ValueError("Phòng không tồn tại")
            
        if room.status != 'playing':
            raise ValueError("Không thể đầu hàng lúc này")
            
        game = room.game
        if room.player_red == identifier:
            game.winner = 'b'
        elif room.player_black == identifier:
            game.winner = 'r'
        else:
            raise ValueError("Bạn không đóng vai trò nào trong ván này để đầu hàng")
            
        game.status = 'finished'
        game.end_reason = 'resign'
        game.save()
        
        room.status = 'finished'
        room.save()
        
        return {
            "type": "game_over",
            "winner": "red" if game.winner == "r" else "black",
            "reason": "resign",
            "surrenderer": identifier
        }

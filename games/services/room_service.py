import random
import string
from django.db import transaction
from games.models import Room
from games.services import engine_adapter, game_service

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
            
        # Fallback for an unexpected half-empty room with no red player.
        if not room.player_red:
            room.player_red = identifier
            room.save(update_fields=['player_red'])
            return room, 'r'

        # The room creator is always red; the joiner is always black.
        if not room.player_black:
            room.player_black = identifier
            room.status = 'playing'
            room.save(update_fields=['player_red', 'player_black', 'status'])
            return room, 'b'

        # Room is full, client becomes spectator
        return room, 'spectator'


def _serialize_last_move(game):
    last_move = game.moves.last()
    if not last_move:
        return None
    return {
        "from": [last_move.from_row, last_move.from_col],
        "to": [last_move.to_row, last_move.to_col],
        "piece": last_move.piece,
        "captured": last_move.captured,
    }


def _serialize_move_history(game):
    return [
        {
            "ply": move.ply,
            "side": move.side,
            "from": [move.from_row, move.from_col],
            "to": [move.to_row, move.to_col],
            "piece": move.piece,
            "captured": move.captured,
        }
        for move in game.moves.all()
    ]

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
    legal_moves = []
    if side in ('r', 'b') and room.status == 'playing' and game.status == 'ongoing' and game.current_turn == side:
        legal_moves = engine_adapter.list_legal_moves(game.board_state, side)

    return {
        "room_id": room_code,
        "status": room.status, 
        "current_turn": game.current_turn,
        "board_state": game.board_state,
        "side": side,
        "winner": game.winner,
        "reason": game.end_reason,
        "last_move": _serialize_last_move(game),
        "move_history": _serialize_move_history(game),
        "legal_moves": legal_moves,
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
            "status": "finished",
            "winner": game.winner,
            "reason": "resign",
            "surrenderer": identifier,
            "board_state": game.board_state,
            "current_turn": game.current_turn,
            "last_move": _serialize_last_move(game),
        }

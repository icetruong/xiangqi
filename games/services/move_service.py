from django.db import transaction
from games.models import Room, Game
from games.services import engine_adapter
from games.services.game_service import _save_move

def apply_pvp_move(game_id, move_data, side):
    try:
        game = Game.objects.get(id=game_id)
    except Game.DoesNotExist:
        raise ValueError("Game not found")

    if game.status != 'ongoing':
        raise ValueError("Game is finished")

    if game.current_turn != side:
        # Nếu chưa đến lượt
        raise ValueError(f"Chưa đến lượt của bạn")

    try:
        new_board, meta = engine_adapter.apply_move(
            game.board_state,
            side,
            move_data,
        )
    except ValueError as e:
        raise ValueError(str(e))

    _save_move(game, move_data, side, meta)

    game.board_state = new_board
    game.current_turn = 'b' if side == 'r' else 'r'
    game.save()

    status, winner, reason = engine_adapter.check_endgame(new_board, game.current_turn)
    if status == 'finished':
        game.status = status
        game.winner = winner
        game.end_reason = reason
        game.save()

    return game, meta

def handle_socket_move(room_code, identifier, move_data):
    with transaction.atomic():
        try:
            room = Room.objects.select_for_update().get(room_code=room_code)
        except Room.DoesNotExist:
            raise ValueError("Phòng không tồn tại")
            
        if room.status != 'playing':
            raise ValueError("Trận đấu chưa bắt đầu hoặc đã kết thúc")
            
        side = None
        if room.player_red == identifier:
            side = 'r'
        elif room.player_black == identifier:
            side = 'b'
        else:
            raise ValueError("Bạn không phải là người chơi trong phòng này")
            
        game, meta = apply_pvp_move(room.game.id, move_data, side)
        
        return {
            "type": "move",
            "player": identifier,
            "side": side,
            "from": move_data['from'],
            "to": move_data['to'],
            "current_turn": game.current_turn,
            "board_state": game.board_state,
            "piece": meta.get('piece'),
            "captured": meta.get('captured')
        }

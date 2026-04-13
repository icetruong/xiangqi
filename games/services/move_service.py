from django.db import transaction

from games.models import Game, Room
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
        raise ValueError("Chua den luot cua ban")

    try:
        new_board, meta = engine_adapter.apply_move(
            game.board_state,
            side,
            move_data,
        )
    except ValueError as exc:
        raise ValueError(str(exc))

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
            raise ValueError("Phong khong ton tai")

        if room.status != 'playing':
            raise ValueError("Tran dau chua bat dau hoac da ket thuc")

        side = None
        if room.player_red == identifier:
            side = 'r'
        elif room.player_black == identifier:
            side = 'b'
        else:
            raise ValueError("Ban khong phai nguoi choi trong phong nay")

        game, meta = apply_pvp_move(room.game.id, move_data, side)

        if game.status == 'finished' and room.status != 'finished':
            room.status = 'finished'
            room.save(update_fields=['status'])

        return {
            "type": "move",
            "player": identifier,
            "side": side,
            "from": move_data['from'],
            "to": move_data['to'],
            "current_turn": game.current_turn,
            "board_state": game.board_state,
            "piece": meta.get('piece'),
            "captured": meta.get('captured'),
            "last_move": {
                "from": move_data['from'],
                "to": move_data['to'],
                "piece": meta.get('piece'),
                "captured": meta.get('captured'),
            },
            "status": room.status,
            "winner": game.winner,
            "reason": game.end_reason,
        }

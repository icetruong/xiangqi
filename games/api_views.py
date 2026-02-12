from rest_framework.decorators import api_view
from rest_framework.response import Response
from rest_framework import status
from games.models import Game
from games.services import game_service, engine_adapter

@api_view(['POST'])
def create_game(request):
    difficulty = request.data.get('difficulty', 'normal')
    player_side = request.data.get('player_side', 'r')
    
    try:
        game = game_service.create_new_game(
            difficulty=difficulty,
            player_side=player_side
        )
        return Response({
            "ok": True,
            "game_id": game.id,
            "board_state": game.board_state,
            "current_turn": game.current_turn,
            "status": game.status,
            "difficulty": game.difficulty
        }, status=status.HTTP_201_CREATED)
    except Exception as e:
        return Response({
            "ok": False,
            "error_code": "SERVER_ERROR",
            "message": str(e)
        }, status=status.HTTP_500_INTERNAL_SERVER_ERROR)

@api_view(['GET'])
def game_detail(request, game_id):
    try:
        game = Game.objects.get(id=game_id)
    except Game.DoesNotExist:
        return Response({
            "ok": False,
            "error_code": "GAME_NOT_FOUND",
            "message": "Game not found"
        }, status=status.HTTP_404_NOT_FOUND)

    # Get last move
    last_move = game.moves.last()
    last_move_data = None
    if last_move:
        last_move_data = {
            "from": [last_move.from_row, last_move.from_col],
            "to": [last_move.to_row, last_move.to_col],
            "piece": last_move.piece,
            "captured": last_move.captured
        }

    return Response({
        "ok": True,
        "game_id": game.id,
        "board_state": game.board_state,
        "current_turn": game.current_turn,
        "status": game.status,
        "winner": game.winner,
        "end_reason": game.end_reason,
        "last_move": last_move_data
    })

@api_view(['POST'])
def make_move(request, game_id):
    try:
        move_data = request.data
        # Validate move format
        if 'from' not in move_data or 'to' not in move_data:
            return Response({
                "ok": False,
                "error_code": "BAD_REQUEST",
                "message": "Missing 'from' or 'to' in request body"
            }, status=status.HTTP_400_BAD_REQUEST)

        game, last_move_meta = game_service.handle_player_move(game_id, move_data)
        
        # Serialize last move
        last_move_response = None
        # Note: last_move_meta here is the dict returned by engine_adapter.apply_move
        # But we really want the coordinates too.
        # game_service returns meta... 
        # Actually handle_player_move returns (game, last_move_info).
        # But wait, create_game returns game object.
        
        # We need to construct the response properly.
        # If AI moved, we want AI's move.
        # 'from'/'to' are not in 'meta' from apply_move unless we put them there.
        # Let's fix game_service logic in my head or adjust response here.
        
        # In game_service:
        # ai_move = engine_adapter.pick_ai_move -> returns {"from":..., "to":...}
        # But apply_move returns meta {"piece":..., "captured":...}
        
        # We need to combine them.
        # game_service.handle_player_move returns (game, last_move_info) 
        # where last_move_info should be sufficient.
        
        # If I look at `game_service.py` again:
        # It calls `pick_ai_move` -> gets generic move dict
        # It calls `apply_move` -> gets meta
        # It returns ... something.
        
        # I should probably just query the DB for the last move, it's safer and cleaner.
        last_move = game.moves.last()
        last_move_data = None
        if last_move:
            last_move_data = {
                "from": [last_move.from_row, last_move.from_col],
                "to": [last_move.to_row, last_move.to_col],
                "piece": last_move.piece,
                "captured": last_move.captured
            }

        return Response({
            "ok": True,
            "board_state": game.board_state,
            "current_turn": game.current_turn,
            "status": game.status,
            "winner": game.winner,
            "end_reason": game.end_reason,
            "last_move": last_move_data
        })

    except ValueError as e:
        return Response({
            "ok": False,
            "error_code": "INVALID_MOVE", # Or NOT_YOUR_TURN etc.
            "message": str(e)
        }, status=status.HTTP_400_BAD_REQUEST)
    except Exception as e:
        return Response({
            "ok": False,
            "error_code": "SERVER_ERROR",
            "message": str(e)
        }, status=status.HTTP_500_INTERNAL_SERVER_ERROR)

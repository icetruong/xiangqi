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

        import threading

        # 1. Apply Player Move
        game, player_move_meta = game_service.apply_player_move(game_id, move_data)
        
        # 2. Trigger AI Move in Background
        if game.status == 'ongoing' and game.current_turn == game.ai_side:
            t = threading.Thread(target=game_service.process_ai_move, args=(game_id,))
            t.daemon = True # Daemon thread so it doesn't block server shutdown
            t.start()
        
        # 3. Construct Response (Immediate)
        # We return the state AFTER player move.
        # The frontend will see "Turn: b" (AI) and should start polling.
        
        last_move_data = {
            "from": move_data['from'],
            "to": move_data['to'],
            "piece": player_move_meta.get('piece'),
            "captured": player_move_meta.get('captured')
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

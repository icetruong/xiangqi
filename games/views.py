from django.shortcuts import render, get_object_or_404, redirect
from games.models import Game
from games.services import game_service
import json

def index(request):
    if request.method == "POST":
        # Create new game logic directly in view for simplicity, or call service
        difficulty = request.POST.get('difficulty', 'normal')
        player_side = request.POST.get('player_side', 'r')
        ai_side = 'b' if player_side == 'r' else 'r'
        
        game = game_service.create_new_game(
            difficulty=difficulty,
            player_side=player_side,
            ai_side=ai_side
        )
        return redirect('games:game_board', game_id=game.id)
        
    return render(request, 'games/index.html')

def game_board(request, game_id):
    # Verify game exists
    game = get_object_or_404(Game, id=game_id)
    
    legal_moves = []
    if game.status == 'ongoing' and game.current_turn == game.player_side:
        from games.services import engine_adapter
        legal_moves = engine_adapter.list_legal_moves(game.board_state, game.player_side)
    
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

    return render(request, 'games/game.html', {
        'game': game,
        'board_state_json': json.dumps(game.board_state),
        'legal_moves_json': json.dumps(legal_moves),
        'last_move_json': json.dumps(last_move_data),
    })

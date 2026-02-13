from django.shortcuts import render, get_object_or_404, redirect
from games.models import Game
from games.services import game_service

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
        
    return render(request, 'games/game.html', {'game': game, 'legal_moves': legal_moves})

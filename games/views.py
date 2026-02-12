from django.shortcuts import render, get_object_or_404
from games.models import Game

def game_board(request, game_id):
    # Verify game exists
    game = get_object_or_404(Game, id=game_id)
    return render(request, 'games/game.html', {'game': game})

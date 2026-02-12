import os
import django
import sys

# Setup Django
sys.path.append(os.getcwd())
os.environ.setdefault("DJANGO_SETTINGS_MODULE", "xiangqi_project.settings")
django.setup()

from games.services import game_service
from games.models import Game, Move

def verify_full_flow():
    print("--- 1. Creating new game ---")
    game = game_service.create_new_game(difficulty='easy')
    print(f"Game ID: {game.id}")
    print(f"Status: {game.status}")
    print(f"Turn: {game.current_turn}")
    
    assert game.status == 'ongoing'
    assert game.current_turn == 'r'
    
    print("\n--- 2. Player makes a move (Red Cannon) ---")
    # Move Red Cannon from (7,1) to (7,4)
    move_data = {"from": [7, 1], "to": [7, 4]}
    
    game, meta = game_service.handle_player_move(game.id, move_data)
    
    print(f"After Player Move:")
    print(f"Turn: {game.current_turn}")
    print(f"Status: {game.status}")
    
    # Check if AI moved?
    # handle_player_move returns after AI move unless game ended.
    # Current turn should be 'r' again if AI moved successfully.
    # OR 'b' if AI failed/game ended?
    # My game_service implementation switches to 'b', runs AI, switches to 'r'.
    
    assert game.current_turn == 'r' 
    
    last_move = game.moves.last()
    print(f"Last Move in DB: {last_move}")
    # Last move should be Black's move (AI)
    assert last_move.side == 'b'
    
    print("\n--- 3. Check Move History ---")
    moves = Move.objects.filter(game=game).order_by('ply')
    for m in moves:
        print(f"Ply {m.ply}: {m.side} {m.piece} {m.from_row},{m.from_col} -> {m.to_row},{m.to_col}")
        
    assert moves.count() == 2 # 1 Player + 1 AI
    
    print("\n--- VERIFICATION SUCCESSFUL ---")

if __name__ == "__main__":
    try:
        verify_full_flow()
    except Exception as e:
        print(f"\nFAILED: {e}")
        import traceback
        traceback.print_exc()

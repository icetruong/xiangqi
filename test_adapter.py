import sys
import os

# Add project root to sys.path so we can import 'games' and 'engine'
sys.path.append(os.getcwd())

from games.services import engine_adapter
from engine.enums import Color

def test_adapter():
    print("Testing init_game_state...")
    board = engine_adapter.init_game_state()
    assert len(board) == 10
    assert len(board[0]) == 9
    # Check Red King at (9,4)
    assert board[9][4] == "rK"
    # Check Black King at (0,4)
    assert board[0][4] == "bK"
    # Check empty square is ""
    assert board[1][1] == ""
    print("PASS: init_game_state")

    print("\nTesting apply_move (valid)...")
    # Move Red Cannon from (7,1) to (7,4) - Valid opening
    # Note: in Xiangqi 2.0, (7,1) is correct row index for Red Cannon?
    # Board:
    # 0-3: Black
    # 4-5: River
    # 6-9: Red
    # Red Cannon at row 7.
    move = {"from": [7, 1], "to": [7, 4]}
    new_board, meta = engine_adapter.apply_move(board, "r", move)
    
    assert new_board[7][1] == ""
    assert new_board[7][4] == "rC"
    print("PASS: apply_move (valid)")

    print("\nTesting list_legal_moves...")
    moves = engine_adapter.list_legal_moves(new_board, "b") # Black's turn
    assert len(moves) > 0
    print(f"PASS: list_legal_moves found {len(moves)} moves for Black")

    print("\nTesting pick_ai_move (random/easy)...")
    ai_move = engine_adapter.pick_ai_move(new_board, "b", "easy")
    print(f"AI picked: {ai_move}")
    
    # Verify we can apply AI move
    board_after_ai, _ = engine_adapter.apply_move(new_board, "b", ai_move)
    print("PASS: pick_ai_move and apply")

if __name__ == "__main__":
    try:
        test_adapter()
        print("\nALL TESTS PASSED!")
    except Exception as e:
        print(f"\nFAILED: {e}")
        import traceback
        traceback.print_exc()

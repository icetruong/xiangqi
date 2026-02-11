from engine.board import Board
from engine.serializer.fen import board_to_fen, load_fen

def test_fen_roundtrip():
    b = Board()
    b.setup_initial()

    fen = board_to_fen(b, turn="r")

    b2 = Board()
    turn = load_fen(b2, fen)

    assert turn == "r"
    assert b2.board == b.board

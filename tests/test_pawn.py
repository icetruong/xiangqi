from engine.board import Board
from engine.rules.move_rules import pawn_moves

def test_red_pawn_before_river_only_forward():
    b = Board()
    b.set(6, 4, "rP")  # đỏ chưa qua sông (sr=6)

    moves = set(pawn_moves(b, (6, 4)))
    assert moves == {(5, 4)}  # chỉ đi lên 1 ô

def test_red_pawn_after_river_can_move_sideways():
    b = Board()
    b.set(4, 4, "rP")  # đỏ đã qua sông (sr=4)

    moves = set(pawn_moves(b, (4, 4)))
    assert (3, 4) in moves      # tiến
    assert (4, 3) in moves      # ngang trái
    assert (4, 5) in moves      # ngang phải
    assert (5, 4) not in moves  # không được lùi

def test_black_pawn_before_river_only_forward():
    b = Board()
    b.set(3, 4, "bP")  # đen chưa qua sông (sr=3)

    moves = set(pawn_moves(b, (3, 4)))
    assert moves == {(4, 4)}  # chỉ đi xuống 1 ô

def test_black_pawn_after_river_can_move_sideways():
    b = Board()
    b.set(5, 4, "bP")  # đen đã qua sông (sr=5)

    moves = set(pawn_moves(b, (5, 4)))
    assert (6, 4) in moves      # tiến
    assert (5, 3) in moves      # ngang trái
    assert (5, 5) in moves      # ngang phải
    assert (4, 4) not in moves  # không được lùi

def test_pawn_cannot_move_into_same_color():
    b = Board()
    b.set(6, 4, "rP")
    b.set(5, 4, "rR")  # quân mình chặn phía trước

    moves = set(pawn_moves(b, (6, 4)))
    assert (5, 4) not in moves
    assert len(moves) == 0

def test_pawn_can_capture_enemy_forward_or_sideways():
    b = Board()
    b.set(4, 4, "rP")  # đỏ đã qua sông
    b.set(3, 4, "bR")  # địch phía trước
    b.set(4, 5, "bP")  # địch ngang phải

    moves = set(pawn_moves(b, (4, 4)))
    assert (3, 4) in moves
    assert (4, 5) in moves

# tests/test_rook.py
from engine.board import Board
from engine.rules.move_rules import rook_moves

def test_rook_free_moves_center_empty():
    b = Board()
    # đặt 1 rook đỏ ở giữa (5,4)
    b.set(5, 4, "rR")

    moves = set(rook_moves(b, (5,4)))

    # rook đi được đến biên theo 4 hướng (trên, dưới, trái, phải)
    assert (0,4) in moves
    assert (9,4) in moves
    assert (5,0) in moves
    assert (5,8) in moves
    # không bao gồm chính nó
    assert (5,4) not in moves

def test_rook_blocked_by_same_color():
    b = Board()
    b.set(5, 4, "rR")
    b.set(5, 6, "rP")  # chặn bên phải

    moves = set(rook_moves(b, (5,4)))
    assert (5,5) in moves
    assert (5,6) not in moves   # không ăn quân mình
    assert (5,7) not in moves   # không đi xuyên qua

def test_rook_can_capture_enemy():
    b = Board()
    b.set(5, 4, "rR")
    b.set(5, 6, "bP")  # quân địch

    moves = set(rook_moves(b, (5,4)))
    assert (5,5) in moves
    assert (5,6) in moves       # ăn được
    assert (5,7) not in moves   # không đi xuyên qua quân bị ăn

from engine.board import Board
from engine.rules.move_rules import king_moves

def test_king_red_center_has_4_moves():
    b = Board()
    b.set(8, 4, "rK")

    moves = set(king_moves(b, (8, 4)))
    expected = {(7, 4), (9, 4), (8, 3), (8, 5)}
    assert moves == expected

def test_king_cannot_leave_palace():
    b = Board()
    b.set(7, 4, "rK")  # cạnh trên cung đỏ

    moves = set(king_moves(b, (7, 4)))
    # không được đi lên (6,4) vì ra ngoài cung
    assert (6, 4) not in moves
    # vẫn đi được 3 hướng còn lại trong cung
    assert (8, 4) in moves
    assert (7, 3) in moves
    assert (7, 5) in moves

def test_king_cannot_capture_same_color():
    b = Board()
    b.set(8, 4, "rK")
    b.set(8, 5, "rP")  # quân mình bên phải

    moves = set(king_moves(b, (8, 4)))
    assert (8, 5) not in moves

def test_king_can_capture_enemy():
    b = Board()
    b.set(8, 4, "rK")
    b.set(8, 5, "bP")  # địch

    moves = set(king_moves(b, (8, 4)))
    assert (8, 5) in moves

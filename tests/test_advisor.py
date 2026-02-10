from engine.board import Board
from engine.rules.move_rules import advisor_moves

def test_in_palace_advisor_red_center_has_4_moves():
    b = Board()
    b.set(8, 4, "rA")  # sĩ đỏ ở giữa cung

    moves = set(advisor_moves(b, (8, 4)))
    expected = {(7, 3), (7, 5), (9, 3), (9, 5)}
    assert moves == expected

def test_advisor_cannot_leave_palace():
    b = Board()
    b.set(7, 3, "rA")  # góc cung

    moves = set(advisor_moves(b, (7, 3)))
    # từ (7,3) chỉ có thể về (8,4) (vì các chéo khác ra ngoài cung)
    assert moves == {(8, 4)}

def test_advisor_blocked_by_same_color():
    b = Board()
    b.set(8, 4, "rA")
    b.set(7, 3, "rP")  # quân mình

    moves = set(advisor_moves(b, (8, 4)))
    assert (7, 3) not in moves
    # các nước còn lại vẫn có
    assert (7, 5) in moves
    assert (9, 3) in moves
    assert (9, 5) in moves

def test_advisor_can_capture_enemy():
    b = Board()
    b.set(8, 4, "rA")
    b.set(7, 3, "bP")  # địch

    moves = set(advisor_moves(b, (8, 4)))
    assert (7, 3) in moves
